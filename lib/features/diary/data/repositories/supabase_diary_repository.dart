import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/enums/diary_art_style.dart';
import '../../../../core/enums/diary_generation_status.dart';
import '../../../../core/enums/diary_genre.dart';
import '../../../../core/enums/weather_type.dart';
import '../../../../core/enums/webtoon_format.dart';
import '../models/diary_album_model.dart';
import '../models/diary_model.dart';
import '../models/diary_panel_model.dart';

class SupabaseDiaryRepository {
  const SupabaseDiaryRepository(this._client);

  final SupabaseClient _client;

  /// 일기를 먼저 DB에 저장하고 Edge Function에서 AI 생성 작업을 이어가도록 호출합니다.
  Future<DiaryModel> createDiary({
    required String userId,
    required String content,
    required DiaryArtStyle artStyle,
    required DiaryGenre genre,
    String? title,
    DateTime? diaryAt,
    WeatherType weather = WeatherType.sunny,
    WebtoonFormat webtoonFormat = WebtoonFormat.cardSlide,
    String? artSubStyle,
    String? genreSubtype,
    List<String> keywordTags = const <String>[],
    String? personaId,
    bool isPublic = false,
  }) async {
    final row = await _client
        .from('diaries')
        .insert(<String, dynamic>{
          'user_id': userId,
          'persona_id': personaId,
          'title': title,
          'diary_at': diaryAt?.toIso8601String(),
          'weather': weather.value,
          'content': content,
          'keyword_tags': keywordTags,
          'art_style': artStyle.value,
          'art_sub_style': artSubStyle,
          'genre': genre.value,
          'genre_subtype': genreSubtype,
          'webtoon_format': webtoonFormat.value,
          'is_public': isPublic,
          'generation_status': DiaryGenerationStatus.queued.value,
        })
        .select()
        .single();

    var diary = DiaryModel.fromJson(row);

    try {
      final response = await _client.functions
          .invoke(
            'generate-diary-assets',
            body: <String, dynamic>{'diary_id': diary.id},
          )
          .timeout(const Duration(seconds: 180));
      if (response.status >= 400) {
        throw Exception(response.data);
      }

      final updatedRow = await _client
          .from('diaries')
          .select()
          .eq('id', diary.id)
          .single();
      diary = DiaryModel.fromJson(updatedRow);
    } catch (error) {
      // AI 이미지 생성이 실패해도 일기 row는 유지해 사용자가 다시 시도할 수 있게 합니다.
      final updatedRow = await _client
          .from('diaries')
          .update(<String, dynamic>{
            'generation_status': DiaryGenerationStatus.failed.value,
            'error_message': error.toString(),
          })
          .eq('id', diary.id)
          .select()
          .single();
      diary = DiaryModel.fromJson(updatedRow);
      throw Exception(error);
    }

    return diary;
  }

