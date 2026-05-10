import 'package:ai_diary_social_platform/core/enums/diary_art_style.dart';
import 'package:ai_diary_social_platform/core/enums/diary_generation_status.dart';
import 'package:ai_diary_social_platform/core/enums/diary_genre.dart';
import 'package:ai_diary_social_platform/core/enums/persona_input_mode.dart';
import 'package:ai_diary_social_platform/core/enums/weather_type.dart';
import 'package:ai_diary_social_platform/core/enums/webtoon_format.dart';
import 'package:ai_diary_social_platform/features/diary/data/models/diary_model.dart';
import 'package:ai_diary_social_platform/features/diary/data/models/diary_panel_model.dart';
import 'package:ai_diary_social_platform/features/feed/data/models/social_feed_item_model.dart';
import 'package:ai_diary_social_platform/features/persona/data/models/persona_model.dart';
import 'package:ai_diary_social_platform/features/profile/data/models/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileModel', () {
    test('pgvector 문자열과 배열을 모두 안전하게 파싱한다', () {
      final fromString = ProfileModel.fromJson(<String, dynamic>{
        'id': 'user-1',
        'username': 'milo',
        'display_name': 'Milo',
        'bio': null,
        'avatar_url': null,
        'tendency_vector': '[0.1, 0.2, 0.3]',
        'is_public': true,
        'created_at': '2026-04-19T00:00:00.000Z',
        'updated_at': '2026-04-19T00:00:00.000Z',
      });

      final fromList = ProfileModel.fromJson(<String, dynamic>{
        'id': 'user-2',
        'username': 'nora',
        'display_name': null,
        'bio': 'hello',
        'avatar_url': 'https://example.com/avatar.png',
        'tendency_vector': <double>[0.4, 0.5],
        'is_public': false,
        'created_at': '2026-04-19T00:00:00.000Z',
        'updated_at': '2026-04-19T00:00:00.000Z',
      });

      expect(fromString.tendencyVector, <double>[0.1, 0.2, 0.3]);
      expect(fromString.displayName, 'Milo');
      expect(fromList.tendencyVector, <double>[0.4, 0.5]);
    });
  });

  group('PersonaModel', () {
    test('감정 프롬프트와 표정 라이브러리 JSON을 문자열 맵으로 유지한다', () {
      final model = PersonaModel.fromJson(<String, dynamic>{
        'id': 'persona-1',
        'user_id': 'user-1',
        'name': '아라',
        'appearance_desc': '긴 검은 머리와 민트색 후드티를 입은 캐릭터',
        'emotion_prompts': <String, dynamic>{
          'happy': '활짝 웃는 표정',
          'sad': '눈시울이 붉어진 표정',
        },
        'expression_library': <String, dynamic>{
          'happy': 'https://example.com/happy.png',
        },
        'default_seed': 777,
        'default_art_style': 'anime_ld',
        'default_genre': 'healing_romance',
        'is_primary': true,
        'input_mode': 'tags',
        'appearance_tags': <String, dynamic>{
          'hair': <String>['black', 'long'],
          'top': 'mint hoodie',
        },
        'base_image_url': 'https://example.com/base.png',
        'template_visibility': 'public',
        'created_at': '2026-04-19T00:00:00.000Z',
        'updated_at': '2026-04-19T00:00:00.000Z',
      });

      expect(model.defaultArtStyle, DiaryArtStyle.animeLd);
      expect(model.defaultGenre, DiaryGenre.healingRomance);
      expect(model.inputMode, PersonaInputMode.tags);
      expect(model.emotionPrompts['happy'], '활짝 웃는 표정');
      expect(model.expressionLibrary['happy'], 'https://example.com/happy.png');
      expect(model.appearanceTags, containsAll(<String>['black', 'long']));
      expect(model.baseImageUrl, 'https://example.com/base.png');
      expect(model.templateVisibility, 'public');
    });
  });

  group('DiaryModel', () {
    test('대기, 처리, 완료, 실패 상태를 enum으로 변환한다', () {
      expect(
        DiaryGenerationStatus.fromValue('queued'),
        DiaryGenerationStatus.queued,
      );
      expect(
        DiaryGenerationStatus.fromValue('processing'),
        DiaryGenerationStatus.processing,
      );
      expect(
        DiaryGenerationStatus.fromValue('completed'),
        DiaryGenerationStatus.completed,
      );
      expect(
        DiaryGenerationStatus.fromValue('failed'),
        DiaryGenerationStatus.failed,
      );
    });

    test('웹툰 형식, 날씨, 태그, 날짜 필드를 안정적으로 파싱한다', () {
      final model = DiaryModel.fromJson(<String, dynamic>{
        'id': 'diary-1',
        'user_id': 'user-1',
        'persona_id': null,
        'title': '비 오는 카페',
        'diary_at': '2026-04-19T12:30:00.000Z',
        'weather': 'rainy',
        'content': '오늘은 정말 즐거운 하루였다.',
        'summary': '즐거운 하루',
        'emotion_tags': <String>['calm', 'grateful'],
        'keyword_tags': <String>['카페', '비'],
        'art_style': 'comics_ld',
        'genre': 'daily_comic',
        'genre_subtype': 'sitcom',
        'webtoon_format': 'qa_slide',
        'image_urls': <String>[
          'https://example.com/1.png',
          'https://example.com/2.png',
        ],
        'is_public': true,
        'generation_status': 'failed',
        'structured_result': <String, dynamic>{'panels': 2, 'tone': 'warm'},
        'generation_seed': 1010,
        'retry_count': 2,
        'error_message': 'timeout',
        'created_at': '2026-04-19T00:00:00.000Z',
        'updated_at': '2026-04-19T00:00:00.000Z',
      });

      expect(model.title, '비 오는 카페');
      expect(model.diaryAt, DateTime.parse('2026-04-19T12:30:00.000Z'));
      expect(model.weather, WeatherType.rainy);
      expect(model.webtoonFormat, WebtoonFormat.qaSlide);
      expect(model.keywordTags, <String>['카페', '비']);
      expect(model.generationStatus, DiaryGenerationStatus.failed);
      expect(model.structuredResult['panels'], 2);
      expect(model.imageUrls.length, 2);
      expect(model.isPublic, isTrue);
      expect(model.retryCount, 2);
      expect(model.errorMessage, 'timeout');
    });
  });

  group('DiaryPanelModel', () {
    test('컷 단위 생성 상태와 재시도 횟수를 파싱한다', () {
      final model = DiaryPanelModel.fromJson(<String, dynamic>{
        'id': 'panel-1',
        'diary_id': 'diary-1',
        'panel_order': 0,
        'panel_type': 'reaction',
        'image_url': 'https://example.com/panel.png',
        'dialogue': '오늘 기분은?',
        'prompt': 'pastel reaction panel',
        'seed': 777,
        'generation_status': 'processing',
        'retry_count': 1,
        'error_message': null,
        'created_at': '2026-04-19T00:00:00.000Z',
        'updated_at': '2026-04-19T00:00:00.000Z',
      });

      expect(model.panelType, 'reaction');
      expect(model.generationStatus, DiaryGenerationStatus.processing);
      expect(model.retryCount, 1);
    });
  });

  group('SocialFeedItemModel', () {
    test('검색과 필터에 필요한 피드 확장 필드를 파싱한다', () {
      final model = SocialFeedItemModel.fromJson(<String, dynamic>{
        'id': 'diary-1',
        'user_id': 'user-1',
        'username': 'milo',
        'display_name': 'Milo',
        'avatar_url': null,
        'persona_id': 'persona-1',
        'persona_name': '아라',
        'title': '버그와의 결투',
        'content': '버그를 해결했다.',
        'summary': '짜릿한 승리',
        'emotion_tags': <String>['excited'],
        'keyword_tags': <String>['프로젝트'],
        'art_style': 'comics_sd',
        'genre': 'daily_comic',
        'webtoon_format': 'reaction_focus',
        'image_urls': <String>['https://example.com/1.png'],
        'first_image_url': 'https://example.com/1.png',
        'like_count': 7,
        'comment_count': 3,
        'created_at': '2026-04-19T00:00:00.000Z',
      });

      expect(model.title, '버그와의 결투');
      expect(model.keywordTags, <String>['프로젝트']);
      expect(model.webtoonFormat, WebtoonFormat.reactionFocus);
      expect(model.firstImageUrl, 'https://example.com/1.png');
    });
  });
}
