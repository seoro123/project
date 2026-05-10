import '../../../../core/enums/diary_art_style.dart';
import '../../../../core/enums/diary_generation_status.dart';
import '../../../../core/enums/diary_genre.dart';
import '../../../../core/enums/weather_type.dart';
import '../../../../core/enums/webtoon_format.dart';
import '../../../../core/utils/value_equality.dart';

class DiaryEntity {
  const DiaryEntity({
    required this.id,
    required this.userId,
    required this.personaId,
    required this.title,
    required this.diaryAt,
    required this.weather,
    required this.content,
    required this.summary,
    required this.emotionTags,
    required this.keywordTags,
    required this.artStyle,
    required this.artSubStyle,
    required this.genre,
    required this.genreSubtype,
    required this.webtoonFormat,
    required this.imageUrls,
    required this.isPublic,
    required this.generationStatus,
    required this.structuredResult,
    required this.generationSeed,
    required this.retryCount,
    required this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? personaId;

  /// 피드와 검색에서 노출되는 작품명입니다.
  final String? title;

  /// 사용자가 기록 대상으로 선택한 실제 일기 날짜와 시간입니다.
  final DateTime? diaryAt;

  /// 날씨 아이콘과 AI 연출 힌트에 사용하는 환경 정보입니다.
  final WeatherType weather;

  /// 사용자가 직접 작성한 원문 일기입니다.
  final String content;

  /// 피드 카드와 AI 파이프라인 입력 최적화에 사용하는 요약문입니다.
  final String? summary;

  /// GPT-4o 감정 분석 결과를 태그 형태로 저장해 추천과 검색에 사용합니다.
  final List<String> emotionTags;

  /// 사용자가 직접 지정하거나 AI가 추출한 핵심 키워드 태그입니다.
  final List<String> keywordTags;

  final DiaryArtStyle artStyle;
  final String? artSubStyle;
  final DiaryGenre genre;
  final String? genreSubtype;
  final WebtoonFormat webtoonFormat;

  /// AI가 생성한 컷 이미지 또는 커버 이미지 URL 배열입니다.
  final List<String> imageUrls;

  /// Masonry 소셜 피드에 공개할지 여부입니다.
  final bool isPublic;

  /// 비동기 생성 파이프라인의 진행 상태입니다.
  final DiaryGenerationStatus generationStatus;

  /// GPT-4o가 반환한 구조화 JSON을 보존해 재생성과 디버깅에 사용합니다.
  final Map<String, dynamic> structuredResult;

  /// Stability AI에서 같은 페르소나 외형을 유지하기 위한 seed입니다.
  final int? generationSeed;

  /// Edge Function 재시도 횟수입니다. 무한 재시도를 막기 위해 DB 제약과 함께 사용합니다.
  final int retryCount;

  /// 생성 실패 시 사용자 안내와 운영 디버깅에 필요한 마지막 오류 메시지입니다.
  final String? errorMessage;

  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DiaryEntity &&
            id == other.id &&
            userId == other.userId &&
            personaId == other.personaId &&
            title == other.title &&
            diaryAt == other.diaryAt &&
            weather == other.weather &&
            content == other.content &&
            summary == other.summary &&
            listEqualsByValue(emotionTags, other.emotionTags) &&
            listEqualsByValue(keywordTags, other.keywordTags) &&
            artStyle == other.artStyle &&
            artSubStyle == other.artSubStyle &&
            genre == other.genre &&
            genreSubtype == other.genreSubtype &&
            webtoonFormat == other.webtoonFormat &&
            listEqualsByValue(imageUrls, other.imageUrls) &&
            isPublic == other.isPublic &&
            generationStatus == other.generationStatus &&
            mapEqualsByValue(structuredResult, other.structuredResult) &&
            generationSeed == other.generationSeed &&
            retryCount == other.retryCount &&
            errorMessage == other.errorMessage &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return Object.hashAll(<Object?>[
      id,
      userId,
      personaId,
      title,
      diaryAt,
      weather,
      content,
      summary,
      Object.hashAll(emotionTags),
      Object.hashAll(keywordTags),
      artStyle,
      artSubStyle,
      genre,
      genreSubtype,
      webtoonFormat,
      Object.hashAll(imageUrls),
      isPublic,
      generationStatus,
      Object.hashAll(
        structuredResult.entries.map(
          (MapEntry<String, dynamic> entry) =>
              Object.hash(entry.key, entry.value),
        ),
      ),
      generationSeed,
      retryCount,
      errorMessage,
      createdAt,
      updatedAt,
    ]);
  }
}
