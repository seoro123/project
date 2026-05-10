import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../diary/data/models/diary_panel_model.dart';
import '../models/diary_comment_model.dart';
import '../models/social_feed_item_model.dart';

class SupabaseFeedRepository {
  const SupabaseFeedRepository(this._client);

  final SupabaseClient _client;

  /// 공개 완료된 일기를 소셜 피드 집계 view에서 가져옵니다.
  Future<List<SocialFeedItemModel>> fetchFeed({
    String? searchKeyword,
    String? usernameKeyword,
    String? tag,
    List<String> tags = const <String>[],
    int limit = 30,
  }) async {
    dynamic query = _client.from('social_feed_items').select();

    if (searchKeyword != null && searchKeyword.trim().isNotEmpty) {
      query = query.ilike('search_text', '%${searchKeyword.trim()}%');
    }

    if (usernameKeyword != null && usernameKeyword.trim().isNotEmpty) {
      query = query.ilike('username', '%${usernameKeyword.trim()}%');
    }

    final filterTags = <String>[
      if (tag != null && tag.trim().isNotEmpty) tag.trim(),
      ...tags
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty),
    ];

    for (final normalizedTag in filterTags.toSet()) {
      query = query.or(
        'emotion_tags.cs.{"$normalizedTag"},keyword_tags.cs.{"$normalizedTag"}',
      );
    }

    final rows = await query.order('created_at', ascending: false).limit(limit);
    return rows
        .map<SocialFeedItemModel>(
          (dynamic row) =>
              SocialFeedItemModel.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }

  /// 좋아요는 RPC로 토글해 중복 insert/delete 경합 상태를 줄입니다.
  Future<bool> toggleLike(String diaryId) async {
    final result = await _client.rpc<bool>(
      'toggle_diary_like',
      params: <String, dynamic>{'target_diary_id': diaryId},
    );
    return result;
  }

  Future<void> deleteDiary(String diaryId) async {
    await _client.from('diaries').delete().eq('id', diaryId);
  }

  Future<List<String>> fetchDiaryImageUrls(String diaryId) async {
    final rows = await _client
        .from('diary_panels')
        .select('image_url')
        .eq('diary_id', diaryId)
        .order('panel_order');

    return rows
        .map<String?>((dynamic row) {
          final map = row as Map<String, dynamic>;
          return map['image_url'] as String?;
        })
        .whereType<String>()
        .where((String url) => url.trim().isNotEmpty)
        .toList();
  }

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

  /// 댓글을 추가합니다. personaScript는 캐릭터가 읽고 말한 대사를 저장할 때 사용합니다.
  Future<void> addComment({
    required String diaryId,
    required String userId,
    required String content,
    String? personaId,
    String? personaScript,
  }) async {
    await _client.from('diary_comments').insert(<String, dynamic>{
      'diary_id': diaryId,
      'user_id': userId,
      'persona_id': personaId,
      'content': content,
      'persona_script': personaScript,
      'moderation_status': 'pending',
    });
  }

  /// 최신 댓글을 가져와 소셜 상세 화면과 댓글 수 갱신에 사용합니다.
  Future<List<DiaryCommentModel>> fetchComments(String diaryId) async {
    final rows = await _client
        .from('diary_comments')
        .select()
        .eq('diary_id', diaryId)
        .order('created_at', ascending: false);

    return rows
        .map<DiaryCommentModel>(
          (dynamic row) =>
              DiaryCommentModel.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }
}
