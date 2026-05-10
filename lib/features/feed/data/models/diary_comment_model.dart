class DiaryCommentModel {
  const DiaryCommentModel({
    required this.id,
    required this.diaryId,
    required this.userId,
    required this.personaId,
    required this.content,
    required this.personaScript,
    required this.moderationStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String diaryId;
  final String userId;
  final String? personaId;
  final String content;
  final String? personaScript;
  final String moderationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 캐릭터 간 소통 댓글 row를 앱 모델로 변환합니다.
  factory DiaryCommentModel.fromJson(Map<String, dynamic> json) {
    return DiaryCommentModel(
      id: json['id'] as String,
      diaryId: json['diary_id'] as String,
      userId: json['user_id'] as String,
      personaId: json['persona_id'] as String?,
      content: json['content'] as String,
      personaScript: json['persona_script'] as String?,
      moderationStatus: json['moderation_status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
