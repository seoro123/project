import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../diary/data/models/diary_panel_model.dart';
import '../models/diary_comment_model.dart';
import '../models/social_feed_item_model.dart';

class SupabaseFeedRepository {
  const SupabaseFeedRepository(this._client);

  final SupabaseClient _client;

  /// 공개 완료된 일기를 소셜 피드 집계 view에서 가져옵니다.
  Future<List<SocialFeedItemModel>> fetchFeed({
    String? searchKeyword,
    String? usernameKeyword,
    String? tag,
    List<String> tags = const <String>[],
    bool followingOnly = false,
    int limit = 30,
  }) async {
    dynamic query = _client.from('social_feed_items').select();

    if (followingOnly) {
      final followingIds = await fetchFollowingUserIds();
      if (followingIds.isEmpty) {
        return const <SocialFeedItemModel>[];
      }
      query = query.inFilter('user_id', followingIds);
    }

    if (searchKeyword != null && searchKeyword.trim().isNotEmpty) {
      final keyword = searchKeyword.trim().replaceAll(',', ' ');
      query = query.or(
        'search_text.ilike.%$keyword%,username.ilike.%$keyword%,display_name.ilike.%$keyword%',
      );
    }

    if (usernameKeyword != null && usernameKeyword.trim().isNotEmpty) {
      query = query.ilike('username', '%${usernameKeyword.trim()}%');
    }

    final filterTags = <String>[
      if (tag != null && tag.trim().isNotEmpty) tag.trim(),
      ...tags
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty),
    ];

    final fetchLimit = filterTags.isEmpty ? limit : 120;
    final rows = await query
        .order('created_at', ascending: false)
        .limit(fetchLimit);
    final posts = rows
        .map<SocialFeedItemModel>(
          (dynamic row) =>
              SocialFeedItemModel.fromJson(row as Map<String, dynamic>),
        )
        .toList();

    if (filterTags.isEmpty) {
      return posts;
    }

