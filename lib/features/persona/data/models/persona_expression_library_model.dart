class PersonaExpressionLibraryModel {
  const PersonaExpressionLibraryModel({
    this.happy,
    this.sad,
    this.angry,
    this.embarrassed,
    this.calm,
  });

  final String? happy;
  final String? sad;
  final String? angry;
  final String? embarrassed;
  final String? calm;

  /// 감정별 기준 이미지 URL 또는 표정 프롬프트를 구조화해 컷 생성 시 재사용합니다.
  factory PersonaExpressionLibraryModel.fromJson(Map<String, dynamic> json) {
    return PersonaExpressionLibraryModel(
      happy: json['happy'] as String?,
      sad: json['sad'] as String?,
      angry: json['angry'] as String?,
      embarrassed: json['embarrassed'] as String?,
      calm: json['calm'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'happy': happy,
      'sad': sad,
      'angry': angry,
      'embarrassed': embarrassed,
      'calm': calm,
    };
  }
}
