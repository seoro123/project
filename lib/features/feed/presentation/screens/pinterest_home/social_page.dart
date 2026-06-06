// ignore_for_file: unused_element, unused_element_parameter

part of '../pinterest_home_screen.dart';

class _SocialPage extends StatelessWidget {
  const _SocialPage({
    required this.refreshTick,
    required this.searchController,
    required this.selectedTags,
    required this.showTagFilter,
    required this.followingOnly,
    required this.onSearchChanged,
    required this.onTagToggled,
    required this.onFilterPressed,
    required this.onFollowingOnlyChanged,
    required this.onFeedChanged,
  });

  final int refreshTick;
  final TextEditingController searchController;
  final Set<String> selectedTags;
  final bool showTagFilter;
  final bool followingOnly;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onTagToggled;
  final VoidCallback onFilterPressed;
  final ValueChanged<bool> onFollowingOnlyChanged;
  final VoidCallback onFeedChanged;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    const tags = <String>[
      'comics_ld',
      'anime_ld',
      'comics_sd',
      'simple_2d',
      'realistic_3d',
      'daily_comic',
      'serious',
      'healing_romance',
      'growth',
      'hard_day',
    ];

    return CustomScrollView(
      slivers: <Widget>[
        if (mobile) ...<Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            sliver: SliverToBoxAdapter(
              child: _MobileSocialHeader(
                searchController: searchController,
                showTagFilter: showTagFilter,
                selectedTags: selectedTags,
                tags: tags,
                onSearchChanged: onSearchChanged,
                onFilterPressed: onFilterPressed,
                onTagToggled: onTagToggled,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            sliver: SliverToBoxAdapter(
              child: _StoryRailPanel(
                compact: true,
                followingOnly: followingOnly,
                onFollowingOnlyChanged: onFollowingOnlyChanged,
                onProfileTap: (Map<String, dynamic> profile) {
                  _showUserStoryViewer(context, profile);
                },
              ),
            ),
          ),
        ],
        if (!mobile)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            sliver: SliverToBoxAdapter(
              child: _GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const _TerminalTitle(
                      eyebrow: 'PUBLIC BOARD',
                      title: 'Mood Diary',
                      code: 'SNS-01',
                    ),
                    const Gap(12),
                    if (mobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          TextField(
                            controller: searchController,
                            textAlign: TextAlign.center,
                            onChanged: onSearchChanged,
                            decoration: _inputDecoration(
                              hintText:
                                  '\uB2C9\uB124\uC784\u00B7\uC791\uD488 \uAC80\uC0C9',
                              icon: Icons.search_rounded,
                            ),
                          ),
                          const Gap(10),
                          SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: onFilterPressed,
                              icon: AnimatedRotation(
                                turns: showTagFilter ? 0.5 : 0,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                child: Icon(
                                  showTagFilter
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.tune_rounded,
                                ),
                              ),
                              label: Text(
                                selectedTags.isEmpty
                                    ? '\uC804\uCCB4 \uD544\uD130'
                                    : '\uD544\uD130 ',
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              textAlign: TextAlign.center,
                              onChanged: onSearchChanged,
                              decoration: _inputDecoration(
                                hintText:
                                    '\uB2C9\uB124\uC784\u00B7\uC791\uD488 \uAC80\uC0C9',
                                icon: Icons.search_rounded,
                              ),
                            ),
                          ),
                          const Gap(10),
                          FilledButton.icon(
                            onPressed: onFilterPressed,
                            icon: AnimatedRotation(
                              turns: showTagFilter ? 0.5 : 0,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                showTagFilter
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.tune_rounded,
                              ),
                            ),
                            label: Text(
                              selectedTags.isEmpty
                                  ? '\uC804\uCCB4 \uD544\uD130'
                                  : '\uD544\uD130 ',
                            ),
                          ),
                        ],
                      ),
                    if (selectedTags.isNotEmpty) ...<Widget>[
                      const Gap(10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: selectedTags.map((String tag) {
                          return InputChip(
                            label: Text('#${_socialDisplayTagText(tag)}'),
                            onDeleted: () => onTagToggled(tag),
                          );
                        }).toList(),
                      ),
                    ],
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return SizeTransition(
                              sizeFactor: animation,
                              axisAlignment: -1,
                              child: FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, -0.04),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                            );
                          },
                      child: showTagFilter
                          ? Padding(
                              key: const ValueKey<String>('tag-filter-open'),
                              padding: const EdgeInsets.only(top: 12),
                              child: _SocialTagFilterPanel(
                                tags: tags,
                                selectedTags: selectedTags,
                                onTagToggled: onTagToggled,
                              ),
                            )
                          : const SizedBox(
                              key: ValueKey<String>('tag-filter-closed'),
                              height: 0,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            mobile ? 10 : 20,
            4,
            mobile ? 10 : 20,
            mobile ? 10 : 16,
          ),
          sliver: SliverToBoxAdapter(
            child: FutureBuilder<List<SocialFeedItemModel>>(
              key: ValueKey<int>(refreshTick),
              future: _fetchSharedPosts(),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<SocialFeedItemModel>> snapshot,
                  ) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _LoadingPanel(
                        message:
                            '\uACF5\uC720\uB41C \uC77C\uAE30\uB97C \uBD88\uB7EC\uC624\uB294 \uC911',
                      );
                    }

                    if (snapshot.hasError) {
                      return _EmptyPanel(
                        message:
                            '\uACF5\uC720\uB41C \uC77C\uAE30\uB97C \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC2B5\uB2C8\uB2E4.',
                      );
                    }

                    final posts =
                        snapshot.data ?? const <SocialFeedItemModel>[];
                    if (posts.isEmpty) {
                      return const _EmptyPanel(
                        message:
                            '\uC544\uC9C1 \uACF5\uC720\uB41C \uC77C\uAE30\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
                      );
                    }

                    return MasonryGridView.extent(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      maxCrossAxisExtent: mobile ? 720 : 280,
                      mainAxisSpacing: mobile ? 10 : 24,
                      crossAxisSpacing: mobile ? 0 : 22,
                      itemCount: posts.length,
                      itemBuilder: (BuildContext context, int index) {
                        return _DimensionalCardSlot(
                          index: index,
                          depth: 1.0,
                          child: _PostCard(
                            post: posts[index],
                            aspectRatio: mobile ? 1.0 : _postAspectRatio(index),
                            onChanged: onFeedChanged,
                          ),
                        );
                      },
                    );
                  },
            ),
          ),
        ),
        if (!mobile)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverToBoxAdapter(
              child: _StoryRailPanel(
                compact: false,
                followingOnly: followingOnly,
                onFollowingOnlyChanged: onFollowingOnlyChanged,
                onProfileTap: (Map<String, dynamic> profile) {
                  _showUserStoryViewer(context, profile);
                },
              ),
            ),
          ),
      ],
    );
  }

  Future<List<SocialFeedItemModel>> _fetchSharedPosts() async {
    if (!SupabaseRuntime.isConfigured) {
      return const <SocialFeedItemModel>[];
    }

    return SupabaseFeedRepository(Supabase.instance.client).fetchFeed(
      searchKeyword: searchController.text,
      tags: selectedTags.toList(),
      followingOnly: followingOnly,
      limit: followingOnly ? 60 : 45,
    );
  }

  void _showUserStoryViewer(
    BuildContext context,
    Map<String, dynamic> profile,
  ) {
    final userId = profile['id']?.toString();
    if (userId == null || userId.isEmpty || !SupabaseRuntime.isConfigured) {
      return;
    }

    final username = profile['username']?.toString() ?? 'user';
    final displayName =
        profile['display_name']?.toString().trim().isNotEmpty == true
        ? profile['display_name'].toString().trim()
        : username;
    final avatarUrl = profile['avatar_url']?.toString();

    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: FutureBuilder<List<SocialFeedItemModel>>(
            future: SupabaseFeedRepository(
              Supabase.instance.client,
            ).fetchUserPosts(userId, limit: 40),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<SocialFeedItemModel>> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  final posts = snapshot.data ?? const <SocialFeedItemModel>[];
                  if (posts.isEmpty) {
                    return _UserStoryEmptyState(displayName: displayName);
                  }

                  return _UserStoryViewer(
                    posts: posts,
                    displayName: displayName,
                    username: username,
                    avatarUrl: avatarUrl,
                  );
                },
          ),
        );
      },
    );
  }

  double _postAspectRatio(int index) {
    const rhythm = <double>[0.86, 0.94, 0.86, 0.94];
    return rhythm[index % rhythm.length];
  }
}

