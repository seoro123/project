class DiaryCommentModel {
  const DiaryCommentModel({
    required this.id,
    required this.diaryId,
    required this.userId,
    required this.parentCommentId,
    required this.personaId,
    required this.content,
    required this.personaScript,
    required this.moderationStatus,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String diaryId;
  final String userId;
  final String? parentCommentId;
  final String? personaId;
  final String content;
  final String? personaScript;
  final String moderationStatus;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 댓글 row와 작성자 프로필 join 결과를 앱 모델로 변환합니다.
  factory DiaryCommentModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] is Map<String, dynamic>
        ? json['profiles'] as Map<String, dynamic>
        : json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return DiaryCommentModel(
      id: json['id'] as String,
      diaryId: json['diary_id'] as String,
      userId: json['user_id'] as String,
      parentCommentId: json['parent_comment_id'] as String?,
      personaId: json['persona_id'] as String?,
      content: json['content'] as String,
      personaScript: json['persona_script'] as String?,
      moderationStatus: json['moderation_status'] as String? ?? 'pending',
      username: profile['username'] as String?,
      displayName: profile['display_name'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