    final normalizedTags = filterTags.toSet();
    return posts
        .where((SocialFeedItemModel post) {
          final postTags = <String>{
            post.artStyle.value,
            post.genre.value,
            post.webtoonFormat.value,
          };
          return normalizedTags.every(postTags.contains);
        })
        .take(limit)
        .toList();
  }

  /// 좋아요는 RPC로 토글해 중복 insert/delete 경합 상태를 줄입니다.
  Future<bool> toggleLike(String diaryId) async {
    final result = await _client.rpc<bool>(
      'toggle_diary_like',
      params: <String, dynamic>{'target_diary_id': diaryId},
    );
    return result;
  }

  Future<bool> isLiked(String diaryId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      return false;
    }

    final rows = await _client
        .from('diary_likes')
        .select('diary_id')
        .eq('user_id', currentUserId)
        .eq('diary_id', diaryId)
        .limit(1);

    return rows.isNotEmpty;
  }

  Future<bool> toggleBookmark(String diaryId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw StateError('로그인이 필요합니다.');
    }

    final existing = await _client
        .from('diary_bookmarks')
        .select('diary_id')
        .eq('user_id', currentUserId)
        .eq('diary_id', diaryId)
        .limit(1);

    if (existing.isNotEmpty) {
      await _client
          .from('diary_bookmarks')
          .delete()
          .eq('user_id', currentUserId)
          .eq('diary_id', diaryId);
      return false;
    }

    await _client.from('diary_bookmarks').insert(<String, dynamic>{
      'diary_id': diaryId,
      'user_id': currentUserId,
    });
    return true;
  }

  Future<bool> isBookmarked(String diaryId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      return false;
    }

    final rows = await _client
        .from('diary_bookmarks')
        .select('diary_id')
        .eq('user_id', currentUserId)
        .eq('diary_id', diaryId)
        .limit(1);

    return rows.isNotEmpty;
  }

  Future<List<SocialFeedItemModel>> fetchBookmarkedPosts({
    int limit = 80,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      return const <SocialFeedItemModel>[];
    }

    final bookmarkRows = await _client
        .from('diary_bookmarks')
        .select('diary_id')
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false)
        .limit(limit);

    final orderedIds = bookmarkRows
        .map<String>(
          (dynamic row) => (row as Map<String, dynamic>)['diary_id'].toString(),
        )
        .toList();
    if (orderedIds.isEmpty) {
      return const <SocialFeedItemModel>[];
    }

    final rows = await _client
        .from('social_feed_items')
        .select()
        .inFilter('id', orderedIds);

    final byId = <String, SocialFeedItemModel>{
      for (final row in rows)
        row['id'].toString(): SocialFeedItemModel.fromJson(row),
    };

    return orderedIds
        .map((String id) => byId[id])
        .whereType<SocialFeedItemModel>()
        .toList();
  }

  Future<List<String>> fetchFollowingUserIds() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      return const <String>[];
    }

    final rows = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', currentUserId);

    return rows.map<String>((dynamic row) {
      final map = row as Map<String, dynamic>;
      return map['following_id'].toString();
    }).toList();
  }

  Future<List<SocialFeedItemModel>> fetchUserPosts(
    String userId, {
    int limit = 60,
  }) async {
    final rows = await _client
        .from('social_feed_items')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return rows
        .map<SocialFeedItemModel>(
          (dynamic row) =>
              SocialFeedItemModel.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }

  Future<bool> isFollowing(String targetUserId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId == targetUserId) {
      return false;
    }

    final rows = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', currentUserId)
        .eq('following_id', targetUserId)
        .limit(1);

    return rows.isNotEmpty;
  }

  Future<bool> toggleFollow(String targetUserId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw StateError('로그인이 필요합니다.');
    }
    if (currentUserId == targetUserId) {
      return false;
    }

    final following = await isFollowing(targetUserId);
    if (following) {
      await _client
          .from('follows')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId);
      return false;
    }

    await _client.from('follows').insert(<String, dynamic>{
      'follower_id': currentUserId,
      'following_id': targetUserId,
    });
    return true;
  }

  Future<void> deleteDiary(String diaryId) async {
    await _client.from('diaries').delete().eq('id', diaryId);
  }

  Future<void> updateDiaryCaption({
    required String diaryId,
    required String caption,
  }) async {
    await _client
        .from('diaries')
        .update(<String, dynamic>{
          'caption': caption.trim().isEmpty ? null : caption.trim(),
        })
        .eq('id', diaryId);
  }

  Future<List<String>> fetchDiaryImageUrls(String diaryId) async {
    final rows = await _client
        .from('diary_panels')
        .select('image_url')
        .eq('diary_id', diaryId)
        .order('panel_order');

    return rows
        .map<String?>((dynamic row) {
          final map = row as Map<String, dynamic>;
          return map['image_url'] as String?;
        })
        .whereType<String>()
        .where((String url) => url.trim().isNotEmpty)
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchFollowingProfiles() async {
    final followingIds = await fetchFollowingUserIds();
    if (followingIds.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final rows = await _client
        .from('profiles')
        .select('id, username, display_name, avatar_url')
        .inFilter('id', followingIds)
        .order('display_name');

    return rows.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final rows = await _client
        .from('profiles')
        .select('id, username, display_name, avatar_url')
        .eq('id', userId)
        .limit(1);
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<int> fetchFollowerCount(String userId) async {
    final rows = await _client
        .from('follows')
        .select('follower_id')
        .eq('following_id', userId);
    return rows.length;
  }

  Future<int> fetchFollowingCount(String userId) async {
    final rows = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);
    return rows.length;
  }

  Future<List<DiaryPanelModel>> fetchDiaryPanels(String diaryId) async {
    final rows = await _client
        .from('diary_panels')
        .select()
        .eq('diary_id', diaryId)
        .order('panel_order');

    return rows
        .map<DiaryPanelModel>(
          (dynamic row) =>
              DiaryPanelModel.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }

  /// 댓글을 추가합니다. personaScript는 캐릭터가 읽고 말한 대사를 저장할 때 사용합니다.
  Future<void> addComment({
    required String diaryId,
    required String userId,
    required String content,
    String? parentCommentId,
    String? personaId,
    String? personaScript,
  }) async {
    await _client.from('diary_comments').insert(<String, dynamic>{
      'diary_id': diaryId,
      'user_id': userId,
      'parent_comment_id': parentCommentId,
      'persona_id': personaId,
      'content': content,
      'persona_script': personaScript,
      'moderation_status': 'pending',
    });
  }

  /// 최신 댓글을 가져와 소셜 상세 화면과 댓글 수 갱신에 사용합니다.
  Future<void> deleteComment(String commentId) async {
    await _client.from('diary_comments').delete().eq('id', commentId);
  }

  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    await _client
        .from('diary_comments')
        .update(<String, dynamic>{'content': content.trim()})
        .eq('id', commentId);
  }

  Future<List<DiaryCommentModel>> fetchComments(String diaryId) async {
    final rows = await _client
        .from('diary_comments')
        .select('*, profiles:user_id(username, display_name, avatar_url)')
        .eq('diary_id', diaryId)
        .order('created_at', ascending: false);

    return rows
        .map<DiaryCommentModel>(
          (dynamic row) =>
              DiaryCommentModel.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }
}