class _MobileSocialHeader extends StatelessWidget {
  const _MobileSocialHeader({
    required this.searchController,
    required this.showTagFilter,
    required this.selectedTags,
    required this.tags,
    required this.onSearchChanged,
    required this.onFilterPressed,
    required this.onTagToggled,
  });

  final TextEditingController searchController;
  final bool showTagFilter;
  final Set<String> selectedTags;
  final List<String> tags;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterPressed;
  final ValueChanged<String> onTagToggled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                const SizedBox(width: 28),
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '\uC18C\uC15C \uD53C\uB4DC',
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                _PressableScale(
                  onTap: onFilterPressed,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: selectedTags.isEmpty
                          ? const Color(0xFFF4F7FB)
                          : AppTheme.tacticalBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selectedTags.isEmpty
                            ? AppTheme.ink.withValues(alpha: 0.08)
                            : AppTheme.tacticalBlue.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            showTagFilter
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.tune_rounded,
                            size: 18,
                            color: AppTheme.tacticalBlue,
                          ),
                          const Gap(4),
                          Text(
                            selectedTags.isEmpty
                                ? '\uD544\uD130'
                                : '${selectedTags.length}',
                            style: const TextStyle(
                              color: AppTheme.tacticalBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: showTagFilter
                  ? Padding(
                      key: const ValueKey<String>('mobile-filter-open'),
                      padding: const EdgeInsets.only(top: 8),
                      child: _SocialTagFilterPanel(
                        tags: tags,
                        selectedTags: selectedTags,
                        onTagToggled: onTagToggled,
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey<String>('mobile-filter-closed'),
                      height: 0,
                    ),
            ),
            const Gap(5),
            SizedBox(
              height: 32,
              child: TextField(
                controller: searchController,
                textAlign: TextAlign.left,
                onChanged: onSearchChanged,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText:
                      '\uB2C9\uB124\uC784\uC774\uB098 \uC791\uD488\uBA85 \uAC80\uC0C9',
                  prefixIcon: const Icon(Icons.search_rounded, size: 19),
                  filled: true,
                  fillColor: const Color(0xFFF4F7FB),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (selectedTags.isNotEmpty) ...<Widget>[
              const Gap(8),
              SizedBox(
                height: 28,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedTags.length,
                  separatorBuilder: (_, _) => const Gap(6),
                  itemBuilder: (BuildContext context, int index) {
                    final tag = selectedTags.elementAt(index);
                    return Chip(
                      label: Text(
                        _socialDisplayTagText(tag),
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FollowerStoryRail extends StatelessWidget {
  const _FollowerStoryRail({
    required this.followingOnly,
    required this.onFollowingOnlyChanged,
    required this.onProfileTap,
  });

  final bool followingOnly;
  final ValueChanged<bool> onFollowingOnlyChanged;
  final ValueChanged<Map<String, dynamic>> onProfileTap;

  @override
  Widget build(BuildContext context) {
    if (!SupabaseRuntime.isConfigured) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 62,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: SupabaseFeedRepository(
          Supabase.instance.client,
        ).fetchFollowingProfiles(),
        builder: (BuildContext context, snapshot) {
          final profiles = snapshot.data ?? const <Map<String, dynamic>>[];
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: profiles.length + 2,
            separatorBuilder: (BuildContext context, int index) => const Gap(6),
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return _StoryBubble(
                  label: '\uBAA8\uB4E0 \uD53C\uB4DC',
                  initial: 'M',
                  icon: Icons.grid_view_rounded,
                  active: !followingOnly,
                  onTap: () => onFollowingOnlyChanged(false),
                );
              }
              if (index == 1) {
                return _StoryBubble(
                  label: '\uD314\uB85C\uC789',
                  initial: 'F',
                  icon: Icons.people_alt_rounded,
                  active: followingOnly,
                  onTap: () => onFollowingOnlyChanged(true),
                );
              }

              final profile = profiles[index - 2];
              final username = profile['username']?.toString() ?? 'user';
              final displayName =
                  profile['display_name']?.toString().trim().isNotEmpty == true
                  ? profile['display_name'].toString().trim()
                  : username;
              final avatarUrl = profile['avatar_url']?.toString();
              return _StoryBubble(
                label: displayName,
                initial: displayName.characters.first.toUpperCase(),
                imageUrl: avatarUrl,
                active: followingOnly,
                showStoryCue: true,
                onTap: () => onProfileTap(profile),
              );
            },
          );
        },
      ),
    );
  }
}

class _StoryRailPanel extends StatelessWidget {
  const _StoryRailPanel({
    required this.compact,
    required this.followingOnly,
    required this.onFollowingOnlyChanged,
    required this.onProfileTap,
  });

  final bool compact;
  final bool followingOnly;
  final ValueChanged<bool> onFollowingOnlyChanged;
  final ValueChanged<Map<String, dynamic>> onProfileTap;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 3),
          child: _FollowerStoryRail(
            followingOnly: followingOnly,
            onFollowingOnlyChanged: onFollowingOnlyChanged,
            onProfileTap: onProfileTap,
          ),
        ),
      );
    }

    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.play_circle_fill_rounded,
              color: AppTheme.tacticalBlue.withValues(alpha: 0.84),
              size: compact ? 17 : 19,
            ),
            const Gap(6),
            Text(
              '\uC2A4\uD1A0\uB9AC',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            if (followingOnly)
              ActionChip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.people_alt_rounded, size: 16),
                label: const Text(
                  '\uD314\uB85C\uC789\uB9CC',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                ),
                onPressed: () => onFollowingOnlyChanged(false),
              ),
          ],
        ),
        Gap(compact ? 4 : 8),
        _FollowerStoryRail(
          followingOnly: followingOnly,
          onFollowingOnlyChanged: onFollowingOnlyChanged,
          onProfileTap: onProfileTap,
        ),
      ],
    );

    return _GlassPanel(child: child);
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({
    required this.label,
    required this.initial,
    required this.onTap,
    this.icon,
    this.imageUrl,
    this.active = false,
    this.showStoryCue = false,
  });

  final String label;
  final String initial;
  final IconData? icon;
  final String? imageUrl;
  final bool active;
  final bool showStoryCue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = imageUrl?.trim().isNotEmpty == true
        ? NetworkImage(imageUrl!)
        : null;
    return SizedBox(
      width: 52,
      child: _PressableScale(
        onTap: onTap,
        child: Column(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: active
                      ? const <Color>[
                          Color(0xFF8FB1FF),
                          Color(0xFFFFB8D2),
                          Color(0xFFB2D8B2),
                        ]
                      : const <Color>[Color(0xFFD8E6FF), Color(0xFFF3E8FF)],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.tacticalBlue.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.92),
                    backgroundImage: image,
                    child: image != null
                        ? null
                        : icon != null
                        ? Icon(icon, color: AppTheme.tacticalBlue)
                        : Text(
                            initial,
                            style: const TextStyle(
                              color: AppTheme.tacticalBlue,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                  if (showStoryCue)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.tacticalBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppTheme.ink.withValues(alpha: 0.18),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const SizedBox(
                          width: 16,
                          height: 16,
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Gap(4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active
                    ? AppTheme.tacticalBlue
                    : AppTheme.ink.withValues(alpha: 0.62),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserStoryViewer extends StatefulWidget {
  const _UserStoryViewer({
    required this.posts,
    required this.displayName,
    required this.username,
    this.avatarUrl,
  });

  final List<SocialFeedItemModel> posts;
  final String displayName;
  final String username;
  final String? avatarUrl;

  @override
  State<_UserStoryViewer> createState() => _UserStoryViewerState();
}

class _UserStoryViewerState extends State<_UserStoryViewer> {
  final PageController _controller = PageController();
  List<_UserStorySlide> _slides = const <_UserStorySlide>[];
  List<int> _workStartIndexes = const <int>[];
  bool _isLoadingSlides = true;
  int _index = 0;
  late String _displayName;
  late String _username;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _displayName = widget.displayName;
    _username = widget.username;
    _avatarUrl = widget.avatarUrl;
    unawaited(_loadSlides());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSlides() async {
    final slides = await _UserStorySlide.fromPostsOrdered(widget.posts);
    if (!mounted) {
      return;
    }
    setState(() {
      _slides = slides;
      _workStartIndexes = _storyWorkStartIndexes(slides);
      _isLoadingSlides = false;
    });
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0) {
      return;
    }
    if (next >= _slides.length) {
      Navigator.of(context).pop();
      return;
    }
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _avatarUrl;
    if (_isLoadingSlides) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6FBFF),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_slides.isEmpty) {
      return _UserStoryEmptyState(displayName: widget.displayName);
    }

    final currentSlide = _slides[_index];
    final currentWork = currentSlide.workIndex + 1;
    final workCount = _workStartIndexes.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: _PastelBackground()),
            PageView.builder(
              controller: _controller,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (int value) {
                setState(() => _index = value);
              },
              itemCount: _slides.length,
              itemBuilder: (BuildContext context, int index) {
                final slide = _slides[index];
                return LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final maxHeight = constraints.maxHeight - 108;
                    final showSideNote =
                        slide.caption.isNotEmpty && constraints.maxWidth >= 760;
                    final sideNoteWidth = showSideNote ? 168.0 : 0.0;
                    final maxWidth =
                        constraints.maxWidth - 22 - sideNoteWidth - 10;
                    final frameWidth = (maxHeight * 2 / 3)
                        .clamp(220.0, maxWidth)
                        .toDouble();
                    final frameHeight = (frameWidth * 3 / 2)
                        .clamp(260.0, maxHeight)
                        .toDouble();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(10, 58, 10, 50),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: frameWidth,
                              height: frameHeight,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: AppTheme.ink.withValues(
                                        alpha: 0.14,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _StorageAwareImage(
                                    url: slide.imageUrl,
                                    fit: BoxFit.contain,
                                    fallback: const ColoredBox(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (showSideNote) ...<Widget>[
                              const Gap(12),
                              SizedBox(
                                width: sideNoteWidth,
                                child: _StorySideNote(text: slide.caption),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.transparent,
                        const Color(0xFFF6FBFF).withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                  child: const SizedBox(height: 150),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    currentSlide.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 10,
              child: Row(
                children: List<Widget>.generate(_slides.length, (int index) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _index
                            ? AppTheme.tacticalBlue
                            : AppTheme.tacticalBlue.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              left: 16,
              right: 8,
              top: 22,
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.tacticalBlue.withValues(
                      alpha: 0.20,
                    ),
                    backgroundImage: avatarUrl?.trim().isNotEmpty == true
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: avatarUrl?.trim().isNotEmpty == true
                        ? null
                        : Text(
                            (_displayName.isEmpty
                                    ? '?'
                                    : _displayName.characters.first)
                                .toUpperCase(),
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
                        Text(
                          _displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '@$_username',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.ink.withValues(alpha: 0.62),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.ink,
                    tooltip: '\uB2EB\uAE30',
                  ),
                ],
              ),
            ),
            Positioned(
              right: 18,
              bottom: 52,
              child: Text(
                '\uC791\uD488 $currentWork / $workCount  \u00B7  \uCEF7 ${_index + 1} / ${_slides.length}',
                style: TextStyle(
                  color: AppTheme.ink.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryNavButton extends StatelessWidget {
  const _StoryNavButton({
    required this.icon,
    required this.visible,
    required this.onTap,
  });

  final IconData icon;
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 160),
      child: IgnorePointer(
        ignoring: !visible,
        child: IconButton.filledTonal(
          onPressed: onTap,
          icon: Icon(icon),
          color: Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.tacticalBlue.withValues(alpha: 0.72),
          ),
        ),
      ),
    );
  }
}

class _StoryWorkButton extends StatelessWidget {
  const _StoryWorkButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.ink,
        disabledForegroundColor: AppTheme.ink.withValues(alpha: 0.28),
        backgroundColor: Colors.white.withValues(alpha: enabled ? 0.88 : 0.42),
        side: BorderSide(
          color: AppTheme.tacticalBlue.withValues(alpha: enabled ? 0.48 : 0.18),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _StorySideNote extends StatelessWidget {
  const _StorySideNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.30),
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
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.edit_note_rounded,
                  size: 16,
                  color: AppTheme.tacticalBlue.withValues(alpha: 0.82),
                ),
                const Gap(4),
                Text(
                  '\uC791\uC131\uC790 \uC8FC\uC11D',
                  style: TextStyle(
                    color: AppTheme.ink.withValues(alpha: 0.64),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const Gap(6),
            Text(
              text,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.ink.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.34,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserStorySlide {
  const _UserStorySlide({
    required this.imageUrl,
    required this.title,
    required this.caption,
    required this.workIndex,
  });

  final String imageUrl;
  final String title;
  final String caption;
  final int workIndex;

  static List<_UserStorySlide> fromPosts(
    List<SocialFeedItemModel> posts, {
    int startWorkIndex = 0,
  }) {
    final slides = <_UserStorySlide>[];
    for (var postIndex = 0; postIndex < posts.length; postIndex++) {
      final post = posts[postIndex];
      final urls = _socialFeedItemImageUrlsReadingOrder(post);
      final title = post.title?.trim().isNotEmpty == true
          ? post.title!.trim()
          : '\uC81C\uBAA9 \uC5C6\uB294 \uC77C\uAE30';
      final caption = post.caption?.trim().isNotEmpty == true
          ? post.caption!.trim()
          : '';
      slides.addAll(
        urls.map(
          (String url) => _UserStorySlide(
            imageUrl: url,
            title: title,
            caption: caption,
            workIndex: startWorkIndex + postIndex,
          ),
        ),
      );
    }
    return slides;
  }

  static Future<List<_UserStorySlide>> fromPostsOrdered(
    List<SocialFeedItemModel> posts, {
    int startWorkIndex = 0,
  }) async {
    if (!SupabaseRuntime.isConfigured) {
      return fromPosts(posts, startWorkIndex: startWorkIndex);
    }

    final repository = SupabaseFeedRepository(Supabase.instance.client);
    final slides = <_UserStorySlide>[];
    for (var postIndex = 0; postIndex < posts.length; postIndex++) {
      final post = posts[postIndex];
      final fallbackUrls = _socialFeedItemImageUrlsReadingOrder(post);
      final title = post.title?.trim().isNotEmpty == true
          ? post.title!.trim()
          : '\uC81C\uBAA9 \uC5C6\uB294 \uC77C\uAE30';
      final caption = post.caption?.trim().isNotEmpty == true
          ? post.caption!.trim()
          : '';

      try {
        final panels = await repository.fetchDiaryPanels(post.id);
        final orderedSlides = _PanelSlideData.fromPanels(
          panels: panels,
          fallbackImageUrls: fallbackUrls,
        );
        slides.addAll(
          orderedSlides.map(
            (_PanelSlideData slide) => _UserStorySlide(
              imageUrl: slide.imageUrl,
              title: title,
              caption: caption,
              workIndex: startWorkIndex + postIndex,
            ),
          ),
        );
      } catch (_) {
        slides.addAll(
          fallbackUrls.map(
            (String url) => _UserStorySlide(
              imageUrl: url,
              title: title,
              caption: caption,
              workIndex: startWorkIndex + postIndex,
            ),
          ),
        );
      }
    }
    return slides;
  }
}

List<int> _storyWorkStartIndexes(List<_UserStorySlide> slides) {
  final indexes = <int>[];
  var lastWorkIndex = -1;
  for (var index = 0; index < slides.length; index++) {
    final workIndex = slides[index].workIndex;
    if (workIndex != lastWorkIndex) {
      indexes.add(index);
      lastWorkIndex = workIndex;
    }
  }
  return indexes;
}

class _UserStoryEmptyState extends StatelessWidget {
  const _UserStoryEmptyState({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Center(
              child: Text(
                '$displayName\uB2D8\uC758 \uD45C\uC2DC\uD560 \uC77C\uAE30\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: Colors.white,
                tooltip: '\uB2EB\uAE30',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuButton extends StatelessWidget {
  const _ProfileMenuButton();

  @override
  Widget build(BuildContext context) {
    if (!SupabaseRuntime.isConfigured) {
      return const SizedBox.shrink();
    }

    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'profile';
    final name = email.split('@').first;
    final mobile = _isMobileLayout(context);

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.all(mobile ? 8 : 10),
        child: PopupMenuButton<String>(
          tooltip: '\uD504\uB85C\uD544',
          offset: Offset(0, mobile ? 42 : 48),
          onSelected: (String value) async {
            if (value == 'my_profile') {
              _showMyProfile(context);
              return;
            }
            if (value == 'bookmarks') {
              _showBookmarks(context);
              return;
            }
            if (value == 'following_list') {
              _showFollowingList(context);
              return;
            }
            if (value == 'logout') {
              await Supabase.instance.client.auth.signOut();
            }
          },
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                enabled: false,
                child: Center(
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'my_profile',
                child: Center(
                  child: Text(
                    '\uB0B4 \uD504\uB85C\uD544',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'bookmarks',
                child: Center(
                  child: Text(
                    '\uBD81\uB9C8\uD06C',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'following_list',
                child: Center(
                  child: Text(
                    '\uD314\uB85C\uC789 \uBAA9\uB85D',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Center(
                  child: Text(
                    '\uB85C\uADF8\uC544\uC6C3',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ];
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: mobile ? 0.96 : 0.86),
              border: Border.all(
                color: mobile
                    ? AppTheme.ink.withValues(alpha: 0.08)
                    : const Color(0xFF9FC4FF),
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: mobile
                  ? const <BoxShadow>[]
                  : <BoxShadow>[
                      BoxShadow(
                        color: AppTheme.tacticalBlue.withValues(alpha: 0.16),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: mobile ? 4 : 10,
                vertical: mobile ? 4 : 7,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFDDEBFF),
                    child: Text(
                      (name.isEmpty ? 'P' : name.substring(0, 1)).toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF5B8EEB),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (!mobile) ...<Widget>[
                    const Gap(7),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF5B8EEB),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFollowingList(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.70,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              children: <Widget>[
                const Text(
                  '\uD314\uB85C\uC789',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const Gap(12),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: SupabaseFeedRepository(
                      Supabase.instance.client,
                    ).fetchFollowingProfiles(),
                    builder: (BuildContext context, snapshot) {
                      final profiles =
                          snapshot.data ?? const <Map<String, dynamic>>[];
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (profiles.isEmpty) {
                        return const Center(
                          child: Text(
                            '\uD314\uB85C\uC789\uD55C \uC0AC\uC6A9\uC790\uAC00 \uC544\uC9C1 \uC5C6\uC2B5\uB2C8\uB2E4.',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: profiles.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (BuildContext context, int index) {
                          final profile = profiles[index];
                          final username =
                              profile['username']?.toString() ?? 'user';
                          final displayName = profile['display_name']
                              ?.toString()
                              .trim();
                          final title =
                              displayName != null && displayName.isNotEmpty
                              ? displayName
                              : username;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.academyLilac,
                              child: Text(
                                title.isEmpty ? '?' : title[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            title: Text(title, textAlign: TextAlign.center),
                            subtitle: Text(
                              '@$username',
                              textAlign: TextAlign.center,
                            ),
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

  void _showBookmarks(BuildContext context) {
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
                    future: SupabaseFeedRepository(
                      Supabase.instance.client,
                    ).fetchBookmarkedPosts(),
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

  void _showBookmarkedPostImages(
    BuildContext context,
    SocialFeedItemModel post,
  ) {
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
                    future: SupabaseFeedRepository(
                      Supabase.instance.client,
                    ).fetchDiaryPanels(post.id),
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

  void _showMyProfile(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog.fullscreen(child: _MyProfileSheet(userId: userId));
      },
    );
  }
}

class _SocialTagFilterPanel extends StatelessWidget {
  const _SocialTagFilterPanel({
    required this.tags,
    required this.selectedTags,
    required this.onTagToggled,
  });

  final List<String> tags;
  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;

  @override
  Widget build(BuildContext context) {
    const groupedTags = <String, List<String>>{
      '\uADF8\uB9BC\uCCB4': <String>[
        'comics_ld',
        'anime_ld',
        'comics_sd',
        'simple_2d',
        'realistic_3d',
      ],
      '\uC7A5\uB974': <String>[
        'daily_comic',
        'serious',
        'healing_romance',
        'growth',
        'hard_day',
      ],
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        border: Border.all(color: const Color(0xFFD9E8FF)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.tune_rounded,
                  size: 17,
                  color: AppTheme.tacticalBlue,
                ),
                const Gap(5),
                const Text(
                  '\uD544\uD130',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                if (selectedTags.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      for (final tag in selectedTags.toList()) {
                        onTagToggled(tag);
                      }
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      '\uCD08\uAE30\uD654',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
              ],
            ),
            const Gap(8),
            ...groupedTags.entries.map((entry) {
              final visibleTags = entry.value
                  .where((String value) => tags.contains(value))
                  .toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FilterChipRail(
                  title: entry.key,
                  tags: visibleTags,
                  selectedTags: selectedTags,
                  onTagToggled: onTagToggled,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _FilterChipRail extends StatelessWidget {
  const _FilterChipRail({
    required this.title,
    required this.tags,
    required this.selectedTags,
    required this.onTagToggled,
  });

  final String title;
  final List<String> tags;
  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 46,
          child: Text(
            title,
            style: TextStyle(
              color: AppTheme.ink.withValues(alpha: 0.58),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tags.length,
              separatorBuilder: (_, _) => const Gap(6),
              itemBuilder: (BuildContext context, int index) {
                final tag = tags[index];
                final selected = selectedTags.contains(tag);
                return FilterChip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  showCheckmark: false,
                  avatar: Icon(
                    _socialTagIcon(tag),
                    size: 14,
                    color: selected ? Colors.white : AppTheme.tacticalBlue,
                  ),
                  label: Text(_filterChipLabel(tag)),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppTheme.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                  selected: selected,
                  selectedColor: AppTheme.tacticalBlue,
                  backgroundColor: const Color(0xFFF7FAFF),
                  side: BorderSide(
                    color: selected
                        ? AppTheme.tacticalBlue
                        : AppTheme.tacticalBlue.withValues(alpha: 0.16),
                  ),
                  onSelected: (_) => onTagToggled(tag),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
