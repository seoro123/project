import '../../../../core/enums/diary_art_style.dart';
import '../../../../core/enums/diary_genre.dart';
import '../../../../core/enums/persona_input_mode.dart';
import '../../../../core/utils/value_equality.dart';

class PersonaEntity {
  const PersonaEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.appearanceDescription,
    required this.emotionPrompts,
    required this.defaultSeed,
    required this.defaultArtStyle,
    required this.defaultGenre,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = false,
    this.inputMode = PersonaInputMode.prose,
    this.appearanceTags = const <String>[],
    this.expressionLibrary = const <String, String>{},
    this.imageUrl,
    this.baseImageUrl,
    this.templateVisibility = 'private',
    this.generationStatus = 'queued',
    this.errorMessage,
  });

  final String id;
  final String userId;

  /// 사용자가 여러 페르소나를 쉽게 구분하도록 하는 이름입니다.
  final String name;

  /// 이미지 생성 때마다 고정으로 포함해 캐릭터 외형 일관성을 유지하는 프롬프트입니다.
  final String appearanceDescription;

  /// 감정명과 표정/포즈 프롬프트를 매핑해 같은 캐릭터의 다양한 표정을 고정합니다.
  final Map<String, String> emotionPrompts;

  /// 동일 캐릭터의 표현 안정성을 높이기 위한 기본 seed입니다.
  final int defaultSeed;

  final DiaryArtStyle defaultArtStyle;
  final DiaryGenre defaultGenre;
  final bool isPrimary;
  final bool isPublic;
  final PersonaInputMode inputMode;

  /// UI 태그 선택과 검색 필터에 사용하는 평면 태그 목록입니다.
  final List<String> appearanceTags;

  /// 감정별 기준 이미지 URL 또는 표정 프롬프트를 저장하는 라이브러리입니다.
  final Map<String, String> expressionLibrary;

  final String? imageUrl;
  final String? baseImageUrl;
  final String templateVisibility;
  final String generationStatus;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PersonaEntity &&
            id == other.id &&
            userId == other.userId &&
            name == other.name &&
            appearanceDescription == other.appearanceDescription &&
            mapEqualsByValue(emotionPrompts, other.emotionPrompts) &&
            defaultSeed == other.defaultSeed &&
            defaultArtStyle == other.defaultArtStyle &&
            defaultGenre == other.defaultGenre &&
            isPrimary == other.isPrimary &&
            isPublic == other.isPublic &&
            inputMode == other.inputMode &&
            listEqualsByValue(appearanceTags, other.appearanceTags) &&
            mapEqualsByValue(expressionLibrary, other.expressionLibrary) &&
            imageUrl == other.imageUrl &&
            baseImageUrl == other.baseImageUrl &&
            templateVisibility == other.templateVisibility &&
            generationStatus == other.generationStatus &&
            errorMessage == other.errorMessage &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return Object.hashAll(<Object?>[
      id,
      userId,
      name,
      appearanceDescription,
      Object.hashAll(
        emotionPrompts.entries.map(
          (MapEntry<String, String> entry) =>
              Object.hash(entry.key, entry.value),
        ),
      ),
      defaultSeed,
      defaultArtStyle,
      defaultGenre,
      isPrimary,
      isPublic,
      inputMode,
      Object.hashAll(appearanceTags),
      Object.hashAll(
        expressionLibrary.entries.map(
          (MapEntry<String, String> entry) =>
              Object.hash(entry.key, entry.value),
        ),
      ),
      imageUrl,
      baseImageUrl,
      templateVisibility,
      generationStatus,
      errorMessage,
      createdAt,
      updatedAt,
    ]);
  }
}
