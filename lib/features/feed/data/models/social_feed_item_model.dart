import '../../../../core/enums/diary_art_style.dart';
import '../../../../core/enums/diary_genre.dart';
import '../../../../core/enums/webtoon_format.dart';
import '../../domain/entities/social_feed_item_entity.dart';

class SocialFeedItemModel extends SocialFeedItemEntity {
  const SocialFeedItemModel({
    required super.id,
    required super.userId,
    required super.username,
    required super.displayName,
    required super.avatarUrl,
    required super.personaId,
    required super.personaName,
    required super.title,
    required super.content,
    required super.caption,
    required super.summary,
    required super.emotionTags,
    required super.keywordTags,
    required super.artStyle,
    required super.genre,
    required super.webtoonFormat,
    required super.imageUrls,
    required super.firstImageUrl,
    required super.likeCount,
    required super.commentCount,
    required super.createdAt,
  });

  /// social_feed_items view row를 피드 카드 모델로 변환합니다.
  factory SocialFeedItemModel.fromJson(Map<String, dynamic> json) {
    return SocialFeedItemModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      personaId: json['persona_id'] as String?,
      personaName: json['persona_name'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String,
      caption: json['caption'] as String?,
      summary: json['summary'] as String?,
      emotionTags: _stringListFromJson(json['emotion_tags']),
      keywordTags: _stringListFromJson(json['keyword_tags']),
      artStyle: DiaryArtStyle.fromValue(
        json['art_style'] as String? ?? DiaryArtStyle.comicsLd.value,
      ),
      genre: DiaryGenre.fromValue(
        json['genre'] as String? ?? DiaryGenre.dailyComic.value,
      ),
      webtoonFormat: WebtoonFormat.fromValue(
        json['webtoon_format'] as String? ?? WebtoonFormat.cardSlide.value,
      ),
      imageUrls: _stringListFromJson(json['image_urls']),
      firstImageUrl: json['first_image_url'] as String?,
      likeCount: (json['like_count'] as int?) ?? 0,
      commentCount: (json['comment_count'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  SocialFeedItemEntity toEntity() => this;

  static List<String> _stringListFromJson(dynamic value) {
    if (value == null) {
      return const <String>[];
    }
    if (value is List) {
      return value.map((dynamic item) => item.toString()).toList();
    }
    return <String>[value.toString()];
  }
}
