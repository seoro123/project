import '../../../../core/utils/value_equality.dart';

class ProfileEntity {
  const ProfileEntity({
    required this.id,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
    required this.tendencyVector,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Supabase auth.users와 1:1로 연결되는 사용자 ID입니다.
  final String id;

  /// URL, 멘션, 검색에 사용하는 고유 사용자 이름입니다.
  final String username;

  /// 화면에 노출할 표시 이름입니다. 없으면 username을 대신 사용합니다.
  final String? displayName;

  /// 사용자 자기소개입니다.
  final String? bio;

  /// Supabase Storage 또는 외부 CDN에 저장된 프로필 이미지 URL입니다.
  final String? avatarUrl;

  /// 추천과 성향 검색에 사용할 pgvector 값입니다.
  final List<double> tendencyVector;

  /// 공개 피드와 추천 영역에 노출 가능한 계정인지 나타냅니다.
  final bool isPublic;

  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProfileEntity &&
            id == other.id &&
            username == other.username &&
            displayName == other.displayName &&
            bio == other.bio &&
            avatarUrl == other.avatarUrl &&
            listEqualsByValue(tendencyVector, other.tendencyVector) &&
            isPublic == other.isPublic &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      username,
      displayName,
      bio,
      avatarUrl,
      Object.hashAll(tendencyVector),
      isPublic,
      createdAt,
      updatedAt,
    );
  }
}
