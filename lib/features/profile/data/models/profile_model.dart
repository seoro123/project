import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.username,
    required super.displayName,
    required super.bio,
    required super.avatarUrl,
    required super.tendencyVector,
    required super.isPublic,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Supabase의 snake_case row를 앱 내부 camelCase 모델로 변환합니다.
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      tendencyVector: _vectorFromJson(json['tendency_vector']),
      isPublic: (json['is_public'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Supabase insert/update에 바로 사용할 수 있는 snake_case JSON입니다.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'display_name': displayName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'tendency_vector': tendencyVector,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProfileEntity toEntity() => this;

  /// pgvector는 환경에 따라 문자열("[0.1,0.2]") 또는 배열로 내려올 수 있어 둘 다 처리합니다.
  static List<double> _vectorFromJson(dynamic value) {
    if (value == null) {
      return const <double>[];
    }

    if (value is List) {
      return value.map((dynamic item) => (item as num).toDouble()).toList();
    }

    if (value is String) {
      final normalized = value.replaceAll('[', '').replaceAll(']', '').trim();
      if (normalized.isEmpty) {
        return const <double>[];
      }

      return normalized
          .split(',')
          .map((String item) => double.parse(item.trim()))
          .toList();
    }

    return const <double>[];
  }
}
