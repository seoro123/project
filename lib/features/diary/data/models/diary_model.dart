import '../../../../core/enums/diary_art_style.dart';
import '../../../../core/enums/diary_generation_status.dart';
import '../../../../core/enums/diary_genre.dart';
import '../../../../core/enums/weather_type.dart';
import '../../../../core/enums/webtoon_format.dart';
import '../../domain/entities/diary_entity.dart';

class DiaryModel extends DiaryEntity {
  const DiaryModel({
    required super.id,
    required super.userId,
    required super.personaId,
    required super.title,
    required super.diaryAt,
    required super.weather,
    required super.content,
    required super.summary,
    required super.emotionTags,
    required super.keywordTags,
    required super.artStyle,
    required super.artSubStyle,
    required super.genre,
    required super.genreSubtype,
    required super.webtoonFormat,
    required super.imageUrls,
    required super.isPublic,
    required super.generationStatus,
    required super.structuredResult,
    required super.generationSeed,
    required super.retryCount,
    required super.errorMessage,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Supabase diaries row의 snake_case 컬럼을 앱에서 쓰는 camelCase 모델로 변환합니다.
  factory DiaryModel.fromJson(Map<String, dynamic> json) {
    return DiaryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      personaId: json['persona_id'] as String?,
      title: json['title'] as String?,
      diaryAt: _dateTimeFromJson(json['diary_at']),
      weather: WeatherType.fromValue(
        json['weather'] as String? ?? WeatherType.sunny.value,
      ),
      content: json['content'] as String,
      summary: json['summary'] as String?,
      emotionTags: _stringListFromJson(json['emotion_tags']),
      keywordTags: _stringListFromJson(json['keyword_tags']),
      artStyle: DiaryArtStyle.fromValue(
        json['art_style'] as String? ?? DiaryArtStyle.comicsLd.value,
      ),
      artSubStyle: json['art_sub_style'] as String?,
      genre: DiaryGenre.fromValue(
        json['genre'] as String? ?? DiaryGenre.dailyComic.value,
      ),
      genreSubtype: json['genre_subtype'] as String?,
      webtoonFormat: WebtoonFormat.fromValue(
        json['webtoon_format'] as String? ?? WebtoonFormat.cardSlide.value,
      ),
      imageUrls: _stringListFromJson(json['image_urls']),
      isPublic: (json['is_public'] as bool?) ?? false,
      generationStatus: DiaryGenerationStatus.fromValue(
        json['generation_status'] as String? ??
            DiaryGenerationStatus.queued.value,
      ),
      structuredResult: Map<String, dynamic>.from(
        json['structured_result'] as Map<String, dynamic>? ??
            <String, dynamic>{},
      ),
      generationSeed: json['generation_seed'] as int?,
      retryCount: (json['retry_count'] as int?) ?? 0,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Supabase insert/update에 바로 사용할 수 있는 snake_case JSON입니다.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'persona_id': personaId,
      'title': title,
      'diary_at': diaryAt?.toIso8601String(),
      'weather': weather.value,
      'content': content,
      'summary': summary,
      'emotion_tags': emotionTags,
      'keyword_tags': keywordTags,
      'art_style': artStyle.value,
      'art_sub_style': artSubStyle,
      'genre': genre.value,
      'genre_subtype': genreSubtype,
      'webtoon_format': webtoonFormat.value,
      'image_urls': imageUrls,
      'is_public': isPublic,
      'generation_status': generationStatus.value,
      'structured_result': structuredResult,
      'generation_seed': generationSeed,
      'retry_count': retryCount,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DiaryEntity toEntity() => this;

  /// Postgres text[]가 null, List, 단일 문자열 중 어떤 형태로 와도 안전하게 목록으로 정규화합니다.
  static List<String> _stringListFromJson(dynamic value) {
    if (value == null) {
      return const <String>[];
    }
    if (value is List) {
      return value.map((dynamic item) => item.toString()).toList();
    }
    return <String>[value.toString()];
  }

  static DateTime? _dateTimeFromJson(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.parse(value as String);
  }
}
