import '../../../../core/enums/diary_art_style.dart';
import '../../../../core/enums/diary_genre.dart';
import '../../../../core/enums/webtoon_format.dart';
import '../../../../core/utils/value_equality.dart';

class SocialFeedItemEntity {
  const SocialFeedItemEntity({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.personaId,
    required this.personaName,
    required this.title,
    required this.content,
    required this.summary,
    required this.emotionTags,
    required this.keywordTags,
    required this.artStyle,
    required this.genre,
    required this.webtoonFormat,
    required this.imageUrls,
    required this.firstImageUrl,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? personaId;
  final String? personaName;
  final String? title;
  final String content;
  final String? summary;
  final List<String> emotionTags;
  final List<String> keywordTags;
  final DiaryArtStyle artStyle;
  final DiaryGenre genre;
  final WebtoonFormat webtoonFormat;
  final List<String> imageUrls;
  final String? firstImageUrl;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SocialFeedItemEntity &&
            id == other.id &&
            userId == other.userId &&
            username == other.username &&
            displayName == other.displayName &&
            avatarUrl == other.avatarUrl &&
            personaId == other.personaId &&
            personaName == other.personaName &&
            title == other.title &&
            content == other.content &&
            summary == other.summary &&
            listEqualsByValue(emotionTags, other.emotionTags) &&
            listEqualsByValue(keywordTags, other.keywordTags) &&
            artStyle == other.artStyle &&
            genre == other.genre &&
            webtoonFormat == other.webtoonFormat &&
            listEqualsByValue(imageUrls, other.imageUrls) &&
            firstImageUrl == other.firstImageUrl &&
            likeCount == other.likeCount &&
            commentCount == other.commentCount &&
            createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    return Object.hashAll(<Object?>[
      id,
      userId,
      username,
      displayName,
      avatarUrl,
      personaId,
      personaName,
      title,
      content,
      summary,
      Object.hashAll(emotionTags),
      Object.hashAll(keywordTags),
      artStyle,
      genre,
      webtoonFormat,
      Object.hashAll(imageUrls),
      firstImageUrl,
      likeCount,
      commentCount,
      createdAt,
    ]);
  }
}
