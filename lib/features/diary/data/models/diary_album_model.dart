import '../../domain/entities/diary_album_entity.dart';

class DiaryAlbumModel extends DiaryAlbumEntity {
  const DiaryAlbumModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.description,
    required super.coverImageUrl,
    required super.colorHex,
    required super.isPublic,
    required super.sortOrder,
    required super.diaryIds,
    required super.createdAt,
    required super.updatedAt,
  });

  /// diary_albums row와 선택적으로 조인된 diary_album_items를 앱 모델로 변환합니다.
  factory DiaryAlbumModel.fromJson(Map<String, dynamic> json) {
    return DiaryAlbumModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      colorHex: json['color_hex'] as String? ?? '#86BFFF',
      isPublic: (json['is_public'] as bool?) ?? false,
      sortOrder: (json['sort_order'] as int?) ?? 0,
      diaryIds: _diaryIdsFromJson(json['diary_album_items']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'cover_image_url': coverImageUrl,
      'color_hex': colorHex,
      'is_public': isPublic,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DiaryAlbumEntity toEntity() => this;

  static List<String> _diaryIdsFromJson(dynamic value) {
    if (value == null) {
      return const <String>[];
    }

    if (value is List) {
      return value
          .map((dynamic item) {
            if (item is Map<String, dynamic>) {
              return item['diary_id']?.toString();
            }
            return item.toString();
          })
          .whereType<String>()
          .toList();
    }

    return const <String>[];
  }
}