  /// 사용자의 일기 목록을 최신순으로 가져옵니다.
  Future<List<DiaryModel>> fetchMyDiaries(String userId) async {
    final rows = await _client
        .from('diaries')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows
        .map<DiaryModel>(
          (dynamic row) => DiaryModel.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }

  /// 일기 컷 목록을 순서대로 가져와 슬라이드/재시도 UI의 기준 데이터로 사용합니다.
  Future<List<DiaryPanelModel>> fetchDiaryPanels(String diaryId) async {
    final rows = await _client
        .from('diary_panels')
        .select()
        .eq('diary_id', diaryId)
        .order('panel_order');

    return rows
        .map<DiaryPanelModel>(
          (dynamic row) =>
              DiaryPanelModel.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }

  /// 컷 단위 재시도 요청을 상태와 카운트에 기록한 뒤 Edge Function에 위임합니다.
  Future<DiaryPanelModel> updateDiaryPanelImageUrl({
    required String panelId,
    required String imageUrl,
  }) async {
    final row = await _client
        .from('diary_panels')
        .update(<String, dynamic>{'image_url': imageUrl})
        .eq('id', panelId)
        .select()
        .single();

    return DiaryPanelModel.fromJson(row);
  }

  Future<void> updateDiaryImageUrls({
    required String diaryId,
    required List<String> imageUrls,
  }) async {
    await _client
        .from('diaries')
        .update(<String, dynamic>{'image_urls': imageUrls})
        .eq('id', diaryId);
  }

  Future<void> retryDiaryPanel({
    required String diaryId,
    required String panelId,
  }) async {
    await _client.rpc<void>(
      'request_diary_panel_retry',
      params: <String, dynamic>{'target_panel_id': panelId},
    );
    await _client.functions.invoke(
      'generate-diary-assets',
      body: <String, dynamic>{
        'diary_id': diaryId,
        'panel_id': panelId,
        'mode': 'retry_panel',
      },
    );
  }

  /// 앨범 목록과 앨범에 들어간 일기 ID를 함께 가져옵니다.
  Future<List<DiaryAlbumModel>> fetchMyAlbums(String userId) async {
    final rows = await _client
        .from('diary_albums')
        .select('*, diary_album_items(diary_id, sort_order)')
        .eq('user_id', userId)
        .order('sort_order')
        .order('created_at', ascending: false);

    return rows
        .map<DiaryAlbumModel>(
          (dynamic row) =>
              DiaryAlbumModel.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }

  /// 새 앨범을 만듭니다.
  Future<DiaryAlbumModel> createAlbum({
    required String userId,
    required String title,
    String? description,
    String colorHex = '#86BFFF',
    bool isPublic = true,
  }) async {
    final row = await _client
        .from('diary_albums')
        .insert(<String, dynamic>{
          'user_id': userId,
          'title': title,
          'description': description,
          'color_hex': colorHex,
          'is_public': isPublic,
        })
        .select()
        .single();

    return DiaryAlbumModel.fromJson(row);
  }

  /// 앨범 안에 본인 일기를 추가합니다. DB 트리거와 RLS가 소유권을 한 번 더 검증합니다.
  Future<void> addDiaryToAlbum({
    required String userId,
    required String albumId,
    required String diaryId,
  }) async {
    await _client.from('diary_album_items').upsert(<String, dynamic>{
      'user_id': userId,
      'album_id': albumId,
      'diary_id': diaryId,
    }, onConflict: 'album_id,diary_id');
  }

  /// 앨범-일기 연결이 RLS에 막힌 경우를 대비해, 게스트 프로토타입용 RPC 없이
  /// 공개 앨범 기준으로 한 번 더 시도합니다. 정책이 적용된 뒤에는 위 upsert만으로
  /// 정상 동작하지만, 이미 생성된 앨범의 공개 플래그가 늦게 반영된 경우를 완충합니다.
  Future<void> addDiaryToAlbumAfterEnsuringPublic({
    required String userId,
    required String albumId,
    required String diaryId,
  }) async {
    await _client
        .from('diary_albums')
        .update(<String, dynamic>{'is_public': true})
        .eq('id', albumId)
        .eq('user_id', userId);

    await addDiaryToAlbum(userId: userId, albumId: albumId, diaryId: diaryId);
  }

  /// 앨범에 소장된 일기를 최신순으로 가져옵니다. diary_album_items를 기준으로
  /// 조인해서, 사용자가 어느 앨범에 무엇을 넣었는지 아카이브 화면에서 바로 보여 줍니다.
  Future<List<DiaryModel>> fetchAlbumDiaries(String albumId) async {
    final rows = await _client
        .from('diary_album_items')
        .select('diaries(*)')
        .eq('album_id', albumId)
        .order('sort_order')
        .order('created_at', ascending: false);

    return rows
        .map<DiaryModel?>((dynamic row) {
          final map = row as Map<String, dynamic>;
          final diary = map['diaries'];
          if (diary is Map<String, dynamic>) {
            return DiaryModel.fromJson(diary);
          }
          return null;
        })
        .whereType<DiaryModel>()
        .toList();
  }
}
