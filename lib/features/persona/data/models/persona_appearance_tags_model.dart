class PersonaAppearanceTagsModel {
  const PersonaAppearanceTagsModel({
    this.skinTone,
    this.hairStyle,
    this.hairColor,
    this.eyeColor,
    this.eyeHighlight,
    this.personality,
    this.top,
    this.bottom,
    this.extraTags = const <String>[],
  });

  final String? skinTone;
  final String? hairStyle;
  final String? hairColor;
  final String? eyeColor;
  final String? eyeHighlight;
  final String? personality;
  final String? top;
  final String? bottom;
  final List<String> extraTags;

  /// 태그 작성 UI의 항목을 Stability AI 프롬프트 조립에 쓰기 쉬운 구조로 보관합니다.
  factory PersonaAppearanceTagsModel.fromJson(Map<String, dynamic> json) {
    return PersonaAppearanceTagsModel(
      skinTone: json['skin_tone'] as String?,
      hairStyle: json['hair_style'] as String?,
      hairColor: json['hair_color'] as String?,
      eyeColor: json['eye_color'] as String?,
      eyeHighlight: json['eye_highlight'] as String?,
      personality: json['personality'] as String?,
      top: json['top'] as String?,
      bottom: json['bottom'] as String?,
      extraTags: _stringListFromJson(json['extra_tags']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'skin_tone': skinTone,
      'hair_style': hairStyle,
      'hair_color': hairColor,
      'eye_color': eyeColor,
      'eye_highlight': eyeHighlight,
      'personality': personality,
      'top': top,
      'bottom': bottom,
      'extra_tags': extraTags,
    };
  }

  static List<String> _stringListFromJson(dynamic value) {
    if (value == null) {
      return const <String>[];
    }
    return (value as List<dynamic>)
        .map((dynamic item) => item.toString())
        .toList();
  }
}
