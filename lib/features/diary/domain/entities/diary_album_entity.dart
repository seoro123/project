import '../../../../core/utils/value_equality.dart';

class DiaryAlbumEntity {
  const DiaryAlbumEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.coverImageUrl,
    required this.colorHex,
    required this.isPublic,
    required this.sortOrder,
    required this.diaryIds,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 사용자가 직접 만든 앨범의 ID입니다.
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final String colorHex;
  final bool isPublic;
  final int sortOrder;

  /// 앨범 상세 화면에서 일기 배치 순서를 유지하기 위한 ID 목록입니다.
  final List<String> diaryIds;

  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DiaryAlbumEntity &&
            id == other.id &&
            userId == other.userId &&
            title == other.title &&
            description == other.description &&
            coverImageUrl == other.coverImageUrl &&
            colorHex == other.colorHex &&
            isPublic == other.isPublic &&
            sortOrder == other.sortOrder &&
            listEqualsByValue(diaryIds, other.diaryIds) &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      title,
      description,
      coverImageUrl,
      colorHex,
      isPublic,
      sortOrder,
      Object.hashAll(diaryIds),
      createdAt,
      updatedAt,
    );
  }
}
