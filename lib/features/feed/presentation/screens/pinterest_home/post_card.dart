// ignore_for_file: unused_element, unused_element_parameter

part of '../pinterest_home_screen.dart';

class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.post,
    required this.aspectRatio,
    required this.onChanged,
  });

  final SocialFeedItemModel post;
  final double aspectRatio;
  final VoidCallback onChanged;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  final PageController _mobileCutController = PageController();
  late int _likeCount = widget.post.likeCount;
  late int _commentCount = widget.post.commentCount;
  late String _caption = widget.post.caption?.trim() ?? '';
  bool _isLiking = false;
  bool _isLiked = false;
  bool _isBookmarking = false;
  bool _isBookmarked = false;
  bool _isDeleting = false;
  int _mobileCutIndex = 0;
  List<String>? _orderedPanelImageUrls;

  bool get _isMine {
    return Supabase.instance.client.auth.currentUser?.id == widget.post.userId;
  }

  @override
  void initState() {
    super.initState();
    _loadLikeState();
    _loadBookmarkState();
    _loadOrderedPanelImageUrls();
  }

  @override
  void dispose() {
    _mobileCutController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _likeCount = widget.post.likeCount;
      _commentCount = widget.post.commentCount;
      _caption = widget.post.caption?.trim() ?? '';
      _isLiked = false;
      _isBookmarked = false;
      _orderedPanelImageUrls = null;
      _mobileCutIndex = 0;
      if (_mobileCutController.hasClients) {
        _mobileCutController.jumpToPage(0);
      }
      _loadLikeState();
      _loadBookmarkState();
      _loadOrderedPanelImageUrls();
    }
  }

  Future<void> _loadOrderedPanelImageUrls() async {
    if (!SupabaseRuntime.isConfigured) {
      return;
    }
    final postId = widget.post.id;
    try {
      final panels = await SupabaseFeedRepository(
        Supabase.instance.client,
      ).fetchDiaryPanels(postId);
      final urls = _diaryPanelImageUrlsReadingOrder(panels);
      if (!mounted || widget.post.id != postId || urls.isEmpty) {
        return;
      }
      setState(() {
        _orderedPanelImageUrls = urls;
        if (_mobileCutIndex >= urls.length) {
          _mobileCutIndex = 0;
          if (_mobileCutController.hasClients) {
            _mobileCutController.jumpToPage(0);
          }
        }
      });
    } catch (_) {
      // Feed still has image_urls as a fallback when panel rows are unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.post.title?.trim().isNotEmpty == true
        ? widget.post.title!.trim()
        : '\uC81C\uBAA9 \uC5C6\uB294 \uC77C\uAE30';
    final caption = _caption;
    final tags = _socialDisplayTagsForPost(widget.post).take(3).toList();
    final imageUrls = _socialPostImageUrls(widget.post);
    final cutCount = imageUrls.length;
    final visibleCutCount = imageUrls.length;
    final currentCut = visibleCutCount == 0
        ? 0
        : _mobileCutIndex.clamp(0, visibleCutCount - 1) + 1;
    final mobile = _isMobileLayout(context);

    if (mobile) {
      return _buildMobilePostCard(
        title: title,
        caption: caption,
        tags: tags,
        cutCount: cutCount,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: AppTheme.pastelBlue.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(8, 5),
          ),
          BoxShadow(
            color: AppTheme.pastelRose.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(-8, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          color: Colors.white.withValues(alpha: 0.96),
          child: Stack(
            children: <Widget>[
              const Positioned.fill(
                child: CustomPaint(painter: _StorybookPaperPainter()),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: AppTheme.tacticalBlue),
              ),
              Positioned(
                left: 4,
                top: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        AppTheme.tacticalBlue.withValues(alpha: 0.92),
                        AppTheme.pastelGreen.withValues(alpha: 0.36),
                        AppTheme.pastelRose.withValues(alpha: 0.28),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: 1.16,
                    child: _PressableScale(
                      onTap: _showDiaryImages,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          ColoredBox(
                            color: const Color(0xFFF4F6FA),
                            child: imageUrls.isEmpty
                                ? const _PostImageFallback()
                                : PageView.builder(
                                    controller: _mobileCutController,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: imageUrls.length,
                                    onPageChanged: (int value) {
                                      setState(() => _mobileCutIndex = value);
                                    },
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                          return _StorageAwareImage(
                                            url: imageUrls[index],
                                            fit: BoxFit.contain,
                                          );
                                        },
                                  ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    AppTheme.tacticalBlue.withValues(
                                      alpha: 0.025,
                                    ),
                                    Colors.transparent,
                                    AppTheme.tacticalBlue.withValues(
                                      alpha: 0.24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const _CornerBrackets(),
                          if (visibleCutCount > 1)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.54),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    '$currentCut / $visibleCutCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (visibleCutCount > 1)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 10,
                              child: _CutPageDots(
                                count: visibleCutCount,
                                index: _mobileCutIndex,
                              ),
                            ),
                          if (cutCount > 0)
                            Positioned(
                              left: 8,
                              bottom: 8,
                              child: _StatusChip(
                                icon: Icons.view_carousel_rounded,
                                label: '$cutCount CUTS',
                              ),
                            ),
                          const Positioned(
                            right: 8,
                            bottom: 8,
                            child: _StatusChip(
                              icon: Icons.public_rounded,
                              label: 'SHARED',
                            ),
                          ),
                          if (_isMine)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: IconButton.filledTonal(
                                onPressed: _isDeleting ? null : _deletePost,
                                icon: _isDeleting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.delete_outline_rounded),
                                tooltip: '\uAC8C\uC2DC\uBB3C \uC0AD\uC81C',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (caption.isNotEmpty) ...<Widget>[
                          const Gap(6),
                          _PressableScale(
                            onTap: _isMine ? _editAuthorCaptionFromFeed : () {},
                            child: _AuthorCaptionPreview(caption: caption),
                          ),
                        ] else if (_isMine) ...<Widget>[
                          const Gap(6),
                          _InlineCaptionButton(
                            onTap: _editAuthorCaptionFromFeed,
                          ),
                        ],
                        const Gap(4),
                        _PressableScale(
                          onTap: _showAuthorProfile,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            child: Text(
                              '@${widget.post.username}',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.tacticalBlue.withValues(
                                  alpha: 0.82,
                                ),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const Gap(8),
                        if (tags.isNotEmpty)
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: tags.map((String tag) {
                              return _SocialPostTag(text: '#$tag');
                            }).toList(),
                          ),
                        const Gap(10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            _PressableScale(
                              onTap: _isLiking ? () {} : _toggleLike,
                              child: _SocialActionChip(
                                icon: _isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                label: '$_likeCount',
                                active: _isLiked,
                                color: AppTheme.pastelRose,
                              ),
                            ),
                            const Gap(10),
                            _PressableScale(
                              onTap: _showCommentsWithReplies,
                              child: _SocialActionChip(
                                icon: Icons.chat_bubble_outline_rounded,
                                label: '$_commentCount',
                                active: _commentCount > 0,
                                color: AppTheme.tacticalBlue,
                              ),
                            ),
                            const Gap(10),
                            _PressableScale(
                              onTap: _isBookmarking ? () {} : _toggleBookmark,
                              child: _SocialActionChip(
                                icon: _isBookmarked
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                label: '\uBD81\uB9C8\uD06C',
                                active: _isBookmarked,
                                color: AppTheme.pastelGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobilePostCard({
    required String title,
    required String caption,
    required List<String> tags,
    required int cutCount,
  }) {
    final imageUrls = _socialPostImageUrls(widget.post);
    final visibleCutCount = imageUrls.length;
    final currentCut = visibleCutCount == 0
        ? 0
        : _mobileCutIndex.clamp(0, visibleCutCount - 1) + 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          border: Border(
            top: BorderSide(color: AppTheme.ink.withValues(alpha: 0.06)),
            bottom: BorderSide(color: AppTheme.ink.withValues(alpha: 0.06)),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 10, 7),
                child: Row(
                  children: <Widget>[
                    _PressableScale(
                      onTap: _showAuthorProfile,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: AppTheme.tacticalBlue.withValues(
                          alpha: 0.14,
                        ),
                        backgroundImage:
                            widget.post.avatarUrl?.trim().isNotEmpty == true
                            ? NetworkImage(widget.post.avatarUrl!)
                            : null,
                        child: widget.post.avatarUrl?.trim().isNotEmpty == true
                            ? null
                            : Text(
                                widget.post.displayName.isEmpty
                                    ? '?'
                                    : widget.post.displayName.characters.first
                                          .toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.tacticalBlue,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11.5,
                                ),
                              ),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: _PressableScale(
                        onTap: _showAuthorProfile,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.post.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '@${widget.post.username}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.ink.withValues(alpha: 0.54),
                                fontWeight: FontWeight.w700,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isMine)
                      IconButton(
                        onPressed: _isDeleting ? null : _deletePost,
                        icon: const Icon(Icons.more_horiz_rounded),
                        visualDensity: VisualDensity.compact,
                        tooltip: '\uAC8C\uC2DC\uBB3C \uC0AD\uC81C',
                      ),
                  ],
                ),
              ),
              AspectRatio(
                aspectRatio: 1.16,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ColoredBox(
                      color: const Color(0xFFF7F9FC),
                      child: imageUrls.isEmpty
                          ? const _PostImageFallback()
                          : PageView.builder(
                              controller: _mobileCutController,
                              physics: const BouncingScrollPhysics(),
                              itemCount: imageUrls.length,
                              onPageChanged: (int value) {
                                setState(() => _mobileCutIndex = value);
                              },
                              itemBuilder: (BuildContext context, int index) {
                                return _StorageAwareImage(
                                  url: imageUrls[index],
                                  fit: BoxFit.contain,
                                );
                              },
                            ),
                    ),
                    if (visibleCutCount > 1)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.54),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              '$currentCut / $visibleCutCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (visibleCutCount > 1)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 10,
                        child: _CutPageDots(
                          count: visibleCutCount,
                          index: _mobileCutIndex,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                child: Row(
                  children: <Widget>[
                    _MobilePostAction(
                      iconData: _isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: '$_likeCount',
                      color: _isLiked ? const Color(0xFFFF5A7A) : AppTheme.ink,
                      onTap: _isLiking ? null : _toggleLike,
                    ),
                    const Gap(6),
                    _MobilePostAction(
                      iconData: Icons.mode_comment_outlined,
                      label: '$_commentCount',
                      color: AppTheme.ink,
                      onTap: _showCommentsWithReplies,
                    ),
                    const Spacer(),
                    _MobilePostAction(
                      iconData: _isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      label: '\uC800\uC7A5',
                      color: _isBookmarked
                          ? AppTheme.tacticalBlue
                          : AppTheme.ink,
                      onTap: _isBookmarking ? null : _toggleBookmark,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 1, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '\uC88B\uC544\uC694 $_likeCount\uAC1C',
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Gap(4),
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      text: TextSpan(
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 12.8,
                          height: 1.34,
                        ),
                        children: <InlineSpan>[
                          TextSpan(
                            text: '$title ',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    if (caption.isNotEmpty) ...<Widget>[
                      const Gap(5),
                      _PressableScale(
                        onTap: _isMine ? _editAuthorCaptionFromFeed : () {},
                        child: _AuthorCaptionPreview(caption: caption),
                      ),
                    ] else if (_isMine) ...<Widget>[
                      const Gap(5),
                      _InlineCaptionButton(onTap: _editAuthorCaptionFromFeed),
                    ],
                    if (tags.isNotEmpty) ...<Widget>[
                      const Gap(7),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: tags.map((String tag) {
                          return _SocialPostTag(text: '#$tag');
                        }).toList(),
                      ),
                    ],
                    if (_commentCount > 0) ...<Widget>[
                      const Gap(5),
                      Text(
                        '\uB313\uAE00 $_commentCount\uAC1C \uBCF4\uAE30',
                        style: TextStyle(
                          color: AppTheme.ink.withValues(alpha: 0.46),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiaryImages() => _showPostImages(widget.post);

  void _goMobileCut(int delta, int total) {
    if (total <= 1) {
      return;
    }
    final next = (_mobileCutIndex + delta).clamp(0, total - 1);
    if (next == _mobileCutIndex) {
      return;
    }
    setState(() => _mobileCutIndex = next);
    if (_mobileCutController.hasClients) {
      unawaited(
        _mobileCutController.animateToPage(
          next,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  List<String> _socialPostImageUrls(SocialFeedItemModel post) {
    final ordered = _orderedPanelImageUrls;
    if (ordered != null && ordered.isNotEmpty) {
      return ordered;
    }
    final urls = _diaryImageUrlsReadingOrder(post.imageUrls);
    if (urls.isNotEmpty) {
      return urls;
    }
    final first = post.firstImageUrl?.trim();
    return first == null || first.isEmpty ? const <String>[] : <String>[first];
  }

  void _showCommentsClean() {
    final controller = TextEditingController();
    var refreshTick = 0;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final currentUserId = Supabase.instance.client.auth.currentUser?.id;
            return FractionallySizedBox(
              heightFactor: 0.78,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    10,
                    18,
                    14 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  widget.post.title?.trim().isNotEmpty == true
                                      ? widget.post.title!.trim()
                                      : '\uC77C\uAE30',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.ink,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  '@${widget.post.username}',
                                  style: TextStyle(
                                    color: AppTheme.ink.withValues(alpha: 0.48),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _SocialActionChip(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: '$_commentCount',
                            active: _commentCount > 0,
                            color: AppTheme.tacticalBlue,
                          ),
                        ],
                      ),
                      const Gap(12),
                      Expanded(
                        child: FutureBuilder<List<DiaryCommentModel>>(
                          key: ValueKey<int>(refreshTick),
                          future: SupabaseFeedRepository(
                            Supabase.instance.client,
                          ).fetchComments(widget.post.id),
                          builder: (BuildContext context, snapshot) {
                            final comments =
                                snapshot.data ?? const <DiaryCommentModel>[];
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (comments.isEmpty) {
                              return Center(
                                child: Text(
                                  '\uC544\uC9C1 \uB313\uAE00\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.ink.withValues(alpha: 0.62),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              itemCount: comments.length,
                              separatorBuilder: (_, _) => Divider(
                                color: AppTheme.tacticalBlue.withValues(
                                  alpha: 0.12,
                                ),
                                height: 18,
                              ),
                              itemBuilder: (BuildContext context, int index) {
                                final comment = comments[index];
                                final name =
                                    comment.displayName?.trim().isNotEmpty ==
                                        true
                                    ? comment.displayName!.trim()
                                    : comment.username?.trim().isNotEmpty ==
                                          true
                                    ? '@${comment.username!.trim()}'
                                    : '\uC0AC\uC6A9\uC790';
                                final time = comment.createdAt
                                    .toLocal()
                                    .toString()
                                    .split('.')
                                    .first;
                                return _CleanCommentTile(
                                  name: name,
                                  content: comment.content,
                                  time: time,
                                  isAuthor:
                                      comment.userId == widget.post.userId,
                                  canEdit: comment.userId == currentUserId,
                                  onEdit: () async {
                                    final nextContent =
                                        await _editCommentDialog(
                                          context,
                                          comment.content,
                                        );
                                    if (nextContent == null ||
                                        nextContent.trim().isEmpty) {
                                      return;
                                    }
                                    await SupabaseFeedRepository(
                                      Supabase.instance.client,
                                    ).updateComment(
                                      commentId: comment.id,
                                      content: nextContent.trim(),
                                    );
                                    widget.onChanged();
                                    setSheetState(() => refreshTick++);
                                  },
                                  canDelete: comment.userId == currentUserId,
                                  onDelete: () async {
                                    await SupabaseFeedRepository(
                                      Supabase.instance.client,
                                    ).deleteComment(comment.id);
                                    if (mounted) {
                                      setState(() {
                                        _commentCount = (_commentCount - 1)
                                            .clamp(0, 999999);
                                      });
                                    }
                                    widget.onChanged();
                                    setSheetState(() => refreshTick++);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const Gap(10),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppTheme.tacticalBlue.withValues(
                              alpha: 0.26,
                            ),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppTheme.ink.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  minLines: 1,
                                  maxLines: 3,
                                  textAlign: TextAlign.left,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    hintText:
                                        '\uB313\uAE00\uC744 \uC785\uB825\uD574 \uC8FC\uC138\uC694',
                                    filled: false,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton.filled(
                                tooltip: '\uB4F1\uB85D',
                                onPressed: () async {
                                  final content = controller.text.trim();
                                  if (content.isEmpty) {
                                    return;
                                  }
                                  final user =
                                      Supabase.instance.client.auth.currentUser;
                                  if (user == null) {
                                    return;
                                  }
                                  await SupabaseFeedRepository(
                                    Supabase.instance.client,
                                  ).addComment(
                                    diaryId: widget.post.id,
                                    userId: user.id,
                                    content: content,
                                  );
                                  controller.clear();
                                  if (mounted) {
                                    setState(() => _commentCount++);
                                  }
                                  widget.onChanged();
                                  setSheetState(() => refreshTick++);
                                },
                                icon: const Icon(Icons.arrow_upward_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCommentsWithReplies() {
    final controller = TextEditingController();
    var refreshTick = 0;
    String? replyingToId;
    String? replyingToName;
    final expandedReplyRoots = <String>{};

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final currentUserId = Supabase.instance.client.auth.currentUser?.id;
            return FractionallySizedBox(
              heightFactor: 0.80,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F6FF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    10,
                    18,
                    14 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  widget.post.title?.trim().isNotEmpty == true
                                      ? widget.post.title!.trim()
                                      : '\uC77C\uAE30',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.ink,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  '@${widget.post.username}',
                                  style: TextStyle(
                                    color: AppTheme.ink.withValues(alpha: 0.48),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _SocialActionChip(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: '$_commentCount',
                            active: _commentCount > 0,
                            color: AppTheme.tacticalBlue,
                          ),
                        ],
                      ),
                      const Gap(12),
                      Expanded(
                        child: FutureBuilder<List<DiaryCommentModel>>(
                          key: ValueKey<int>(refreshTick),
                          future: SupabaseFeedRepository(
                            Supabase.instance.client,
                          ).fetchComments(widget.post.id),
                          builder: (BuildContext context, snapshot) {
                            final comments =
                                snapshot.data ?? const <DiaryCommentModel>[];
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (comments.isEmpty) {
                              return Center(
                                child: Text(
                                  '\uC544\uC9C1 \uB313\uAE00\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.ink.withValues(alpha: 0.62),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              );
                            }

                            final repliesByParent =
                                <String, List<DiaryCommentModel>>{};
                            final roots = <DiaryCommentModel>[];
                            for (final comment in comments.reversed) {
                              final parentId = comment.parentCommentId;
                              if (parentId == null || parentId.isEmpty) {
                                roots.add(comment);
                              } else {
                                repliesByParent
                                    .putIfAbsent(
                                      parentId,
                                      () => <DiaryCommentModel>[],
                                    )
                                    .add(comment);
                              }
                            }

                            final visibleComments = <DiaryCommentModel>[];
                            for (final root in roots) {
                              visibleComments.add(root);
                              if (expandedReplyRoots.contains(root.id)) {
                                visibleComments.addAll(
                                  repliesByParent[root.id] ??
                                      const <DiaryCommentModel>[],
                                );
                              }
                            }

                            return ListView.separated(
                              itemCount: visibleComments.length,
                              separatorBuilder: (_, _) => Divider(
                                color: AppTheme.tacticalBlue.withValues(
                                  alpha: 0.10,
                                ),
                                height: 14,
                              ),
                              itemBuilder: (BuildContext context, int index) {
                                final comment = visibleComments[index];
                                final isReply =
                                    comment.parentCommentId != null &&
                                    comment.parentCommentId!.isNotEmpty;
                                final name = _commentDisplayName(comment);
                                final replies =
                                    repliesByParent[comment.id] ??
                                    const <DiaryCommentModel>[];
                                final time = comment.createdAt
                                    .toLocal()
                                    .toString()
                                    .split('.')
                                    .first;
                                return _CleanCommentTile(
                                  name: name,
                                  content: comment.content,
                                  time: time,
                                  isAuthor:
                                      comment.userId == widget.post.userId,
                                  canDelete: comment.userId == currentUserId,
                                  canEdit: comment.userId == currentUserId,
                                  isReply: isReply,
                                  replyCount: isReply ? 0 : replies.length,
                                  repliesExpanded: expandedReplyRoots.contains(
                                    comment.id,
                                  ),
                                  onToggleReplies: replies.isEmpty
                                      ? null
                                      : () {
                                          setSheetState(() {
                                            if (expandedReplyRoots.contains(
                                              comment.id,
                                            )) {
                                              expandedReplyRoots.remove(
                                                comment.id,
                                              );
                                            } else {
                                              expandedReplyRoots.add(
                                                comment.id,
                                              );
                                            }
                                          });
                                        },
                                  onReply: () {
                                    setSheetState(() {
                                      replyingToId = comment.id;
                                      replyingToName = name;
                                    });
                                  },
                                  onDelete: () async {
                                    await SupabaseFeedRepository(
                                      Supabase.instance.client,
                                    ).deleteComment(comment.id);
                                    if (mounted) {
                                      setState(() {
                                        _commentCount = (_commentCount - 1)
                                            .clamp(0, 999999);
                                      });
                                    }
                                    widget.onChanged();
                                    setSheetState(() {
                                      if (replyingToId == comment.id) {
                                        replyingToId = null;
                                        replyingToName = null;
                                      }
                                      refreshTick++;
                                    });
                                  },
                                  onEdit: () async {
                                    final nextContent =
                                        await _editCommentDialog(
                                          context,
                                          comment.content,
                                        );
                                    if (nextContent == null ||
                                        nextContent.trim().isEmpty) {
                                      return;
                                    }
                                    await SupabaseFeedRepository(
                                      Supabase.instance.client,
                                    ).updateComment(
                                      commentId: comment.id,
                                      content: nextContent,
                                    );
                                    widget.onChanged();
                                    setSheetState(() {
                                      refreshTick++;
                                    });
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const Gap(10),
                      if (replyingToId != null) ...<Widget>[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InputChip(
                            label: Text(
                              '@$replyingToName\uC5D0\uAC8C \uB2F5\uAE00 \uC911',
                            ),
                            onDeleted: () {
                              setSheetState(() {
                                replyingToId = null;
                                replyingToName = null;
                              });
                            },
                            deleteIcon: const Icon(Icons.close_rounded),
                          ),
                        ),
                        const Gap(8),
                      ],
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppTheme.tacticalBlue.withValues(
                              alpha: 0.26,
                            ),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppTheme.ink.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  minLines: 1,
                                  maxLines: 3,
                                  textAlign: TextAlign.left,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    hintText:
                                        '\uB313\uAE00\uC744 \uC785\uB825\uD574 \uC8FC\uC138\uC694',
                                    filled: false,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton.filled(
                                tooltip: '\uB4F1\uB85D',
                                onPressed: () async {
                                  final content = controller.text.trim();
                                  if (content.isEmpty) {
                                    return;
                                  }
                                  final user =
                                      Supabase.instance.client.auth.currentUser;
                                  if (user == null) {
                                    return;
                                  }
                                  await SupabaseFeedRepository(
                                    Supabase.instance.client,
                                  ).addComment(
                                    diaryId: widget.post.id,
                                    userId: user.id,
                                    content: content,
                                    parentCommentId: replyingToId,
                                  );
                                  controller.clear();
                                  final wasReply = replyingToId != null;
                                  if (mounted) {
                                    setState(() => _commentCount++);
                                  }
                                  widget.onChanged();
                                  setSheetState(() {
                                    if (wasReply) {
                                      replyingToId = null;
                                      replyingToName = null;
                                    }
                                    refreshTick++;
                                  });
                                },
                                icon: const Icon(Icons.arrow_upward_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPostImages(SocialFeedItemModel post) {
    final fallbackUrls = _socialFeedItemImageUrlsReadingOrder(post);
    final captionController = TextEditingController(text: _caption);
    final isAuthor =
        Supabase.instance.client.auth.currentUser?.id == widget.post.userId;
    var detailCaption = _caption;
    var savingCaption = false;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return FractionallySizedBox(
              heightFactor: 0.88,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: FutureBuilder<List<DiaryPanelModel>>(
                  future: SupabaseFeedRepository(
                    Supabase.instance.client,
                  ).fetchDiaryPanels(post.id),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<List<DiaryPanelModel>> snapshot,
                      ) {
                        final panels =
                            snapshot.data ?? const <DiaryPanelModel>[];
                        final urls = panels.isEmpty
                            ? fallbackUrls
                            : _diaryPanelImageUrlsReadingOrder(panels);

                        final captionBox = _AuthorCaptionBox(
                          caption: detailCaption,
                          controller: captionController,
                          isAuthor: isAuthor,
                          isEditing: false,
                          isSaving: savingCaption,
                          onEdit: () => unawaited(
                            _openAuthorCaptionEditor(
                              context: context,
                              controller: captionController,
                              currentCaption: detailCaption,
                              setSheetState: setSheetState,
                              post: post,
                              onUpdated: (String nextCaption) {
                                detailCaption = nextCaption;
                                if (mounted) {
                                  setState(() => _caption = nextCaption);
                                }
                                widget.onChanged();
                              },
                              setSaving: (bool value) {
                                savingCaption = value;
                              },
                            ),
                          ),
                          onCancel: () {
                            captionController.text = detailCaption;
                          },
                          onSave: () async {
                            final nextCaption = captionController.text
                                .trim()
                                .characters
                                .take(240)
                                .toString();
                            setSheetState(() => savingCaption = true);
                            try {
                              await SupabaseFeedRepository(
                                Supabase.instance.client,
                              ).updateDiaryCaption(
                                diaryId: post.id,
                                caption: nextCaption,
                              );
                              if (mounted) {
                                setState(() => _caption = nextCaption);
                              }
                              widget.onChanged();
                              setSheetState(() {
                                detailCaption = nextCaption;
                              });
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '\uC8FC\uC11D \uC800\uC7A5 \uC2E4\uD328: ${_friendlyGenerationError(error)}',
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setSheetState(() => savingCaption = false);
                              }
                            }
                          },
                        );

                        return Column(
                          children: <Widget>[
                            Text(
                              post.title?.trim().isNotEmpty == true
                                  ? post.title!.trim()
                                  : '\uC81C\uBAA9 \uC5C6\uB294 \uC77C\uAE30',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const Gap(10),
                            Expanded(
                              child:
                                  snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : LayoutBuilder(
                                      builder:
                                          (
                                            BuildContext context,
                                            BoxConstraints constraints,
                                          ) {
                                            final showSideNote =
                                                isAuthor ||
                                                detailCaption.trim().isNotEmpty;
                                            if (!showSideNote) {
                                              return _ImageUrlSlideDeck(
                                                imageUrls: urls,
                                                panels: panels,
                                              );
                                            }
                                            return Column(
                                              children: <Widget>[
                                                Expanded(
                                                  child: _ImageUrlSlideDeck(
                                                    imageUrls: urls,
                                                    panels: panels,
                                                  ),
                                                ),
                                                const Gap(6),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: captionBox,
                                                ),
                                              ],
                                            );
                                          },
                                    ),
                            ),
                          ],
                        );
                      },
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(captionController.dispose);
  }

  void _showAuthorProfile() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          child: _AuthorProfileSheet(
            post: widget.post,
            onOpenPost: (SocialFeedItemModel post) {
              Navigator.of(context).pop();
              _showPostImages(post);
            },
          ),
        );
      },
    );
  }

  Future<void> _editAuthorCaptionFromFeed() async {
    if (!_isMine) {
      return;
    }
    final controller = TextEditingController(text: _caption);
    try {
      final nextCaption = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('\uCEA1\uC158'),
            content: SizedBox(
              width: 360,
              child: TextField(
                controller: controller,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                maxLength: 240,
                textAlign: TextAlign.left,
                decoration: const InputDecoration(
                  hintText:
                      '\uC791\uD488 \uC606\uC5D0 \uBCF4\uC5EC\uC904 \uC9E7\uC740 \uCEA1\uC158',
                ),
              ),
            ),
            actions: <Widget>[
              if (_caption.trim().isNotEmpty)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(''),
                  child: const Text('\uC0AD\uC81C'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('\uCDE8\uC18C'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('\uC800\uC7A5'),
              ),
            ],
          );
        },
      );
      if (nextCaption == null) {
        return;
      }
      final normalized = nextCaption.trim().characters.take(240).toString();
      await SupabaseFeedRepository(
        Supabase.instance.client,
      ).updateDiaryCaption(diaryId: widget.post.id, caption: normalized);
      if (!mounted) {
        return;
      }
      setState(() => _caption = normalized);
      widget.onChanged();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '\uCEA1\uC158 \uC800\uC7A5 \uC2E4\uD328: ${_friendlyGenerationError(error)}',
            ),
          ),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _toggleLike() async {
    if (!SupabaseRuntime.isConfigured) {
      return;
    }
    setState(() => _isLiking = true);
    try {
      final liked = await SupabaseFeedRepository(
        Supabase.instance.client,
      ).toggleLike(widget.post.id);
      if (mounted) {
        setState(() {
          _isLiked = liked;
          _likeCount = (_likeCount + (liked ? 1 : -1)).clamp(0, 999999);
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('\uC0AD\uC81C \uC2E4\uD328: ')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLiking = false);
      }
    }
  }

  Future<void> _toggleBookmark() async {
    if (!SupabaseRuntime.isConfigured) {
      return;
    }
    setState(() => _isBookmarking = true);
    try {
      final bookmarked = await SupabaseFeedRepository(
        Supabase.instance.client,
      ).toggleBookmark(widget.post.id);
      if (mounted) {
        setState(() => _isBookmarked = bookmarked);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '\uBD81\uB9C8\uD06C \uC800\uC7A5 \uC2E4\uD328: ${_friendlyGenerationError(error)}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBookmarking = false);
      }
    }
  }

  Future<void> _loadLikeState() async {
    if (!SupabaseRuntime.isConfigured) {
      return;
    }
    try {
      final liked = await SupabaseFeedRepository(
        Supabase.instance.client,
      ).isLiked(widget.post.id);
      if (mounted) {
        setState(() => _isLiked = liked);
      }
    } catch (_) {}
  }

  Future<void> _loadBookmarkState() async {
    if (!SupabaseRuntime.isConfigured) {
      return;
    }
    try {
      final bookmarked = await SupabaseFeedRepository(
        Supabase.instance.client,
      ).isBookmarked(widget.post.id);
      if (mounted) {
        setState(() => _isBookmarked = bookmarked);
      }
    } catch (_) {}
  }

  Future<void> _loadFollowState() async {
    if (!SupabaseRuntime.isConfigured || _isMine) {
      return;
    }
    try {
      await SupabaseFeedRepository(
        Supabase.instance.client,
      ).isFollowing(widget.post.userId);
      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    if (_isMine) {
      return;
    }
    setState(() {});
    try {
      await SupabaseFeedRepository(
        Supabase.instance.client,
      ).toggleFollow(widget.post.userId);
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '\uD314\uB85C\uC6B0 \uC2E4\uD328: ${_friendlyGenerationError(error)}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '\uAC8C\uC2DC\uBB3C \uC0AD\uC81C',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            '\uC774 \uAC8C\uC2DC\uBB3C\uC740 \uC0AD\uC81C\uD558\uBA74 \uB418\uB3CC\uB9B4 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('\uCDE8\uC18C'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('\uC0AD\uC81C'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await SupabaseFeedRepository(
        Supabase.instance.client,
      ).deleteDiary(widget.post.id);
      widget.onChanged();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('\uC0AD\uC81C \uC2E4\uD328: ')));
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _showCommentsV2() {
    final controller = TextEditingController();
    var refreshTick = 0;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final currentUserId = Supabase.instance.client.auth.currentUser?.id;
            return FractionallySizedBox(
              heightFactor: 0.74,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  18 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            widget.post.title?.trim().isNotEmpty == true
                                ? widget.post.title!.trim()
                                : '\uC77C\uAE30',
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        _SocialActionChip(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: '$_commentCount',
                          active: _commentCount > 0,
                          color: AppTheme.tacticalBlue,
                        ),
                      ],
                    ),
                    const Gap(14),
                    Expanded(
                      child: FutureBuilder<List<DiaryCommentModel>>(
                        key: ValueKey<int>(refreshTick),
                        future: SupabaseFeedRepository(
                          Supabase.instance.client,
                        ).fetchComments(widget.post.id),
                        builder: (BuildContext context, snapshot) {
                          final comments =
                              snapshot.data ?? const <DiaryCommentModel>[];
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (comments.isEmpty) {
                            return const Center(
                              child: Text(
                                '\uC544\uC9C1 \uB313\uAE00\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            itemCount: comments.length,
                            separatorBuilder: (context, index) => Divider(
                              color: AppTheme.tacticalBlue.withValues(
                                alpha: 0.18,
                              ),
                              height: 22,
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              final comment = comments[index];
                              final name =
                                  comment.displayName?.trim().isNotEmpty == true
                                  ? comment.displayName!.trim()
                                  : comment.username?.trim().isNotEmpty == true
                                  ? '@${comment.username!.trim()}'
                                  : '\uC0AC\uC6A9\uC790';
                              final time = comment.createdAt
                                  .toLocal()
                                  .toString()
                                  .split('.')
                                  .first;

                              return _PixivCommentTile(
                                name: name,
                                content: comment.content,
                                time: time,
                                isAuthor: comment.userId == widget.post.userId,
                                canEdit: comment.userId == currentUserId,
                                onEdit: () async {
                                  final nextContent = await _editCommentDialog(
                                    context,
                                    comment.content,
                                  );
                                  if (nextContent == null ||
                                      nextContent.trim().isEmpty) {
                                    return;
                                  }
                                  await SupabaseFeedRepository(
                                    Supabase.instance.client,
                                  ).updateComment(
                                    commentId: comment.id,
                                    content: nextContent.trim(),
                                  );
                                  widget.onChanged();
                                  setSheetState(() => refreshTick++);
                                },
                                canDelete: comment.userId == currentUserId,
                                onDelete: () async {
                                  await SupabaseFeedRepository(
                                    Supabase.instance.client,
                                  ).deleteComment(comment.id);
                                  if (mounted) {
                                    setState(() {
                                      _commentCount = (_commentCount - 1).clamp(
                                        0,
                                        999999,
                                      );
                                    });
                                  }
                                  widget.onChanged();
                                  setSheetState(() => refreshTick++);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const Gap(12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppTheme.tacticalBlue.withValues(alpha: 0.36),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: controller,
                                minLines: 1,
                                maxLines: 3,
                                textAlign: TextAlign.left,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  hintText:
                                      '\uB313\uAE00\uC744 \uC785\uB825\uD574 \uC8FC\uC138\uC694',
                                  filled: false,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            IconButton.filled(
                              tooltip: '\uB4F1\uB85D',
                              onPressed: () async {
                                final content = controller.text.trim();
                                if (content.isEmpty) {
                                  return;
                                }
                                final user =
                                    Supabase.instance.client.auth.currentUser;
                                if (user == null) {
                                  return;
                                }
                                await SupabaseFeedRepository(
                                  Supabase.instance.client,
                                ).addComment(
                                  diaryId: widget.post.id,
                                  userId: user.id,
                                  content: content,
                                );
                                controller.clear();
                                if (mounted) {
                                  setState(() => _commentCount++);
                                }
                                widget.onChanged();
                                setSheetState(() => refreshTick++);
                              },
                              icon: const Icon(Icons.arrow_upward_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showComments() {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              0,
              18,
              18 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              children: <Widget>[
                const Text(
                  '\uB313\uAE00',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const Gap(12),
                Expanded(
                  child: FutureBuilder<List<DiaryCommentModel>>(
                    future: SupabaseFeedRepository(
                      Supabase.instance.client,
                    ).fetchComments(widget.post.id),
                    builder: (BuildContext context, snapshot) {
                      final comments =
                          snapshot.data ?? const <DiaryCommentModel>[];
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (comments.isEmpty) {
                        return const Center(
                          child: Text(
                            '\uC544\uC9C1 \uB313\uAE00\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: comments.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (BuildContext context, int index) {
                          final comment = comments[index];
                          final isAuthorComment =
                              comment.userId == widget.post.userId;
                          final name =
                              comment.displayName?.trim().isNotEmpty == true
                              ? comment.displayName!.trim()
                              : comment.username?.trim().isNotEmpty == true
                              ? '@${comment.username!.trim()}'
                              : '\uC0AC\uC6A9\uC790';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isAuthorComment
                                  ? AppTheme.pastelGreen
                                  : AppTheme.academyLilac,
                              child: Icon(
                                isAuthorComment
                                    ? Icons.edit_note_rounded
                                    : Icons.person_rounded,
                                color: AppTheme.ink,
                              ),
                            ),
                            title: Text(
                              comment.content,
                              textAlign: TextAlign.center,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                isAuthorComment
                                    ? '\uC791\uC131\uC790 \uC8FC\uC11D 夷?$name'
                                    : '$name 夷?${comment.createdAt.toLocal().toString().split('.').first}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Gap(10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textAlign: TextAlign.center,
                        decoration: _figmaField('\uB313\uAE00 \uC785\uB825'),
                      ),
                    ),
                    const Gap(8),
                    FilledButton(
                      onPressed: () async {
                        final content = controller.text.trim();
                        if (content.isEmpty) {
                          return;
                        }
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user == null) {
                          return;
                        }
                        await SupabaseFeedRepository(
                          Supabase.instance.client,
                        ).addComment(
                          diaryId: widget.post.id,
                          userId: user.id,
                          content: content,
                        );
                        if (mounted) {
                          setState(() => _commentCount++);
                        }
                        widget.onChanged();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('\uB4F1\uB85D'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _openAuthorCaptionEditor({
  required BuildContext context,
  required TextEditingController controller,
  required String currentCaption,
  required StateSetter setSheetState,
  required SocialFeedItemModel post,
  required ValueChanged<String> onUpdated,
  required ValueChanged<bool> setSaving,
}) async {
  controller.text = currentCaption;
  final nextCaption = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('\uC791\uC131\uC790 \uC8FC\uC11D'),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            maxLength: 240,
            textAlign: TextAlign.left,
            decoration: const InputDecoration(
              hintText:
                  '\uC774 \uC791\uD488\uC5D0 \uB300\uD55C \uC9E7\uC740 \uBA54\uBAA8',
            ),
          ),
        ),
        actions: <Widget>[
          if (currentCaption.trim().isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(context).pop(''),
              child: const Text('\uC0AD\uC81C'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('\uCDE8\uC18C'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('\uC800\uC7A5'),
          ),
        ],
      );
    },
  );
  if (nextCaption == null) {
    controller.text = currentCaption;
    return;
  }

  final normalized = nextCaption.trim().characters.take(240).toString();
  setSheetState(() => setSaving(true));
  try {
    await SupabaseFeedRepository(
      Supabase.instance.client,
    ).updateDiaryCaption(diaryId: post.id, caption: normalized);
    onUpdated(normalized);
    controller.text = normalized;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '\uC8FC\uC11D \uC800\uC7A5 \uC2E4\uD328: ${_friendlyGenerationError(error)}',
          ),
        ),
      );
    }
  } finally {
    if (context.mounted) {
      setSheetState(() => setSaving(false));
    }
  }
}

class _AuthorCaptionBox extends StatelessWidget {
  const _AuthorCaptionBox({
    required this.caption,
    required this.controller,
    required this.isAuthor,
    required this.isEditing,
    required this.isSaving,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  final String caption;
  final TextEditingController controller;
  final bool isAuthor;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final trimmedCaption = caption.trim();
    if (!isAuthor && caption.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    if (!isEditing) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
        child: Row(
          crossAxisAlignment: trimmedCaption.isEmpty
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: trimmedCaption.isEmpty ? 0 : 2),
              child: Icon(
                Icons.sticky_note_2_rounded,
                color: AppTheme.tacticalBlue.withValues(alpha: 0.72),
                size: 17,
              ),
            ),
            const Gap(6),
            Expanded(
              child: trimmedCaption.isEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: isAuthor ? onEdit : null,
                        icon: const Icon(Icons.add_rounded, size: 17),
                        label: const Text(
                          '\uC791\uC131\uC790 \uC8FC\uC11D \uCD94\uAC00',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.tacticalBlue,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 2,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      trimmedCaption,
                      textAlign: TextAlign.left,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.ink.withValues(alpha: 0.76),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
            ),
            if (isAuthor && trimmedCaption.isNotEmpty)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: '\uC8FC\uC11D \uC218\uC815',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_note_rounded, size: 19),
              ),
          ],
        ),
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      constraints: BoxConstraints(
        minHeight: isEditing
            ? 148
            : trimmedCaption.isNotEmpty
            ? 86
            : 76,
      ),
      decoration: BoxDecoration(
        color: isEditing
            ? const Color(0xFFFBFDFF).withValues(alpha: 0.98)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEditing
              ? AppTheme.tacticalBlue.withValues(alpha: 0.44)
              : const Color(0xFFBFD9FF),
          width: isEditing ? 1.5 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(
              alpha: isEditing ? 0.14 : 0.08,
            ),
            blurRadius: isEditing ? 14 : 7,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, isEditing ? 10 : 9, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.sticky_note_2_rounded,
                  color: AppTheme.tacticalBlue,
                  size: 18,
                ),
                const Gap(7),
                Expanded(
                  child: Text(
                    '\uC791\uC131\uC790 \uC8FC\uC11D',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: AppTheme.ink.withValues(alpha: 0.82),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (isEditing)
                  AnimatedBuilder(
                    animation: controller,
                    builder: (BuildContext context, Widget? child) {
                      return _CaptionCountPill(
                        count: controller.text.characters.length,
                      );
                    },
                  )
                else if (isAuthor)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: caption.trim().isEmpty
                        ? '\uC8FC\uC11D \uCD94\uAC00'
                        : '\uC8FC\uC11D \uC218\uC815',
                    onPressed: onEdit,
                    icon: Icon(
                      caption.trim().isEmpty
                          ? Icons.add_comment_rounded
                          : Icons.edit_note_rounded,
                      size: 20,
                    ),
                  ),
              ],
            ),
            if (isEditing) ...<Widget>[
              const Gap(10),
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 4,
                maxLength: 240,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: AppTheme.ink.withValues(alpha: 0.88),
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
                decoration: _figmaField('\uC8FC\uC11D \uC785\uB825').copyWith(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.96),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.tacticalBlue.withValues(alpha: 0.28),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.tacticalBlue.withValues(alpha: 0.68),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const Gap(6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (caption.trim().isNotEmpty)
                    IconButton(
                      onPressed: isSaving
                          ? null
                          : () {
                              controller.clear();
                              onSave();
                            },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      tooltip: '\uC8FC\uC11D \uC0AD\uC81C',
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: isSaving ? null : onCancel,
                    child: const Text('\uCDE8\uC18C'),
                  ),
                  const Gap(6),
                  FilledButton(
                    onPressed: isSaving ? null : onSave,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(72, 38),
                    ),
                    child: Text(
                      isSaving ? '\uC800\uC7A5 \uC911...' : '\uC800\uC7A5',
                    ),
                  ),
                ],
              ),
            ] else ...<Widget>[
              const Gap(8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.tacticalBlue.withValues(alpha: 0.24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
                  child: trimmedCaption.isEmpty
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('\uC8FC\uC11D \uCD94\uAC00'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.tacticalBlue,
                              side: BorderSide(
                                color: AppTheme.tacticalBlue.withValues(
                                  alpha: 0.44,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          trimmedCaption,
                          textAlign: TextAlign.left,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.ink.withValues(alpha: 0.86),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MobilePostAction extends StatelessWidget {
  const _MobilePostAction({
    required this.iconData,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData iconData;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap ?? () {},
      child: Opacity(
        opacity: onTap == null ? 0.46 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.10)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(iconData, size: 18, color: color),
                const Gap(4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CutPageDots extends StatelessWidget {
  const _CutPageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (int i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: active ? 16 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: active ? 0.95 : 0.58),
            borderRadius: BorderRadius.circular(999),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 5,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _CutStepButton extends StatelessWidget {
  const _CutStepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.32),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _AuthorCaptionPreview extends StatelessWidget {
  const _AuthorCaptionPreview({required this.caption});

  final String caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.sticky_note_2_rounded,
            size: 15,
            color: AppTheme.tacticalBlue.withValues(alpha: 0.70),
          ),
          const Gap(5),
          Expanded(
            child: Text(
              caption,
              textAlign: TextAlign.left,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.ink.withValues(alpha: 0.68),
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptionCountPill extends StatelessWidget {
  const _CaptionCountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.pastelBlue.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          '$count/240',
          style: TextStyle(
            color: AppTheme.ink.withValues(alpha: 0.58),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MyProfileSheet extends StatefulWidget {
  const _MyProfileSheet({required this.userId});

  final String userId;

  @override
  State<_MyProfileSheet> createState() => _MyProfileSheetState();
}

class _MyProfileSheetState extends State<_MyProfileSheet> {
  late final SupabaseFeedRepository _repository = SupabaseFeedRepository(
    Supabase.instance.client,
  );
  late Future<List<SocialFeedItemModel>> _postsFuture;
  late Future<Map<String, dynamic>?> _profileFuture;
  late Future<int> _followerCountFuture;
  late Future<int> _followingCountFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _repository.fetchUserPosts(widget.userId);
    _profileFuture = _repository.fetchProfile(widget.userId);
    _followerCountFuture = _repository.fetchFollowerCount(widget.userId);
    _followingCountFuture = _repository.fetchFollowingCount(widget.userId);
  }

  void _showBookmarks() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.86,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              children: <Widget>[
                Text(
                  '\uBD81\uB9C8\uD06C',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: FutureBuilder<List<SocialFeedItemModel>>(
                    future: _repository.fetchBookmarkedPosts(),
                    builder: (BuildContext context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final posts =
                          snapshot.data ?? const <SocialFeedItemModel>[];
                      if (posts.isEmpty) {
                        return const Center(
                          child: Text(
                            '\uC544\uC9C1 \uBD81\uB9C8\uD06C\uD55C \uC791\uD488\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: posts.length,
                        separatorBuilder: (_, _) => const Gap(12),
                        itemBuilder: (BuildContext context, int index) {
                          return _PostCard(
                            post: posts[index],
                            aspectRatio: 1,
                            onChanged: () {},
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBookmarkedPostImages(SocialFeedItemModel post) {
    final fallbackUrls = _socialFeedItemImageUrlsReadingOrder(post);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.88,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              children: <Widget>[
                Text(
                  post.title?.trim().isNotEmpty == true
                      ? post.title!.trim()
                      : '\uC81C\uBAA9 \uC5C6\uB294 \uC77C\uAE30',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: FutureBuilder<List<DiaryPanelModel>>(
                    future: _repository.fetchDiaryPanels(post.id),
                    builder: (BuildContext context, snapshot) {
                      final panels = snapshot.data ?? const <DiaryPanelModel>[];
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return _ImageUrlSlideDeck(
                        imageUrls: fallbackUrls,
                        panels: panels,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _profileFuture,
          builder: (BuildContext context, profileSnapshot) {
            final profile = profileSnapshot.data;
            final username =
                profile?['username']?.toString() ??
                Supabase.instance.client.auth.currentUser?.email
                    ?.split('@')
                    .first ??
                'user';
            final displayName =
                profile?['display_name']?.toString().trim().isNotEmpty == true
                ? profile!['display_name'].toString().trim()
                : username;
            final avatarUrl = profile?['avatar_url']?.toString();
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: '\uB2EB\uAE30',
                    ),
                  ),
                  const Gap(4),
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.pastelBlue.withValues(
                      alpha: 0.65,
                    ),
                    backgroundImage: avatarUrl?.trim().isNotEmpty == true
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: avatarUrl?.trim().isNotEmpty == true
                        ? null
                        : Text(
                            displayName.characters.first.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                  ),
                  const Gap(10),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '@$username',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.ink.withValues(alpha: 0.58),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Gap(14),
                  FutureBuilder<List<int>>(
                    future: Future.wait<int>([
                      _postsFuture.then((List<SocialFeedItemModel> posts) {
                        return posts.length;
                      }),
                      _followerCountFuture,
                      _followingCountFuture,
                    ]),
                    builder: (BuildContext context, snapshot) {
                      final values = snapshot.data ?? const <int>[0, 0, 0];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _ProfileStat(label: '\uC791\uD488', value: values[0]),
                          _ProfileStat(
                            label: '\uD314\uB85C\uC6CC',
                            value: values[1],
                          ),
                          _ProfileStat(
                            label: '\uD314\uB85C\uC789',
                            value: values[2],
                          ),
                        ],
                      );
                    },
                  ),
                  const Gap(14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.tacticalBlue.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.auto_stories_rounded,
                            color: AppTheme.tacticalBlue.withValues(
                              alpha: 0.88,
                            ),
                            size: 20,
                          ),
                          const Gap(7),
                          Expanded(
                            child: Text(
                              '\uB0B4 \uC791\uD488',
                              textAlign: TextAlign.left,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: _showBookmarks,
                            icon: const Icon(Icons.bookmark_rounded, size: 18),
                            label: const Text('\uBD81\uB9C8\uD06C'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(10),
                  FutureBuilder<List<SocialFeedItemModel>>(
                    future: _postsFuture,
                    builder: (BuildContext context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 42),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final posts =
                          snapshot.data ?? const <SocialFeedItemModel>[];
                      if (posts.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 42),
                          child: Center(
                            child: Text(
                              '\uC544\uC9C1 \uAC8C\uC2DC\uBB3C\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: posts.length,
                        separatorBuilder: (_, _) => const Gap(12),
                        itemBuilder: (BuildContext context, int index) {
                          return _PostCard(
                            post: posts[index],
                            aspectRatio: 1,
                            onChanged: () {
                              setState(() {
                                _postsFuture = _repository.fetchUserPosts(
                                  widget.userId,
                                );
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: <Widget>[
          Text(
            '$value',
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.ink.withValues(alpha: 0.58),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorProfileSheet extends StatefulWidget {
  const _AuthorProfileSheet({required this.post, required this.onOpenPost});

  final SocialFeedItemModel post;
  final ValueChanged<SocialFeedItemModel> onOpenPost;

  @override
  State<_AuthorProfileSheet> createState() => _AuthorProfileSheetState();
}

class _AuthorProfileSheetState extends State<_AuthorProfileSheet> {
  late final SupabaseFeedRepository _repository = SupabaseFeedRepository(
    Supabase.instance.client,
  );
  late Future<List<SocialFeedItemModel>> _postsFuture;
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  bool get _isMine {
    return Supabase.instance.client.auth.currentUser?.id == widget.post.userId;
  }

  @override
  void initState() {
    super.initState();
    _postsFuture = _repository.fetchUserPosts(widget.post.userId);
    _loadFollowState();
  }

  Future<void> _loadFollowState() async {
    if (_isMine) {
      return;
    }
    final following = await _repository.isFollowing(widget.post.userId);
    if (mounted) {
      setState(() => _isFollowing = following);
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _isFollowLoading = true);
    try {
      final following = await _repository.toggleFollow(widget.post.userId);
      if (mounted) {
        setState(() => _isFollowing = following);
      }
    } finally {
      if (mounted) {
        setState(() => _isFollowLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.post.displayName.trim().isNotEmpty
        ? widget.post.displayName.trim()
        : widget.post.username;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: '\uB2EB\uAE30',
                ),
              ),
              const Gap(4),
              CircleAvatar(
                radius: 34,
                backgroundColor: AppTheme.pastelBlue.withValues(alpha: 0.65),
                backgroundImage:
                    widget.post.avatarUrl?.trim().isNotEmpty == true
                    ? NetworkImage(widget.post.avatarUrl!)
                    : null,
                child: widget.post.avatarUrl?.trim().isNotEmpty == true
                    ? null
                    : Text(
                        displayName.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
              ),
              const Gap(10),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '@${widget.post.username}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.ink.withValues(alpha: 0.58),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Gap(12),
              if (!_isMine)
                FilledButton.icon(
                  onPressed: _isFollowLoading ? null : _toggleFollow,
                  icon: _isFollowLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isFollowing
                              ? Icons.person_remove_alt_1_rounded
                              : Icons.person_add_alt_1_rounded,
                        ),
                  label: Text(
                    _isFollowing
                        ? '\uD314\uB85C\uC789 \uC911'
                        : '\uD314\uB85C\uC6B0',
                  ),
                ),
              const Gap(18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '\uC791\uD488',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Gap(10),
              FutureBuilder<List<SocialFeedItemModel>>(
                future: _postsFuture,
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<SocialFeedItemModel>> snapshot,
                    ) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 42),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final posts =
                          snapshot.data ?? const <SocialFeedItemModel>[];
                      if (posts.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 42),
                          child: Center(
                            child: Text(
                              '\uAC8C\uC2DC\uBB3C\uC774 \uC544\uC9C1 \uC5C6\uC2B5\uB2C8\uB2E4.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: posts.length,
                        separatorBuilder: (_, _) => const Gap(12),
                        itemBuilder: (BuildContext context, int index) {
                          return _PostCard(
                            post: posts[index],
                            aspectRatio: 1,
                            onChanged: () {
                              setState(() {
                                _postsFuture = _repository.fetchUserPosts(
                                  widget.post.userId,
                                );
                              });
                            },
                          );
                        },
                      );
                    },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileWorkTile extends StatelessWidget {
  const _ProfileWorkTile({required this.post, required this.onTap});

  final SocialFeedItemModel post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = post.title?.trim().isNotEmpty == true
        ? post.title!.trim()
        : '\uC81C\uBAA9 \uC5C6\uB294 \uC77C\uAE30';
    return _PressableScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            border: Border.all(
              color: AppTheme.tacticalBlue.withValues(alpha: 0.18),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.ink.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 8,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: _StorageAwareImage(
                    url: post.firstImageUrl ?? '',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    height: 1.18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PixivCommentTile extends StatelessWidget {
  const _PixivCommentTile({
    required this.name,
    required this.content,
    required this.time,
    required this.isAuthor,
    required this.canEdit,
    required this.onEdit,
    required this.canDelete,
    required this.onDelete,
  });

  final String name;
  final String content;
  final String time;
  final bool isAuthor;
  final bool canEdit;
  final bool canDelete;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: isAuthor
                ? AppTheme.pastelGreen.withValues(alpha: 0.82)
                : AppTheme.academyLilac.withValues(alpha: 0.82),
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (isAuthor) ...<Widget>[
                      const Gap(6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.pastelGreen.withValues(alpha: 0.60),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '\uC791\uC131\uC790',
                          style: TextStyle(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                    const Gap(8),
                    Text(
                      time,
                      style: TextStyle(
                        color: AppTheme.ink.withValues(alpha: 0.42),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Gap(5),
                Text(
                  content,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (canEdit || canDelete)
            PopupMenuButton<String>(
              tooltip: '\uB313\uAE00 \uBA54\uB274',
              icon: const Icon(Icons.more_horiz_rounded),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                if (canEdit)
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('\uC218\uC815'),
                  ),
                if (canDelete)
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('\uC0AD\uC81C'),
                  ),
              ],
              onSelected: (String value) async {
                if (value == 'edit') {
                  await onEdit();
                  return;
                }
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text(
                      '\uB313\uAE00 \uC0AD\uC81C',
                      textAlign: TextAlign.center,
                    ),
                    content: const Text(
                      '\uC774 \uB313\uAE00\uC744 \uC0AD\uC81C\uD560\uAE4C\uC694?',
                      textAlign: TextAlign.center,
                    ),
                    actionsAlignment: MainAxisAlignment.center,
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('\uCDE8\uC18C'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('\uC0AD\uC81C'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await onDelete();
                }
              },
            ),
        ],
      ),
    );
  }
}

class _CleanCommentTile extends StatelessWidget {
  const _CleanCommentTile({
    required this.name,
    required this.content,
    required this.time,
    required this.isAuthor,
    required this.canDelete,
    required this.onDelete,
    this.canEdit = false,
    this.onEdit,
    this.isReply = false,
    this.replyCount = 0,
    this.repliesExpanded = false,
    this.onToggleReplies,
    this.onReply,
  });

  final String name;
  final String content;
  final String time;
  final bool isAuthor;
  final bool canDelete;
  final bool canEdit;
  final bool isReply;
  final int replyCount;
  final bool repliesExpanded;
  final VoidCallback? onToggleReplies;
  final VoidCallback? onReply;
  final Future<void> Function() onDelete;
  final Future<void> Function()? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 34 : 0, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 17,
            backgroundColor: isAuthor
                ? AppTheme.pastelGreen.withValues(alpha: 0.95)
                : AppTheme.tacticalBlue.withValues(alpha: 0.24),
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Gap(10),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.tacticalBlue.withValues(alpha: 0.24),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.ink.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (isAuthor) ...<Widget>[
                          const Gap(6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.pastelGreen.withValues(
                                alpha: 0.82,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '\uC791\uC131\uC790',
                              style: TextStyle(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                        const Gap(8),
                        Expanded(
                          child: Text(
                            time,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.ink.withValues(alpha: 0.52),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(5),
                    Text(
                      content,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const Gap(6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 2,
                        children: <Widget>[
                          TextButton.icon(
                            onPressed: onReply,
                            icon: const Icon(
                              Icons.subdirectory_arrow_right_rounded,
                            ),
                            label: const Text('\uB2F5\uAE00'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.tacticalBlue,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(52, 28),
                            ),
                          ),
                          if (!isReply && replyCount > 0)
                            TextButton.icon(
                              onPressed: onToggleReplies,
                              icon: Icon(
                                repliesExpanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                              ),
                              label: Text(
                                repliesExpanded
                                    ? '\uB2F5\uAE00 \uC811\uAE30'
                                    : '\uB2F5\uAE00 $replyCount\uAC1C \uBCF4\uAE30',
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.ink.withValues(
                                  alpha: 0.72,
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(86, 28),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (canEdit || canDelete)
            PopupMenuButton<String>(
              tooltip: '\uB313\uAE00 \uC0AD\uC81C',
              icon: const Icon(Icons.more_horiz_rounded),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                if (canEdit)
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('\uC218\uC815'),
                  ),
                if (canDelete)
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('\uC0AD\uC81C'),
                  ),
              ],
              onSelected: (String value) async {
                if (value == 'edit') {
                  await onEdit?.call();
                  return;
                }
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text(
                        '\uB313\uAE00 \uC0AD\uC81C',
                        textAlign: TextAlign.center,
                      ),
                      content: const Text(
                        '\uC774 \uB313\uAE00\uC744 \uC0AD\uC81C\uD560\uAE4C\uC694?',
                        textAlign: TextAlign.center,
                      ),
                      actionsAlignment: MainAxisAlignment.center,
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('\uCDE8\uC18C'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('\uC0AD\uC81C'),
                        ),
                      ],
                    );
                  },
                );
                if (confirmed == true) {
                  await onDelete();
                }
              },
            ),
        ],
      ),
    );
  }
}

class _InlineCaptionButton extends StatelessWidget {
  const _InlineCaptionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: _PressableScale(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppTheme.tacticalBlue.withValues(alpha: 0.22),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.add_comment_rounded,
                  size: 15,
                  color: AppTheme.tacticalBlue,
                ),
                Gap(5),
                Text(
                  '\uCEA1\uC158 \uCD94\uAC00',
                  style: TextStyle(
                    color: AppTheme.tacticalBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _commentDisplayName(DiaryCommentModel comment) {
  if (comment.displayName?.trim().isNotEmpty == true) {
    return comment.displayName!.trim();
  }
  if (comment.username?.trim().isNotEmpty == true) {
    return '@${comment.username!.trim()}';
  }
  return '\uC0AC\uC6A9\uC790';
}

Future<String?> _editCommentDialog(
  BuildContext context,
  String initialContent,
) async {
  final controller = TextEditingController(text: initialContent);
  try {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '\uB313\uAE00 \uC218\uC815',
            textAlign: TextAlign.center,
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            textAlign: TextAlign.left,
            decoration: const InputDecoration(
              hintText:
                  '\uB313\uAE00\uC744 \uC785\uB825\uD574 \uC8FC\uC138\uC694',
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('\uCDE8\uC18C'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('\uC800\uC7A5'),
            ),
          ],
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.isFollowing,
    required this.isLoading,
    required this.onTap,
  });

  final bool isFollowing;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: isLoading ? () {} : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isFollowing
              ? AppTheme.pastelGreen.withValues(alpha: 0.76)
              : AppTheme.tacticalBlue.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isFollowing
                ? AppTheme.tacticalBlue.withValues(alpha: 0.52)
                : Colors.white.withValues(alpha: 0.86),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                isFollowing
                    ? Icons.check_rounded
                    : Icons.person_add_alt_1_rounded,
                size: 15,
                color: isFollowing ? AppTheme.ink : Colors.white,
              ),
            const Gap(5),
            Text(
              isFollowing ? '\uD314\uB85C\uC789 \uC911' : '\uD314\uB85C\uC6B0',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isFollowing ? AppTheme.ink : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialActionChip extends StatelessWidget {
  const _SocialActionChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isLikeChip = color == AppTheme.pastelRose;
    final isBookmarkChip = label == '\uBD81\uB9C8\uD06C';
    const heartPink = Color(0xFFFF9ABA);
    const bookmarkGreen = Color(0xFF62B894);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isLikeChip
            ? Colors.white.withValues(alpha: 0.86)
            : isBookmarkChip
            ? (active
                  ? const Color(0xFFE3F6ED).withValues(alpha: 0.98)
                  : Colors.white.withValues(alpha: 0.92))
            : active
            ? color.withValues(alpha: 0.50)
            : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isBookmarkChip
              ? bookmarkGreen.withValues(alpha: active ? 0.92 : 0.58)
              : active && !isLikeChip
              ? color.withValues(alpha: 0.95)
              : AppTheme.tacticalBlue.withValues(alpha: 0.34),
          width: (active && !isLikeChip) || isBookmarkChip ? 1.3 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: active ? 0.16 : 0.08),
            blurRadius: active ? 10 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 18,
            color: active
                ? (isLikeChip
                      ? heartPink
                      : isBookmarkChip
                      ? bookmarkGreen
                      : color)
                : isLikeChip
                ? AppTheme.ink.withValues(alpha: 0.58)
                : isBookmarkChip
                ? bookmarkGreen.withValues(alpha: 0.86)
                : AppTheme.ink.withValues(alpha: 0.58),
          ),
          const Gap(4),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.ink.withValues(alpha: active ? 0.92 : 0.66),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
