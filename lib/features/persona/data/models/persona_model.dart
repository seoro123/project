import '../../../../core/enums/diary_art_style.dart';
import '../../../../core/enums/diary_genre.dart';
import '../../../../core/enums/persona_input_mode.dart';
import '../../domain/entities/persona_entity.dart';

class PersonaModel extends PersonaEntity {
  const PersonaModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.appearanceDescription,
    required super.emotionPrompts,
    required super.defaultSeed,
    required super.defaultArtStyle,
    required super.defaultGenre,
    required super.isPrimary,
    required super.createdAt,
    required super.updatedAt,
    super.isPublic,
    super.inputMode,
    super.appearanceTags,
    super.expressionLibrary,
    super.imageUrl,
    super.baseImageUrl,
    super.templateVisibility,
    super.generationStatus,
    super.errorMessage,
  });

  /// emotion_prompts와 expression_library의 jsonb 객체를 String Map으로 정규화합니다.
  factory PersonaModel.fromJson(Map<String, dynamic> json) {
    return PersonaModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      appearanceDescription: json['appearance_desc'] as String,
      emotionPrompts: _stringMapFromJson(json['emotion_prompts']),
      defaultSeed: json['default_seed'] as int,
      defaultArtStyle: DiaryArtStyle.fromValue(
        json['default_art_style'] as String? ?? DiaryArtStyle.comicsLd.value,
      ),
      defaultGenre: DiaryGenre.fromValue(
        json['default_genre'] as String? ?? DiaryGenre.dailyComic.value,
      ),
      isPrimary: (json['is_primary'] as bool?) ?? false,
      isPublic: (json['is_public'] as bool?) ?? false,
      inputMode: PersonaInputMode.fromValue(
        json['input_mode'] as String? ?? PersonaInputMode.prose.value,
      ),
      appearanceTags: _appearanceTagsFromJson(json['appearance_tags']),
      expressionLibrary: _stringMapFromJson(json['expression_library']),
      imageUrl: json['image_url'] as String?,
      baseImageUrl: json['base_image_url'] as String?,
      templateVisibility: json['template_visibility'] as String? ?? 'private',
      generationStatus: json['generation_status'] as String? ?? 'queued',
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'name': name,
      'appearance_desc': appearanceDescription,
      'emotion_prompts': emotionPrompts,
      'default_seed': defaultSeed,
      'default_art_style': defaultArtStyle.value,
      'default_genre': defaultGenre.value,
      'is_primary': isPrimary,
      'is_public': isPublic,
      'input_mode': inputMode.value,
      'appearance_tags': appearanceTags,
      'expression_library': expressionLibrary,
      'image_url': imageUrl,
      'base_image_url': baseImageUrl,
      'template_visibility': templateVisibility,
      'generation_status': generationStatus,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PersonaEntity toEntity() => this;

  static Map<String, String> _stringMapFromJson(dynamic value) {
    if (value == null) {
      return const <String, String>{};
    }

    return (value as Map<String, dynamic>).map(
      (String key, dynamic item) => MapEntry(key, item.toString()),
    );
  }

  /// 이전 text[] 스키마와 새 jsonb 스키마를 모두 읽어 마이그레이션 중에도 UI가 깨지지 않게 합니다.
  static List<String> _appearanceTagsFromJson(dynamic value) {
    if (value == null) {
      return const <String>[];
    }
    if (value is List) {
      return value.map((dynamic item) => item.toString()).toList();
    }
    if (value is Map<String, dynamic>) {
      return value.values
          .expand<String>((dynamic item) {
            if (item is List) {
              return item.map((dynamic tag) => tag.toString());
            }
            return <String>[item.toString()];
          })
          .toSet()
          .toList();
    }
    return <String>[value.toString()];
  }
}
