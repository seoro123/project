import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/diary_art_style.dart';
import '../../../../core/enums/diary_generation_status.dart';
import '../../../../core/enums/diary_genre.dart';
import '../../../../core/enums/persona_input_mode.dart';
import '../../../../core/enums/weather_type.dart';
import '../../../../core/enums/webtoon_format.dart';
import '../../../diary/data/models/diary_model.dart';
import '../../../persona/data/models/persona_model.dart';
import '../../../profile/data/models/profile_model.dart';

/// 백엔드 연결 전에도 화면과 모델 매핑을 검증할 수 있도록 데모 프로필을 제공합니다.
final showcaseProfileProvider = Provider<ProfileModel>((ref) {
  return ProfileModel(
    id: 'user-demo-01',
    username: 'mintcloud',
    displayName: '민트구름',
    bio: '감정 기록을 웹툰 컷으로 남기는 AI 다이어리 크리에이터',
    avatarUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
    tendencyVector: const <double>[0.81, 0.34, 0.65, 0.92],
    isPublic: true,
    createdAt: DateTime.parse('2026-04-20T09:00:00.000Z'),
    updatedAt: DateTime.parse('2026-04-23T04:00:00.000Z'),
  );
});

/// 페르소나 외형과 감정 프롬프트가 이미지 일관성의 기준점이 됩니다.
final showcasePersonasProvider = Provider<List<PersonaModel>>((ref) {
  return <PersonaModel>[
    PersonaModel(
      id: 'persona-main',
      userId: 'user-demo-01',
      name: '아라',
      appearanceDescription: '긴 검은 머리, 민트색 후드티, 부드러운 눈매, 파스텔 블루 배경, 따뜻한 표정 연출',
      emotionPrompts: const <String, String>{
        'happy': '입꼬리가 크게 올라간 밝은 미소',
        'sad': '눈시울이 붉어진 조용한 표정',
        'angry': '눈썹을 살짝 찡그린 절제된 분노',
        'embarrassed': '볼이 붉어진 수줍은 표정',
      },
      expressionLibrary: const <String, String>{
        'happy': 'happy_face_reference.png',
        'calm': 'calm_face_reference.png',
      },
      defaultSeed: 777,
      defaultArtStyle: DiaryArtStyle.animeLd,
      defaultGenre: DiaryGenre.healingRomance,
      isPrimary: true,
      isPublic: true,
      inputMode: PersonaInputMode.prose,
      appearanceTags: const <String>['black_hair', 'mint_hoodie', 'soft_eyes'],
      templateVisibility: 'public',
      createdAt: DateTime.parse('2026-04-20T10:00:00.000Z'),
      updatedAt: DateTime.parse('2026-04-23T05:00:00.000Z'),
    ),
    PersonaModel(
      id: 'persona-sub',
      userId: 'user-demo-01',
      name: '도바',
      appearanceDescription: '짧은 은색 머리, 작은 망토, 코믹한 SD 비율, RPG 길드 마스코트, 과장된 제스처',
      emotionPrompts: const <String, String>{
        'happy': '두 팔을 번쩍 들고 웃는 에너지 넘치는 표정',
        'serious': '전투 전 집중하는 단단한 표정',
      },
      defaultSeed: 4242,
      defaultArtStyle: DiaryArtStyle.comicsSd,
      defaultGenre: DiaryGenre.fantasyAction,
      isPrimary: false,
      isPublic: false,
      inputMode: PersonaInputMode.tags,
      appearanceTags: const <String>['silver_hair', 'cape', 'sd_body'],
      createdAt: DateTime.parse('2026-04-20T12:00:00.000Z'),
      updatedAt: DateTime.parse('2026-04-22T18:30:00.000Z'),
    ),
  ];
});

/// AI 생성 상태별 UI를 확인하기 위한 샘플 일기입니다.
final showcaseDiariesProvider = Provider<List<DiaryModel>>((ref) {
  return <DiaryModel>[
    DiaryModel(
      id: 'diary-001',
      userId: 'user-demo-01',
      personaId: 'persona-main',
      title: '비 오는 카페에서',
      diaryAt: DateTime.parse('2026-04-22T14:00:00.000Z'),
      weather: WeatherType.rainy,
      content: '오늘은 카페 창가에 앉아 비가 내리는 걸 보며 마음을 정리했다.',
      summary: '비 오는 오후의 차분한 행복',
      emotionTags: const <String>['calm', 'healing', 'grateful'],
      keywordTags: const <String>['카페', '비', '휴식'],
      artStyle: DiaryArtStyle.animeLd,
      artSubStyle: 'LD',
      genre: DiaryGenre.healingRomance,
      genreSubtype: 'daily_healing',
      webtoonFormat: WebtoonFormat.cardSlide,
      imageUrls: const <String>[
        'https://images.unsplash.com/photo-1511920170033-f8396924c348?w=900',
      ],
      isPublic: true,
      generationStatus: DiaryGenerationStatus.completed,
      structuredResult: const <String, dynamic>{'panels': 3, 'tone': 'soft'},
      generationSeed: 777,
      retryCount: 0,
      errorMessage: null,
      createdAt: DateTime.parse('2026-04-22T14:20:00.000Z'),
      updatedAt: DateTime.parse('2026-04-22T14:24:00.000Z'),
    ),
    DiaryModel(
      id: 'diary-002',
      userId: 'user-demo-01',
      personaId: 'persona-sub',
      title: '버그와의 결투',
      diaryAt: DateTime.parse('2026-04-23T01:00:00.000Z'),
      weather: WeatherType.foggy,
      content: '프로젝트 마감 직전에 버그를 잡고 나니 온 팀이 환호했다.',
      summary: '버그 해결 직후의 짜릿한 승리',
      emotionTags: const <String>['excited', 'teamwork', 'comic'],
      keywordTags: const <String>['프로젝트', '버그', '팀워크'],
      artStyle: DiaryArtStyle.comicsSd,
      artSubStyle: 'SD',
      genre: DiaryGenre.dailyComic,
      genreSubtype: 'sitcom',
      webtoonFormat: WebtoonFormat.reactionFocus,
      imageUrls: const <String>[],
      isPublic: false,
      generationStatus: DiaryGenerationStatus.processing,
      structuredResult: const <String, dynamic>{'panels': 4, 'tone': 'upbeat'},
      generationSeed: 4242,
      retryCount: 0,
      errorMessage: null,
      createdAt: DateTime.parse('2026-04-23T01:10:00.000Z'),
      updatedAt: DateTime.parse('2026-04-23T01:12:00.000Z'),
    ),
  ];
});
