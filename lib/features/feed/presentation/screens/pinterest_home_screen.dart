// ignore_for_file: unused_element, unused_element_parameter

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/config/supabase_runtime.dart';
import '../../../../core/enums/diary_art_style.dart';
import '../../../../core/enums/diary_genre.dart';
import '../../../../core/enums/persona_input_mode.dart';
import '../../../../core/enums/weather_type.dart';
import '../../../../core/enums/webtoon_format.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/reference_image_file_picker.dart';
import '../../../diary/data/models/diary_album_model.dart';
import '../../../diary/data/models/diary_model.dart';
import '../../../diary/data/models/diary_panel_model.dart';
import '../../../diary/data/models/diary_style_template_model.dart';
import '../../../diary/data/repositories/supabase_diary_repository.dart';
import '../../../persona/data/models/persona_model.dart';
import '../../../persona/data/repositories/supabase_persona_repository.dart';
import '../../data/models/diary_comment_model.dart';
import '../../data/models/social_feed_item_model.dart';
import '../../data/repositories/supabase_feed_repository.dart';

bool _isMobileLayout(BuildContext context) {
  return MediaQuery.sizeOf(context).width < 640;
}

int _postCutCount(SocialFeedItemModel post) {
  final count = post.imageUrls
      .where((String url) => url.trim().isNotEmpty)
      .length;
  if (count > 0) {
    return count;
  }
  return post.firstImageUrl?.trim().isNotEmpty == true ? 1 : 0;
}

List<DiaryPanelModel> _diaryPanelsReadingOrder(List<DiaryPanelModel> panels) {
  return panels
      .where(
        (DiaryPanelModel panel) => panel.imageUrl?.trim().isNotEmpty == true,
      )
      .toList()
    ..sort(
      (DiaryPanelModel a, DiaryPanelModel b) =>
          a.panelOrder.compareTo(b.panelOrder),
    );
}

List<String> _diaryImageUrlsReadingOrder(List<String> imageUrls) {
  return imageUrls.where((String url) => url.trim().isNotEmpty).toList();
}

List<String> _diaryPanelImageUrlsReadingOrder(List<DiaryPanelModel> panels) {
  return _diaryPanelsReadingOrder(panels)
      .map((DiaryPanelModel panel) => panel.imageUrl)
      .whereType<String>()
      .where((String url) => url.trim().isNotEmpty)
      .toList();
}

List<String> _socialFeedItemImageUrlsReadingOrder(SocialFeedItemModel post) {
  final urls = _diaryImageUrlsReadingOrder(post.imageUrls);
  if (urls.isNotEmpty) {
    return urls;
  }
  final first = post.firstImageUrl?.trim();
  return first == null || first.isEmpty ? const <String>[] : <String>[first];
}

class _AppUserSession {
  const _AppUserSession({required this.id, required this.displayName});

  final String id;
  final String displayName;
}

Future<_AppUserSession> _ensureSupabaseUserProfile() async {
  if (!SupabaseRuntime.isConfigured) {
    throw StateError(
      '\u0053\u0075\u0070\u0061\u0062\u0061\u0073\u0065 \uC124\uC815\uC774 \uD544\uC694\uD569\uB2C8\uB2E4.',
    );
  }

  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) {
    throw StateError(
      '\uB85C\uADF8\uC778\uC774 \uD544\uC694\uD569\uB2C8\uB2E4.',
    );
  }

  final email = user.email ?? user.id;
  final displayName =
      user.userMetadata?['display_name']?.toString().trim().isNotEmpty == true
      ? user.userMetadata!['display_name'].toString().trim()
      : email.split('@').first;

  await client.from('profiles').upsert(<String, dynamic>{
    'id': user.id,
    'username': _safeProfileUsername(email, user.id),
    'display_name': displayName,
    'avatar_url': user.userMetadata?['avatar_url']?.toString(),
    'is_public': true,
  });

  return _AppUserSession(id: user.id, displayName: displayName);
}

String _safeProfileUsername(String email, String userId) {
  final raw = email.split('@').first;
  final normalized = raw
      .replaceAll(RegExp('[^a-zA-Z0-9_]'), '_')
      .padRight(3, '_');
  final suffix = userId.replaceAll('-', '').substring(0, 6);
  final base = normalized.length > 16
      ? normalized.substring(0, 16)
      : normalized;
  return '${base}_$suffix';
}

String _friendlyGenerationError(Object error) {
  final message = error.toString();
  final lower = message.toLowerCase();
  if (lower.contains('gemini') &&
      (lower.contains('quota') ||
          lower.contains('billing') ||
          lower.contains('payment') ||
          lower.contains('429'))) {
    return 'Gemini \uC774\uBBF8\uC9C0 \uC0DD\uC131 \uD55C\uB3C4/\uACB0\uC81C \uC624\uB958\uC785\uB2C8\uB2E4. Google Cloud \uD504\uB85C\uC81D\uD2B8 \uACB0\uC81C \uC0C1\uD0DC\uB97C \uD655\uC778\uD558\uACE0 \uC7A0\uC2DC \uD6C4 \uB2E4\uC2DC \uC2DC\uB3C4\uD574 \uC8FC\uC138\uC694.';
  }
  if (lower.contains('insufficient_quota') ||
      lower.contains('exceeded your current quota')) {
    return 'AI \uC0AC\uC6A9 \uD55C\uB3C4 \uB610\uB294 \uACB0\uC81C \uBC18\uC601 \uBB38\uC81C\uC785\uB2C8\uB2E4. API \uD0A4\uC758 \uD504\uB85C\uC81D\uD2B8 \uACB0\uC81C/\uCFFC\uD130\uB97C \uD655\uC778\uD574 \uC8FC\uC138\uC694.';
  }
  if (lower.contains('billing') || lower.contains('payment required')) {
    return 'AI \uACB0\uC81C \uC124\uC815\uC744 \uD655\uC778\uD574 \uC8FC\uC138\uC694. Gemini API \uACB0\uC81C\uAC00 \uD604\uC7AC \uD504\uB85C\uC81D\uD2B8\uC5D0 \uC5F0\uACB0\uB418\uC5B4 \uC788\uC5B4\uC57C \uD569\uB2C8\uB2E4.';
  }
  if (lower.contains('stability') &&
      (lower.contains('credits') ||
          lower.contains('balance') ||
          lower.contains('payment'))) {
    return 'Stability AI \uD06C\uB808\uB527\uC774 \uBD80\uC871\uD558\uAC70\uB098 \uACB0\uC81C \uBC18\uC601 \uC804\uC785\uB2C8\uB2E4. \uD06C\uB808\uB527 \uCDA9\uC804 \uD6C4 \uB2E4\uC2DC \uC2DC\uB3C4\uD574 \uC8FC\uC138\uC694.';
  }
  if (lower.contains('openai_api_key') ||
      lower.contains('stability_api_key') ||
      lower.contains('missing openai') ||
      lower.contains('missing stability')) {
    return 'Supabase Edge Function Secret\uC758 GEMINI_API_KEY\uC640 IMAGE_PROVIDER \uC124\uC815\uC744 \uD655\uC778\uD574 \uC8FC\uC138\uC694.';
  }
  if (lower.contains('invalid_api_key') ||
      lower.contains('invalid api key') ||
      lower.contains('incorrect api key')) {
    return 'AI API Key\uAC00 \uC62C\uBC14\uB974\uC9C0 \uC54A\uC2B5\uB2C8\uB2E4. Supabase Edge Function Secret\uC758 \uD0A4\uB97C \uD655\uC778\uD574 \uC8FC\uC138\uC694.';
  }
  if (lower.contains('failed to fetch')) {
    return 'Edge Function \uD638\uCD9C\uC5D0 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4. \uB124\uD2B8\uC6CC\uD06C, Supabase \uD568\uC218 \uBC30\uD3EC \uC0C1\uD0DC, CORS\uB97C \uD655\uC778\uD574 \uC8FC\uC138\uC694.';
  }
  if (message.contains('PGRST205') ||
      message.contains("Could not find the table 'public.profiles'")) {
    return 'Supabase REST schema cache\uAC00 profiles \uD14C\uC774\uBE14\uC744 \uC544\uC9C1 \uBABB \uBCF4\uACE0 \uC788\uC2B5\uB2C8\uB2E4. '
        'SQL\uC744 \uC2E4\uD589\uD55C Supabase \uD504\uB85C\uC81D\uD2B8\uAC00 \\uC778\uC9C0 \uD655\uC778\uD558\uACE0, '
        'diagnose_current_project.sql\uC744 \uC2E4\uD589\uD574 \uC8FC\uC138\uC694.';
  }
  if (message.contains('JWT') || message.contains('row-level security')) {
    return 'Supabase RLS \uC624\uB958\uC785\uB2C8\uB2E4. \uB85C\uADF8\uC778\uD55C \uACC4\uC815\uC758 \uB370\uC774\uD130\uB9CC \uC800\uC7A5\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4. \uC6D0\uBB38: ';
  }
  if (message.contains('Invalid API key') || message.contains('code: 401')) {
    return 'Supabase URL\uACFC anon/publishable API key\uAC00 \uC11C\uB85C \uB2E4\uB978 \uD504\uB85C\uC81D\uD2B8\uC785\uB2C8\uB2E4. '
        '.env\uC758 SUPABASE_ANON_KEY\uB97C \uD604\uC7AC \uD504\uB85C\uC81D\uD2B8\uC758 anon key\uB85C \uAD50\uCCB4\uD574 \uC8FC\uC138\uC694.';
  }
  return message;
}

class PinterestHomeScreen extends StatefulWidget {
  const PinterestHomeScreen({super.key});

  @override
  State<PinterestHomeScreen> createState() => _PinterestHomeScreenState();
}

class _PinterestHomeScreenState extends State<PinterestHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedTags = <String>{};
  bool _showTagFilter = false;
  bool _followingOnly = false;
  int _tabIndex = 0;
  int _feedRefreshTick = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _SocialPage(
        refreshTick: _feedRefreshTick,
        searchController: _searchController,
        selectedTags: _selectedTags,
        showTagFilter: _showTagFilter,
        followingOnly: _followingOnly,
        onSearchChanged: (_) => setState(() {}),
        onTagToggled: _toggleTag,
        onFilterPressed: () {
          setState(() => _showTagFilter = !_showTagFilter);
        },
        onFollowingOnlyChanged: (bool value) {
          setState(() => _followingOnly = value);
        },
        onFeedChanged: () => setState(() => _feedRefreshTick++),
      ),
      const _TemplatePage(),
      _DiaryPage(
        onSharedDiaryCreated: () {
          setState(() {
            _feedRefreshTick++;
            _tabIndex = 0;
          });
        },
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFF),
      body: Stack(
        children: <Widget>[
          const _PastelBackground(),
          SafeArea(
            child: DefaultTextStyle.merge(
              textAlign: TextAlign.center,
              child: pages[_tabIndex],
            ),
          ),
          if (_tabIndex == 0) SafeArea(child: const _ProfileMenuButton()),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.94),
              border: Border(
                top: BorderSide(color: AppTheme.ink.withValues(alpha: 0.10)),
              ),
            ),
            child: SafeArea(
              top: false,
              minimum: EdgeInsets.only(
                bottom: _isMobileLayout(context) ? 6 : 0,
              ),
              child: NavigationBar(
                height: _isMobileLayout(context) ? 62 : 68,
                indicatorColor: AppTheme.tacticalBlue.withValues(alpha: 0.18),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return TextStyle(
                    color: selected
                        ? AppTheme.tacticalBlue
                        : AppTheme.ink.withValues(alpha: 0.62),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                  );
                }),
                selectedIndex: _tabIndex,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                onDestinationSelected: (int index) {
                  setState(() => _tabIndex = index);
                },
                destinations: const <NavigationDestination>[
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_rounded),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: '\uD53C\uB4DC',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.face_retouching_natural_rounded),
                    selectedIcon: Icon(Icons.face_retouching_natural_rounded),
                    label: '\uCE90\uB9AD\uD130',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.auto_stories_rounded),
                    selectedIcon: Icon(Icons.auto_stories_rounded),
                    label: '\uC77C\uAE30',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }
}

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

class _DiaryPage extends StatefulWidget {
  const _DiaryPage({required this.onSharedDiaryCreated});

  final VoidCallback onSharedDiaryCreated;

  @override
  State<_DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<_DiaryPage> {
  static const List<String> _defaultAlbumTitles = <String>[
    '\uBE44\uACF5\uAC1C',
    '\uC77C\uC0C1',
    '\uC18C\uC911\uD55C \uC21C\uAC04',
  ];

  static const List<DiaryStyleTemplateModel>
  _fallbackStyleTemplates = <DiaryStyleTemplateModel>[
    DiaryStyleTemplateModel(
      id: 'semi_realistic_daily',
      name: '\uADF9\uD654\uD615 \uC77C\uAE30',
      description:
          '\uD45C\uC815\uACFC \uC7A5\uBA74\uC744 \uC12C\uC138\uD558\uAC8C \uC0B4\uB9AC\uB294 LD',
      artStyle: DiaryArtStyle.comicsLd,
      artSubStyle: '\uADF9\uD654\uD615 (Semi-Realistic)',
      prompt:
          'Semi-realistic Korean diary webtoon style, believable stylized anatomy, firm contour lines, expressive face planes, clear hands, cinematic daily lighting, dramatic but readable single vertical card panel.',
      sortOrder: 10,
    ),
    DiaryStyleTemplateModel(
      id: 'graphic_anime_daily',
      name: '\uC560\uB2C8\uD615 \uADF8\uB798\uD53D',
      description:
          '\uAE54\uB054\uD55C \uC120\uACFC \uC140 \uC250\uC774\uB529 \uC911\uC2EC',
      artStyle: DiaryArtStyle.animeLd,
      artSubStyle: '\uC560\uB2C8\uD615 (Graphic)',
      prompt:
          'Graphic anime diary webtoon style, clean stylized linework, crisp cel shading, expressive animated eyes, smooth hair clumps, controlled color blocks, clear emotional acting.',
      sortOrder: 20,
    ),
    DiaryStyleTemplateModel(
      id: 'casual_cartoon_daily',
      name: '\uCE90\uC8FC\uC5BC \uB9CC\uD654',
      description:
          '\uC6C3\uAE34 \uD45C\uC815\uACFC \uACFC\uC7A5\uB41C \uC561\uC158\uC5D0 \uC801\uD569',
      artStyle: DiaryArtStyle.comicsSd,
      artSubStyle: '\uCE90\uC8FC\uC5BC \uB9CC\uD654\uD615 (Cartoon)',
      prompt:
          'Casual cartoon diary style, simplified cute proportions, bouncy shapes, exaggerated comedy expressions, bright flat color blocks, sweat drops, motion marks, playful daily gag timing.',
      sortOrder: 30,
    ),
    DiaryStyleTemplateModel(
      id: 'simple_character_daily',
      name: '\uC2EC\uD50C \uCE90\uB9AD\uD130',
      description:
          '\uC544\uC774\uCF58\uCC98\uB7FC \uC77D\uD788\uB294 \uB2E8\uC21C\uD55C SD',
      artStyle: DiaryArtStyle.simple2d,
      artSubStyle: '\uCE90\uB9AD\uD130\uD615 (Simple Character)',
      prompt:
          'Simple character diary style, mascot-like 2D silhouette, minimal facial features, rounded body, clean outlines, flat pastel fills, readable props, calm negative space.',
      sortOrder: 40,
    ),
    DiaryStyleTemplateModel(
      id: 'soft_3d_daily',
      name: '\uC18C\uD504\uD2B8 3D',
      description:
          '\uC785\uCCB4\uAC10\uACFC \uBE5B\uC774 \uBCF4\uC774\uB294 3D',
      artStyle: DiaryArtStyle.realistic3d,
      artSubStyle: '\uC785\uCCB4 \uB80C\uB354\uB9C1 (3D Style)',
      prompt:
          'Stylized 3D animated diary scene, volumetric rounded character, sculpted hair, soft materials, ambient occlusion, cast shadows, cozy miniature daily environment, no flat 2D line art.',
      sortOrder: 50,
    ),
  ];

  final PageController _controller = PageController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _albumController = TextEditingController();
  final Map<String, String> _albumIdsByTitle = <String, String>{};
  final Map<String, String> _templateIdsByName = <String, String>{};
  final List<PersonaModel> _diaryPersonas = <PersonaModel>[];
  final List<DiaryStyleTemplateModel> _styleTemplates =
      <DiaryStyleTemplateModel>[];
  final Map<String, int> _albumDiaryCounts = <String, int>{};
  final Map<String, List<DiaryModel>> _albumDiariesByTitle =
      <String, List<DiaryModel>>{};
  final List<DiaryPanelModel> _generatedPanels = <DiaryPanelModel>[];
  final List<String> _generatedImageUrls = <String>[];

  int _page = 0;
  String _template = '';
  String _selectedPersonaId = '';
  String _album = '\uC77C\uC0C1 \uAE30\uB85D';
  String _weather = 'sunny';
  String _saveMode = 'archive';
  String _artStyle = '\uC0AC\uC2E4\uC801 \uC2A4\uD0C0\uC77C (LD)';
  String _artSubStyle = '\uADF9\uD654\uD615 (Semi-Realistic)';
  String _styleTemplateId = '';
  String _genre = '\uC720\uCF8C\uD558\uACE0 \uC6C3\uAE34 \uB0A0';
  String _genreSubtype = '';
  int _targetCutCount = 0;
  bool _isSaving = false;
  bool _isLoadingArchive = false;
  bool _isLoadingTemplates = false;
  int _finalMobileFlowKey = 0;
  String? _selectedArchiveAlbum;

  final List<String> _albums = <String>[..._defaultAlbumTitles];
  final List<String> _templates = <String>[];

  @override
  void initState() {
    super.initState();
    unawaited(_loadAlbums());
    unawaited(_loadDiaryTemplates());
    unawaited(_loadStyleTemplates());
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 4 : 12,
        mobile ? 4 : 10,
        mobile ? 4 : 12,
        mobile ? 8 : 14,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: mobile ? double.infinity : 1240,
          ),
          child: _DiaryFigmaFrame(
            title: _title,
            pageIndex: _page,
            bookChrome: true,
            onClose: () => _go(0),
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (int value) => setState(() => _page = value),
              children: <Widget>[
                _DiaryOpenPage(
                  onArchive: () {
                    unawaited(_loadAlbums());
                    _go(2);
                  },
                  onStart: () {
                    setState(() => _finalMobileFlowKey++);
                    _go(1);
                  },
                ),
                _DiaryFinalScreen(
                  key: ValueKey<int>(_finalMobileFlowKey),
                  templates: _templates,
                  selectedPersonaId: _selectedPersonaId,
                  personas: _diaryPersonas,
                  titleController: _titleController,
                  bodyController: _bodyController,
                  tagController: _tagController,
                  titleText: _titleController.text,
                  weather: _weather,
                  artStyle: _artStyle,
                  artSubStyle: _artSubStyle,
                  selectedStyleTemplateId: _styleTemplateId,
                  styleTemplates: _styleTemplates,
                  genre: _genre,
                  genreSubtype: _genreSubtype,
                  targetCutCount: _targetCutCount,
                  artSubStyleOptions: _artSubStyleCards
                      .map((_FigmaCardData item) => item.label)
                      .toList(),
                  genreSubtypeOptions: _genreSubtypeCards
                      .map((_FigmaCardData item) => item.label)
                      .toList(),
                  keywordTags: _keywordTags(),
                  isSaving: _isSaving,
                  onArtStyleChanged: _selectArtStyle,
                  onArtSubStyleChanged: (String value) {
                    setState(() => _artSubStyle = value);
                  },
                  onStyleTemplateChanged: _selectStyleTemplate,
                  onGenreChanged: _selectGenre,
                  onGenreSubtypeChanged: (String value) {
                    setState(() => _genreSubtype = value);
                  },
                  onTargetCutCountChanged: (int value) {
                    setState(() => _targetCutCount = value);
                  },
                  onTemplateChanged: (String value) {
                    setState(() {
                      _selectedPersonaId = value;
                      PersonaModel? persona;
                      for (final item in _diaryPersonas) {
                        if (item.id == value) {
                          persona = item;
                          break;
                        }
                      }
                      if (persona != null) {
                        _template = persona.name;
                      }
                    });
                  },
                  onDraftChanged: () => setState(() {}),
                  onWeatherChanged: (String value) {
                    setState(() => _weather = value);
                  },
                  onGenerate: () => unawaited(_showDiaryPublishSettings()),
                  onBack: () => _go(0),
                  isLoadingTemplates: _isLoadingTemplates,
                  previewImageUrls: _generatedImageUrls,
                ),
                _ArchiveScreen(
                  albums: _albums,
                  albumDiaryCounts: _albumDiaryCounts,
                  albumDiariesByTitle: _albumDiariesByTitle,
                  selectedAlbum: _selectedArchiveAlbum,
                  isLoading: _isLoadingArchive,
                  controller: _albumController,
                  onBack: () => _go(0),
                  onCreateAlbum: _createAlbum,
                  onAlbumSelected: (String title) {
                    setState(() => _selectedArchiveAlbum = title);
                  },
                  onDeleteAlbum: _deleteAlbum,
                  onOpenDiary: _showArchivedDiary,
                  onRemoveDiary: _removeDiaryFromAlbum,
                  onDeleteDiary: _deleteArchivedDiary,
                  onRefresh: _loadAlbums,
                ),
                _GeneratedDiarySlideScreen(
                  panels: _generatedPanels,
                  imageUrls: _generatedImageUrls,
                  onBack: () => _go(1),
                  onRetryPanel: _retryGeneratedPanel,
                  onDone: () {
                    if (_saveMode == 'share') {
                      widget.onSharedDiaryCreated();
                      _go(0);
                    } else {
                      _go(2);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _title {
    return switch (_page) {
      0 => '\uC77C\uAE30',
      1 => '\uC77C\uAE30(\uC124\uC815)',
      2 => '\uC544\uCE74\uC774\uBE0C',
      3 => '\uC77C\uAE30(\uC0DD\uC131 \uACB0\uACFC)',
      _ => '\uC77C\uAE30',
    };
  }

  Future<void> _loadAlbums() async {
    if (!SupabaseRuntime.isConfigured) {
      return;
    }

    setState(() => _isLoadingArchive = true);

    try {
      final user = await _ensureSupabaseUserProfile();
      final repository = SupabaseDiaryRepository(Supabase.instance.client);
      var albums = await repository.fetchMyAlbums(user.id);
      if (albums.isEmpty) {
        for (final title in _defaultAlbumTitles) {
          await repository.createAlbum(userId: user.id, title: title);
        }
        albums = await repository.fetchMyAlbums(user.id);
      }
      if (!mounted) {
        return;
      }
      if (albums.isEmpty) {
        if (mounted) {
          setState(() {
            _albums
              ..clear()
              ..addAll(_defaultAlbumTitles);
            _albumIdsByTitle.clear();
            _albumDiaryCounts.clear();
            _albumDiariesByTitle.clear();
            _album = _albums.first;
            _selectedArchiveAlbum ??= _albums.first;
            _isLoadingArchive = false;
          });
        }
        return;
      }

      final albumDiaries = <String, List<DiaryModel>>{};
      for (final album in albums) {
        albumDiaries[album.title] = await repository.fetchAlbumDiaries(
          album.id,
        );
      }

      setState(() {
        _albums
          ..clear()
          ..addAll(albums.map((DiaryAlbumModel album) => album.title));
        _albumIdsByTitle
          ..clear()
          ..addEntries(
            albums.map(
              (DiaryAlbumModel album) => MapEntry(album.title, album.id),
            ),
          );
        _albumDiaryCounts
          ..clear()
          ..addEntries(
            albums.map((DiaryAlbumModel album) {
              final diaries = albumDiaries[album.title] ?? const <DiaryModel>[];
              return MapEntry(album.title, diaries.length);
            }),
          );
        _albumDiariesByTitle
          ..clear()
          ..addAll(albumDiaries);
        if (!_albums.contains(_album)) {
          _album = _albums.first;
        }
        if (_selectedArchiveAlbum == null ||
            !_albums.contains(_selectedArchiveAlbum)) {
          _selectedArchiveAlbum = _albums.first;
        }
        _isLoadingArchive = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingArchive = false);
      }
    }
  }

  Future<void> _loadDiaryTemplates() async {
    if (!SupabaseRuntime.isConfigured) {
      return;
    }

    setState(() => _isLoadingTemplates = true);

    try {
      final user = await _ensureSupabaseUserProfile();
      final repository = SupabasePersonaRepository(Supabase.instance.client);
      final visibleTemplates = await repository.fetchVisibleTemplates(user.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _diaryPersonas
          ..clear()
          ..addAll(visibleTemplates);
        _templates
          ..clear()
          ..addAll(
            visibleTemplates
                .map((PersonaModel template) => template.name)
                .toSet(),
          );
        _templateIdsByName
          ..clear()
          ..addEntries(
            visibleTemplates.map(
              (PersonaModel template) => MapEntry(template.name, template.id),
            ),
          );
        if (_diaryPersonas.isEmpty) {
          _template = '';
          _selectedPersonaId = '';
        } else if (!_diaryPersonas.any(
          (PersonaModel item) => item.id == _selectedPersonaId,
        )) {
          final firstMine = _diaryPersonas
              .where((PersonaModel item) => item.userId == user.id)
              .toList();
          final selected = firstMine.isNotEmpty
              ? firstMine.first
              : _diaryPersonas.first;
          _selectedPersonaId = selected.id;
          _template = selected.name;
        }
        _isLoadingTemplates = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _diaryPersonas.clear();
          _templates.clear();
          _templateIdsByName.clear();
          _template = '';
          _selectedPersonaId = '';
          _isLoadingTemplates = false;
        });
      }
    }
  }

  Future<void> _loadStyleTemplates() async {
    if (!SupabaseRuntime.isConfigured) {
      setState(() {
        _styleTemplates
          ..clear()
          ..addAll(_fallbackStyleTemplates);
        _applyStyleTemplate(_styleTemplates.first);
      });
      return;
    }

    try {
      final templates = await SupabaseDiaryRepository(
        Supabase.instance.client,
      ).fetchStyleTemplates();
      if (!mounted) {
        return;
      }
      setState(() {
        _styleTemplates
          ..clear()
          ..addAll(templates.isEmpty ? _fallbackStyleTemplates : templates);
        _applyStyleTemplate(_styleTemplates.first);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _styleTemplates
            ..clear()
            ..addAll(_fallbackStyleTemplates);
          _applyStyleTemplate(_styleTemplates.first);
        });
      }
    }
  }

  void _createAlbum(String title) {
    unawaited(_createAlbumAsync(title));
  }

  Future<void> _showArchivedDiary(DiaryModel diary) async {
    final panels = SupabaseRuntime.isConfigured
        ? await SupabaseDiaryRepository(
            Supabase.instance.client,
          ).fetchDiaryPanels(diary.id)
        : const <DiaryPanelModel>[];
    final imageUrls = panels.isEmpty
        ? _diaryImageUrlsReadingOrder(diary.imageUrls)
        : _diaryPanelImageUrlsReadingOrder(panels);
    if (!mounted) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.90,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              children: <Widget>[
                Text(
                  diary.title?.trim().isNotEmpty == true
                      ? diary.title!.trim()
                      : '\uC81C\uBAA9 \uC5C6\uB294 \uC77C\uAE30',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _ImageUrlSlideDeck(
                    imageUrls: imageUrls,
                    panels: panels,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeDiaryFromAlbum(
    String albumTitle,
    DiaryModel diary,
  ) async {
    final albumId = _albumIdsByTitle[albumTitle];
    if (albumId == null) {
      return;
    }
    await SupabaseDiaryRepository(
      Supabase.instance.client,
    ).removeDiaryFromAlbum(albumId: albumId, diaryId: diary.id);
    await _loadAlbums();
  }

  Future<void> _deleteArchivedDiary(String albumTitle, DiaryModel diary) async {
    await SupabaseDiaryRepository(
      Supabase.instance.client,
    ).deleteDiary(diary.id);
    await _loadAlbums();
    widget.onSharedDiaryCreated();
  }

  Future<void> _deleteAlbum(String albumTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('\uC568\uBC94 \uC0AD\uC81C'),
          content: Text(
            '\u2018$albumTitle\u2019 \uC568\uBC94\uC744 \uC0AD\uC81C\uD560\uAE4C\uC694?\n\uC568\uBC94\uB9CC \uC0AD\uC81C\uB418\uACE0 \uC77C\uAE30 \uC790\uCCB4\uB294 \uB0A8\uC544\uC788\uC2B5\uB2C8\uB2E4.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('\uCDE8\uC18C'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('\uC0AD\uC81C'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final albumId = _albumIdsByTitle[albumTitle];
    if (SupabaseRuntime.isConfigured && albumId != null) {
      try {
        await SupabaseDiaryRepository(
          Supabase.instance.client,
        ).deleteAlbum(albumId);
      } catch (error) {
        if (mounted) {
          _showMessage(
            '\uC568\uBC94 \uC0AD\uC81C \uC2E4\uD328: ${_friendlyGenerationError(error)}',
          );
        }
        return;
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _albums.remove(albumTitle);
      _albumIdsByTitle.remove(albumTitle);
      _albumDiaryCounts.remove(albumTitle);
      _albumDiariesByTitle.remove(albumTitle);
      if (_selectedArchiveAlbum == albumTitle) {
        _selectedArchiveAlbum = _albums.isEmpty ? null : _albums.first;
      }
      if (_album == albumTitle) {
        _album = _albums.isEmpty ? '' : _albums.first;
      }
    });
    _showMessage('\uC568\uBC94\uC744 \uC0AD\uC81C\uD588\uC2B5\uB2C8\uB2E4.');
  }

  Future<String?> _createAlbumAsync(String title) async {
    final normalized = title.trim();
    if (normalized.isEmpty) {
      return _albumIdsByTitle[normalized];
    }

    if (_albums.contains(normalized)) {
      setState(() => _album = normalized);
      return _albumIdsByTitle[normalized];
    }

    String? albumId;
    if (SupabaseRuntime.isConfigured) {
      try {
        final user = await _ensureSupabaseUserProfile();
        final repository = SupabaseDiaryRepository(Supabase.instance.client);
        final album = await repository.createAlbum(
          userId: user.id,
          title: normalized,
        );
        albumId = album.id;
      } catch (error) {
        if (mounted) {
          _showMessage(
            '\uC568\uBC94\uC740 \uD654\uBA74\uC5D0\uB9CC \uCD94\uAC00\uD588\uC2B5\uB2C8\uB2E4. DB \uC800\uC7A5 \uC2E4\uD328: ${_friendlyGenerationError(error)}',
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _albums.add(normalized);
        if (albumId != null) {
          _albumIdsByTitle[normalized] = albumId;
        }
        _albumDiaryCounts.putIfAbsent(normalized, () => 0);
        _albumDiariesByTitle.putIfAbsent(
          normalized,
          () => const <DiaryModel>[],
        );
        _album = normalized;
        _selectedArchiveAlbum = normalized;
        _albumController.clear();
      });
    }

    return albumId;
  }

  Future<void> _showDiaryPublishSettings() async {
    var draftSaveMode = _saveMode;
    var draftAlbum = _album;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('\uCD5C\uC885 \uBC1C\uD589 \uC124\uC815'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _SaveModeSelector(
                      selected: draftSaveMode,
                      onChanged: (String value) {
                        setDialogState(() => draftSaveMode = value);
                      },
                    ),
                    if (draftSaveMode == 'archive') ...<Widget>[
                      const Gap(16),
                      _FigmaDropdown(
                        label: '\uC18C\uC7A5\uD560 \uC568\uBC94',
                        value: draftAlbum,
                        values: _albums,
                        onChanged: (String value) {
                          setDialogState(() => draftAlbum = value);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('\uCDE8\uC18C'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.publish_rounded),
                  label: const Text(
                    '\uC774 \uC124\uC815\uC73C\uB85C \uBC1C\uD589',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _saveMode = draftSaveMode;
      _album = draftAlbum;
    });
    await _saveDiary();
  }

  Future<void> _saveDiary() async {
    if (_bodyController.text.trim().isEmpty) {
      _showMessage(
        '\uC77C\uAE30 \uB0B4\uC6A9\uC744 \uBA3C\uC800 \uC791\uC131\uD574 \uC8FC\uC138\uC694.',
      );
      return;
    }

    setState(() => _isSaving = true);
    setState(() {
      _generatedPanels.clear();
      _generatedImageUrls.clear();
    });

    try {
      final user = await _ensureSupabaseUserProfile();
      var personaId = _selectedPersonaId.isNotEmpty
          ? _selectedPersonaId
          : _templateIdsByName[_template];
      if (personaId == null) {
        await _loadDiaryTemplates();
        personaId = _selectedPersonaId.isNotEmpty
            ? _selectedPersonaId
            : _templateIdsByName[_template];
      }
      if (personaId == null) {
        _showMessage(
          '\uC120\uD0DD\uD55C \uCE90\uB9AD\uD130\uB97C DB\uC5D0\uC11C \uCC3E\uC9C0 \uBABB\uD588\uC2B5\uB2C8\uB2E4. \uCE90\uB9AD\uD130 \uD0ED\uC744 \uD55C \uBC88 \uC5F4\uACE0 \uB2E4\uC2DC \uC2DC\uB3C4\uD574 \uC8FC\uC138\uC694.',
        );
        return;
      }
      final repository = SupabaseDiaryRepository(Supabase.instance.client);
      final diary = await repository.createDiary(
        userId: user.id,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        content: _bodyController.text.trim(),
        diaryAt: DateTime.now(),
        weather: WeatherType.fromValue(_weather),
        webtoonFormat: _selectedWebtoonFormat(),
        artStyle: _selectedArtStyle(),
        artSubStyle: _artSubStyle,
        styleTemplateId: _selectedStyleTemplate?.id,
        styleTemplatePrompt: _selectedStyleTemplate?.prompt,
        genre: _selectedGenre(),
        genreSubtype: _selectedGenreSubtype().isEmpty
            ? null
            : _selectedGenreSubtype(),
        keywordTags: _generationKeywordTags(),
        personaId: personaId,
        isPublic: _saveMode == 'share',
        visibility: _visibilityFromSaveMode(_saveMode),
      );
      var panels = await repository.fetchDiaryPanels(diary.id);
      panels = await _drawFinalSpeechBubbles(
        repository: repository,
        userId: user.id,
        diaryId: diary.id,
        panels: panels,
      );
      final finalImageUrls = _diaryPanelImageUrlsReadingOrder(panels);
      if (finalImageUrls.isNotEmpty) {
        await repository.updateDiaryImageUrls(
          diaryId: diary.id,
          imageUrls: finalImageUrls,
        );
      }

      if (_saveMode == 'archive') {
        var albumId = _albumIdsByTitle[_album];
        albumId ??= await _createAlbumAsync(_album);
        if (albumId != null) {
          await repository.addDiaryToAlbumAfterEnsuringPublic(
            userId: user.id,
            albumId: albumId,
            diaryId: diary.id,
          );
          _albumDiaryCounts[_album] = (_albumDiaryCounts[_album] ?? 0) + 1;
          _albumDiariesByTitle[_album] = <DiaryModel>[
            diary,
            ...(_albumDiariesByTitle[_album] ?? const <DiaryModel>[]),
          ];
          _selectedArchiveAlbum = _album;
          unawaited(_loadAlbums());
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _generatedPanels
          ..clear()
          ..addAll(panels);
        _generatedImageUrls
          ..clear()
          ..addAll(
            finalImageUrls.isNotEmpty
                ? finalImageUrls
                : _diaryImageUrlsReadingOrder(
                    panels
                        .map((DiaryPanelModel panel) => panel.imageUrl)
                        .whereType<String>()
                        .toList(),
                  ),
          );
      });

      _showMessage(
        _saveMode == 'share'
            ? '\uACF5\uC720 \uC77C\uAE30\uB85C \uC800\uC7A5\uB410\uC2B5\uB2C8\uB2E4. \uC18C\uC15C \uD53C\uB4DC\uC5D0 \uD45C\uC2DC\uB429\uB2C8\uB2E4.'
            : _saveMode == 'followers'
            ? '\uD314\uB85C\uC6CC \uACF5\uAC1C \uC77C\uAE30\uB85C \uC800\uC7A5\uB410\uC2B5\uB2C8\uB2E4.'
            : '\uC77C\uAE30\uAC00 \uC568\uBC94\uC5D0 \uC18C\uC7A5\uB410\uC2B5\uB2C8\uB2E4.',
      );
      if (_saveMode == 'share' || _saveMode == 'followers') {
        widget.onSharedDiaryCreated();
      }
      _go(3);
    } catch (error) {
      if (mounted) {
        _showMessage(
          '\uC800\uC7A5 \uC2E4\uD328: ${_friendlyGenerationError(error)}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<List<DiaryPanelModel>> _drawFinalSpeechBubbles({
    required SupabaseDiaryRepository repository,
    required String userId,
    required String diaryId,
    required List<DiaryPanelModel> panels,
    Set<String>? onlyPanelIds,
  }) async {
    final renderedPanels = <DiaryPanelModel>[];
    for (final panel in panels) {
      if (onlyPanelIds != null && !onlyPanelIds.contains(panel.id)) {
        renderedPanels.add(panel);
        continue;
      }
      final imageUrl = panel.imageUrl;
      final dialogue = panel.dialogue?.trim();
      if (imageUrl == null ||
          imageUrl.isEmpty ||
          dialogue == null ||
          dialogue.isEmpty) {
        renderedPanels.add(panel);
        continue;
      }

      try {
        final sourceBytes = await _downloadDiaryAssetBytes(imageUrl);
        final textLayerBytes = await _drawWebtoonBubbleIntoImage(
          sourceBytes: sourceBytes,
          dialogue: dialogue,
          prompt: panel.prompt,
        );
        final path =
            '$userId/diaries/$diaryId/panel-${panel.panelOrder}-bubble-${DateTime.now().millisecondsSinceEpoch}.png';
        await Supabase.instance.client.storage
            .from('diary-assets')
            .uploadBinary(
              path,
              textLayerBytes,
              fileOptions: const FileOptions(
                contentType: 'image/png',
                upsert: true,
              ),
            );
        final publicUrl = Supabase.instance.client.storage
            .from('diary-assets')
            .getPublicUrl(path);
        renderedPanels.add(
          await repository.updateDiaryPanelImageUrl(
            panelId: panel.id,
            imageUrl: publicUrl,
          ),
        );
      } catch (_) {
        renderedPanels.add(panel);
      }
    }
    return renderedPanels;
  }

  Future<void> _retryGeneratedPanel(
    DiaryPanelModel panel,
    String retryFeedback,
  ) async {
    setState(() => _isSaving = true);
    try {
      final user = await _ensureSupabaseUserProfile();
      final repository = SupabaseDiaryRepository(Supabase.instance.client);
      await repository.retryDiaryPanel(
        diaryId: panel.diaryId,
        panelId: panel.id,
        retryFeedback: retryFeedback,
      );
      var panels = await repository.fetchDiaryPanels(panel.diaryId);
      panels = await _drawFinalSpeechBubbles(
        repository: repository,
        userId: user.id,
        diaryId: panel.diaryId,
        panels: panels,
        onlyPanelIds: <String>{panel.id},
      );
      final finalImageUrls = _diaryPanelImageUrlsReadingOrder(panels);
      if (finalImageUrls.isNotEmpty) {
        await repository.updateDiaryImageUrls(
          diaryId: panel.diaryId,
          imageUrls: finalImageUrls,
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _generatedPanels
          ..clear()
          ..addAll(panels);
        _generatedImageUrls
          ..clear()
          ..addAll(finalImageUrls);
      });
      _showMessage(
        '\uC774\uBBF8\uC9C0 \uC0DD\uC131\uC744 \uC694\uCCAD\uD588\uC2B5\uB2C8\uB2E4.',
      );
    } catch (error) {
      if (mounted) {
        _showMessage('\uC774\uBBF8\uC9C0 \uC0DD\uC131 \uC2E4\uD328: ');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<Uint8List> _downloadDiaryAssetBytes(String imageUrl) async {
    final storagePath = _storagePathFromDiaryAssetPublicUrl(imageUrl);
    if (storagePath != null) {
      return Supabase.instance.client.storage
          .from('diary-assets')
          .download(storagePath);
    }

    final data = await NetworkAssetBundle(Uri.parse(imageUrl)).load(imageUrl);
    return data.buffer.asUint8List();
  }

  Future<Uint8List> _drawWebtoonBubbleIntoImage({
    required Uint8List sourceBytes,
    required String dialogue,
    required String? prompt,
  }) async {
    final codec = await instantiateImageCodec(sourceBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(image, Offset.zero, Paint());

    final text = _normalizeDialogueForBubble(dialogue);
    final initialTextRect = _dialogueTextRect(
      width: width,
      height: height,
      prompt: prompt,
      text: text,
    );
    final bubbleRect = initialTextRect
        .inflate(width * 0.055)
        .intersect(
          Rect.fromLTWH(
            width * 0.02,
            height * 0.02,
            width * 0.96,
            height * 0.94,
          ),
        );
    final textRect = _insetForText(bubbleRect, width);
    final bubbleRadius = Radius.circular(width * 0.055);
    final bubbleFill = Paint()..color = Colors.white.withValues(alpha: 0.96);
    final bubbleBorder = Paint()
      ..color = const Color(0xFF22262E).withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.006;
    final bubbleShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final bubbleRRect = RRect.fromRectAndRadius(bubbleRect, bubbleRadius);
    canvas.drawRRect(
      bubbleRRect.shift(Offset(width * 0.006, height * 0.006)),
      bubbleShadow,
    );
    canvas.drawRRect(bubbleRRect, bubbleFill);
    canvas.drawRRect(bubbleRRect, bubbleBorder);

    final tail = _dialogueBubbleTail(
      bubbleRect: bubbleRect,
      prompt: prompt,
      width: width,
      height: height,
    );
    canvas.drawPath(
      tail.shift(Offset(width * 0.006, height * 0.006)),
      bubbleShadow,
    );
    canvas.drawPath(tail, bubbleFill);
    canvas.drawPath(tail, bubbleBorder);

    final fontSize = _fitDialogueFontSize(
      text: text,
      maxWidth: textRect.width,
      maxHeight: textRect.height,
      imageWidth: width,
    );
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFF1E2430),
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          height: 1.18,
          letterSpacing: 0,
          fontFamily: GoogleFonts.notoSansKr().fontFamily,
          shadows: <Shadow>[
            Shadow(
              color: Colors.white.withValues(alpha: 0.82),
              blurRadius: 1.5,
            ),
          ],
          fontFamilyFallback: const <String>[
            'Noto Sans KR',
            'Malgun Gothic',
            'Apple SD Gothic Neo',
            'Arial Unicode MS',
            'sans-serif',
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 6,
    );
    painter.layout(maxWidth: textRect.width);
    painter.paint(
      canvas,
      Offset(
        textRect.left + (textRect.width - painter.width) / 2,
        textRect.top + (textRect.height - painter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final result = await picture.toImage(image.width, image.height);
    final byteData = await result.toByteData(format: ImageByteFormat.png);
    image.dispose();
    result.dispose();
    return byteData!.buffer.asUint8List();
  }

  Rect _dialogueTextRect({
    required double width,
    required double height,
    required String? prompt,
    required String text,
  }) {
    final value = (prompt ?? '').toLowerCase();
    final candidates = _dialogueTextCandidates(
      width: width,
      height: height,
      text: text,
    );
    return _insetForText(_preferredDialogueCandidate(value, candidates), width);
  }

  List<Rect> _dialogueTextCandidates({
    required double width,
    required double height,
    required String text,
  }) {
    final lengthFactor = (text.length / 42).clamp(0.0, 1.0);
    final bubbleWidth = width * (0.56 + lengthFactor * 0.22);
    final bubbleHeight = height * (0.15 + lengthFactor * 0.13);
    final marginX = width * 0.06;
    final topY = height * 0.045;
    final sideY = height * 0.32;
    final bottomY = height * 0.68;
    return <Rect>[
      Rect.fromLTWH(marginX, topY, bubbleWidth, bubbleHeight),
      Rect.fromLTWH(
        width - bubbleWidth - marginX,
        topY,
        bubbleWidth,
        bubbleHeight,
      ),
      Rect.fromLTWH((width - bubbleWidth) / 2, topY, bubbleWidth, bubbleHeight),
      Rect.fromLTWH(marginX, sideY, bubbleWidth, bubbleHeight),
      Rect.fromLTWH(
        width - bubbleWidth - marginX,
        sideY,
        bubbleWidth,
        bubbleHeight,
      ),
      Rect.fromLTWH(marginX, bottomY, bubbleWidth, bubbleHeight),
      Rect.fromLTWH(
        width - bubbleWidth - marginX,
        bottomY,
        bubbleWidth,
        bubbleHeight,
      ),
      Rect.fromLTWH(
        (width - bubbleWidth) / 2,
        bottomY,
        bubbleWidth,
        bubbleHeight,
      ),
    ];
  }

  Rect _preferredDialogueCandidate(String prompt, List<Rect> candidates) {
    if (prompt.contains('upper_left')) {
      return candidates[0];
    }
    if (prompt.contains('upper_right')) {
      return candidates[1];
    }
    if (prompt.contains('center_top')) {
      return candidates[2];
    }
    if (prompt.contains('left_side')) {
      return candidates[0];
    }
    if (prompt.contains('right_side')) {
      return candidates[1];
    }
    if (prompt.contains('bottom_left')) {
      return candidates[5];
    }
    if (prompt.contains('bottom_right')) {
      return candidates[6];
    }
    return candidates[0];
  }

  Rect _insetForText(Rect bubbleRect, double imageWidth) {
    final horizontalInset = imageWidth * 0.052;
    final verticalInset = imageWidth * 0.026;
    return Rect.fromLTRB(
      bubbleRect.left + horizontalInset,
      bubbleRect.top + verticalInset,
      bubbleRect.right - horizontalInset,
      bubbleRect.bottom - verticalInset,
    );
  }

  Path _dialogueBubbleTail({
    required Rect bubbleRect,
    required String? prompt,
    required double width,
    required double height,
  }) {
    final value = (prompt ?? '').toLowerCase();
    final tailWidth = width * 0.06;
    final tailHeight = height * 0.032;
    final towardRight =
        value.contains('right') || bubbleRect.center.dx < width / 2;
    final anchorX = towardRight
        ? bubbleRect.left + bubbleRect.width * 0.68
        : bubbleRect.left + bubbleRect.width * 0.32;
    final anchorY = bubbleRect.bottom - 1;
    final tipX = towardRight ? anchorX + tailWidth : anchorX - tailWidth;
    final tipY = (anchorY + tailHeight).clamp(0, height - 2).toDouble();

    return Path()
      ..moveTo(anchorX - tailWidth * 0.42, anchorY)
      ..quadraticBezierTo(tipX, tipY, anchorX + tailWidth * 0.42, anchorY)
      ..close();
  }

  String _normalizeDialogueForBubble(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
    return cleaned.replaceAll(RegExp(r'\.{3,}$'), '').trim();
  }

  double _fitDialogueFontSize({
    required String text,
    required double maxWidth,
    required double maxHeight,
    required double imageWidth,
  }) {
    final base = text.length > 42 ? imageWidth * 0.050 : imageWidth * 0.056;
    for (var size = base; size >= imageWidth * 0.026; size -= 0.8) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            height: 1.18,
            fontFamily: GoogleFonts.notoSansKr().fontFamily,
            fontFamilyFallback: const <String>[
              'Noto Sans KR',
              'Malgun Gothic',
              'Apple SD Gothic Neo',
              'Arial Unicode MS',
              'sans-serif',
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 6,
      )..layout(maxWidth: maxWidth);
      if (painter.height <= maxHeight && !painter.didExceedMaxLines) {
        return size;
      }
    }
    return imageWidth * 0.026;
  }

  List<String> _keywordTags() {
    return const <String>[];
  }

  List<String> _generationKeywordTags() {
    return <String>[
      ..._keywordTags(),
      if (_targetCutCount > 0) '__cut_count_$_targetCutCount',
    ];
  }

  WebtoonFormat _selectedWebtoonFormat() {
    // The final output always uses the selected card slide format.
    return WebtoonFormat.cardSlide;
  }

  DiaryArtStyle _selectedArtStyle() {
    final template = _selectedStyleTemplate;
    if (template != null) {
      return template.artStyle;
    }
    return switch (_artSubStyle) {
      '\uC560\uB2C8\uD615 (Graphic)' => DiaryArtStyle.animeLd,
      '\uCE90\uC8FC\uC5BC \uB9CC\uD654\uD615 (Cartoon)' =>
        DiaryArtStyle.comicsSd,
      '\uCE90\uB9AD\uD130\uD615 (Simple Character)' => DiaryArtStyle.simple2d,
      '\uC785\uCCB4 \uB80C\uB354\uB9C1 (3D Style)' => DiaryArtStyle.realistic3d,
      _ => DiaryArtStyle.comicsLd,
    };
  }

  DiaryStyleTemplateModel? get _selectedStyleTemplate {
    for (final template in _styleTemplates) {
      if (template.id == _styleTemplateId) {
        return template;
      }
    }
    return _styleTemplates.isEmpty ? null : _styleTemplates.first;
  }

  DiaryGenre _selectedGenre() {
    return switch (_genre) {
      '\uC9C4\uC9C0\uD558\uACE0 \uCC28\uBD84\uD55C \uB0A0' =>
        DiaryGenre.serious,
      '\uB530\uB73B\uD558\uACE0 \uD589\uBCF5\uD55C \uB0A0' =>
        DiaryGenre.healingRomance,
      '\uBFCC\uB73B\uD558\uACE0 \uC131\uCDE8\uAC10 \uC788\uB294 \uB0A0' =>
        DiaryGenre.growth,
      '\uD798\uB4E4\uACE0 \uC9C0\uCE5C \uB0A0' => DiaryGenre.hardDay,
      _ => DiaryGenre.dailyComic,
    };
  }

  String _selectedGenreSubtype() {
    return switch (_genreSubtype) {
      '' => '',
      '\uC77C\uC0C1' => 'daily',
      '\uAC1C\uADF8' => 'gag',
      '\uB0B4\uBA74' => 'inner',
      '\uC131\uCC30' => 'reflection',
      '\uAC10\uC131' => 'warm_emotion',
      '\uCCAD\uCD98' => 'youth',
      '\uC131\uC7A5' => 'growth',
      '\uC5F4\uC815' => 'passion',
      '\uCE58\uC720' => 'healing',
      '\uACF5\uAC10' => 'empathy',
      _ => _genreSubtype,
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.center)),
    );
  }

  List<_FigmaCardData> get _artSubStyleCards {
    return switch (_artStyle) {
      '\uB2E8\uC21C\uD654 \uC2A4\uD0C0\uC77C (SD)' => const <_FigmaCardData>[
        _FigmaCardData(
          '\uCE90\uC8FC\uC5BC \uB9CC\uD654\uD615 (Cartoon)',
          '\uC608\uC2DC \uC774\uBBF8\uC9C0',
          description:
              '\uD45C\uC815\uACFC \uB3D9\uC791\uC774 \uD06C\uAC8C \uC77D\uD788\uB294 \uB9CC\uD654\uD615',
        ),
        _FigmaCardData(
          '\uCE90\uB9AD\uD130\uD615 (Simple Character)',
          '\uC608\uC2DC \uC774\uBBF8\uC9C0',
          description:
              '\uC120\uACFC \uC0C9\uC744 \uB2E8\uC21C\uD654\uD574 \uCE90\uB9AD\uD130\uC131\uC744 \uAC15\uC870',
        ),
      ],
      '\uC785\uCCB4\uD615 \uC2A4\uD0C0\uC77C (3D)' => const <_FigmaCardData>[
        _FigmaCardData(
          '\uC785\uCCB4 \uB80C\uB354\uB9C1 (3D Style)',
          '\uC608\uC2DC \uC774\uBBF8\uC9C0',
          description:
              '\uC870\uBA85\uACFC \uC7AC\uC9C8\uAC10\uC774 \uC0B4\uC544\uC788\uB294 3D \uB80C\uB354',
        ),
      ],
      _ => const <_FigmaCardData>[
        _FigmaCardData(
          '\uADF9\uD654\uD615 (Semi-Realistic)',
          '\uC608\uC2DC \uC774\uBBF8\uC9C0',
          description:
              '\uAC10\uC815\uC120\uC740 \uB9CC\uD654\uCC98\uB7FC, \uC7A5\uBA74\uC740 \uB354 \uC12C\uC138\uD558\uAC8C',
        ),
        _FigmaCardData(
          '\uC560\uB2C8\uD615 (Graphic)',
          '\uC608\uC2DC \uC774\uBBF8\uC9C0',
          description:
              '\uC120\uBA85\uD55C \uC120\uACFC \uC0C9\uAC10\uC73C\uB85C \uC6F9\uD230\uCC98\uB7FC',
        ),
      ],
    };
  }

  List<_FigmaCardData> get _genreSubtypeCards {
    return switch (_genre) {
      '\uC9C4\uC9C0\uD558\uACE0 \uCC28\uBD84\uD55C \uB0A0' =>
        const <_FigmaCardData>[
          _FigmaCardData('\uB0B4\uBA74', 'inner'),
          _FigmaCardData('\uC131\uCC30', 'reflect'),
        ],
      '\uB530\uB73B\uD558\uACE0 \uD589\uBCF5\uD55C \uB0A0' =>
        const <_FigmaCardData>[
          _FigmaCardData('\uAC10\uC131', 'warm'),
          _FigmaCardData('\uCCAD\uCD98', 'youth'),
        ],
      '\uBFCC\uB73B\uD558\uACE0 \uC131\uCDE8\uAC10 \uC788\uB294 \uB0A0' =>
        const <_FigmaCardData>[
          _FigmaCardData('\uC131\uC7A5', 'growth'),
          _FigmaCardData('\uC5F4\uC815', 'passion'),
        ],
      '\uD798\uB4E4\uACE0 \uC9C0\uCE5C \uB0A0' => const <_FigmaCardData>[
        _FigmaCardData('\uCE58\uC720', 'heal'),
        _FigmaCardData('\uACF5\uAC10', 'empathy'),
      ],
      _ => const <_FigmaCardData>[
        _FigmaCardData('\uC77C\uC0C1', 'daily'),
        _FigmaCardData('\uAC1C\uADF8', 'gag'),
      ],
    };
  }

  void _selectArtStyle(String value) {
    setState(() {
      _artStyle = value;
      _artSubStyle = _artSubStyleCards.first.label;
    });
  }

  void _selectStyleTemplate(String value) {
    final template = _styleTemplates.firstWhere(
      (DiaryStyleTemplateModel item) => item.id == value,
      orElse: () => _styleTemplates.isEmpty
          ? _fallbackStyleTemplates.first
          : _styleTemplates.first,
    );
    setState(() => _applyStyleTemplate(template));
  }

  void _applyStyleTemplate(DiaryStyleTemplateModel template) {
    _styleTemplateId = template.id;
    _artStyle = _styleNameFromTemplate(template);
    _artSubStyle = template.artSubStyle ?? template.name;
  }

  String _styleNameFromTemplate(DiaryStyleTemplateModel template) {
    return switch (template.artStyle) {
      DiaryArtStyle.realistic3d => '\uC785\uCCB4\uD615 \uC2A4\uD0C0\uC77C (3D)',
      DiaryArtStyle.simple2d ||
      DiaryArtStyle.comicsSd ||
      DiaryArtStyle.animeSd => '\uB2E8\uC21C\uD654 \uC2A4\uD0C0\uC77C (SD)',
      _ => '\uC0AC\uC2E4\uC801 \uC2A4\uD0C0\uC77C (LD)',
    };
  }

  void _selectGenre(String value) {
    setState(() {
      _genre = value;
      _genreSubtype = '';
    });
  }

  void _go(int page) {
    Feedback.forTap(context);
    SystemSound.play(SystemSoundType.click);
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }
}

class _DiaryFigmaFrame extends StatelessWidget {
  const _DiaryFigmaFrame({
    required this.title,
    required this.child,
    required this.onClose,
    this.pageIndex = 0,
    this.bookChrome = false,
  });

  final String title;
  final int pageIndex;
  final Widget child;
  final VoidCallback onClose;
  final bool bookChrome;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    if (mobile && bookChrome && pageIndex < 0) {
      final pageNumber = (pageIndex + 1).clamp(1, 4);
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFEAF2FF),
              Color(0xFFF7FAFF),
              Color(0xFFDCEAFF),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                top: 14,
                bottom: 94,
                width: 58,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: <Color>[
                        Color(0xFF7EA4F5),
                        Color(0xFFAFC9FF),
                        Color(0xFFE4EEFF),
                      ],
                    ),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF7EA4F5).withValues(alpha: 0.28),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                top: 22,
                bottom: 102,
                width: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                left: 29,
                top: 22,
                bottom: 102,
                width: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.tacticalBlue.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                right: 2,
                top: 24,
                bottom: 98,
                width: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: <Color>[
                        const Color(0xFFE8F0FF).withValues(alpha: 0.98),
                        const Color(0xFFBFD3FF).withValues(alpha: 0.92),
                      ],
                    ),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(18),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 7,
                top: 42,
                bottom: 116,
                width: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ),
              Positioned(
                right: 11,
                top: 48,
                bottom: 122,
                width: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.50),
                  ),
                ),
              ),
              Positioned(
                left: 23,
                right: 9,
                top: 0,
                bottom: 86,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6E5FF).withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
              Positioned(
                left: 26,
                right: 9,
                top: 0,
                bottom: 92,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: <Color>[
                        Color(0xFFE9F2FF),
                        Color(0xFFFFFEFF),
                        Color(0xFFF7FAFF),
                      ],
                      stops: <double>[0, 0.16, 1],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFBFD3FF).withValues(alpha: 0.86),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppTheme.tacticalBlue.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 13),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.86),
                        blurRadius: 0,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 40,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: <Color>[
                                  const Color(
                                    0xFF8FB3FA,
                                  ).withValues(alpha: 0.28),
                                  const Color(
                                    0xFFDCEAFF,
                                  ).withValues(alpha: 0.22),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 36,
                          right: 16,
                          top: 84,
                          child: Column(
                            children: List<Widget>.generate(
                              7,
                              (int index) => Padding(
                                padding: const EdgeInsets.only(bottom: 33),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF9EB9F6,
                                    ).withValues(alpha: 0.14),
                                  ),
                                  child: const SizedBox(height: 1),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 9,
                          top: 58,
                          bottom: 18,
                          width: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF9EB9F6,
                              ).withValues(alpha: 0.20),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 14,
                          top: 64,
                          bottom: 22,
                          width: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF9EB9F6,
                              ).withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        Column(
                          children: <Widget>[
                            SizedBox(
                              height: 48,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 24,
                                  right: 7,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFCFE0FF),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              bottom: Radius.circular(7),
                                            ),
                                        border: Border.all(
                                          color: AppTheme.ink.withValues(
                                            alpha: 0.08,
                                          ),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          8,
                                          6,
                                          8,
                                          7,
                                        ),
                                        child: Text(
                                          'p.$pageNumber',
                                          style: TextStyle(
                                            color: AppTheme.ink.withValues(
                                              alpha: 0.62,
                                            ),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Gap(10),
                                    Expanded(
                                      child: Text(
                                        title,
                                        textAlign: TextAlign.left,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppTheme.ink,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (title != '\uC77C\uAE30')
                                      IconButton(
                                        onPressed: onClose,
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 20,
                                        ),
                                        color: AppTheme.ink.withValues(
                                          alpha: 0.62,
                                        ),
                                        tooltip: '\uB2EB\uAE30',
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(child: const SizedBox.shrink()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 32,
                right: 18,
                bottom: 86,
                height: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.66),
                        const Color(0xFFC8D9FF).withValues(alpha: 0.42),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                left: 36,
                right: 18,
                top: 48,
                bottom: 0,
                child: child,
              ),
            ],
          ),
        ),
      );
    }

    if (mobile && bookChrome && pageIndex < 0) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFF6FAFF),
              Color(0xFFEAF3FF),
              Color(0xFFF9FBFF),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: child,
        ),
      );
    }

    if (!mobile && bookChrome) {
      return _DesktopDiaryBinderFrame(
        title: title,
        pageIndex: pageIndex,
        onClose: onClose,
        child: child,
      );
    }

    if (mobile && bookChrome) {
      return child;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: mobile ? Colors.transparent : const Color(0xFFFBFEFF),
        border: mobile
            ? null
            : Border.all(color: const Color(0xFFD2E3FA), width: 1.8),
        borderRadius: BorderRadius.circular(mobile ? 0 : 8),
        boxShadow: mobile
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: AppTheme.tacticalBlue.withValues(alpha: 0.13),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFFEAF4FF).withValues(alpha: 0.96),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ],
      ),
      child: Stack(
        children: <Widget>[
          if (!mobile) const Positioned.fill(child: _FigmaPastelWash()),
          if (!mobile)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.72),
                      Colors.transparent,
                      const Color(0xFFEAF6FF).withValues(alpha: 0.22),
                    ],
                  ),
                ),
              ),
            ),
          Column(
            children: <Widget>[
              SizedBox(
                height: mobile ? 38 : 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: mobile
                              ? Colors.transparent
                              : AppTheme.tacticalBlue,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          border: mobile
                              ? null
                              : Border(
                                  bottom: BorderSide(
                                    color: AppTheme.tacticalBlue.withValues(
                                      alpha: 0.54,
                                    ),
                                  ),
                                ),
                          boxShadow: mobile
                              ? const <BoxShadow>[]
                              : <BoxShadow>[
                                  BoxShadow(
                                    color: AppTheme.tacticalBlue.withValues(
                                      alpha: 0.20,
                                    ),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                      ),
                    ),
                    if (mobile)
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppTheme.tacticalBlue.withValues(
                                  alpha: 0.16,
                                ),
                              ),
                            ),
                          ),
                          child: const SizedBox(height: 1),
                        ),
                      ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: mobile
                                ? AppTheme.tacticalBlue
                                : Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: mobile ? 13 : null,
                            shadows: const <Shadow>[
                              Shadow(
                                color: Color(0x447890DE),
                                blurRadius: 7,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (title != '\uC77C\uAE30')
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.cancel_rounded),
                          color: mobile ? AppTheme.tacticalBlue : Colors.white,
                          tooltip: '\uB2EB\uAE30',
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesktopDiaryBinderFrame extends StatelessWidget {
  const _DesktopDiaryBinderFrame({
    required this.title,
    required this.pageIndex,
    required this.onClose,
    required this.child,
  });

  final String title;
  final int pageIndex;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFF4F8FF),
            Color(0xFFEAF3FF),
            Color(0xFFF9FBFF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E4FA), width: 1.2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF7388C4).withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 18,
              right: 18,
              top: 16,
              bottom: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7F0FF)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppTheme.ink.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiaryOpenPage extends StatelessWidget {
  const _DiaryOpenPage({required this.onArchive, required this.onStart});

  final VoidCallback onArchive;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 14 : 48,
        mobile ? 12 : 28,
        mobile ? 14 : 48,
        mobile ? 12 : 34,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final compact = constraints.maxWidth < 620;
          final mobileCardHeight = ((constraints.maxHeight - 18) / 2).clamp(
            108.0,
            132.0,
          );
          final cards = <Widget>[
            _FigmaGradientButton(
              title: '\uBCF4\uAD00\uD568',
              subtitle: '\uADF8\uB3D9\uC548\uC758 \uAE30\uB85D',
              colors: const <Color>[Color(0xFFF09AB8), Color(0xFFFFC7B0)],
              icon: Icons.inventory_2_rounded,
              onTap: onArchive,
            ),
            _FigmaGradientButton(
              title: '\uC0C8 \uC77C\uAE30',
              subtitle: '\uC77C\uAE30 \uC791\uC131 \uC2DC\uC791',
              colors: const <Color>[Color(0xFF8FB8F8), Color(0xFF8FE0A1)],
              icon: Icons.edit_note_rounded,
              onTap: onStart,
            ),
          ];

          if (mobile) {
            final gridWidth = min(constraints.maxWidth, 620.0);
            return _DiaryCoverMobile(
              width: gridWidth,
              onStart: onStart,
              onArchive: onArchive,
            );
          }

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  height: mobile ? mobileCardHeight : 118,
                  child: cards.last,
                ),
                Gap(mobile ? 10 : 12),
                SizedBox(
                  height: mobile ? mobileCardHeight : 118,
                  child: cards.first,
                ),
              ],
            );
          }

          return _DiaryClosedCoverDesktop(
            onStart: onStart,
            onArchive: onArchive,
          );
        },
      ),
    );
  }
}

class _DiaryClosedCoverDesktop extends StatelessWidget {
  const _DiaryClosedCoverDesktop({
    required this.onStart,
    required this.onArchive,
  });

  final VoidCallback onStart;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1.62,
        child: _DiaryClosedCover(
          onStart: onStart,
          onArchive: onArchive,
          compact: false,
        ),
      ),
    );
  }
}

class _DiaryClosedCover extends StatelessWidget {
  const _DiaryClosedCover({
    required this.onStart,
    required this.onArchive,
    required this.compact,
  });

  final VoidCallback onStart;
  final VoidCallback onArchive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(compact ? 22 : 28);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          child: ClipRRect(
            borderRadius: radius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFD9E6FF),
                    Color(0xFFC3D6FA),
                    Color(0xFFB4C9EF),
                  ],
                ),
                borderRadius: radius,
                border: Border.all(
                  color: const Color(0xFFF2F7FF).withValues(alpha: 0.98),
                  width: compact ? 1.6 : 2.2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.ink.withValues(alpha: 0.18),
                    blurRadius: compact ? 18 : 30,
                    offset: Offset(0, compact ? 10 : 18),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.54),
                    blurRadius: 0,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Stack(
                children: <Widget>[
                  const Positioned.fill(child: _DiaryStripePattern()),
                  Positioned(
                    left: compact ? 52 : 92,
                    right: compact ? 16 : 30,
                    top: compact ? 14 : 22,
                    height: compact ? 34 : 48,
                    child: _DiaryLaceTrim(compact: compact),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: compact ? 16 : 34,
          top: compact ? 18 : 28,
          bottom: compact ? 18 : 28,
          width: compact ? 34 : 64,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF9DB4E2),
              borderRadius: BorderRadius.circular(compact ? 22 : 32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppTheme.ink.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: compact ? 2 : 8,
          top: compact ? 46 : 58,
          bottom: compact ? 46 : 58,
          width: compact ? 74 : 146,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List<Widget>.generate(
              compact ? 5 : 6,
              (int index) => _DiarySpringLoop(compact: compact),
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 58 : 146,
              compact ? 26 : 46,
              compact ? 12 : 52,
              compact ? 24 : 48,
            ),
            child: _DiaryCoverContent(
              compact: compact,
              onArchive: onArchive,
              onStart: onStart,
            ),
          ),
        ),
      ],
    );
  }
}

class _DiarySpringLoop extends StatelessWidget {
  const _DiarySpringLoop({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 62.0 : 122.0;
    final height = compact ? 24.0 : 40.0;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: <Widget>[
          Positioned(
            left: compact ? 17 : 25,
            right: 0,
            child: Container(
              height: compact ? 15 : 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFFF8FAFF),
                  width: compact ? 4 : 7,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.ink.withValues(alpha: 0.24),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            child: Container(
              width: compact ? 31 : 43,
              height: compact ? 31 : 43,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: <Color>[
                    Color(0xFFFFFFFF),
                    Color(0xFFE5EAF4),
                    Color(0xFFA8B5CA),
                  ],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.ink.withValues(alpha: 0.20),
                    blurRadius: 7,
                    offset: const Offset(1, 3),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: compact ? 8 : 12,
            child: Container(
              width: compact ? 14 : 19,
              height: compact ? 14 : 19,
              decoration: BoxDecoration(
                color: const Color(0xFF9DB4E2),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.ink.withValues(alpha: 0.10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryCoverContent extends StatelessWidget {
  const _DiaryCoverContent({
    required this.compact,
    required this.onArchive,
    required this.onStart,
  });

  final bool compact;
  final VoidCallback onArchive;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Align(
          alignment: const Alignment(0.86, -0.88),
          child: _DiaryMoonSticker(compact: compact),
        ),
        Align(
          alignment: const Alignment(-0.86, -0.82),
          child: _DiaryBalloonSticker(compact: compact),
        ),
        Column(
          children: <Widget>[
            const Spacer(flex: 1),
            _DiaryCoverTitlePlate(compact: compact),
            SizedBox(height: compact ? 8 : 16),
            Expanded(
              flex: compact ? 6 : 6,
              child: Center(child: _DiaryCatSticker(compact: compact)),
            ),
            SizedBox(height: compact ? 6 : 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _DiaryCoverActionPill(
                  icon: Icons.inventory_2_rounded,
                  label: '\uBCF4\uAD00\uD568',
                  onTap: onArchive,
                  compact: compact,
                ),
                Gap(compact ? 8 : 18),
                _DiaryCoverActionPill(
                  icon: Icons.edit_note_rounded,
                  label: '\uC0C8 \uC77C\uAE30',
                  onTap: onStart,
                  compact: compact,
                ),
              ],
            ),
            const Spacer(flex: 1),
          ],
        ),
      ],
    );
  }
}

class _DiaryStripePattern extends StatelessWidget {
  const _DiaryStripePattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _DiaryStripePainter());
  }
}

class _DiaryLaceTrim extends StatelessWidget {
  const _DiaryLaceTrim({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DiaryLacePainter(compact: compact));
  }
}

class _DiaryCloudSticker extends StatelessWidget {
  const _DiaryCloudSticker({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 120 : 190,
      height: compact ? 78 : 118,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(painter: const _DiaryCloudPainter()),
          ),
          Positioned(
            left: compact ? 22 : 34,
            top: compact ? 25 : 40,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.tacticalBlue.withValues(alpha: 0.68),
              size: compact ? 16 : 22,
            ),
          ),
          Positioned(
            right: compact ? 23 : 38,
            bottom: compact ? 20 : 30,
            child: Icon(
              Icons.star_rounded,
              color: const Color(0xFFFFD86E).withValues(alpha: 0.90),
              size: compact ? 17 : 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryCoverTitlePlate extends StatelessWidget {
  const _DiaryCoverTitlePlate({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF8EB9EF), width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : 30,
          vertical: compact ? 8 : 12,
        ),
        child: Text(
          'Mood diary',
          style: TextStyle(
            color: const Color(0xFF68A3DD),
            fontSize: compact ? 22 : 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            shadows: <Shadow>[
              Shadow(
                color: Colors.white.withValues(alpha: 0.95),
                blurRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiaryMoonSticker extends StatelessWidget {
  const _DiaryMoonSticker({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 66.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: <Widget>[
          Icon(
            Icons.nightlight_round,
            size: size,
            color: const Color(0xFFFFDF68),
          ),
          Positioned(
            right: 0,
            top: size * 0.08,
            child: Icon(
              Icons.star_rounded,
              size: size * 0.26,
              color: Colors.white.withValues(alpha: 0.94),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryBalloonSticker extends StatelessWidget {
  const _DiaryBalloonSticker({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 36.0 : 58.0;
    return SizedBox(
      width: size,
      height: size * 1.45,
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFBFD0).withValues(alpha: 0.78),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: SizedBox(width: size, height: size),
          ),
          Positioned(
            top: size * 0.88,
            child: Container(
              width: 1.4,
              height: size * 0.50,
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryCoverMemoCard extends StatelessWidget {
  const _DiaryCoverMemoCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD5C6B6)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        width: compact ? 78 : 130,
        height: compact ? 54 : 88,
        child: CustomPaint(painter: const _DiaryPaperLinesPainter()),
      ),
    );
  }
}

class _DiarySoftBadge extends StatelessWidget {
  const _DiarySoftBadge({required this.icon, required this.compact});

  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 38.0 : 58.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFC5D6F2)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          size: size * 0.42,
          color: AppTheme.tacticalBlue.withValues(alpha: 0.64),
        ),
      ),
    );
  }
}

class _DiaryRibbonBow extends StatelessWidget {
  const _DiaryRibbonBow({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 46.0 : 72.0;
    return SizedBox(
      width: size,
      height: size * 0.78,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Transform.rotate(
            angle: -0.46,
            child: _DiaryBowLoop(width: size * 0.48, compact: compact),
          ),
          Transform.rotate(
            angle: 0.46,
            child: _DiaryBowLoop(width: size * 0.48, compact: compact),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFC8D8F2)),
            ),
            child: SizedBox(width: size * 0.18, height: size * 0.18),
          ),
          Positioned(
            left: size * 0.32,
            bottom: 0,
            child: Transform.rotate(
              angle: 0.14,
              child: Container(
                width: size * 0.12,
                height: size * 0.38,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E7FF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Positioned(
            right: size * 0.32,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.14,
              child: Container(
                width: size * 0.12,
                height: size * 0.38,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E7FF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryBowLoop extends StatelessWidget {
  const _DiaryBowLoop({required this.width, required this.compact});

  final double width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF).withValues(alpha: 0.92),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(width),
          bottomLeft: Radius.circular(width),
          topRight: Radius.circular(compact ? 6 : 9),
          bottomRight: Radius.circular(compact ? 6 : 9),
        ),
        border: Border.all(color: const Color(0xFFC4D4EE)),
      ),
      child: SizedBox(width: width, height: compact ? 22 : 34),
    );
  }
}

class _DiaryStickerCluster extends StatelessWidget {
  const _DiaryStickerCluster({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 76 : 122,
      height: compact ? 80 : 128,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            top: compact ? 8 : 12,
            child: _DiaryRoundSticker(
              color: const Color(0xFFF9FBFF),
              size: compact ? 34 : 52,
              icon: Icons.auto_awesome_rounded,
            ),
          ),
          Positioned(
            right: compact ? 5 : 8,
            top: 0,
            child: _DiaryRoundSticker(
              color: const Color(0xFFDDEAFF),
              size: compact ? 28 : 42,
              icon: Icons.favorite_rounded,
            ),
          ),
          Positioned(
            left: compact ? 22 : 36,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.12,
              child: _DiaryMiniTicket(compact: compact),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryCatSticker extends StatelessWidget {
  const _DiaryCatSticker({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 138.0 : 218.0;
    return SizedBox(
      width: size,
      height: size * 0.82,
      child: CustomPaint(painter: _DiaryCatStickerPainter(compact: compact)),
    );
  }
}

class _DiaryFloppyEar extends StatelessWidget {
  const _DiaryFloppyEar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF88B8EE), width: 2),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

class _DiaryCloudBase extends StatelessWidget {
  const _DiaryCloudBase({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: const _DiaryCloudBasePainter()),
    );
  }
}

class _DiaryCheek extends StatelessWidget {
  const _DiaryCheek({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFBFD0).withValues(alpha: 0.72),
        shape: BoxShape.circle,
      ),
      child: SizedBox(width: size, height: size * 0.72),
    );
  }
}

class _DiaryMascotPaw extends StatelessWidget {
  const _DiaryMascotPaw({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF88B8EE), width: 1.5),
      ),
      child: SizedBox(width: size, height: size * 0.86),
    );
  }
}

class _DiaryCatStickerPainter extends CustomPainter {
  const _DiaryCatStickerPainter({required this.compact});

  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final blue = const Color(0xFF7DB5EC);
    final paleBlue = const Color(0xFFEAF5FF);
    final ink = const Color(0xFF5B9FDC);
    final cheek = const Color(0xFFFFBCD1);
    final yellow = const Color(0xFFFFD86E);
    final white = const Color(0xFFFFFEFA);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.13, h * 0.18, w * 0.74, h * 0.70),
        Radius.circular(w * 0.18),
      ),
      Paint()
        ..color = AppTheme.ink.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    final cloud = Path()
      ..moveTo(w * 0.08, h * 0.66)
      ..cubicTo(w * 0.02, h * 0.50, w * 0.17, h * 0.40, w * 0.29, h * 0.47)
      ..cubicTo(w * 0.34, h * 0.28, w * 0.55, h * 0.29, w * 0.60, h * 0.47)
      ..cubicTo(w * 0.74, h * 0.38, w * 0.92, h * 0.48, w * 0.88, h * 0.66)
      ..cubicTo(w * 0.95, h * 0.76, w * 0.82, h * 0.88, w * 0.67, h * 0.82)
      ..cubicTo(w * 0.55, h * 0.95, w * 0.34, h * 0.90, w * 0.31, h * 0.78)
      ..cubicTo(w * 0.20, h * 0.84, w * 0.07, h * 0.78, w * 0.08, h * 0.66)
      ..close();
    final fill = Paint()
      ..color = white
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 2.0 : 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(cloud, fill);
    canvas.drawPath(cloud, stroke);

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.55),
        width: w * 0.28,
        height: h * 0.28,
      ),
      Radius.circular(w * 0.15),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, stroke);

    void drawEar({required Offset center, required bool flip}) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      if (flip) {
        canvas.scale(-1, 1);
      }
      final ear = Path()
        ..moveTo(-w * 0.095, h * 0.055)
        ..cubicTo(-w * 0.078, -h * 0.025, -w * 0.018, -h * 0.085, 0, -h * 0.095)
        ..cubicTo(
          w * 0.022,
          -h * 0.070,
          w * 0.085,
          -h * 0.006,
          w * 0.100,
          h * 0.060,
        )
        ..cubicTo(
          w * 0.050,
          h * 0.040,
          -w * 0.042,
          h * 0.040,
          -w * 0.095,
          h * 0.055,
        )
        ..close();
      canvas.drawPath(ear, fill);
      canvas.drawPath(ear, stroke);
      final inner = Path()
        ..moveTo(-w * 0.040, h * 0.030)
        ..cubicTo(
          -w * 0.025,
          -h * 0.015,
          -w * 0.005,
          -h * 0.038,
          w * 0.010,
          -h * 0.048,
        )
        ..cubicTo(
          w * 0.030,
          -h * 0.020,
          w * 0.052,
          h * 0.012,
          w * 0.058,
          h * 0.036,
        )
        ..close();
      canvas.drawPath(
        inner,
        Paint()..color = const Color(0xFFFFDCE7).withValues(alpha: 0.82),
      );
      canvas.restore();
    }

    drawEar(center: Offset(w * 0.38, h * 0.23), flip: false);
    drawEar(center: Offset(w * 0.62, h * 0.23), flip: true);

    final head = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.34),
        width: w * 0.40,
        height: h * 0.34,
      ),
      Radius.circular(w * 0.17),
    );
    canvas.drawRRect(head, fill);
    canvas.drawRRect(head, stroke);

    final blushPaint = Paint()
      ..color = cheek.withValues(alpha: 0.76)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.39, h * 0.38),
        width: w * 0.07,
        height: h * 0.045,
      ),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.61, h * 0.38),
        width: w * 0.07,
        height: h * 0.045,
      ),
      blushPaint,
    );

    final facePaint = Paint()
      ..color = ink
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.43, h * 0.32), w * 0.018, facePaint);
    canvas.drawCircle(Offset(w * 0.57, h * 0.32), w * 0.018, facePaint);

    final mouthPaint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1.6 : 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.50, h * 0.36),
      Offset(w * 0.50, h * 0.39),
      mouthPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.475, h * 0.39),
        width: w * 0.052,
        height: h * 0.052,
      ),
      0.12,
      2.30,
      false,
      mouthPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.525, h * 0.39),
        width: w * 0.052,
        height: h * 0.052,
      ),
      0.70,
      2.30,
      false,
      mouthPaint,
    );

    for (final center in <Offset>[
      Offset(w * 0.38, h * 0.56),
      Offset(w * 0.62, h * 0.56),
    ]) {
      final paw = Rect.fromCenter(
        center: center,
        width: w * 0.085,
        height: h * 0.11,
      );
      canvas.drawOval(paw, fill);
      canvas.drawOval(paw, stroke);
    }

    final starPath = Path()
      ..moveTo(w * 0.50, h * 0.47)
      ..lineTo(w * 0.535, h * 0.535)
      ..lineTo(w * 0.61, h * 0.545)
      ..lineTo(w * 0.555, h * 0.595)
      ..lineTo(w * 0.57, h * 0.67)
      ..lineTo(w * 0.50, h * 0.635)
      ..lineTo(w * 0.43, h * 0.67)
      ..lineTo(w * 0.445, h * 0.595)
      ..lineTo(w * 0.39, h * 0.545)
      ..lineTo(w * 0.465, h * 0.535)
      ..close();
    canvas.drawPath(starPath, Paint()..color = yellow);
    canvas.drawPath(
      starPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.86)
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 1.0 : 1.4,
    );

    _drawSparkle(
      canvas,
      Offset(w * 0.23, h * 0.62),
      w * 0.035,
      Paint()..color = paleBlue,
    );
    _drawSparkle(
      canvas,
      Offset(w * 0.76, h * 0.60),
      w * 0.028,
      Paint()..color = paleBlue,
    );
    _drawSparkle(
      canvas,
      Offset(w * 0.72, h * 0.76),
      w * 0.025,
      Paint()..color = yellow,
    );
  }

  @override
  bool shouldRepaint(covariant _DiaryCatStickerPainter oldDelegate) {
    return oldDelegate.compact != compact;
  }
}

class _DiaryCatEar extends StatelessWidget {
  const _DiaryCatEar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const _DiaryCatEarPainter(),
    );
  }
}

class _DiaryCatEye extends StatelessWidget {
  const _DiaryCatEye({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.ink.withValues(alpha: 0.72),
        shape: BoxShape.circle,
      ),
      child: SizedBox(width: size, height: size),
    );
  }
}

class _DiaryWhiskers extends StatelessWidget {
  const _DiaryWhiskers({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.34,
      child: CustomPaint(painter: const _DiaryWhiskerPainter()),
    );
  }
}

class _DiaryRoundSticker extends StatelessWidget {
  const _DiaryRoundSticker({
    required this.color,
    required this.size,
    required this.icon,
  });

  final Color color;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          size: size * 0.46,
          color: AppTheme.tacticalBlue.withValues(alpha: 0.70),
        ),
      ),
    );
  }
}

class _DiaryMiniTicket extends StatelessWidget {
  const _DiaryMiniTicket({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFB9CBE9)),
      ),
      child: SizedBox(
        width: compact ? 48 : 74,
        height: compact ? 22 : 32,
        child: Center(
          child: Container(
            width: compact ? 22 : 36,
            height: 2,
            color: const Color(0xFFC8D8F2),
          ),
        ),
      ),
    );
  }
}

class _DiaryPressedFlower extends StatelessWidget {
  const _DiaryPressedFlower({required this.color, required this.compact});

  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 42 : 68,
      height: compact ? 76 : 120,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Positioned(
            bottom: 0,
            child: Container(
              width: 2,
              height: compact ? 56 : 92,
              color: color.withValues(alpha: 0.56),
            ),
          ),
          for (var index = 0; index < 5; index++)
            Positioned(
              bottom: compact ? 17.0 + index * 8 : 26.0 + index * 13,
              left: index.isEven ? (compact ? 12 : 18) : (compact ? 21 : 34),
              child: Transform.rotate(
                angle: index.isEven ? -0.62 : 0.62,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: SizedBox(
                    width: compact ? 20 : 32,
                    height: compact ? 8 : 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiaryCoverActionPill extends StatelessWidget {
  const _DiaryCoverActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final maxLabelWidth = compact ? 56.0 : 96.0;
    return _PressableScale(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF6FAFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF9FB9E6), width: 1.2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 17,
            vertical: compact ? 7 : 11,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: AppTheme.tacticalBlue, size: compact ? 15 : 20),
              Gap(compact ? 4 : 7),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxLabelWidth),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: compact ? 11 : 14,
                    fontWeight: FontWeight.w900,
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

class _DiaryPageStamp extends StatelessWidget {
  const _DiaryPageStamp({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2F6),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE9B5C6)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Icon(icon, color: const Color(0xFFD783A5), size: 20),
          ),
        ),
        const Gap(10),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.ink.withValues(alpha: 0.64),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DiaryHandNote extends StatelessWidget {
  const _DiaryHandNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6CC).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEDC8A)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.ink.withValues(alpha: 0.72),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            height: 1.28,
          ),
        ),
      ),
    );
  }
}

class _DiaryCoverMobile extends StatelessWidget {
  const _DiaryCoverMobile({
    required this.width,
    required this.onStart,
    required this.onArchive,
  });

  final double width;
  final VoidCallback onStart;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final coverWidth = min(max(width, 290.0), screenWidth - 36);
    return Center(
      child: SizedBox(
        width: coverWidth,
        height: min(430, max(340, coverWidth * 1.28)),
        child: _DiaryClosedCover(
          onStart: onStart,
          onArchive: onArchive,
          compact: true,
        ),
      ),
    );
  }
}

class _DiaryCoverActionCard extends StatelessWidget {
  const _DiaryCoverActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.paperColor,
    required this.stickerColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color paperColor;
  final Color stickerColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            top: 8,
            left: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: paperColor.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.38),
                  width: 1.2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.tacticalBlue.withValues(alpha: 0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 11,
                    right: 11,
                    top: 44,
                    child: Column(
                      children: List<Widget>.generate(
                        4,
                        (int index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.14),
                            ),
                            child: const SizedBox(height: 1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 9,
                    top: 9,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: stickerColor.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.80),
                        ),
                      ),
                      child: const SizedBox(width: 18, height: 18),
                    ),
                  ),
                  Positioned(
                    right: 9,
                    top: 9,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: accentColor.withValues(alpha: 0.72),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 24, 10, 15),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(9),
                              child: Icon(
                                icon,
                                size: 24,
                                color: AppTheme.tacticalBlue.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                            ),
                          ),
                          const Gap(14),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.tacticalBlue,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.tacticalBlue.withValues(
                                alpha: 0.72,
                              ),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              height: 1.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: -10,
            child: Transform.rotate(
              angle: -0.03,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.70),
                  ),
                ),
                child: const SizedBox(height: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryBinderHole extends StatelessWidget {
  const _DiaryBinderHole();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.14),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.10),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        width: 13,
        height: 13,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.tacticalBlue.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(width: 5, height: 5),
          ),
        ),
      ),
    );
  }
}

class _DiaryMiniMemo extends StatelessWidget {
  const _DiaryMiniMemo();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D8).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List<Widget>.generate(
            3,
            (int index) => Padding(
              padding: EdgeInsets.only(bottom: index == 2 ? 0 : 5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.tacticalBlue.withValues(alpha: 0.18),
                ),
                child: SizedBox(width: index == 2 ? 28 : 42, height: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiaryTapeStrip extends StatelessWidget {
  const _DiaryTapeStrip({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
      ),
      child: SizedBox(width: width, height: 20),
    );
  }
}

class _DiaryStickerDot extends StatelessWidget {
  const _DiaryStickerDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.86),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
      ),
      child: SizedBox(width: size, height: size),
    );
  }
}

class _DiaryStickerStar extends StatelessWidget {
  const _DiaryStickerStar();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.star_rounded,
      size: 24,
      color: const Color(0xFFFFD36A).withValues(alpha: 0.92),
    );
  }
}

class _DiaryWriteScreen extends StatelessWidget {
  const _DiaryWriteScreen({
    required this.titleController,
    required this.bodyController,
    required this.tagController,
    required this.weather,
    required this.onWeatherChanged,
    required this.onBack,
    required this.onNext,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final TextEditingController tagController;
  final String weather;
  final ValueChanged<String> onWeatherChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 7 : 16,
        mobile ? 7 : 10,
        mobile ? 7 : 16,
        mobile ? 7 : 12,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final compact = constraints.maxWidth < 760;
          final contentWidth = constraints.maxWidth > 1540
              ? 1540.0
              : constraints.maxWidth;

          return Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: compact
                        ? Column(
                            children: <Widget>[
                              Expanded(
                                child: _DiaryLogPanel(
                                  titleController: titleController,
                                  bodyController: bodyController,
                                ),
                              ),
                              Gap(mobile ? 8 : 12),
                              SizedBox(
                                height: mobile ? 194 : 330,
                                child: _DiaryMetaPanel(
                                  tagController: tagController,
                                  weather: weather,
                                  onWeatherChanged: onWeatherChanged,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                flex: 8,
                                child: _DiaryLogPanel(
                                  titleController: titleController,
                                  bodyController: bodyController,
                                ),
                              ),
                              const Gap(28),
                              Expanded(
                                flex: 5,
                                child: _DiaryMetaPanel(
                                  tagController: tagController,
                                  weather: weather,
                                  onWeatherChanged: onWeatherChanged,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const Gap(8),
              Center(
                child: SizedBox(
                  width: contentWidth,
                  child: _DiaryWriteFooter(onBack: onBack, onNext: onNext),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DiaryLogPanel extends StatelessWidget {
  const _DiaryLogPanel({
    required this.titleController,
    required this.bodyController,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;

  @override
  Widget build(BuildContext context) {
    return _RaisedDiaryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const _FigmaTinyTag(text: 'DIARY LOG'),
          const Gap(10),
          TextField(
            controller: titleController,
            textAlign: TextAlign.center,
            decoration: _figmaField(
              '\uC791\uD488 \uC81C\uBAA9\uC744 \uC785\uB825\uD574 \uC8FC\uC138\uC694',
            ),
          ),
          const Gap(10),
          Expanded(
            child: TextField(
              controller: bodyController,
              expands: true,
              maxLines: null,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.top,
              decoration: _figmaField(
                '\uC624\uB298\uC758 \uC7A5\uBA74\uC740 50\uAE00\uC790 \uC774\uC0C1\uC5D0 \uAC10\uC815\uD45C\uD604\uC744 2\uAC1C \uC774\uC0C1 \uC11E\uC5B4\uC918\uC57C \uD6A8\uACFC\uC801\uC785\uB2C8\uB2E4.',
              ).copyWith(contentPadding: const EdgeInsets.all(16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryMetaPanel extends StatelessWidget {
  const _DiaryMetaPanel({
    required this.tagController,
    required this.weather,
    required this.onWeatherChanged,
  });

  final TextEditingController tagController;
  final String weather;
  final ValueChanged<String> onWeatherChanged;

  @override
  Widget build(BuildContext context) {
    return _RaisedDiaryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const _FigmaTinyTag(text: 'SCENE META'),
          const Gap(10),
          _WeatherIconSelector(selected: weather, onChanged: onWeatherChanged),
          const Gap(8),
          Expanded(
            child: TextField(
              controller: tagController,
              expands: true,
              maxLines: null,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.top,
              decoration: _figmaField(
                '\uD504\uB86C\uD504\uD2B8 \uACE0\uC815 \uD0A4\uC6CC\uB4DC',
              ).copyWith(contentPadding: const EdgeInsets.all(16)),
            ),
          ),
          const Gap(8),
          SizedBox(
            height: 44,
            child: Center(
              child: Text(
                '\uC5EC\uAE30\uC5D0 \uC801\uC740 \uB2E8\uC5B4\uB294 \uD53C\uB4DC \uD0DC\uADF8\uAC00 \uC544\uB2C8\uB77C AI\uAC00 \uAF2D \uBC18\uC601\uD574\uC57C \uD560 \uC694\uC18C\uC785\uB2C8\uB2E4.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF5B7FB7).withValues(alpha: 0.82),
                  height: 1.25,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryWriteFooter extends StatelessWidget {
  const _DiaryWriteFooter({required this.onBack, required this.onNext});

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: <Widget>[
          _FigmaBackButton(onTap: onBack),
          const Spacer(),
          _FigmaNextButton(onTap: onNext),
        ],
      ),
    );
  }
}

class _FigmaBackButton extends StatefulWidget {
  const _FigmaBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_FigmaBackButton> createState() => _FigmaBackButtonState();
}

class _FigmaBackButtonState extends State<_FigmaBackButton> {
  @override
  Widget build(BuildContext context) {
    return _FigmaMotionButton(
      label: '\uC774\uC804',
      icon: Icons.arrow_back_ios_new_rounded,
      onTap: widget.onTap,
      filled: false,
      iconOnRight: false,
    );
  }
}

class _FigmaNextButton extends StatelessWidget {
  const _FigmaNextButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _FigmaMotionButton(
      label: '\uB2E4\uC74C',
      icon: Icons.arrow_forward_rounded,
      onTap: onTap,
      filled: true,
      iconOnRight: true,
    );
  }
}

class _FigmaSkipButton extends StatelessWidget {
  const _FigmaSkipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _FigmaMotionButton(
      label: '\uAC74\uB108\uB6F0\uAE30',
      icon: Icons.double_arrow_rounded,
      onTap: onTap,
      filled: false,
      iconOnRight: true,
    );
  }
}

class _FigmaMotionButton extends StatefulWidget {
  const _FigmaMotionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
    required this.iconOnRight,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool iconOnRight;

  @override
  State<_FigmaMotionButton> createState() => _FigmaMotionButtonState();
}

class _FigmaMotionButtonState extends State<_FigmaMotionButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _pressed || _hovered;
    final foreground = widget.filled
        ? Colors.white
        : (isActive ? const Color(0xFF5F82D9) : const Color(0xFF7897DF));
    final background = widget.filled
        ? (isActive ? const Color(0xFF83A4EF) : const Color(0xFF9AB3F3))
        : Colors.white.withValues(alpha: _pressed ? 0.96 : 0.9);
    final iconOffset = widget.iconOnRight
        ? (_pressed
              ? const Offset(0.08, 0)
              : (_hovered ? const Offset(0.04, 0) : Offset.zero))
        : (_pressed
              ? const Offset(-0.08, 0)
              : (_hovered ? const Offset(-0.04, 0) : Offset.zero));

    final icon = AnimatedSlide(
      offset: iconOffset,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: Container(
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          color: widget.filled
              ? Colors.white.withValues(alpha: 0.2)
              : const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.filled
                ? Colors.white.withValues(alpha: 0.45)
                : const Color(0xFFB9CCFA),
            width: 1.2,
          ),
        ),
        child: Icon(widget.icon, size: 18, color: foreground),
      ),
    );

    final label = Text(
      widget.label,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: foreground,
        fontWeight: FontWeight.w900,
        fontSize: 16,
        height: 1,
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          Feedback.forTap(context);
          SystemSound.play(SystemSoundType.click);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.955 : (_hovered ? 1.025 : 1),
          duration: const Duration(milliseconds: 150),
          curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            height: 52,
            constraints: const BoxConstraints(minWidth: 126),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: background,
              border: Border.all(
                color: widget.filled
                    ? Colors.white.withValues(alpha: 0.72)
                    : (isActive
                          ? const Color(0xFF7FA4F2)
                          : const Color(0xFF9CB7F0)),
                width: isActive ? 2 : 1.5,
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color:
                      (widget.filled
                              ? const Color(0xFF6F8FE2)
                              : const Color(0xFF83A5F2))
                          .withValues(alpha: _pressed ? 0.14 : 0.25),
                  blurRadius: _pressed ? 8 : 18,
                  offset: _pressed ? const Offset(0, 3) : const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withValues(
                    alpha: widget.filled ? 0.36 : 0.95,
                  ),
                  blurRadius: 0,
                  spreadRadius: 2,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.iconOnRight
                  ? <Widget>[label, const Gap(8), icon]
                  : <Widget>[icon, const Gap(8), label],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherIconSelector extends StatelessWidget {
  const _WeatherIconSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  static const List<_WeatherOption> _options = <_WeatherOption>[
    _WeatherOption('sunny', Icons.wb_sunny_rounded, '\uB9D1\uC74C'),
    _WeatherOption('cloudy', Icons.cloud_rounded, '\uD750\uB9BC'),
    _WeatherOption('rainy', Icons.grain_rounded, '\uBE44'),
    _WeatherOption('snowy', Icons.ac_unit_rounded, '\uB208'),
    _WeatherOption('foggy', Icons.foggy, '\uC548\uAC1C'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const _FigmaTinyTag(text: '\uB0A0\uC528'),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _options.map((_WeatherOption option) {
            final isSelected = selected == option.value;
            return Tooltip(
              message: option.label,
              child: _PressableScale(
                onTap: () => onChanged(option.value),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEAF3FF)
                        : Colors.white.withValues(alpha: 0.84),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF8EAEEB)
                          : const Color(0xFFC3DAFF),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppTheme.tacticalBlue.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 46,
                    height: 42,
                    child: Icon(
                      option.icon,
                      color: isSelected ? const Color(0xFF6F92DA) : null,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _WeatherOption {
  const _WeatherOption(this.value, this.icon, this.label);

  final String value;
  final IconData icon;
  final String label;
}

class _DiaryTagScreen extends StatelessWidget {
  const _DiaryTagScreen({
    required this.topLabel,
    required this.bottomLabel,
    required this.cards,
    required this.onBack,
    required this.onNext,
    this.onSelected,
    this.showSkip = false,
  });

  final String topLabel;
  final String bottomLabel;
  final List<_FigmaCardData> cards;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final ValueChanged<String>? onSelected;
  final bool showSkip;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 8 : 28,
        mobile ? 8 : 8,
        mobile ? 8 : 28,
        mobile ? 10 : 14,
      ),
      child: Column(
        children: <Widget>[
          _FigmaPill(text: topLabel),
          Gap(mobile ? 10 : 16),
          Expanded(
            child: mobile
                ? GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.88,
                        ),
                    itemCount: cards.length,
                    itemBuilder: (BuildContext context, int index) {
                      final data = cards[index];
                      return _PressableScale(
                        onTap: () {
                          onSelected?.call(data.label);
                          onNext();
                        },
                        child: _FigmaEmptyCard(data: data),
                      );
                    },
                  )
                : Row(
                    children: cards.map((_FigmaCardData data) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _PressableScale(
                            onTap: () {
                              onSelected?.call(data.label);
                              onNext();
                            },
                            child: _FigmaEmptyCard(data: data),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          Gap(mobile ? 6 : 8),
          Row(
            children: <Widget>[
              _FigmaBackButton(onTap: onBack),
              const Gap(8),
              Expanded(
                child: Center(child: _FigmaTinyTag(text: bottomLabel)),
              ),
              if (showSkip)
                _FigmaSkipButton(onTap: onNext)
              else
                const SizedBox(width: 126),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiaryFinalScreen extends StatelessWidget {
  const _DiaryFinalScreen({
    super.key,
    required this.templates,
    required this.selectedPersonaId,
    required this.personas,
    required this.titleController,
    required this.bodyController,
    required this.tagController,
    required this.titleText,
    required this.weather,
    required this.artStyle,
    required this.artSubStyle,
    required this.selectedStyleTemplateId,
    required this.styleTemplates,
    required this.genre,
    required this.genreSubtype,
    required this.targetCutCount,
    required this.artSubStyleOptions,
    required this.genreSubtypeOptions,
    required this.keywordTags,
    required this.isSaving,
    required this.onArtStyleChanged,
    required this.onArtSubStyleChanged,
    required this.onStyleTemplateChanged,
    required this.onGenreChanged,
    required this.onGenreSubtypeChanged,
    required this.onTargetCutCountChanged,
    required this.onTemplateChanged,
    required this.onGenerate,
    required this.onBack,
    required this.isLoadingTemplates,
    required this.previewImageUrls,
    required this.onDraftChanged,
    required this.onWeatherChanged,
  });

  final List<String> templates;
  final String selectedPersonaId;
  final List<PersonaModel> personas;
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final TextEditingController tagController;
  final String titleText;
  final String weather;
  final String artStyle;
  final String artSubStyle;
  final String selectedStyleTemplateId;
  final List<DiaryStyleTemplateModel> styleTemplates;
  final String genre;
  final String genreSubtype;
  final int targetCutCount;
  final List<String> artSubStyleOptions;
  final List<String> genreSubtypeOptions;
  final List<String> keywordTags;
  final bool isSaving;
  final bool isLoadingTemplates;
  final List<String> previewImageUrls;
  final ValueChanged<String> onArtStyleChanged;
  final ValueChanged<String> onArtSubStyleChanged;
  final ValueChanged<String> onStyleTemplateChanged;
  final ValueChanged<String> onGenreChanged;
  final ValueChanged<String> onGenreSubtypeChanged;
  final ValueChanged<int> onTargetCutCountChanged;
  final ValueChanged<String> onTemplateChanged;
  final VoidCallback onDraftChanged;
  final ValueChanged<String> onWeatherChanged;
  final VoidCallback onGenerate;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final hasTemplates = templates.isNotEmpty;
    final mobile = _isMobileLayout(context);

    if (mobile) {
      return _FinalMobilePager(
        hasTemplates: hasTemplates,
        selectedPersonaId: selectedPersonaId,
        personas: personas,
        titleController: titleController,
        bodyController: bodyController,
        tagController: tagController,
        weather: weather,
        selectedStyleTemplateId: selectedStyleTemplateId,
        styleTemplates: styleTemplates,
        genre: genre,
        genreSubtype: genreSubtype,
        targetCutCount: targetCutCount,
        genreSubtypeOptions: genreSubtypeOptions,
        keywordTags: keywordTags,
        isSaving: isSaving,
        isLoadingTemplates: isLoadingTemplates,
        previewImageUrls: previewImageUrls,
        onWeatherChanged: onWeatherChanged,
        onStyleTemplateChanged: onStyleTemplateChanged,
        onGenreChanged: onGenreChanged,
        onGenreSubtypeChanged: onGenreSubtypeChanged,
        onTargetCutCountChanged: onTargetCutCountChanged,
        onTemplateChanged: onTemplateChanged,
        onDraftChanged: onDraftChanged,
        onGenerate: onGenerate,
        onBack: onBack,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 8 : 28,
        mobile ? 8 : 8,
        mobile ? 8 : 28,
        mobile ? 10 : 14,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final canvasWidth = 1480.0;
          final canvasHeight = 650.0;

          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: canvasWidth,
                height: canvasHeight,
                child: Column(
                  children: <Widget>[
                    const _FigmaPill(
                      text: '\uC77C\uAE30 \uCD5C\uC885 \uC124\uC815',
                    ),
                    const Gap(12),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                            flex: 7,
                            child: _FinalGlassPanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  _FinalSummaryStrip(
                                    titleText: titleController.text,
                                    weather: weather,
                                    artStyle: artStyle,
                                    artSubStyle: artSubStyle,
                                    selectedStyleTemplateId:
                                        selectedStyleTemplateId,
                                    styleTemplates: styleTemplates,
                                    genre: genre,
                                    genreSubtype: genreSubtype,
                                    keywordCount: keywordTags.length,
                                  ),
                                  const Gap(14),
                                  Expanded(
                                    child: _FinalLiveDiaryEditor(
                                      titleController: titleController,
                                      bodyController: bodyController,
                                      tagController: tagController,
                                      weather: weather,
                                      artStyle: artStyle,
                                      artSubStyle: artSubStyle,
                                      selectedStyleTemplateId:
                                          selectedStyleTemplateId,
                                      styleTemplates: styleTemplates,
                                      genre: genre,
                                      genreSubtype: genreSubtype,
                                      artSubStyleOptions: artSubStyleOptions,
                                      genreSubtypeOptions: genreSubtypeOptions,
                                      onWeatherChanged: onWeatherChanged,
                                      onArtStyleChanged: onArtStyleChanged,
                                      onArtSubStyleChanged:
                                          onArtSubStyleChanged,
                                      onStyleTemplateChanged:
                                          onStyleTemplateChanged,
                                      onGenreChanged: onGenreChanged,
                                      onGenreSubtypeChanged:
                                          onGenreSubtypeChanged,
                                      onChanged: onDraftChanged,
                                      mobile: false,
                                    ),
                                  ),
                                  const Gap(14),
                                  _DiaryFinalActionBar(
                                    hasTemplates: hasTemplates,
                                    isSaving: isSaving,
                                    onBack: onBack,
                                    onGenerate: onGenerate,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Gap(18),
                          Expanded(
                            flex: 5,
                            child: _FinalGlassPanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Expanded(
                                    child: _TemplateChoiceSelector(
                                      selectedPersonaId: selectedPersonaId,
                                      personas: personas,
                                      onChanged: onTemplateChanged,
                                      isLoading: isLoadingTemplates,
                                    ),
                                  ),
                                  const Gap(14),
                                  SizedBox(
                                    height: 184,
                                    child: _DiaryWebtoonPreviewCard(
                                      imageUrls: previewImageUrls,
                                      isLoading: isSaving,
                                      title: titleController.text,
                                      body: bodyController.text,
                                      weather: weather,
                                      genre: genre,
                                      genreSubtype: genreSubtype,
                                      keywordTags: keywordTags,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FinalGlassPanel extends StatelessWidget {
  const _FinalGlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFA).withValues(alpha: 0.96),
        border: Border.all(color: const Color(0xFFB9CDEB), width: 1.6),
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
          BoxShadow(
            color: const Color(0xFFEAF3FF).withValues(alpha: 0.70),
            blurRadius: 0,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(painter: const _DiaryPaperLinesPainter()),
            ),
            Padding(padding: const EdgeInsets.all(20), child: child),
          ],
        ),
      ),
    );
  }
}

class _FinalSummaryStrip extends StatelessWidget {
  const _FinalSummaryStrip({
    required this.titleText,
    required this.weather,
    required this.artStyle,
    required this.artSubStyle,
    required this.selectedStyleTemplateId,
    required this.styleTemplates,
    required this.genre,
    required this.genreSubtype,
    required this.keywordCount,
  });

  final String titleText;
  final String weather;
  final String artStyle;
  final String artSubStyle;
  final String selectedStyleTemplateId;
  final List<DiaryStyleTemplateModel> styleTemplates;
  final String genre;
  final String genreSubtype;
  final int keywordCount;

  @override
  Widget build(BuildContext context) {
    final title = titleText.trim().isEmpty
        ? '\uC81C\uBAA9 \uC5C6\uC74C'
        : titleText.trim();
    final selectedTemplate = styleTemplates.where(
      (DiaryStyleTemplateModel item) => item.id == selectedStyleTemplateId,
    );
    final templateName = selectedTemplate.isEmpty
        ? artSubStyle
        : selectedTemplate.first.name;
    final details = <String>[
      _weatherLabel(weather),
      '\uD15C\uD50C\uB9BF: $templateName',
      '$genre / $genreSubtype',
      if (keywordCount > 0) '\uD0A4\uC6CC\uB4DC $keywordCount\uAC1C',
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF).withValues(alpha: 0.96),
        border: Border.all(color: const Color(0xFFAFC5EA), width: 1.2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.auto_stories_rounded,
                  color: Color(0xFF6EA3FF),
                  size: 22,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: details.map((String item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppTheme.tacticalBlue.withValues(alpha: 0.42),
                    ),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      color: AppTheme.ink.withValues(alpha: 0.86),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinalPublishHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.pastelBlue.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.22),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.inventory_2_rounded,
              color: AppTheme.tacticalBlue,
              size: 20,
            ),
            Gap(8),
            Expanded(
              child: Text(
                '\uACF5\uAC1C \uBC94\uC704\uC640 \uC18C\uC7A5 \uC704\uCE58\uB294 \uCD5C\uC885 \uBC1C\uD589\uD560 \uB54C \uC120\uD0DD\uD574\uC694.',
                style: TextStyle(
                  color: AppTheme.tacticalBlue,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinalMobilePager extends StatefulWidget {
  const _FinalMobilePager({
    required this.hasTemplates,
    required this.selectedPersonaId,
    required this.personas,
    required this.titleController,
    required this.bodyController,
    required this.tagController,
    required this.weather,
    required this.selectedStyleTemplateId,
    required this.styleTemplates,
    required this.genre,
    required this.genreSubtype,
    required this.targetCutCount,
    required this.genreSubtypeOptions,
    required this.keywordTags,
    required this.isSaving,
    required this.isLoadingTemplates,
    required this.previewImageUrls,
    required this.onWeatherChanged,
    required this.onStyleTemplateChanged,
    required this.onGenreChanged,
    required this.onGenreSubtypeChanged,
    required this.onTargetCutCountChanged,
    required this.onTemplateChanged,
    required this.onDraftChanged,
    required this.onGenerate,
    required this.onBack,
  });

  final bool hasTemplates;
  final String selectedPersonaId;
  final List<PersonaModel> personas;
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final TextEditingController tagController;
  final String weather;
  final String selectedStyleTemplateId;
  final List<DiaryStyleTemplateModel> styleTemplates;
  final String genre;
  final String genreSubtype;
  final int targetCutCount;
  final List<String> genreSubtypeOptions;
  final List<String> keywordTags;
  final bool isSaving;
  final bool isLoadingTemplates;
  final List<String> previewImageUrls;
  final ValueChanged<String> onWeatherChanged;
  final ValueChanged<String> onStyleTemplateChanged;
  final ValueChanged<String> onGenreChanged;
  final ValueChanged<String> onGenreSubtypeChanged;
  final ValueChanged<int> onTargetCutCountChanged;
  final ValueChanged<String> onTemplateChanged;
  final VoidCallback onDraftChanged;
  final VoidCallback onGenerate;
  final VoidCallback onBack;

  @override
  State<_FinalMobilePager> createState() => _FinalMobilePagerState();
}

class _FinalMobilePagerState extends State<_FinalMobilePager> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final canPublish = widget.hasTemplates && !widget.isSaving;
    PersonaModel? selectedPersona;
    for (final persona in widget.personas) {
      if (persona.id == widget.selectedPersonaId) {
        selectedPersona = persona;
        break;
      }
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final fallbackHeight = MediaQuery.sizeOf(context).height - 56;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : fallbackHeight.clamp(520.0, 760.0);
        return SizedBox(
          height: height,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                bottom: 78,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 5, 14, 18),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                    child: _step == 0
                        ? _FinalMobileDiaryStep(
                            key: const ValueKey<String>('final-diary-step'),
                            titleController: widget.titleController,
                            bodyController: widget.bodyController,
                            weather: widget.weather,
                            selectedPersonaId: widget.selectedPersonaId,
                            personas: widget.personas,
                            isLoadingTemplates: widget.isLoadingTemplates,
                            onWeatherChanged: widget.onWeatherChanged,
                            onTemplateChanged: widget.onTemplateChanged,
                            onChanged: widget.onDraftChanged,
                          )
                        : _FinalMobileSceneStep(
                            key: const ValueKey<String>('final-scene-step'),
                            title: widget.titleController.text,
                            body: widget.bodyController.text,
                            weather: widget.weather,
                            selectedStyleTemplateId:
                                widget.selectedStyleTemplateId,
                            styleTemplates: widget.styleTemplates,
                            genre: widget.genre,
                            genreSubtype: widget.genreSubtype,
                            targetCutCount: widget.targetCutCount,
                            genreSubtypeOptions: widget.genreSubtypeOptions,
                            keywordTags: widget.keywordTags,
                            isSaving: widget.isSaving,
                            previewImageUrls: widget.previewImageUrls,
                            previewPersonaName: selectedPersona?.name,
                            previewPersonaImageUrl:
                                selectedPersona?.imageUrl ??
                                selectedPersona?.baseImageUrl,
                            onStyleTemplateChanged:
                                widget.onStyleTemplateChanged,
                            onGenreChanged: widget.onGenreChanged,
                            onGenreSubtypeChanged: widget.onGenreSubtypeChanged,
                            onTargetCutCountChanged:
                                widget.onTargetCutCountChanged,
                            onChanged: widget.onDraftChanged,
                          ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 8,
                child: _FinalMobileStepBar(
                  step: _step,
                  isSaving: widget.isSaving,
                  canPublish: canPublish,
                  onBack: _step == 0
                      ? widget.onBack
                      : () {
                          setState(() => _step = 0);
                        },
                  onNext: _step == 0
                      ? () {
                          setState(() => _step = 1);
                        }
                      : widget.onGenerate,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FinalMobileDiaryStep extends StatelessWidget {
  const _FinalMobileDiaryStep({
    super.key,
    required this.titleController,
    required this.bodyController,
    required this.weather,
    required this.selectedPersonaId,
    required this.personas,
    required this.isLoadingTemplates,
    required this.onWeatherChanged,
    required this.onTemplateChanged,
    required this.onChanged,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final String weather;
  final String selectedPersonaId;
  final List<PersonaModel> personas;
  final bool isLoadingTemplates;
  final ValueChanged<String> onWeatherChanged;
  final ValueChanged<String> onTemplateChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _FinalMobileCard(
      title: '\uC124\uC815',
      subtitle: '1/2 \uC77C\uAE30\uC640 \uB0A0\uC528',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _FinalMobileLabel(
            icon: Icons.edit_note_rounded,
            text: '\uC77C\uAE30',
          ),
          const Gap(9),
          SizedBox(
            height: 46,
            child: TextField(
              controller: titleController,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.left,
              onChanged: (_) => onChanged(),
              decoration: _finalMobileFlatField('\uC791\uD488 \uC81C\uBAA9'),
            ),
          ),
          const Gap(10),
          SizedBox(
            height: 148,
            child: TextField(
              controller: bodyController,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.38,
              ),
              expands: true,
              maxLines: null,
              textAlign: TextAlign.left,
              textAlignVertical: TextAlignVertical.top,
              onChanged: (_) => onChanged(),
              decoration: _finalMobileFlatField(
                '\uC624\uB298\uC758 \uC7A5\uBA74',
              ),
            ),
          ),
          const Gap(12),
          const _FinalMobileLabel(
            icon: Icons.wb_sunny_rounded,
            text: '\uB0A0\uC528',
          ),
          const Gap(8),
          _FinalMobileWeatherPicker(
            selected: weather,
            onChanged: (String value) {
              onWeatherChanged(value);
              onChanged();
            },
          ),
          const Gap(14),
          const _FinalMobileLabel(
            icon: Icons.face_retouching_natural_rounded,
            text: '\uCE90\uB9AD\uD130',
          ),
          const Gap(8),
          SizedBox(
            height: 112,
            child: _TemplateChoiceSelector(
              selectedPersonaId: selectedPersonaId,
              personas: personas,
              onChanged: onTemplateChanged,
              isLoading: isLoadingTemplates,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalMobileSceneStep extends StatelessWidget {
  const _FinalMobileSceneStep({
    super.key,
    required this.title,
    required this.body,
    required this.weather,
    required this.selectedStyleTemplateId,
    required this.styleTemplates,
    required this.genre,
    required this.genreSubtype,
    required this.targetCutCount,
    required this.genreSubtypeOptions,
    required this.keywordTags,
    required this.isSaving,
    required this.previewImageUrls,
    required this.previewPersonaName,
    required this.previewPersonaImageUrl,
    required this.onStyleTemplateChanged,
    required this.onGenreChanged,
    required this.onGenreSubtypeChanged,
    required this.onTargetCutCountChanged,
    required this.onChanged,
  });

  final String title;
  final String body;
  final String weather;
  final String selectedStyleTemplateId;
  final List<DiaryStyleTemplateModel> styleTemplates;
  final String genre;
  final String genreSubtype;
  final int targetCutCount;
  final List<String> genreSubtypeOptions;
  final List<String> keywordTags;
  final bool isSaving;
  final List<String> previewImageUrls;
  final String? previewPersonaName;
  final String? previewPersonaImageUrl;
  final ValueChanged<String> onStyleTemplateChanged;
  final ValueChanged<String> onGenreChanged;
  final ValueChanged<String> onGenreSubtypeChanged;
  final ValueChanged<int> onTargetCutCountChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _FinalMobileCard(
      title: '\uC124\uC815',
      subtitle: '2/2 \uC7A5\uBA74\uACFC \uCEF7\uC218',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _FinalMobileLabel(
            icon: Icons.tune_rounded,
            text: '\uC7A5\uBA74',
          ),
          const Gap(10),
          _FinalStyleControls(
            genre: genre,
            genreSubtype: genreSubtype,
            targetCutCount: targetCutCount,
            genreSubtypeOptions: genreSubtypeOptions,
            onGenreChanged: (String value) {
              onGenreChanged(value);
              onChanged();
            },
            onGenreSubtypeChanged: (String value) {
              onGenreSubtypeChanged(value);
              onChanged();
            },
            onTargetCutCountChanged: (int value) {
              onTargetCutCountChanged(value);
              onChanged();
            },
          ),
          const Gap(12),
          _FinalStyleTemplateSelector(
            selectedId: selectedStyleTemplateId,
            templates: styleTemplates,
            onChanged: (String value) {
              onStyleTemplateChanged(value);
              onChanged();
            },
          ),
          const Gap(12),
          SizedBox(
            height: 156,
            child: _DiaryWebtoonPreviewCard(
              imageUrls: previewImageUrls,
              isLoading: isSaving,
              title: title,
              body: body,
              weather: weather,
              genre: genre,
              genreSubtype: genreSubtype,
              keywordTags: keywordTags,
              personaName: previewPersonaName,
              personaImageUrl: previewPersonaImageUrl,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalMobileWeatherPicker extends StatelessWidget {
  const _FinalMobileWeatherPicker({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _WeatherIconSelector._options.map((_WeatherOption option) {
          final isSelected = selected == option.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: option.label,
              child: _PressableScale(
                onTap: () => onChanged(option.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 46,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEAF3FF)
                        : Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppTheme.tacticalBlue, width: 1.5)
                        : null,
                  ),
                  child: Icon(
                    option.icon,
                    size: 22,
                    color: isSelected
                        ? AppTheme.tacticalBlue
                        : AppTheme.ink.withValues(alpha: 0.68),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FinalMobileCard extends StatelessWidget {
  const _FinalMobileCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEFA).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC6D8F4)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(painter: const _DiaryPaperLinesPainter()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.ink.withValues(alpha: 0.68),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinalMobileStepBar extends StatelessWidget {
  const _FinalMobileStepBar({
    required this.step,
    required this.isSaving,
    required this.canPublish,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final bool isSaving;
  final bool canPublish;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isPublishStep = step == 1;
    final label = isPublishStep
        ? isSaving
              ? '\uC774\uBBF8\uC9C0 \uC0DD\uC131 \uC911...'
              : '\uBC1C\uD589 \uC124\uC815\uD558\uAE30'
        : '\uB2E4\uC74C';
    return Row(
      children: <Widget>[
        SizedBox(
          width: 60,
          height: 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFE6F0F1),
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppTheme.ink.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AppTheme.ink.withValues(alpha: 0.72),
              tooltip: '\uC774\uC804',
            ),
          ),
        ),
        const Gap(10),
        Expanded(
          child: SizedBox(
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF90A9EE).withValues(alpha: 0.36),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF96ACEF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(
                    0xFFB6C2DE,
                  ).withValues(alpha: 0.76),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.72),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isPublishStep && !canPublish ? null : onNext,
                icon: Icon(
                  isPublishStep
                      ? Icons.publish_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FinalMobileSetupPanel extends StatelessWidget {
  const _FinalMobileSetupPanel({
    required this.titleController,
    required this.bodyController,
    required this.tagController,
    required this.weather,
    required this.artStyle,
    required this.artSubStyle,
    required this.selectedStyleTemplateId,
    required this.styleTemplates,
    required this.genre,
    required this.genreSubtype,
    required this.artSubStyleOptions,
    required this.genreSubtypeOptions,
    required this.onWeatherChanged,
    required this.onArtStyleChanged,
    required this.onArtSubStyleChanged,
    required this.onStyleTemplateChanged,
    required this.onGenreChanged,
    required this.onGenreSubtypeChanged,
    required this.onChanged,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final TextEditingController tagController;
  final String weather;
  final String artStyle;
  final String artSubStyle;
  final String selectedStyleTemplateId;
  final List<DiaryStyleTemplateModel> styleTemplates;
  final String genre;
  final String genreSubtype;
  final List<String> artSubStyleOptions;
  final List<String> genreSubtypeOptions;
  final ValueChanged<String> onWeatherChanged;
  final ValueChanged<String> onArtStyleChanged;
  final ValueChanged<String> onArtSubStyleChanged;
  final ValueChanged<String> onStyleTemplateChanged;
  final ValueChanged<String> onGenreChanged;
  final ValueChanged<String> onGenreSubtypeChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final diaryFields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _FinalMobileLabel(
          icon: Icons.edit_note_rounded,
          text: '\uC77C\uAE30',
        ),
        const Gap(5),
        SizedBox(
          height: 38,
          child: TextField(
            controller: titleController,
            textAlign: TextAlign.left,
            onChanged: (_) => onChanged(),
            decoration: _finalMobileField('\uC791\uD488 \uC81C\uBAA9'),
          ),
        ),
        const Gap(6),
        SizedBox(
          height: 142,
          child: TextField(
            controller: bodyController,
            expands: true,
            maxLines: null,
            textAlign: TextAlign.left,
            textAlignVertical: TextAlignVertical.top,
            onChanged: (_) => onChanged(),
            decoration: _finalMobileField('\uC624\uB298\uC758 \uC7A5\uBA74'),
          ),
        ),
        const Gap(5),
        Text(
          '\uC624\uB298\uC758 \uC7A5\uBA74\uC740 50\uAE00\uC790 \uC774\uC0C1\uC5D0 \uAC10\uC815\uD45C\uD604\uC744 2\uAC1C \uC774\uC0C1 \uC11E\uC5B4\uC918\uC57C \uD6A8\uACFC\uC801\uC785\uB2C8\uB2E4.',
          style: TextStyle(
            color: AppTheme.ink.withValues(alpha: 0.70),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
      ],
    );

    final sceneFields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _FinalMobileLabel(icon: Icons.tune_rounded, text: '\uC7A5\uBA74'),
        const Gap(5),
        Row(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _WeatherIconSelector._options.map((
                    _WeatherOption option,
                  ) {
                    final selected = weather == option.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Tooltip(
                        message: option.label,
                        child: _PressableScale(
                          onTap: () {
                            onWeatherChanged(option.value);
                            onChanged();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 42,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFEAF3FF)
                                  : Colors.white.withValues(alpha: 0.86),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.tacticalBlue
                                    : const Color(0xFFC3DAFF),
                                width: selected ? 1.8 : 1,
                              ),
                              boxShadow: selected
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color: AppTheme.tacticalBlue.withValues(
                                          alpha: 0.16,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : const <BoxShadow>[],
                            ),
                            child: Icon(
                              option.icon,
                              size: 21,
                              color: selected
                                  ? AppTheme.tacticalBlue
                                  : AppTheme.ink.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final styleFields = _FinalStyleTemplateSelector(
      selectedId: selectedStyleTemplateId,
      templates: styleTemplates,
      onChanged: (String value) {
        onStyleTemplateChanged(value);
        onChanged();
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                '\uCD5C\uC885 \uC124\uC815',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '\uBC1C\uD589 \uC804 \uD655\uC778',
              style: TextStyle(
                color: AppTheme.ink.withValues(alpha: 0.68),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const Gap(8),
        diaryFields,
        const Gap(10),
        sceneFields,
        const Gap(10),
        styleFields,
      ],
    );
  }
}

class _FinalMobileLabel extends StatelessWidget {
  const _FinalMobileLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 17, color: AppTheme.tacticalBlue),
        const Gap(7),
        Text(
          text,
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 15.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _FinalStyleTemplateSelector extends StatelessWidget {
  const _FinalStyleTemplateSelector({
    required this.selectedId,
    required this.templates,
    required this.onChanged,
  });

  final String selectedId;
  final List<DiaryStyleTemplateModel> templates;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    final values = templates.isEmpty
        ? _DiaryPageState._fallbackStyleTemplates
        : templates;
    final selected =
        values.any((DiaryStyleTemplateModel item) => item.id == selectedId)
        ? selectedId
        : values.first.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _FinalMobileLabel(
          icon: Icons.style_rounded,
          text: '\uADF8\uB9BC\uCCB4 \uD15C\uD50C\uB9BF',
        ),
        const Gap(6),
        SizedBox(
          height: mobile ? 44 : 48,
          child: DropdownButtonFormField<String>(
            initialValue: selected,
            isExpanded: true,
            decoration: _finalMobileFlatField(
              '\uD15C\uD50C\uB9BF \uC120\uD0DD',
            ),
            items: values.map((DiaryStyleTemplateModel item) {
              return DropdownMenuItem<String>(
                value: item.id,
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),
        ),
        if (!mobile) ...<Widget>[
          const Gap(6),
          _StyleTemplateImageSlot(
            template: values.firstWhere(
              (DiaryStyleTemplateModel item) => item.id == selected,
              orElse: () => values.first,
            ),
          ),
        ],
      ],
    );
  }
}

class _StyleTemplateImageSlot extends StatelessWidget {
  const _StyleTemplateImageSlot({required this.template});

  final DiaryStyleTemplateModel template;

  @override
  Widget build(BuildContext context) {
    final imageUrl = template.previewImageUrl;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 104,
          child: imageUrl == null || imageUrl.trim().isEmpty
              ? const SizedBox.expand()
              : _StorageAwareImage(url: imageUrl),
        ),
      ),
    );
  }
}

class _FinalStyleControls extends StatelessWidget {
  const _FinalStyleControls({
    required this.genre,
    required this.genreSubtype,
    required this.targetCutCount,
    required this.genreSubtypeOptions,
    required this.onGenreChanged,
    required this.onGenreSubtypeChanged,
    required this.onTargetCutCountChanged,
  });

  final String genre;
  final String genreSubtype;
  final int targetCutCount;
  final List<String> genreSubtypeOptions;
  final ValueChanged<String> onGenreChanged;
  final ValueChanged<String> onGenreSubtypeChanged;
  final ValueChanged<int> onTargetCutCountChanged;

  static const List<String> _genres = <String>[
    '\uC720\uCF8C\uD558\uACE0 \uC6C3\uAE34 \uB0A0',
    '\uC9C4\uC9C0\uD558\uACE0 \uCC28\uBD84\uD55C \uB0A0',
    '\uB530\uB73B\uD558\uACE0 \uD589\uBCF5\uD55C \uB0A0',
    '\uBFCC\uB73B\uD558\uACE0 \uC131\uCDE8\uAC10 \uC788\uB294 \uB0A0',
    '\uD798\uB4E4\uACE0 \uC9C0\uCE5C \uB0A0',
  ];

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    final genreDropdown = _FinalCompactDropdown(
      label: '\uC0C1\uC704 \uC5F0\uCD9C',
      value: genre,
      values: _genres,
      onChanged: onGenreChanged,
    );
    final genreControls = mobile
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFEFA).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  genreDropdown,
                  const Gap(7),
                  _FinalSubtypeChecklist(
                    selected: genreSubtype,
                    options: genreSubtypeOptions,
                    onChanged: onGenreSubtypeChanged,
                  ),
                ],
              ),
            ),
          )
        : Row(
            children: <Widget>[
              Expanded(child: genreDropdown),
              const Gap(8),
              Expanded(
                child: _FinalSubtypeChecklist(
                  selected: genreSubtype,
                  options: genreSubtypeOptions,
                  onChanged: onGenreSubtypeChanged,
                ),
              ),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _FinalMobileLabel(
          icon: Icons.movie_filter_rounded,
          text: '\uC5F0\uCD9C',
        ),
        const Gap(6),
        genreControls,
        const Gap(8),
        _FinalCutCountControl(
          value: targetCutCount,
          onChanged: onTargetCutCountChanged,
        ),
      ],
    );
  }
}

class _FinalSubtypeChecklist extends StatelessWidget {
  const _FinalSubtypeChecklist({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  final String selected;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.checklist_rounded,
              size: 14,
              color: AppTheme.ink.withValues(alpha: 0.50),
            ),
            const Gap(5),
            Text(
              '\uC138\uBD80 \uB290\uB08C',
              style: TextStyle(
                color: AppTheme.ink.withValues(alpha: 0.58),
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              '\uC120\uD0DD \uC548 \uD574\uB3C4 \uB428',
              style: TextStyle(
                color: AppTheme.ink.withValues(alpha: 0.38),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Gap(6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: options.map((String option) {
            final checked = selected == option;
            return FilterChip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              showCheckmark: true,
              label: Text(option),
              selected: checked,
              selectedColor: const Color(0xFFEAF4F1),
              checkmarkColor: const Color(0xFF528A78),
              backgroundColor: const Color(0xFFFFFEFA),
              side: BorderSide(
                color: checked
                    ? const Color(0xFF528A78).withValues(alpha: 0.56)
                    : AppTheme.ink.withValues(alpha: 0.11),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (bool value) {
                onChanged(value ? option : '');
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FinalCutCountControl extends StatelessWidget {
  const _FinalCutCountControl({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const values = <int>[0, 1, 4, 8, 16];
    return Row(
      children: <Widget>[
        Text(
          '\uCEF7 \uC218',
          style: TextStyle(
            color: AppTheme.ink.withValues(alpha: 0.74),
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Gap(8),
        Expanded(
          child: SegmentedButtonTheme(
            data: SegmentedButtonThemeData(
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? const Color(0xFFE6F0FF)
                      : Colors.white.withValues(alpha: 0.76);
                }),
                side: WidgetStateProperty.resolveWith((states) {
                  return BorderSide(
                    color: states.contains(WidgetState.selected)
                        ? AppTheme.tacticalBlue.withValues(alpha: 0.72)
                        : AppTheme.ink.withValues(alpha: 0.14),
                  );
                }),
              ),
            ),
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: values
                  .map(
                    (int item) => ButtonSegment<int>(
                      value: item,
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(item == 0 ? 'AI \uB9DE\uCDA4' : '$item'),
                      ),
                    ),
                  )
                  .toList(),
              selected: <int>{values.contains(value) ? value : 0},
              onSelectionChanged: (Set<int> selected) {
                onChanged(selected.first);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FinalCompactDropdown extends StatelessWidget {
  const _FinalCompactDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: DropdownButtonFormField<String>(
        initialValue: values.contains(value) ? value : values.first,
        isExpanded: true,
        decoration: _finalMobileField(
          label,
        ).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10)),
        items: values.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5),
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

InputDecoration _finalMobileField(String hintText) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.90),
    hintStyle: TextStyle(
      color: AppTheme.ink.withValues(alpha: 0.48),
      fontSize: 15,
      fontWeight: FontWeight.w800,
    ),
    alignLabelWithHint: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(
        color: AppTheme.tacticalBlue.withValues(alpha: 0.34),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(
        color: AppTheme.tacticalBlue.withValues(alpha: 0.34),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(
        color: AppTheme.tacticalBlue.withValues(alpha: 0.72),
        width: 1.6,
      ),
    ),
  );
}

InputDecoration _finalMobileFlatField(String hintText) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: const Color(0xFFF9FBFF).withValues(alpha: 0.90),
    hintStyle: TextStyle(
      color: AppTheme.ink.withValues(alpha: 0.55),
      fontSize: 15,
      fontWeight: FontWeight.w900,
    ),
    alignLabelWithHint: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD5E1F4)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD5E1F4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: AppTheme.tacticalBlue.withValues(alpha: 0.42),
        width: 1.2,
      ),
    ),
  );
}

class _FinalLiveDiaryEditor extends StatelessWidget {
  const _FinalLiveDiaryEditor({
    required this.titleController,
    required this.bodyController,
    required this.tagController,
    required this.weather,
    required this.artStyle,
    required this.artSubStyle,
    required this.selectedStyleTemplateId,
    required this.styleTemplates,
    required this.genre,
    required this.genreSubtype,
    required this.artSubStyleOptions,
    required this.genreSubtypeOptions,
    required this.onWeatherChanged,
    required this.onArtStyleChanged,
    required this.onArtSubStyleChanged,
    required this.onStyleTemplateChanged,
    required this.onGenreChanged,
    required this.onGenreSubtypeChanged,
    required this.onChanged,
    required this.mobile,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final TextEditingController tagController;
  final String weather;
  final String artStyle;
  final String artSubStyle;
  final String selectedStyleTemplateId;
  final List<DiaryStyleTemplateModel> styleTemplates;
  final String genre;
  final String genreSubtype;
  final List<String> artSubStyleOptions;
  final List<String> genreSubtypeOptions;
  final ValueChanged<String> onWeatherChanged;
  final ValueChanged<String> onArtStyleChanged;
  final ValueChanged<String> onArtSubStyleChanged;
  final ValueChanged<String> onStyleTemplateChanged;
  final ValueChanged<String> onGenreChanged;
  final ValueChanged<String> onGenreSubtypeChanged;
  final VoidCallback onChanged;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final wideMobile = mobile && MediaQuery.sizeOf(context).width >= 520;
    final logPanel = _FinalEditorSection(
      title: '\uC77C\uAE30 \uB0B4\uC6A9',
      icon: Icons.edit_note_rounded,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: mobile ? 44 : 44,
            child: TextField(
              controller: titleController,
              textAlign: TextAlign.center,
              onChanged: (_) => onChanged(),
              decoration: _figmaField(
                '\uC791\uD488 \uC81C\uBAA9\uC744 \uC785\uB825\uD574 \uC8FC\uC138\uC694',
              ),
            ),
          ),
          const Gap(8),
          SizedBox(
            height: wideMobile ? 58 : (mobile ? 78 : 112),
            child: TextField(
              controller: bodyController,
              expands: true,
              maxLines: null,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.top,
              onChanged: (_) => onChanged(),
              decoration: _figmaField(
                '\uC624\uB298\uC758 \uC7A5\uBA74\uC744 \uC801\uC5B4 \uC8FC\uC138\uC694',
              ).copyWith(contentPadding: const EdgeInsets.all(14)),
            ),
          ),
        ],
      ),
    );

    final metaPanel = _FinalEditorSection(
      title: '\uC7A5\uBA74 \uC124\uC815',
      icon: Icons.tune_rounded,
      child: Column(
        children: <Widget>[
          _WeatherIconSelector(
            selected: weather,
            onChanged: (String value) {
              onWeatherChanged(value);
              onChanged();
            },
          ),
          const Gap(8),
          _FinalStyleTemplateSelector(
            selectedId: selectedStyleTemplateId,
            templates: styleTemplates,
            onChanged: (String value) {
              onStyleTemplateChanged(value);
              onChanged();
            },
          ),
        ],
      ),
    );

    if (mobile) {
      return Column(children: <Widget>[logPanel, const Gap(8), metaPanel]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(flex: 6, child: logPanel),
        const Gap(12),
        Expanded(flex: 4, child: metaPanel),
      ],
    );
  }
}

class _FinalEditorSection extends StatelessWidget {
  const _FinalEditorSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: mobile
            ? Colors.white.withValues(alpha: 0.90)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(mobile ? 10 : 12),
        border: Border.all(
          color: const Color(0xFFB8D2FF).withValues(alpha: mobile ? 0.70 : 1),
          width: mobile ? 1 : 1.3,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(mobile ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Icon(icon, size: 18, color: AppTheme.tacticalBlue),
                const Gap(7),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            Gap(mobile ? 7 : 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _DiaryFinalActionBar extends StatelessWidget {
  const _DiaryFinalActionBar({
    required this.hasTemplates,
    required this.isSaving,
    required this.onBack,
    required this.onGenerate,
    this.compact = false,
  });

  final bool hasTemplates;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onGenerate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = !hasTemplates
        ? '\uCE90\uB9AD\uD130\uB97C \uBA3C\uC800 \uC120\uD0DD\uD574 \uC8FC\uC138\uC694'
        : isSaving
        ? '\uC774\uBBF8\uC9C0 \uC0DD\uC131 \uC911...'
        : '\uCD5C\uC885 \uBC1C\uD589 \uC124\uC815\uD558\uAE30';

    if (compact) {
      return Row(
        children: <Widget>[
          SizedBox(
            width: 48,
            height: 54,
            child: IconButton.filledTonal(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              tooltip: '\uC774\uC804',
            ),
          ),
          const Gap(8),
          Expanded(
            child: SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: isSaving || !hasTemplates ? null : onGenerate,
                icon: const Icon(Icons.publish_rounded),
                label: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7FA8FF), width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 12),
        child: Row(
          children: <Widget>[
            if (!compact) ...<Widget>[
              _FigmaBackButton(onTap: onBack),
              const Gap(12),
            ] else ...<Widget>[
              IconButton.filledTonal(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                tooltip: '\uC774\uC804',
              ),
              const Gap(8),
            ],
            Expanded(
              child: SizedBox(
                height: compact ? 52 : 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSaving || !hasTemplates
                        ? const <BoxShadow>[]
                        : <BoxShadow>[
                            BoxShadow(
                              color: AppTheme.tacticalBlue.withValues(
                                alpha: 0.26,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: FilledButton.icon(
                    onPressed: isSaving || !hasTemplates ? null : onGenerate,
                    icon: const Icon(Icons.publish_rounded),
                    label: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiaryWebtoonPreviewCard extends StatelessWidget {
  const _DiaryWebtoonPreviewCard({
    required this.imageUrls,
    required this.isLoading,
    required this.title,
    required this.body,
    required this.weather,
    required this.genre,
    required this.genreSubtype,
    required this.keywordTags,
    this.personaName,
    this.personaImageUrl,
  });

  final List<String> imageUrls;
  final bool isLoading;
  final String title;
  final String body;
  final String weather;
  final String genre;
  final String genreSubtype;
  final List<String> keywordTags;
  final String? personaName;
  final String? personaImageUrl;

  @override
  Widget build(BuildContext context) {
    final imageUrl = imageUrls.isEmpty ? null : imageUrls.first;
    final mobile = _isMobileLayout(context);
    final ready = body.trim().isNotEmpty;
    final displayTitle = title.trim().isEmpty
        ? '\uC81C\uBAA9 \uC5C6\uB294 \uC77C\uAE30'
        : title.trim();
    final displayBody = body.trim().isEmpty
        ? '\uC77C\uAE30 \uB0B4\uC6A9\uC744 \uC785\uB825\uD558\uBA74 \uC774 \uBBF8\uB9AC\uBCF4\uAE30\uC5D0 \uBC14\uB85C \uBC18\uC601\uB429\uB2C8\uB2E4.'
        : body.trim();
    final personaUrl = personaImageUrl?.trim();
    final hasPersonaImage = personaUrl != null && personaUrl.isNotEmpty;
    final personaLabel = personaName?.trim().isNotEmpty == true
        ? personaName!.trim()
        : '\uC120\uD0DD \uCE90\uB9AD\uD130';
    final tagWidgets = <Widget>[
      _PreviewTag(text: genre),
      if (!mobile && genreSubtype.trim().isNotEmpty)
        _PreviewTag(text: genreSubtype),
      if (!mobile && keywordTags.isNotEmpty)
        _PreviewTag(text: '#${keywordTags.first}'),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        border: Border.all(color: const Color(0xFF8FB6FF), width: 1.2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (imageUrl != null)
              _StorageAwareImage(url: imageUrl)
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      const Color(0xFFF9FCFF),
                      AppTheme.pastelBlue.withValues(alpha: 0.26),
                      AppTheme.pastelRose.withValues(alpha: 0.10),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(mobile ? 12 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            ready
                                ? Icons.auto_awesome_motion_rounded
                                : Icons.edit_note_rounded,
                            size: 18,
                            color: ready
                                ? AppTheme.tacticalBlue
                                : AppTheme.ink.withValues(alpha: 0.72),
                          ),
                          const Gap(6),
                          Expanded(
                            child: Text(
                              ready
                                  ? '\uC0DD\uC131 \uBBF8\uB9AC\uBCF4\uAE30'
                                  : '\uC77C\uAE30\uB97C \uC785\uB825\uD574 \uC8FC\uC138\uC694',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _StatusChip(
                            icon: _weatherIcon(weather),
                            label: _weatherLabel(weather),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    displayTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF4E6FD0),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16.5,
                                    ),
                                  ),
                                  const Gap(6),
                                  Expanded(
                                    child: Text(
                                      displayBody,
                                      maxLines: mobile ? 2 : 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppTheme.ink.withValues(
                                          alpha: 0.88,
                                        ),
                                        height: 1.44,
                                        fontSize: mobile ? 12.8 : 12.8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Gap(10),
                            SizedBox(
                              width: mobile ? 58 : 86,
                              child: Column(
                                children: <Widget>[
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.74,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.tacticalBlue
                                                .withValues(alpha: 0.18),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: hasPersonaImage
                                            ? _StorageAwareImage(
                                                url: personaUrl,
                                              )
                                            : Center(
                                                child: Icon(
                                                  Icons
                                                      .face_retouching_natural_rounded,
                                                  color: AppTheme.tacticalBlue
                                                      .withValues(alpha: 0.70),
                                                  size: 30,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const Gap(4),
                                  Text(
                                    personaLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTheme.ink.withValues(
                                        alpha: 0.78,
                                      ),
                                      fontSize: 10.8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!mobile) ...<Widget>[
                        const Gap(8),
                        Wrap(spacing: 6, runSpacing: 5, children: tagWidgets),
                      ],
                    ],
                  ),
                ),
              ),
            if (imageUrl != null)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: _PreviewImageOverlay(
                  title: displayTitle,
                  weather: weather,
                  tags: tagWidgets.take(mobile ? 3 : 4).toList(),
                ),
              ),
            if (isLoading)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      CircularProgressIndicator(strokeWidth: 2),
                      Gap(12),
                      Text(
                        '\uC6F9\uD230 \uC774\uBBF8\uC9C0 \uC0DD\uC131 \uC911...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF75A8FF),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (imageUrls.length > 1)
              Positioned(
                left: 8,
                top: 8,
                child: _StatusChip(
                  icon: Icons.view_carousel_rounded,
                  label: '${imageUrls.length} CUTS',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewTag extends StatelessWidget {
  const _PreviewTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            text,
            softWrap: true,
            style: const TextStyle(
              color: AppTheme.tacticalBlue,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewImageOverlay extends StatelessWidget {
  const _PreviewImageOverlay({
    required this.title,
    required this.weather,
    required this.tags,
  });

  final String title;
  final String weather;
  final List<Widget> tags;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Gap(6),
                    Icon(
                      _weatherIcon(weather),
                      size: 15,
                      color: AppTheme.tacticalBlue,
                    ),
                  ],
                ),
                if (tags.isNotEmpty) ...<Widget>[
                  const Gap(6),
                  Wrap(spacing: 5, runSpacing: 4, children: tags),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneratedDiarySlideScreen extends StatefulWidget {
  const _GeneratedDiarySlideScreen({
    required this.panels,
    required this.imageUrls,
    required this.onBack,
    required this.onRetryPanel,
    required this.onDone,
  });

  final List<DiaryPanelModel> panels;
  final List<String> imageUrls;
  final VoidCallback onBack;
  final Future<void> Function(DiaryPanelModel panel, String retryFeedback)
  onRetryPanel;
  final VoidCallback onDone;

  @override
  State<_GeneratedDiarySlideScreen> createState() =>
      _GeneratedDiarySlideScreenState();
}

class _GeneratedDiarySlideScreenState
    extends State<_GeneratedDiarySlideScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  String? _retryingPanelId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToSlide(int target, int length) {
    if (target < 0 || target >= length) {
      return;
    }
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = _PanelSlideData.fromPanels(
      panels: widget.panels,
      fallbackImageUrls: widget.imageUrls,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(44, 12, 44, 20),
      child: Column(
        children: <Widget>[
          const _FigmaPill(text: 'GENERATED DIARY'),
          const Gap(14),
          Expanded(
            child: slides.isEmpty
                ? const Center(
                    child: Text(
                      '\uC544\uC9C1 \uC0DD\uC131\uB41C \uC774\uBBF8\uC9C0\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      PageView.builder(
                        controller: _controller,
                        onPageChanged: (int value) {
                          setState(() => _index = value);
                        },
                        itemCount: slides.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Center(
                            child: AspectRatio(
                              aspectRatio: 2 / 3,
                              child: _WebtoonPanelCard(slide: slides[index]),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
          const Gap(12),
          if (slides.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _SlideStepButton(
                  icon: Icons.chevron_left_rounded,
                  label: '\uC774\uC804 \uCEF7',
                  enabled: _index > 0,
                  onTap: () => _goToSlide(_index - 1, slides.length),
                ),
                const Gap(12),
                ...List<Widget>.generate(slides.length, (int index) {
                  final selected = index == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: selected ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.tacticalBlue
                          : AppTheme.pastelBlue.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
                const Gap(12),
                _SlideStepButton(
                  icon: Icons.chevron_right_rounded,
                  label: '\uB2E4\uC74C \uCEF7',
                  enabled: _index < slides.length - 1,
                  onTap: () => _goToSlide(_index + 1, slides.length),
                ),
              ],
            ),
          if (slides.isNotEmpty && slides[_index].panel != null) ...<Widget>[
            const Gap(10),
            _PressableScale(
              onTap: () async {
                if (_retryingPanelId != null) {
                  return;
                }
                final panel = slides[_index].panel!;
                final retryFeedback = await _askRetryFeedback(context);
                if (retryFeedback == null) {
                  return;
                }
                setState(() => _retryingPanelId = panel.id);
                try {
                  await widget.onRetryPanel(panel, retryFeedback);
                } finally {
                  if (mounted) {
                    setState(() => _retryingPanelId = null);
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF9FB9F6)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppTheme.tacticalBlue.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (_retryingPanelId == slides[_index].panel!.id)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.refresh_rounded, size: 20),
                    const Gap(8),
                    Text(
                      _retryingPanelId == slides[_index].panel!.id
                          ? '\uC774\uBBF8\uC9C0 \uC7AC\uC0DD\uC131 \uC911...'
                          : '\uC774\uBBF8\uC9C0 \uC7AC\uC0DD\uC131',
                      style: const TextStyle(
                        color: Color(0xFF5B78D6),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Gap(12),
          Row(
            children: <Widget>[
              OutlinedButton(
                onPressed: widget.onBack,
                child: const Text('\uC774\uC804'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: widget.onDone,
                child: const Text('\uC644\uB8CC'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String?> _askRetryFeedback(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('\uCE90\uB9AD\uD130 \uC218\uC815'),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText:
                  '\uBC14\uAFB8\uACE0 \uC2F6\uC740 \uC810\uC744 \uC801\uC5B4 \uC8FC\uC138\uC694. \uC608: \uD45C\uC815\uC740 \uBC1D\uAC8C, \uBC30\uACBD\uC740 \uAD50\uC2E4\uB85C',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('\uCDE8\uC18C'),
            ),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('\uC218\uC815'),
            ),
          ],
        );
      },
    );
  }
}

class _PanelSlideData {
  const _PanelSlideData({
    required this.imageUrl,
    required this.index,
    this.panel,
    this.panelType,
    this.dialogue,
    this.prompt,
    this.tags = const <String>[],
  });

  final String imageUrl;
  final int index;
  final DiaryPanelModel? panel;
  final String? panelType;
  final String? dialogue;
  final String? prompt;
  final List<String> tags;

  static List<_PanelSlideData> fromPanels({
    required List<DiaryPanelModel> panels,
    required List<String> fallbackImageUrls,
  }) {
    final slides = _diaryPanelsReadingOrder(panels)
        .map(
          (DiaryPanelModel panel) => _PanelSlideData(
            imageUrl: panel.imageUrl!,
            index: panel.panelOrder,
            panel: panel,
            panelType: panel.panelType,
            dialogue: panel.dialogue,
            prompt: panel.prompt,
            tags: _extractPanelTags(panel.prompt),
          ),
        )
        .toList();

    if (slides.isNotEmpty) {
      return slides;
    }

    return _diaryImageUrlsReadingOrder(fallbackImageUrls)
        .asMap()
        .entries
        .map(
          (MapEntry<int, String> entry) =>
              _PanelSlideData(imageUrl: entry.value, index: entry.key),
        )
        .toList();
  }
}

List<String> _extractPanelTags(String? prompt) {
  if (prompt == null || prompt.trim().isEmpty) {
    return const <String>[];
  }

  final matches = RegExp(r'#([^\s,;|]+)').allMatches(prompt);
  return matches
      .map((RegExpMatch match) => match.group(1))
      .whereType<String>()
      .where((String tag) => tag.trim().isNotEmpty)
      .toSet()
      .take(4)
      .toList();
}

class _WebtoonPanelCard extends StatelessWidget {
  const _WebtoonPanelCard({required this.slide});

  final _PanelSlideData slide;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.tacticalBlue, width: 1.6),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _StorageAwareImage(url: slide.imageUrl),
      ),
    );
  }
}

class _ImageUrlSlideDeck extends StatefulWidget {
  const _ImageUrlSlideDeck({required this.imageUrls, this.panels = const []});

  final List<String> imageUrls;
  final List<DiaryPanelModel> panels;

  @override
  State<_ImageUrlSlideDeck> createState() => _ImageUrlSlideDeckState();
}

class _ImageUrlSlideDeckState extends State<_ImageUrlSlideDeck> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToSlide(int target, int length) {
    if (target < 0 || target >= length) {
      return;
    }
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = _PanelSlideData.fromPanels(
      panels: widget.panels,
      fallbackImageUrls: widget.imageUrls,
    );

    if (slides.isEmpty) {
      return const Center(
        child: Text(
          '\uD45C\uC2DC\uD560 \uC774\uBBF8\uC9C0\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              PageView.builder(
                controller: _controller,
                onPageChanged: (int value) => setState(() => _index = value),
                itemCount: slides.length,
                itemBuilder: (BuildContext context, int index) {
                  return Center(
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: _WebtoonPanelCard(slide: slides[index]),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const Gap(12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _SlideStepButton(
              icon: Icons.chevron_left_rounded,
              label: '\uC774\uC804 \uCEF7',
              enabled: _index > 0,
              onTap: () => _goToSlide(_index - 1, slides.length),
            ),
            const Gap(12),
            ...List<Widget>.generate(slides.length, (int index) {
              final selected = index == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: selected ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.tacticalBlue
                      : AppTheme.pastelBlue.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
            const Gap(12),
            _SlideStepButton(
              icon: Icons.chevron_right_rounded,
              label: '\uB2E4\uC74C \uCEF7',
              enabled: _index < slides.length - 1,
              onTap: () => _goToSlide(_index + 1, slides.length),
            ),
          ],
        ),
      ],
    );
  }
}

class _SlideStepButton extends StatelessWidget {
  const _SlideStepButton({
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
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.36,
      child: FilledButton.tonalIcon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 20),
        label: Text(label, textAlign: TextAlign.center),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.92),
          foregroundColor: AppTheme.tacticalBlue,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.66),
          disabledForegroundColor: AppTheme.ink.withValues(alpha: 0.34),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(84, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(
              color: AppTheme.tacticalBlue.withValues(alpha: 0.42),
            ),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _StorageAwareImage extends StatelessWidget {
  const _StorageAwareImage({
    required this.url,
    this.fallback = const _PostImageFallback(),
    this.fit = BoxFit.cover,
  });

  final String url;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return fallback;
    }

    return Image.network(
      url,
      fit: fit,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        final storagePath = _storagePathFromPublicUrl(url);
        if (storagePath == null || !SupabaseRuntime.isConfigured) {
          return fallback;
        }

        return FutureBuilder<Uint8List>(
          future: Supabase.instance.client.storage
              .from('diary-assets')
              .download(storagePath),
          builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            final bytes = snapshot.data;
            if (bytes == null || bytes.isEmpty) {
              return fallback;
            }
            return Image.memory(bytes, fit: fit);
          },
        );
      },
    );
  }

  String? _storagePathFromPublicUrl(String imageUrl) {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null) {
      return null;
    }

    const marker = '/storage/v1/object/public/diary-assets/';
    final index = uri.path.indexOf(marker);
    if (index < 0) {
      return null;
    }

    final encodedPath = uri.path.substring(index + marker.length);
    return Uri.decodeComponent(encodedPath);
  }
}

String? _storagePathFromDiaryAssetPublicUrl(String imageUrl) {
  final uri = Uri.tryParse(imageUrl);
  if (uri == null) {
    return null;
  }

  const marker = '/storage/v1/object/public/diary-assets/';
  final index = uri.path.indexOf(marker);
  if (index < 0) {
    return null;
  }

  final encodedPath = uri.path.substring(index + marker.length);
  return Uri.decodeComponent(encodedPath);
}

class _TemplateChoiceSelector extends StatefulWidget {
  const _TemplateChoiceSelector({
    required this.selectedPersonaId,
    required this.personas,
    required this.onChanged,
    this.isLoading = false,
  });

  final String selectedPersonaId;
  final List<PersonaModel> personas;
  final ValueChanged<String> onChanged;
  final bool isLoading;

  @override
  State<_TemplateChoiceSelector> createState() =>
      _TemplateChoiceSelectorState();
}

class _TemplateChoiceSelectorState extends State<_TemplateChoiceSelector> {
  String _scope = 'mine';

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final scopedPersonas = widget.personas.where((PersonaModel persona) {
      if (_scope == 'mine') {
        return persona.userId == currentUserId;
      }
      return persona.userId != currentUserId &&
          (persona.isPublic || persona.templateVisibility == 'followers');
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (!mobile) ...<Widget>[
          const _FigmaTinyTag(text: '\uCE90\uB9AD\uD130 \uC120\uD0DD'),
          const Gap(6),
        ],
        SegmentedButtonTheme(
          data: SegmentedButtonThemeData(
            style: ButtonStyle(
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? AppTheme.ink
                    : AppTheme.ink.withValues(alpha: 0.78);
              }),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? const Color(0xFFE6F0FF)
                    : Colors.white.withValues(alpha: mobile ? 0.72 : 0.90);
              }),
              side: WidgetStateProperty.resolveWith((states) {
                return BorderSide(
                  color: states.contains(WidgetState.selected)
                      ? AppTheme.tacticalBlue.withValues(alpha: 0.72)
                      : AppTheme.ink.withValues(alpha: mobile ? 0.12 : 0.28),
                  width: states.contains(WidgetState.selected) ? 1.3 : 1,
                );
              }),
            ),
          ),
          child: SegmentedButton<String>(
            segments: <ButtonSegment<String>>[
              ButtonSegment<String>(
                value: 'mine',
                icon: mobile ? null : Icon(Icons.bookmark_rounded),
                label: Text('\uB0B4 \uCE90\uB9AD\uD130'),
              ),
              ButtonSegment<String>(
                value: 'shared',
                icon: mobile ? null : Icon(Icons.public_rounded),
                label: Text('\uACF5\uC720 \uCE90\uB9AD\uD130'),
              ),
            ],
            selected: <String>{_scope},
            onSelectionChanged: (Set<String> values) {
              setState(() => _scope = values.first);
              final filtered = widget.personas.where((PersonaModel persona) {
                if (values.first == 'mine') {
                  return persona.userId == currentUserId;
                }
                return persona.userId != currentUserId &&
                    (persona.isPublic ||
                        persona.templateVisibility == 'followers');
              }).toList();
              if (filtered.isNotEmpty) {
                widget.onChanged(filtered.first.id);
              }
            },
          ),
        ),
        const Gap(6),
        if (widget.isLoading) ...<Widget>[
          const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          const Gap(8),
        ],
        if (widget.personas.isEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.62),
              border: Border.all(color: const Color(0xFFBFD9FF)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Center(
                child: Text(
                  '\uCE90\uB9AD\uD130 \uD0ED\uC5D0\uC11C \uBA3C\uC800 \uCE90\uB9AD\uD130\uB97C \uB9CC\uB4E4\uC5B4 \uC8FC\uC138\uC694.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF5B8EEB),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          )
        else if (scopedPersonas.isEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.62),
              border: Border.all(color: const Color(0xFFBFD9FF)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Center(
                child: Text(
                  _scope == 'mine'
                      ? '\uB0B4 \uCE90\uB9AD\uD130\uAC00 \uC544\uC9C1 \uC5C6\uC2B5\uB2C8\uB2E4.'
                      : '\uACF5\uC720 \uCE90\uB9AD\uD130\uAC00 \uC544\uC9C1 \uC5C6\uC2B5\uB2C8\uB2E4.',
                  style: const TextStyle(
                    color: Color(0xFF5B8EEB),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: PageView.builder(
              controller: PageController(
                viewportFraction: mobile ? 0.36 : 0.48,
              ),
              padEnds: false,
              itemCount: scopedPersonas.length,
              onPageChanged: (int index) {
                widget.onChanged(scopedPersonas[index].id);
              },
              itemBuilder: (BuildContext context, int index) {
                final persona = scopedPersonas[index];
                final imageUrl = persona.imageUrl ?? persona.baseImageUrl;
                final isSelected = widget.selectedPersonaId == persona.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _PressableScale(
                    onTap: () => widget.onChanged(persona.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEAF3FF)
                            : Colors.white.withValues(alpha: 0.76),
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFF6EA3FF),
                                width: 1.7,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl == null || imageUrl.isEmpty
                                    ? const Center(
                                        child: Icon(
                                          Icons.face_retouching_natural_rounded,
                                          color: Color(0xFF8BB9FF),
                                          size: 42,
                                        ),
                                      )
                                    : _StorageAwareImage(url: imageUrl),
                              ),
                            ),
                            const Gap(5),
                            Text(
                              persona.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.ink,
                                fontSize: isSelected ? 14.5 : 13.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (!mobile) ...<Widget>[
                              const Gap(2),
                              Text(
                                _scope == 'mine'
                                    ? '\uB0B4 \uCE90\uB9AD\uD130'
                                    : '\uACF5\uC720 \uCE90\uB9AD\uD130',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.ink.withValues(alpha: 0.82),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SaveModeSelector extends StatelessWidget {
  const _SaveModeSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButtonTheme(
        data: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.selected)
                  ? const Color(0xFFDDEBFF)
                  : Colors.white.withValues(alpha: 0.92);
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.selected)
                  ? AppTheme.ink
                  : AppTheme.ink.withValues(alpha: 0.72);
            }),
            side: WidgetStateProperty.resolveWith((states) {
              return BorderSide(
                color: states.contains(WidgetState.selected)
                    ? const Color(0xFF6EA3FF)
                    : AppTheme.tacticalBlue.withValues(alpha: 0.42),
                width: states.contains(WidgetState.selected) ? 1.8 : 1.1,
              );
            }),
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontWeight: FontWeight.w900),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            ),
          ),
        ),
        child: SegmentedButton<String>(
          showSelectedIcon: true,
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(
              value: 'share',
              icon: Icon(Icons.ios_share_rounded),
              label: Text('\uC804\uCCB4 \uACF5\uAC1C'),
            ),
            ButtonSegment<String>(
              value: 'followers',
              icon: Icon(Icons.people_alt_rounded),
              label: Text('\uD314\uB85C\uC6CC \uACF5\uAC1C'),
            ),
            ButtonSegment<String>(
              value: 'archive',
              icon: Icon(Icons.inventory_2_rounded),
              label: Text('\uC18C\uC7A5'),
            ),
          ],
          selected: <String>{selected},
          onSelectionChanged: (Set<String> values) {
            Feedback.forTap(context);
            SystemSound.play(SystemSoundType.click);
            onChanged(values.first);
          },
        ),
      ),
    );
  }
}

String _visibilityFromSaveMode(String saveMode) {
  return switch (saveMode) {
    'share' => 'public',
    'followers' => 'followers',
    _ => 'private',
  };
}

String _saveModeFromVisibility(String visibility) {
  return switch (visibility) {
    'public' => 'share',
    'followers' => 'followers',
    _ => 'archive',
  };
}

class _ArchiveScreen extends StatelessWidget {
  const _ArchiveScreen({
    required this.albums,
    required this.albumDiaryCounts,
    required this.albumDiariesByTitle,
    required this.selectedAlbum,
    required this.isLoading,
    required this.controller,
    required this.onBack,
    required this.onCreateAlbum,
    required this.onAlbumSelected,
    required this.onDeleteAlbum,
    required this.onOpenDiary,
    required this.onRemoveDiary,
    required this.onDeleteDiary,
    required this.onRefresh,
  });

  final List<String> albums;
  final Map<String, int> albumDiaryCounts;
  final Map<String, List<DiaryModel>> albumDiariesByTitle;
  final String? selectedAlbum;
  final bool isLoading;
  final TextEditingController controller;
  final VoidCallback onBack;
  final ValueChanged<String> onCreateAlbum;
  final ValueChanged<String> onAlbumSelected;
  final Future<void> Function(String albumTitle) onDeleteAlbum;
  final ValueChanged<DiaryModel> onOpenDiary;
  final Future<void> Function(String albumTitle, DiaryModel diary)
  onRemoveDiary;
  final Future<void> Function(String albumTitle, DiaryModel diary)
  onDeleteDiary;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 12 : 46,
        mobile ? 10 : 18,
        mobile ? 12 : 46,
        mobile ? 78 : 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: mobile ? double.infinity : 1120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _FigmaBackButton(onTap: onBack),
                  const Gap(12),
                  const _FigmaPill(text: '\uC568\uBC94 \uB9CC\uB4E4\uAE30'),
                ],
              ),
              const Gap(16),
              mobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextField(
                          controller: controller,
                          decoration: _finalMobileField(
                            '\uC568\uBC94 \uC774\uB984',
                          ),
                          onSubmitted: onCreateAlbum,
                        ),
                        const Gap(8),
                        SizedBox(
                          height: 44,
                          child: FilledButton.icon(
                            onPressed: () => onCreateAlbum(controller.text),
                            icon: const Icon(Icons.create_new_folder_rounded),
                            label: const Text('\uB9CC\uB4E4\uAE30'),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: _figmaField(
                              '\uC568\uBC94 \uC774\uB984',
                            ),
                            onSubmitted: onCreateAlbum,
                          ),
                        ),
                        const Gap(10),
                        FilledButton.icon(
                          onPressed: () => onCreateAlbum(controller.text),
                          icon: const Icon(Icons.create_new_folder_rounded),
                          label: const Text('\uB9CC\uB4E4\uAE30'),
                        ),
                      ],
                    ),
              const Gap(18),
              Expanded(
                child: albums.isEmpty
                    ? const Center(
                        child: Text(
                          '\uC544\uC9C1 \uC568\uBC94\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: mobile ? 180 : 210,
                          mainAxisSpacing: mobile ? 10 : 14,
                          crossAxisSpacing: mobile ? 10 : 14,
                          childAspectRatio: mobile ? 1.18 : 1.45,
                        ),
                        itemCount: albums.length,
                        itemBuilder: (BuildContext context, int index) {
                          final albumTitle = albums[index];
                          final diaryCount = albumDiaryCounts[albumTitle] ?? 0;
                          final isSelected = selectedAlbum == albumTitle;
                          return _LifeFourCutAlbumCard(
                            title: albumTitle,
                            diaryCount: diaryCount,
                            isSelected: isSelected,
                            onTap: () {
                              onAlbumSelected(albumTitle);
                              _showAlbumDiariesDialog(context, albumTitle);
                            },
                            onDelete: () => onDeleteAlbum(albumTitle),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlbumDiariesDialog(BuildContext context, String albumTitle) {
    final diaries = albumDiariesByTitle[albumTitle] ?? const <DiaryModel>[];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: _LifeFourCutAlbumInteriorFrame(
              albumTitle: albumTitle,
              isLoading: isLoading,
              isEmpty: diaries.isEmpty,
              onRefresh: () {
                Navigator.of(context).pop();
                unawaited(onRefresh());
              },
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : diaries.isEmpty
                  ? const Center(
                      child: Text(
                        '\uC800\uC7A5\uB41C \uC77C\uAE30\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                      itemCount: diaries.length,
                      separatorBuilder: (_, _) => const Gap(10),
                      itemBuilder: (BuildContext context, int index) {
                        final diary = diaries[index];
                        return _ArchiveDiaryTile(
                          diary: diary,
                          onOpen: () => onOpenDiary(diary),
                          onRemove: () => onRemoveDiary(albumTitle, diary),
                          onDelete: () => onDeleteDiary(albumTitle, diary),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _ArchiveDiaryTile extends StatelessWidget {
  const _ArchiveDiaryTile({
    required this.diary,
    required this.onOpen,
    required this.onRemove,
    required this.onDelete,
  });

  final DiaryModel diary;
  final VoidCallback onOpen;
  final Future<void> Function() onRemove;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final title = diary.title?.trim().isNotEmpty == true
        ? diary.title!.trim()
        : '\uC81C\uBAA9 \uC5C6\uB294 \uC77C\uAE30';
    final dateText = diary.diaryAt == null
        ? ''
        : '${diary.diaryAt!.year}.${diary.diaryAt!.month.toString().padLeft(2, '0')}.${diary.diaryAt!.day.toString().padLeft(2, '0')}';

    return _PressableScale(
      onTap: onOpen,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          border: Border.all(color: const Color(0xFFC7DFFF)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 74,
                height: 74,
                child: _ArchiveDiaryPreview(
                  imageUrls: _diaryImageUrlsReadingOrder(diary.imageUrls),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF5B8EEB),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      [
                        dateText,
                        _weatherLabel(diary.weather.value),
                      ].where((String text) => text.isNotEmpty).join(' / '),
                      style: const TextStyle(
                        color: Color(0xFF8EA0C0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      diary.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF526071)),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: '\uBCF4\uAD00\uD568 \uBA54\uB274',
                onSelected: (String value) async {
                  if (value == 'remove') {
                    await onRemove();
                  } else if (value == 'delete') {
                    await onDelete();
                  }
                },
                itemBuilder: (BuildContext context) {
                  return const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'remove',
                      child: Text('\uC568\uBC94\uC5D0\uC11C \uBE7C\uAE30'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('\uC77C\uAE30 \uC0AD\uC81C'),
                    ),
                  ];
                },
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LifeFourCutAlbumInteriorFrame extends StatelessWidget {
  const _LifeFourCutAlbumInteriorFrame({
    required this.albumTitle,
    required this.isLoading,
    required this.isEmpty,
    required this.onRefresh,
    required this.child,
  });

  final String albumTitle;
  final bool isLoading;
  final bool isEmpty;
  final VoidCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF232936),
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                _FilmPerforationDot(active: !isEmpty),
                const Gap(8),
                Expanded(
                  child: Text(
                    albumTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  color: Colors.white,
                  tooltip: '\uC0C8\uB85C\uACE0\uCE68',
                ),
              ],
            ),
            const Gap(8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _FilmPerforationRail(),
                  const Gap(10),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.pastelBlue.withValues(alpha: 0.75),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: child,
                      ),
                    ),
                  ),
                  const Gap(10),
                  const _FilmPerforationRail(),
                ],
              ),
            ),
            const Gap(10),
            Text(
              isLoading
                  ? 'PRINTING...'
                  : isEmpty
                  ? 'EMPTY ALBUM'
                  : 'MY DIARY FILM',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilmPerforationRail extends StatelessWidget {
  const _FilmPerforationRail();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List<Widget>.generate(
          8,
          (int index) => Container(
            width: 10,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilmPerforationDot extends StatelessWidget {
  const _FilmPerforationDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: active ? AppTheme.pastelGreen : AppTheme.pastelBlue,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: (active ? AppTheme.pastelGreen : AppTheme.pastelBlue)
                .withValues(alpha: 0.55),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}

class _LifeFourCutAlbumCard extends StatelessWidget {
  const _LifeFourCutAlbumCard({
    required this.title,
    required this.diaryCount,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final int diaryCount;
  final bool isSelected;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.pastelBlue.withValues(alpha: 0.46)
              : Colors.white.withValues(alpha: 0.82),
          border: Border.all(
            color: isSelected ? AppTheme.tacticalBlue : const Color(0xFFBFD9FF),
            width: isSelected ? 1.8 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        const Color(0xFFFFFFFF).withValues(alpha: 0.72),
                        AppTheme.pastelBlue.withValues(alpha: 0.18),
                        AppTheme.pastelGreen.withValues(alpha: 0.16),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: PopupMenuButton<String>(
                  tooltip: '\uC568\uBC94 \uBA54\uB274',
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: AppTheme.tacticalBlue.withValues(alpha: 0.60),
                  ),
                  onSelected: (String value) async {
                    if (value == 'delete') {
                      await onDelete();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('\uC568\uBC94 \uC0AD\uC81C'),
                      ),
                    ];
                  },
                ),
              ),
              Positioned(
                right: 12,
                bottom: 10,
                child: Icon(
                  Icons.folder_rounded,
                  color: AppTheme.tacticalBlue.withValues(alpha: 0.22),
                  size: 32,
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF5B78D6),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const Gap(6),
                      Text(
                        '$diaryCount\uAC1C \uC77C\uAE30',
                        style: const TextStyle(
                          color: Color(0xFF8EA0C0),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.tacticalBlue
                        : const Color(0xFFC7DFFF),
                    shape: BoxShape.circle,
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

class _ArchiveDiaryPreview extends StatelessWidget {
  const _ArchiveDiaryPreview({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    String? url;
    for (final item in imageUrls) {
      if (item.trim().isNotEmpty) {
        url = item;
        break;
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          border: Border.all(color: const Color(0xFF9FC4FF)),
        ),
        child: url == null || url.isEmpty
            ? const Icon(Icons.auto_stories_rounded, color: Color(0xFF8BB9FF))
            : _StorageAwareImage(url: url),
      ),
    );
  }
}

String _weatherLabel(String value) {
  return switch (value) {
    'cloudy' => '\uD750\uB9BC',
    'rainy' => '\uBE44',
    'snowy' => '\uB208',
    'foggy' => '\uC548\uAC1C',
    _ => '\uB9D1\uC74C',
  };
}

IconData _weatherIcon(String value) {
  return switch (value) {
    'cloudy' => Icons.cloud_rounded,
    'rainy' => Icons.grain_rounded,
    'snowy' => Icons.ac_unit_rounded,
    'foggy' => Icons.foggy,
    _ => Icons.wb_sunny_rounded,
  };
}

String _socialTagLabel(String value) {
  return switch (value) {
    'card_slide' ||
    'image_focus' ||
    'qa_slide' ||
    'reaction_focus' => '\uCE74\uB4DC \uC2AC\uB77C\uC774\uB4DC',
    'comics_ld' => '\uADF9\uD654\uD615',
    'anime_ld' => '\uC560\uB2C8\uD615',
    'comics_sd' => '\uCE90\uC8FC\uC5BC \uB9CC\uD654\uD615',
    'anime_sd' => '\uCE90\uC8FC\uC5BC \uB9CC\uD654\uD615',
    'simple_2d' => '\uCE90\uB9AD\uD130\uD615',
    'realistic_3d' => '\uC785\uCCB4 \uB80C\uB354\uB9C1',
    'daily_comic' => '\uC720\uCF8C\uD558\uACE0 \uC6C3\uAE34 \uB0A0',
    'serious' => '\uC9C4\uC9C0\uD558\uACE0 \uCC28\uBD84\uD55C \uB0A0',
    'fantasy_action' => '\uAC1C\uADF8/\uC561\uC158',
    'healing_romance' => '\uB530\uB73B\uD558\uACE0 \uD589\uBCF5\uD55C \uB0A0',
    'growth' =>
      '\uBFCC\uB73B\uD558\uACE0 \uC131\uCDE8\uAC10 \uC788\uB294 \uB0A0',
    'hard_day' => '\uD798\uB4E4\uACE0 \uC9C0\uCE5C \uB0A0',
    _ => value,
  };
}

List<String> _socialDisplayTagsForPost(SocialFeedItemModel post) {
  return <String>[
    _socialDisplayTagText(post.artStyle.value),
    _socialDisplayTagText(post.genre.value),
  ];
}

String _socialDisplayTagText(String value) => _socialTagLabel(value);

String _filterChipLabel(String value) {
  return switch (value) {
    'comics_ld' => '\uADF9\uD654',
    'anime_ld' => '\uC560\uB2C8',
    'comics_sd' || 'anime_sd' => '\uCE90\uC8FC\uC5BC',
    'simple_2d' => '\uCE90\uB9AD\uD130',
    'realistic_3d' => '3D',
    'daily_comic' => '\uC720\uCF8C',
    'serious' => '\uC9C4\uC9C0',
    'healing_romance' => '\uB530\uB73B',
    'growth' => '\uBFCC\uB73B',
    'hard_day' => '\uC9C0\uCE5C',
    _ => _socialDisplayTagText(value),
  };
}

String _socialTagText(String value) => _socialTagLabel(value);

IconData _socialTagIcon(String value) {
  return switch (value) {
    'image_focus' => Icons.image_rounded,
    'qa_slide' => Icons.forum_rounded,
    'reaction_focus' => Icons.sentiment_very_satisfied_rounded,
    'comics_ld' || 'comics_sd' => Icons.auto_stories_rounded,
    'anime_ld' || 'anime_sd' => Icons.star_rounded,
    'simple_2d' => Icons.favorite_rounded,
    'realistic_3d' => Icons.view_in_ar_rounded,
    'daily_comic' => Icons.wb_sunny_rounded,
    'serious' => Icons.nights_stay_rounded,
    'fantasy_action' => Icons.bolt_rounded,
    'healing_romance' => Icons.local_florist_rounded,
    'growth' => Icons.emoji_events_rounded,
    'hard_day' => Icons.volunteer_activism_rounded,
    _ => Icons.sell_rounded,
  };
}

class _SocialPostTag extends StatelessWidget {
  const _SocialPostTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.pastelBlue.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.26),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 170),
          child: Text(
            text,
            textAlign: TextAlign.center,
            softWrap: true,
            style: const TextStyle(
              color: AppTheme.tacticalBlue,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _FigmaGradientButton extends StatelessWidget {
  const _FigmaGradientButton({
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
    this.icon,
  });

  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    final effectiveColors = colors;
    return _PressableScale(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: effectiveColors),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: mobile ? 0.10 : 0.18),
              blurRadius: mobile ? 10 : 20,
              offset: Offset(0, mobile ? 5 : 13),
            ),
            BoxShadow(
              color: colors.first.withValues(alpha: mobile ? 0.13 : 0.24),
              blurRadius: mobile ? 12 : 24,
              offset: Offset(mobile ? -4 : -8, mobile ? 3 : 6),
            ),
            BoxShadow(
              color: colors.last.withValues(alpha: mobile ? 0.12 : 0.22),
              blurRadius: mobile ? 12 : 24,
              offset: Offset(mobile ? 4 : 8, mobile ? 3 : 5),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.26),
                      Colors.transparent,
                      AppTheme.pastelRose.withValues(alpha: 0.10),
                    ],
                  ),
                ),
              ),
            ),
            if (!mobile) const Positioned.fill(child: _CornerBrackets()),
            if (icon != null && !mobile)
              Positioned(
                right: mobile ? -8 : -7,
                bottom: mobile ? -10 : -11,
                child: Icon(
                  icon,
                  size: mobile ? 50 : 76,
                  color: Colors.white.withValues(alpha: mobile ? 0.12 : 0.18),
                ),
              ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: mobile ? 14 : 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null && mobile) ...<Widget>[
                      Icon(
                        icon,
                        size: 30,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                      const Gap(12),
                    ],
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: mobile ? 19 : null,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Gap(mobile ? 8 : 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w800,
                        fontSize: mobile ? 15 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.94 : (_hovered ? 1.018 : 1.0);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 135),
          curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
          child: AnimatedRotation(
            turns: _pressed ? -0.003 : (_hovered ? 0.0015 : 0),
            duration: const Duration(milliseconds: 135),
            curve: Curves.easeOutCubic,
            child: AnimatedSlide(
              offset: _pressed ? const Offset(0, 0.032) : Offset.zero,
              duration: const Duration(milliseconds: 135),
              curve: Curves.easeOutCubic,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  void onTap() {
    Feedback.forTap(context);
    SystemSound.play(SystemSoundType.click);
    widget.onTap();
  }
}

class _DimensionalCardSlot extends StatelessWidget {
  const _DimensionalCardSlot({
    required this.index,
    required this.child,
    this.depth = 1,
  });

  final int index;
  final Widget child;
  final double depth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3 * depth),
      child: child,
    );
  }
}

class _RaisedDiaryPanel extends StatelessWidget {
  const _RaisedDiaryPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFA).withValues(alpha: mobile ? 0.96 : 0.92),
        border: Border.all(
          color: const Color(0xFFE7D8F2).withValues(alpha: mobile ? 0.82 : 1),
          width: mobile ? 1 : 1.5,
        ),
        borderRadius: BorderRadius.circular(mobile ? 12 : 10),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(
              alpha: mobile ? 0.06 : 0.08,
            ),
            blurRadius: mobile ? 10 : 16,
            offset: Offset(0, mobile ? 4 : 8),
          ),
          if (!mobile)
            BoxShadow(
              color: const Color(0xFFFFF1C8).withValues(alpha: 0.36),
              blurRadius: 18,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(mobile ? 12 : 8),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.60),
                      Colors.transparent,
                      const Color(0xFFFFF5E2).withValues(alpha: 0.30),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: const _DiaryPaperLinesPainter()),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(mobile ? 10 : 14),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FigmaEmptyCard extends StatelessWidget {
  const _FigmaEmptyCard({required this.data});

  final _FigmaCardData data;

  @override
  Widget build(BuildContext context) {
    final description = data.description?.trim();
    final subtext = data.subtext?.trim();
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.13),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.68),
          border: Border.all(color: const Color(0xFF9FC4FF), width: 1.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8FF).withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: AppTheme.tacticalBlue.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Stack(
                    children: <Widget>[
                      const Positioned.fill(child: _CornerBrackets()),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.image_rounded,
                              color: AppTheme.tacticalBlue.withValues(
                                alpha: 0.55,
                              ),
                              size: 25,
                            ),
                            const Gap(5),
                            Text(
                              data.placeholder,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF75A8FF),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(8),
              Text(
                data.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.graphite,
                  fontSize: 12.5,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (description != null && description.isNotEmpty) ...<Widget>[
                const Gap(5),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.ink.withValues(alpha: 0.62),
                    fontSize: 10.5,
                    height: 1.22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              if (subtext != null && subtext.isNotEmpty) ...<Widget>[
                const Gap(5),
                Text(
                  subtext,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.tacticalBlue,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FigmaDropdown extends StatelessWidget {
  const _FigmaDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: _figmaField(label),
      items: values.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Center(child: Text(item, textAlign: TextAlign.center)),
        );
      }).toList(),
      onChanged: (String? next) {
        if (next != null) {
          Feedback.forTap(context);
          SystemSound.play(SystemSoundType.click);
          onChanged(next);
        }
      },
    );
  }
}

class _FigmaSmallField extends StatelessWidget {
  const _FigmaSmallField({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        border: Border.all(color: const Color(0xFFACCCFF)),
        borderRadius: BorderRadius.circular(6),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF6EA3FF)),
        ),
      ),
    );
  }
}

class _TerminalTitle extends StatelessWidget {
  const _TerminalTitle({
    required this.eyebrow,
    required this.title,
    required this.code,
  });

  final String eyebrow;
  final String title;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 6,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.tacticalBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Gap(10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                eyebrow,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.graphite.withValues(alpha: 0.58),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.graphite,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        _StatusChip(icon: Icons.tag_rounded, label: code),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.tacticalBlue.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 13, color: AppTheme.signalYellow),
            const Gap(4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _CornerBracketPainter()));
  }
}

class _CornerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const length = 18.0;
    const inset = 8.0;

    canvas
      ..drawLine(
        const Offset(inset, inset),
        const Offset(inset + length, inset),
        paint,
      )
      ..drawLine(
        const Offset(inset, inset),
        const Offset(inset, inset + length),
        paint,
      )
      ..drawLine(
        Offset(size.width - inset, inset),
        Offset(size.width - inset - length, inset),
        paint,
      )
      ..drawLine(
        Offset(size.width - inset, inset),
        Offset(size.width - inset, inset + length),
        paint,
      )
      ..drawLine(
        Offset(inset, size.height - inset),
        Offset(inset + length, size.height - inset),
        paint,
      )
      ..drawLine(
        Offset(inset, size.height - inset),
        Offset(inset, size.height - inset - length),
        paint,
      )
      ..drawLine(
        Offset(size.width - inset, size.height - inset),
        Offset(size.width - inset - length, size.height - inset),
        paint,
      )
      ..drawLine(
        Offset(size.width - inset, size.height - inset),
        Offset(size.width - inset, size.height - inset - length),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FigmaPill extends StatelessWidget {
  const _FigmaPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF82A8F6), Color(0xFFAEC6CF)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.76)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF82A8F6).withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FigmaTinyTag extends StatelessWidget {
  const _FigmaTinyTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF).withValues(alpha: 0.88),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.54),
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.tacticalBlue,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FigmaPastelWash extends StatelessWidget {
  const _FigmaPastelWash();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFF4FBFF),
            Color(0xFFFFF7FB),
            Color(0xFFF5FFF7),
          ],
          stops: <double>[0, 0.42, 0.76, 1],
        ),
      ),
    );
  }
}

InputDecoration _figmaField(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFA4A4C8)),
    filled: true,
    fillColor: const Color(0xFFFFFEFA).withValues(alpha: 0.88),
    contentPadding: const EdgeInsets.all(12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFE2D5EF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFE2D5EF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFD68BA8), width: 1.7),
    ),
  );
}

class _FigmaCardData {
  const _FigmaCardData(
    this.label,
    this.placeholder, {
    this.description,
    this.subtext,
  });

  final String label;
  final String placeholder;
  final String? description;
  final String? subtext;
}

class _TemplatePage extends StatefulWidget {
  const _TemplatePage();

  @override
  State<_TemplatePage> createState() => _TemplatePageState();
}

class _TemplatePageState extends State<_TemplatePage> {
  final TextEditingController _nameController = TextEditingController(
    text: '\uB098\uC758 \uCE90\uB9AD\uD130',
  );
  final TextEditingController _memoController = TextEditingController();
  final Set<String> _selectedTags = <String>{};
  int _step = 0;
  String _mode = 'prose';
  String _templateName = '\uB098\uC758 \uCE90\uB9AD\uD130';
  String? _templatePreviewImageUrl;
  String _templateSaveMode = 'share';
  String _templateScope = 'mine';
  bool _isSaving = false;
  int _templateRefreshTick = 0;
  Uint8List? _referenceImageBytes;
  String? _referenceImageName;
  bool _isRestoringDraft = false;
  bool _hasCharacterDraft = false;
  bool _isEditingDraft = false;

  static const Map<String, List<String>> _tagGroups = <String, List<String>>{
    '\uC678\uAD00': <String>[
      '\uBC1D\uC740 \uC678\uAD00',
      '\uB3D9\uADF8\uB780 \uC678\uAD00',
      '\uCC28\uBD84\uD55C \uC678\uAD00',
      '\uACE0\uC591\uC774\uC0C1',
      '\uC8FC\uADFC\uAE68',
    ],
    '\uBA38\uB9AC': <String>[
      '\uAC80\uC740 \uBA38\uB9AC',
      '\uAC08\uC0C9 \uBA38\uB9AC',
      '\uAE08\uBC1C',
      '\uC740\uBC1C',
      '\uBD84\uD64D \uBA38\uB9AC',
      '\uB2E8\uBC1C',
      '\uC911\uB2E8\uBC1C',
      '\uAE34 \uBA38\uB9AC',
      '\uC6E8\uC774\uBE0C',
      '\uD3EC\uB2C8\uD14C\uC77C',
    ],
    '\uB208': <String>[
      '\uD478\uB978 \uB208',
      '\uAC08\uC0C9 \uB208',
      '\uCD08\uB85D \uB208',
      '\uAC80\uC740 \uB208',
      '\uBC18\uC9DD\uC774\uB294 \uB208',
      '\uB3D9\uADF8\uB780 \uB208',
      '\uC67C\uCABD \uD5E4\uC5B4\uD540',
      '\uC624\uB978\uCABD \uD5E4\uC5B4\uD540',
      '\uBCC4\uBE5B \uD5E4\uC5B4\uD540',
    ],
    '\uC131\uACA9': <String>[
      '\uCC28\uBD84\uD568',
      '\uC7A5\uB09C\uC2A4\uB7EC\uC6C0',
      '\uC218\uC90D\uC74C',
      '\uD65C\uBC1C\uD568',
      '\uB3C4\uB3C4\uD568',
      '\uB2E4\uC815\uD568',
      '\uCFE8\uD568',
    ],
    '\uC758\uC0C1': <String>[
      '\uD6C4\uB4DC',
      '\uAD50\uBCF5',
      '\uC2A4\uD53C\uCE74',
      '\uB2C8\uD2B8',
      '\uC815\uC7A5',
      '\uC2A4\uC6E8\uD130',
      '\uC2A4\uCEE4\uD2B8',
      '\uCCAD\uBC14\uC9C0',
      '\uC6B4\uB3D9\uBCF5',
    ],
    '\uC18C\uD488': <String>[
      '\uB9AC\uBCF8',
      '\uBAA8\uC790',
      '\uC548\uACBD',
      '\uD5E4\uB4DC\uD3F0',
      '\uBA38\uB9AC\uB760',
      '\uAC00\uBC29',
    ],
    '\uBD84\uC704\uAE30': <String>[
      '\uB3D9\uD654\uD48D',
      '\uBBF8\uB798\uD48D',
      '\uB3D9\uC6D0\uBB34\uB4DC',
      '\uB9C8\uBC95\uC18C\uB140',
      '\uC544\uC774\uB3CC',
      '\uD654\uC0AC\uD568',
      '\uB85C\uB9E8\uD2F1',
    ],
  };

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_handleTemplateNameChanged);
    _memoController.addListener(_handleTemplateMemoChanged);
    unawaited(_restoreCharacterDraft());
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleTemplateNameChanged);
    _memoController.removeListener(_handleTemplateMemoChanged);
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 1) {
      return _buildModeSelector(context);
    }
    if (_step == 2) {
      return _buildCreator(context);
    }

    final mobile = _isMobileLayout(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final mobileColumns = screenWidth >= 720 ? 3 : 2;
    final mobileCardSpacing = screenWidth >= 520 ? 12.0 : 8.0;
    final mobileCardWidth =
        ((screenWidth - 34 - (mobileCardSpacing * (mobileColumns - 1))) /
                mobileColumns)
            .clamp(150.0, 236.0)
            .toDouble();
    final cardWidth = mobile ? mobileCardWidth : 176.0;
    final cardHeight = mobile ? 214.0 : 236.0;
    final mobileGridWidth =
        (cardWidth * mobileColumns) + (mobileCardSpacing * (mobileColumns - 1));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 8 : 28,
        mobile ? 10 : 18,
        mobile ? 8 : 28,
        mobile ? 64 : 26,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: mobile ? double.infinity : 1120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '\uCE90\uB9AD\uD130',
                style: TextStyle(
                  color: const Color(0xFF6EA3FF),
                  fontWeight: FontWeight.w900,
                  fontSize: mobile ? 14 : 16,
                ),
              ),
              Gap(mobile ? 6 : 8),
              Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.tacticalBlue.withValues(alpha: 0.96);
                        }
                        return AppTheme.academyLilac.withValues(alpha: 0.42);
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return AppTheme.graphite;
                      }),
                      side: WidgetStateProperty.resolveWith((states) {
                        final selected = states.contains(WidgetState.selected);
                        return BorderSide(
                          color: selected
                              ? AppTheme.graphite
                              : AppTheme.tacticalBlue.withValues(alpha: 0.62),
                          width: selected ? 1.8 : 1.2,
                        );
                      }),
                      shadowColor: WidgetStateProperty.all(
                        AppTheme.graphite.withValues(alpha: 0.36),
                      ),
                      elevation: WidgetStateProperty.resolveWith((states) {
                        return states.contains(WidgetState.selected) ? 6 : 2;
                      }),
                      textStyle: WidgetStateProperty.all(
                        const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                        ),
                      ),
                      visualDensity: mobile
                          ? VisualDensity.compact
                          : VisualDensity.standard,
                    ),
                    segments: const <ButtonSegment<String>>[
                      ButtonSegment<String>(
                        value: 'mine',
                        icon: Icon(Icons.bookmark_rounded),
                        label: Text('\uB0B4 \uCE90\uB9AD\uD130'),
                      ),
                      ButtonSegment<String>(
                        value: 'drafts',
                        icon: Icon(Icons.inventory_2_rounded),
                        label: Text('\uC784\uC2DC\uC800\uC7A5'),
                      ),
                      ButtonSegment<String>(
                        value: 'others',
                        icon: Icon(Icons.public_rounded),
                        label: Text('\uACF5\uC720'),
                      ),
                    ],
                    selected: <String>{_templateScope},
                    onSelectionChanged: (Set<String> values) {
                      setState(() {
                        _templateScope = values.first;
                        _templateRefreshTick++;
                      });
                    },
                  ),
                ),
              ),
              Gap(mobile ? 6 : 8),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: mobile
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.92),
                    border: mobile
                        ? null
                        : Border.all(color: const Color(0xFFE6F0FF)),
                    borderRadius: BorderRadius.circular(mobile ? 0 : 0),
                  ),
                  child: Stack(
                    children: <Widget>[
                      if (!mobile)
                        const Positioned.fill(child: _FigmaPastelWash()),
                      FutureBuilder<List<PersonaModel>>(
                        key: ValueKey<int>(_templateRefreshTick),
                        future: _fetchSharedTemplates(),
                        builder:
                            (
                              BuildContext context,
                              AsyncSnapshot<List<PersonaModel>> snapshot,
                            ) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const <Widget>[
                                      CircularProgressIndicator(strokeWidth: 2),
                                      Gap(12),
                                      Text(
                                        '\uCE90\uB9AD\uD130\uB97C \uBD88\uB7EC\uC624\uB294 \uC911',
                                        style: TextStyle(
                                          color: AppTheme.tacticalBlue,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (snapshot.hasError) {
                                return const Center(
                                  child: Text(
                                    '\uCE90\uB9AD\uD130\uB97C \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC2B5\uB2C8\uB2E4.',
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }

                              final templates = _filterTemplatesForScope(
                                snapshot.data ?? const <PersonaModel>[],
                              );
                              if (_templateScope == 'drafts') {
                                return _buildDraftCharacterTab(mobile);
                              }
                              final cards = <Widget>[
                                if (_templateScope == 'mine')
                                  _TemplateGalleryCard(
                                    title:
                                        '\uC0C8 \uCE90\uB9AD\uD130\n\uB9CC\uB4E4\uAE30',
                                    isCreateCard: true,
                                    onTap: () => setState(() => _step = 1),
                                  ),
                                ...templates.map(
                                  (PersonaModel template) =>
                                      _TemplateGalleryCard(
                                        title: template.name,
                                        badge: template.isPublic
                                            ? '\uACF5\uC720'
                                            : '\uC18C\uC7A5',
                                        imageUrl:
                                            template.imageUrl ??
                                            template.baseImageUrl,
                                        onTap: () {
                                          _showTemplateDetail(
                                            context,
                                            template,
                                          );
                                        },
                                      ),
                                ),
                              ];

                              if (cards.isEmpty) {
                                return Center(
                                  child: Text(
                                    _templateScope == 'mine'
                                        ? '\uC544\uC9C1 \uC18C\uC7A5\uD55C \uCE90\uB9AD\uD130\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.'
                                        : '\uC544\uC9C1 \uACF5\uAC1C \uCE90\uB9AD\uD130\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }

                              return SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(
                                  mobile ? 8 : 42,
                                  mobile ? 10 : 34,
                                  mobile ? 8 : 42,
                                  mobile ? 12 : 34,
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: mobile ? mobileGridWidth : null,
                                    child: Wrap(
                                      alignment: mobile
                                          ? WrapAlignment.start
                                          : WrapAlignment.center,
                                      runAlignment: mobile
                                          ? WrapAlignment.start
                                          : WrapAlignment.center,
                                      spacing: mobile ? mobileCardSpacing : 30,
                                      runSpacing: mobile ? 8 : 34,
                                      children: cards.indexed
                                          .map(
                                            ((int, Widget) entry) => SizedBox(
                                              width: cardWidth,
                                              height: cardHeight,
                                              child: _DimensionalCardSlot(
                                                index: entry.$1,
                                                depth: 0.72,
                                                child: entry.$2,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
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
  }

  Future<List<PersonaModel>> _fetchSharedTemplates() async {
    if (!SupabaseRuntime.isConfigured) {
      return const <PersonaModel>[];
    }

    final user = await _ensureSupabaseUserProfile();
    final repository = SupabasePersonaRepository(Supabase.instance.client);
    return repository.fetchVisibleTemplates(user.id);
  }

  List<PersonaModel> _filterTemplatesForScope(List<PersonaModel> templates) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (_templateScope == 'mine') {
      return templates
          .where((PersonaModel template) => template.userId == currentUserId)
          .toList();
    }

    return templates
        .where((PersonaModel template) => template.isPublic)
        .followedBy(
          templates.where(
            (PersonaModel template) =>
                !template.isPublic &&
                template.templateVisibility == 'followers',
          ),
        )
        .toSet()
        .toList();
  }

  Widget _buildDraftCharacterTab(bool mobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        mobile ? 12 : 34,
        mobile ? 14 : 28,
        mobile ? 12 : 34,
        mobile ? 18 : 30,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: _hasCharacterDraft
              ? _CharacterDraftPublishPanel(
                  name: _templateName,
                  memo: _memoController.text,
                  tags: _selectedTags.toList(),
                  imageUrl: _templatePreviewImageUrl,
                  imageBytes: _referenceImageBytes,
                  isPublishing: _isSaving,
                  onEdit: () {
                    setState(() {
                      _isEditingDraft = true;
                      _step = 2;
                    });
                  },
                  onPublish: () =>
                      unawaited(_showCharacterDraftPublishSettings()),
                  onClear: () => unawaited(
                    _clearCharacterDraft(showSnackBar: true, clearForm: true),
                  ),
                )
              : _EmptyDraftCharacterPanel(
                  onCreate: () => setState(() => _step = 1),
                ),
        ),
      ),
    );
  }

  void _handleTemplateNameChanged() {
    if (_isRestoringDraft) {
      return;
    }
    final nextName = _nameController.text.trim();
    setState(() {
      _templateName = nextName.isEmpty
          ? '\uB098\uC758 \uCE90\uB9AD\uD130'
          : nextName;
    });
    _scheduleCharacterDraftSave();
  }

  void _handleTemplateMemoChanged() {
    if (_isRestoringDraft) {
      return;
    }
    setState(() {});
    _scheduleCharacterDraftSave();
  }

  void _startCharacterDraft(String mode) {
    _isRestoringDraft = true;
    setState(() {
      _isEditingDraft = false;
      _mode = mode;
      _templateName = '\uB098\uC758 \uCE90\uB9AD\uD130';
      _templatePreviewImageUrl = null;
      _referenceImageBytes = null;
      _referenceImageName = null;
      _selectedTags.clear();
      _step = 2;
    });
    _nameController.text = _templateName;
    _memoController.clear();
    _isRestoringDraft = false;
  }

  Widget _buildModeSelector(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 8 : 28,
        mobile ? 8 : 18,
        mobile ? 8 : 28,
        mobile ? 92 : 26,
      ),
      child: _DiaryFigmaFrame(
        title: '\uCE90\uB9AD\uD130 \uB9CC\uB4E4\uAE30',
        onClose: () => setState(() => _step = 0),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            mobile ? 18 : 46,
            mobile ? 18 : 28,
            mobile ? 18 : 46,
            mobile ? 22 : 34,
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final compact = constraints.maxWidth < 700;
              final cards = <Widget>[
                _FigmaGradientButton(
                  title: 'PROSE START',
                  subtitle: '\uC904\uAE00\uB85C \uB9CC\uB4E4\uAE30',
                  icon: Icons.edit_note_rounded,
                  colors: const <Color>[
                    AppTheme.pastelRose,
                    AppTheme.pastelPeach,
                  ],
                  onTap: () => _startCharacterDraft('prose'),
                ),
                _FigmaGradientButton(
                  title: 'TAG START',
                  subtitle: '\uD0DC\uADF8\uB85C \uB9CC\uB4E4\uAE30',
                  icon: Icons.grid_view_rounded,
                  colors: const <Color>[
                    AppTheme.pastelBlue,
                    AppTheme.pastelGreen,
                  ],
                  onTap: () => _startCharacterDraft('tags'),
                ),
              ];

              if (compact) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 118, child: cards.first),
                    const Gap(18),
                    SizedBox(height: 118, child: cards.last),
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(child: cards.first),
                  const Gap(34),
                  Expanded(child: cards.last),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCreator(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        mobile ? 12 : 28,
        mobile ? 12 : 18,
        mobile ? 12 : 28,
        mobile ? 92 : 26,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _GlassPanel(
            child: Padding(
              padding: EdgeInsets.all(mobile ? 14 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton.filledTonal(
                        tooltip: '\uB4A4\uB85C',
                        onPressed: () => setState(() => _step = 1),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          _isEditingDraft
                              ? '\uC784\uC2DC\uC800\uC7A5 \uC218\uC815'
                              : _mode == 'tags'
                              ? '\uD0DC\uADF8\uB85C \uB9CC\uB4E4\uAE30'
                              : '\uC904\uAE00\uB85C \uB9CC\uB4E4\uAE30',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.graphite,
                              ),
                        ),
                      ),
                      const SizedBox(width: 52),
                    ],
                  ),
                  const Gap(22),
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints _) {
                      final showProseEditor =
                          _isEditingDraft || _mode == 'prose';
                      final showTagEditor = _isEditingDraft || _mode == 'tags';
                      final editor = DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.74),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppTheme.tacticalBlue.withValues(
                              alpha: 0.30,
                            ),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppTheme.tacticalBlue.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(mobile ? 12 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              TextField(
                                controller: _nameController,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  labelText: '\uCE90\uB9AD\uD130 \uC774\uB984',
                                  hintText: '\uC774\uB984',
                                ),
                              ),
                              const Gap(14),
                              _ReferenceFilePicker(
                                imageBytes: _referenceImageBytes,
                                imageName: _referenceImageName,
                                isBusy: _isSaving,
                                onPick: _pickReferenceImage,
                                onClear: _clearReferenceImage,
                              ),
                              if (showProseEditor) ...<Widget>[
                                const Gap(14),
                                SizedBox(
                                  height: 160,
                                  child: TextField(
                                    controller: _memoController,
                                    textAlign: TextAlign.center,
                                    textAlignVertical: TextAlignVertical.top,
                                    expands: true,
                                    maxLines: null,
                                    decoration: const InputDecoration(
                                      alignLabelWithHint: true,
                                      labelText: '\uC904\uAE00 \uC124\uC815',
                                      hintText:
                                          '\uC678\uD615, \uC131\uACA9, \uC758\uC0C1',
                                    ),
                                  ),
                                ),
                              ],
                              if (showTagEditor) ...<Widget>[
                                const Gap(14),
                                _CharacterTagPicker(
                                  groups: _tagGroups,
                                  selectedTags: _selectedTags,
                                  onTagToggled: _toggleTemplateTag,
                                  onClear: () {
                                    setState(() => _selectedTags.clear());
                                    _scheduleCharacterDraftSave();
                                  },
                                ),
                              ],
                              const Gap(14),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: _isSaving
                                          ? null
                                          : () => unawaited(
                                              _finishCharacterDraft(),
                                            ),
                                      icon: const Icon(
                                        Icons.archive_outlined,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        '\uC784\uC2DC\uC800\uC7A5',
                                      ),
                                    ),
                                  ),
                                  const Gap(10),
                                  IconButton.filledTonal(
                                    tooltip:
                                        '\uC784\uC2DC\uC800\uC7A5 \uCE78\uC73C\uB85C \uB3CC\uC544\uAC00\uAE30',
                                    onPressed: _isSaving
                                        ? null
                                        : () => setState(() => _step = 0),
                                    icon: const Icon(Icons.view_module_rounded),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );

                      return editor;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickReferenceImage() async {
    try {
      final pickedImage = await pickReferenceImageFile();
      if (pickedImage == null) {
        return;
      }
      if (!mounted) {
        return;
      }
      if (!_isSupportedReferenceImageName(pickedImage.name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\uCC38\uACE0 \uC774\uBBF8\uC9C0\uB294 JPG, PNG, WebP, GIF\uB9CC \uC0AC\uC6A9\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4.',
            ),
          ),
        );
        return;
      }

      setState(() {
        _referenceImageBytes = pickedImage.bytes;
        _referenceImageName = pickedImage.name;
      });
      _scheduleCharacterDraftSave();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '\uC774\uBBF8\uC9C0 \uC120\uD0DD\uC5D0 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4. $error',
          ),
        ),
      );
    }
  }

  void _clearReferenceImage() {
    setState(() {
      _referenceImageBytes = null;
      _referenceImageName = null;
    });
    _scheduleCharacterDraftSave();
  }

  Future<String?> _uploadReferenceImage(String userId) async {
    final bytes = _referenceImageBytes;
    if (bytes == null) {
      return null;
    }

    final extension = _imageExtensionFromName(_referenceImageName);
    final storagePath =
        '$userId/persona-references/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await Supabase.instance.client.storage
        .from('diary-assets')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: _imageContentType(extension),
            upsert: true,
          ),
        );

    return Supabase.instance.client.storage
        .from('diary-assets')
        .getPublicUrl(storagePath);
  }

  String _imageExtensionFromName(String? name) {
    final lower = (name ?? '').toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'jpg';
    }
    if (lower.endsWith('.webp')) {
      return 'webp';
    }
    if (lower.endsWith('.gif')) {
      return 'gif';
    }
    return 'png';
  }

  bool _isSupportedReferenceImageName(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  String _imageContentType(String extension) {
    return switch (extension) {
      'jpg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/png',
    };
  }

  void _toggleTemplateTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
    _scheduleCharacterDraftSave();
  }

  void _scheduleCharacterDraftSave() {
    // Drafts are persisted explicitly with the temporary save action.
  }

  Future<void> _restoreCharacterDraft() async {
    try {
      if (!SupabaseRuntime.isConfigured) {
        return;
      }
      final user = await _ensureSupabaseUserProfile();
      final draft = await SupabasePersonaRepository(
        Supabase.instance.client,
      ).fetchPersonaDraft(user.id);
      if (!mounted) {
        return;
      }
      if (draft == null) {
        setState(() {
          _hasCharacterDraft = false;
        });
        return;
      }

      _isRestoringDraft = true;
      setState(() {
        _mode = draft.inputMode == PersonaInputMode.tags ? 'tags' : 'prose';
        _templateName = draft.name;
        _templateSaveMode = _saveModeFromVisibility(draft.templateVisibility);
        _selectedTags
          ..clear()
          ..addAll(draft.appearanceTags);
        _referenceImageBytes = null;
        _referenceImageName = null;
        _templatePreviewImageUrl = draft.referenceImageUrl;
        _hasCharacterDraft = true;
      });
      _nameController.text = _templateName;
      _memoController.text = draft.appearanceDescription;
      _isRestoringDraft = false;
    } catch (_) {
      _isRestoringDraft = false;
    }
  }

  Future<void> _saveCharacterDraft({required bool showSnackBar}) async {
    try {
      final user = await _ensureSupabaseUserProfile();
      final bytes = _referenceImageBytes;
      final referenceImageUrl = bytes == null
          ? _templatePreviewImageUrl
          : await _uploadReferenceImage(user.id);
      final draft = await SupabasePersonaRepository(Supabase.instance.client)
          .upsertPersonaDraft(
            userId: user.id,
            name: _templateName,
            appearanceDescription: _memoController.text,
            inputMode: _mode == 'tags'
                ? PersonaInputMode.tags
                : PersonaInputMode.prose,
            appearanceTags: _selectedTags.toList(),
            templateVisibility: _visibilityFromSaveMode(_templateSaveMode),
            referenceImageUrl: referenceImageUrl,
          );
      if (mounted) {
        setState(() {
          _hasCharacterDraft = true;
          _templatePreviewImageUrl = draft.referenceImageUrl;
          _referenceImageBytes = null;
          _referenceImageName = null;
          _templateScope = 'drafts';
          _templateRefreshTick++;
        });
      }
      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\uCE90\uB9AD\uD130 \uC124\uC815\uC744 \uC784\uC2DC \uC800\uC7A5\uD588\uC2B5\uB2C8\uB2E4.',
            ),
          ),
        );
      }
    } catch (error) {
      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\uC784\uC2DC \uC800\uC7A5 \uC2E4\uD328: $error'),
          ),
        );
      }
    }
  }

  Future<void> _finishCharacterDraft() async {
    await _saveCharacterDraft(showSnackBar: true);
    if (mounted) {
      setState(() {
        _isEditingDraft = false;
        _step = 0;
      });
    }
  }

  Future<void> _clearCharacterDraft({
    bool showSnackBar = false,
    bool clearForm = false,
  }) async {
    if (SupabaseRuntime.isConfigured) {
      final user = await _ensureSupabaseUserProfile();
      await SupabasePersonaRepository(
        Supabase.instance.client,
      ).deletePersonaDraft(user.id);
    }
    if (clearForm && mounted) {
      _isRestoringDraft = true;
      setState(() {
        _templateName = '\uB098\uC758 \uCE90\uB9AD\uD130';
        _templateSaveMode = 'share';
        _templatePreviewImageUrl = null;
        _referenceImageBytes = null;
        _referenceImageName = null;
        _selectedTags.clear();
        _hasCharacterDraft = false;
        _isEditingDraft = false;
      });
      _nameController.text = _templateName;
      _memoController.clear();
      _isRestoringDraft = false;
    }
    if (showSnackBar && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\uC784\uC2DC\uC800\uC7A5\uC744 \uBE44\uC6E0\uC2B5\uB2C8\uB2E4.',
          ),
        ),
      );
    }
  }

  Future<void> _showCharacterDraftPublishSettings() async {
    var draftSaveMode = _templateSaveMode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('\uCE90\uB9AD\uD130 \uCD5C\uC885 \uBC1C\uD589'),
              content: SizedBox(
                width: 520,
                child: _SaveModeSelector(
                  selected: draftSaveMode,
                  onChanged: (String value) {
                    setDialogState(() => draftSaveMode = value);
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('\uCDE8\uC18C'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.publish_rounded),
                  label: const Text('\uCD5C\uC885 \uBC1C\uD589'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _templateSaveMode = draftSaveMode);
    await _saveCharacterDraft(showSnackBar: false);
    await _publishCharacterDraft();
  }

  Future<void> _publishCharacterDraft() async {
    await _createTemplate();
  }

  Future<void> _createTemplate() async {
    final memo = _memoController.text.trim();
    final tagPrompt = _selectedTags.join(', ');
    final savedReferenceImageUrl = _templatePreviewImageUrl;
    final prompt = [
      if (memo.isEmpty && tagPrompt.isEmpty)
        '\uC0AC\uC6A9\uC790\uAC00 \uC791\uC131\uD55C \uCE90\uB9AD\uD130',
      if (memo.isNotEmpty) memo,
      if (tagPrompt.isNotEmpty)
        '\uD0DC\uADF8\uB85C \uACE0\uC815\uD55C \uC678\uD615 \uC694\uC18C: $tagPrompt',
      '\uD45C\uC815\uC774 \uC0B4\uC544\uC788\uB294 \uADC0\uC5EC\uC6B4 \uC6F9\uD230 \uCE90\uB9AD\uD130 \uC544\uD2B8',
    ].join('\n');

    setState(() {
      _isSaving = true;
      _templatePreviewImageUrl = null;
    });

    try {
      final user = await _ensureSupabaseUserProfile();
      final referenceImageUrl = _referenceImageBytes == null
          ? savedReferenceImageUrl
          : await _uploadReferenceImage(user.id);
      final effectivePrompt = [
        if (referenceImageUrl != null)
          [
            'Reference image URL: $referenceImageUrl',
            'The uploaded image is the primary design source. Use image-derived visual cues before written tags.',
            'Extract safe visual cues from the actual image: face shape, eye shape and gaze, eyebrow impression, hair volume, bangs, hair length, skin tone, outfit colors, accessories, and overall mood.',
            'Reinterpret those cues as an original Korean diary webtoon character, not a direct likeness of the person in the photo.',
            'If written memo or selected tags conflict with the photo, follow the photo first. Use tags only as secondary style and mood hints.',
            'Final output must be exactly one original reusable character, not a character sheet, grid, collage, or multiple variations.',
          ].join('\\n'),
        prompt,
      ].join('\\n');
      if (mounted) {}
      final repository = SupabasePersonaRepository(Supabase.instance.client);
      final persona = await repository.createPersonaTemplate(
        userId: user.id,
        name: _templateName.trim().isEmpty
            ? '\uACF5\uC720 \uCE90\uB9AD\uD130'
            : _templateName.trim(),
        appearanceDescription: effectivePrompt,
        seed: DateTime.now().millisecondsSinceEpoch % 2147483647,
        inputMode: _mode == 'tags'
            ? PersonaInputMode.tags
            : PersonaInputMode.prose,
        appearanceTags: _selectedTags.toList(),
        expressionLibrary: const <String, String>{
          'happy': '\uD658\uD558\uAC8C \uC6C3\uB294 \uD45C\uC815',
          'sad': '\uB208\uBB3C\uC774 \uACE0\uC778 \uC2AC\uD508 \uD45C\uC815',
          'angry': '\uBD89\uC740 \uD45C\uC815\uC758 \uD654\uB09C \uC5BC\uAD74',
          'embarrassed':
              '\uB2F9\uD669\uD574 \uB540\uC744 \uD758\uB9AC\uB294 \uD45C\uC815',
          'calm': '\uD3C9\uC628\uD558\uACE0 \uCC28\uBD84\uD55C \uD45C\uC815',
        },
        isPublic: _templateSaveMode == 'share',
        templateVisibility: _visibilityFromSaveMode(_templateSaveMode),
        referenceImageUrl: referenceImageUrl,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            persona.generationStatus == 'failed'
                ? '\uCE90\uB9AD\uD130\uB294 \uC800\uC7A5\uB410\uC9C0\uB9CC \uC774\uBBF8\uC9C0\uB294 \uC544\uC9C1 \uC644\uC131\uB418\uC9C0 \uC54A\uC558\uC2B5\uB2C8\uB2E4: '
                      '${_friendlyTemplateError(persona.errorMessage ?? 'unknown error')}'
                : _templateSaveMode == 'share'
                ? '\uCE90\uB9AD\uD130\uAC00 \uACF5\uC720\uC640 \uB0B4 \uCE90\uB9AD\uD130\uC5D0 \uC800\uC7A5\uB410\uC2B5\uB2C8\uB2E4.'
                : _templateSaveMode == 'followers'
                ? '\uCE90\uB9AD\uD130\uAC00 \uD314\uB85C\uC6CC \uACF5\uAC1C\uB85C \uC800\uC7A5\uB410\uC2B5\uB2C8\uB2E4.'
                : '\uCE90\uB9AD\uD130\uAC00 \uB0B4 \uCE90\uB9AD\uD130\uC5D0 \uC800\uC7A5\uB410\uC2B5\uB2C8\uB2E4.',
          ),
        ),
      );
      setState(() {
        _templatePreviewImageUrl = persona.imageUrl ?? persona.baseImageUrl;
        _step = persona.generationStatus == 'failed' ? _step : 0;
        _templateRefreshTick++;
        if (persona.generationStatus != 'failed') {
          _templateName = '\uB098\uC758 \uCE90\uB9AD\uD130';
          _templateSaveMode = 'share';
          _referenceImageBytes = null;
          _referenceImageName = null;
          _selectedTags.clear();
          _hasCharacterDraft = false;
        }
      });
      if (persona.generationStatus != 'failed') {
        _isRestoringDraft = true;
        _nameController.text = _templateName;
        _memoController.clear();
        _isRestoringDraft = false;
        unawaited(_clearCharacterDraft());
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '\uCE90\uB9AD\uD130 \uC800\uC7A5 \uC2E4\uD328: ${_friendlyTemplateError(error)}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _friendlyTemplateError(Object error) {
    final message = error.toString();
    if (message.contains('create_guest_persona') ||
        message.contains('PGRST202')) {
      return '\uCE90\uB9AD\uD130 \uC0DD\uC131 RPC\uAC00 DB\uC5D0 \uC5C6\uC2B5\uB2C8\uB2E4. run_template_rpc_bundle.sql\uC744 \uC2E4\uD589\uD574 \uC8FC\uC138\uC694.';
    }
    if (message.contains('row-level security')) {
      return '\uCE90\uB9AD\uD130 RLS \uC624\uB958\uC785\uB2C8\uB2E4. \uB85C\uADF8\uC778\uD55C \uACC4\uC815\uC758 \uCE90\uB9AD\uD130\uB9CC \uC800\uC7A5\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4. \uC6D0\uBB38: $message';
    }
    if (message.contains('Failed to fetch')) {
      return 'generate-persona-image Edge Function \uD638\uCD9C\uC5D0 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4. Supabase \uBC30\uD3EC\uC640 OPENAI_API_KEY, STABILITY_API_KEY Secret\uC744 \uD655\uC778\uD574 \uC8FC\uC138\uC694.';
    }
    return _friendlyGenerationError(error);
  }

  void _showTemplateDetail(BuildContext context, PersonaModel template) {
    final isMine =
        Supabase.instance.client.auth.currentUser?.id == template.userId;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  template.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const Gap(12),
                SizedBox(
                  height: 160,
                  child: _TemplateDetailImage(
                    imageUrl: template.imageUrl ?? template.baseImageUrl,
                  ),
                ),
                const Gap(12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: template.appearanceTags
                      .map((String tag) => _FigmaTinyTag(text: tag))
                      .toList(),
                ),
                const Spacer(),
                if (isMine) ...<Widget>[
                  const Gap(12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text(
                                  '\uCE90\uB9AD\uD130 \uC0AD\uC81C',
                                  textAlign: TextAlign.center,
                                ),
                                content: const Text(
                                  '\uC774 \uCE90\uB9AD\uD130\uB294 \uC0AD\uC81C\uD558\uBA74 \uB418\uB3CC\uB9B4 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4.',
                                  textAlign: TextAlign.center,
                                ),
                                actionsAlignment: MainAxisAlignment.center,
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('\uCDE8\uC18C'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('\uC0AD\uC81C'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirmed != true) {
                            return;
                          }
                          await SupabasePersonaRepository(
                            Supabase.instance.client,
                          ).deletePersonaTemplate(template.id);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                          if (mounted) {
                            setState(() => _templateRefreshTick++);
                          }
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('\uC0AD\uC81C'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyDraftCharacterPanel extends StatelessWidget {
  const _EmptyDraftCharacterPanel({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 26, 18, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.inventory_2_rounded,
              color: AppTheme.tacticalBlue.withValues(alpha: 0.82),
              size: 44,
            ),
            const Gap(12),
            Text(
              '\uC784\uC2DC\uC800\uC7A5\uB41C \uCE90\uB9AD\uD130\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Gap(6),
            Text(
              '\uB9CC\uB4E0 \uCE90\uB9AD\uD130\uB97C \uC5EC\uAE30\uC11C \uD655\uC778\uD558\uACE0 \uBC1C\uD589\uD574\uC694.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.ink.withValues(alpha: 0.58),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const Gap(16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('\uCE90\uB9AD\uD130 \uB9CC\uB4E4\uAE30'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterDraftPublishPanel extends StatelessWidget {
  const _CharacterDraftPublishPanel({
    required this.name,
    required this.memo,
    required this.tags,
    required this.isPublishing,
    required this.onEdit,
    required this.onPublish,
    required this.onClear,
    this.imageUrl,
    this.imageBytes,
  });

  final String name;
  final String memo;
  final List<String> tags;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final bool isPublishing;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.26),
          width: 1.2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(mobile ? 12 : 16),
        child: mobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _children(context),
              )
            : Row(children: _children(context)),
      ),
    );
  }

  List<Widget> _children(BuildContext context) {
    final mobile = _isMobileLayout(context);
    final details = Column(
      crossAxisAlignment: mobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: mobile
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: <Widget>[
            const Icon(
              Icons.inventory_2_rounded,
              color: AppTheme.tacticalBlue,
              size: 18,
            ),
            const Gap(6),
            Text(
              '\uC784\uC2DC\uC800\uC7A5 \uCE90\uB9AD\uD130',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.tacticalBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const Gap(5),
        Text(
          name.trim().isEmpty ? '\uB098\uC758 \uCE90\uB9AD\uD130' : name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: mobile ? TextAlign.center : TextAlign.left,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (tags.isNotEmpty) ...<Widget>[
          const Gap(8),
          Wrap(
            alignment: mobile ? WrapAlignment.center : WrapAlignment.start,
            spacing: 6,
            runSpacing: 6,
            children: tags
                .take(3)
                .map((String tag) => _FigmaTinyTag(text: tag))
                .toList(),
          ),
        ],
      ],
    );
    return <Widget>[
      SizedBox(
        width: mobile ? double.infinity : 116,
        height: mobile ? 150 : 132,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.pastelBlue.withValues(alpha: 0.20),
              border: Border.all(
                color: AppTheme.tacticalBlue.withValues(alpha: 0.20),
              ),
            ),
            child: imageBytes != null
                ? Image.memory(imageBytes!, fit: BoxFit.cover)
                : imageUrl?.trim().isNotEmpty == true
                ? _StorageAwareImage(
                    url: imageUrl!.trim(),
                    fallback: const _TemplateImageFallback(),
                  )
                : const Icon(
                    Icons.face_retouching_natural_rounded,
                    color: AppTheme.tacticalBlue,
                    size: 38,
                  ),
          ),
        ),
      ),
      Gap(mobile ? 10 : 14),
      if (mobile) details else Expanded(child: details),
      Gap(mobile ? 10 : 14),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: mobile ? double.infinity : 190),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            FilledButton.icon(
              onPressed: isPublishing ? null : onPublish,
              icon: isPublishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish_rounded),
              label: Text(
                isPublishing
                    ? '\uBC1C\uD589 \uC911...'
                    : '\uCD5C\uC885 \uBC1C\uD589',
              ),
            ),
            const Gap(8),
            OutlinedButton.icon(
              onPressed: isPublishing ? null : onEdit,
              icon: const Icon(Icons.tune_rounded),
              label: const Text('\uC218\uC815'),
            ),
            const Gap(8),
            IconButton.filledTonal(
              tooltip: '\uC784\uC2DC\uC800\uC7A5 \uC0AD\uC81C',
              onPressed: isPublishing ? null : onClear,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    ];
  }
}

class _TemplateGalleryCard extends StatelessWidget {
  const _TemplateGalleryCard({
    required this.title,
    this.isCreateCard = false,
    this.badge,
    this.imageUrl,
    this.onTap,
  });

  final String title;
  final bool isCreateCard;
  final String? badge;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return SizedBox(
      width: double.infinity,
      child: _PressableScale(
        onTap: onTap ?? () {},
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: mobile ? 0.96 : 0.88),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.tacticalBlue.withValues(
                alpha: mobile ? 0.38 : 0.50,
              ),
              width: mobile ? 1 : 1.3,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.ink.withValues(alpha: mobile ? 0.10 : 0.20),
                blurRadius: mobile ? 10 : 20,
                offset: Offset(0, mobile ? 5 : 14),
              ),
              BoxShadow(
                color: AppTheme.pastelRose.withValues(
                  alpha: mobile ? 0.07 : 0.12,
                ),
                blurRadius: mobile ? 12 : 22,
                offset: Offset(mobile ? -3 : -6, mobile ? 3 : 6),
              ),
              BoxShadow(
                color: AppTheme.pastelBlue.withValues(
                  alpha: mobile ? 0.10 : 0.18,
                ),
                blurRadius: mobile ? 12 : 22,
                offset: Offset(mobile ? 3 : 6, mobile ? 2 : 4),
              ),
              if (!mobile)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.86),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 8 : 10,
              vertical: mobile ? 9 : 16,
            ),
            child: Stack(
              children: <Widget>[
                if (!mobile)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Colors.white.withValues(alpha: 0.34),
                            Colors.transparent,
                            AppTheme.tacticalBlue.withValues(alpha: 0.025),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (!mobile)
                  const Positioned(
                    top: 0,
                    left: 12,
                    right: 12,
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFCFE1FF),
                    ),
                  ),
                if (!mobile) const Positioned.fill(child: _CornerBrackets()),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (badge != null) ...<Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: _FigmaTinyTag(text: badge!),
                      ),
                      Gap(mobile ? 3 : 6),
                    ],
                    if (isCreateCard) ...<Widget>[
                      Icon(
                        Icons.add_rounded,
                        size: mobile ? 50 : 66,
                        color: AppTheme.tacticalBlue,
                      ),
                      Gap(mobile ? 10 : 18),
                    ] else if (imageUrl != null &&
                        imageUrl!.isNotEmpty) ...<Widget>[
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFBFD9FF),
                                width: 1.2,
                              ),
                            ),
                            child: _StorageAwareImage(
                              url: imageUrl!,
                              fallback: const _TemplateImageFallback(),
                            ),
                          ),
                        ),
                      ),
                      Gap(mobile ? 5 : 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: mobile ? 34 : (isCreateCard ? 50 : 42),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            title,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.tacticalBlue,
                              fontSize: mobile ? 15 : 18,
                              height: 1.04,
                              fontStyle: mobile
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateImageFallback extends StatelessWidget {
  const _TemplateImageFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        border: Border.all(color: const Color(0xFFBFD9FF)),
      ),
      child: const Center(
        child: Icon(
          Icons.face_retouching_natural_rounded,
          color: Color(0xFFA5CCFF),
          size: 42,
        ),
      ),
    );
  }
}

class _TemplateDetailImage extends StatelessWidget {
  const _TemplateDetailImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.62),
          border: Border.all(color: const Color(0xFFBFD9FF)),
        ),
        child: url == null || url.isEmpty
            ? const Center(child: _TemplateImageFallback())
            : _StorageAwareImage(
                url: url,
                fallback: const _TemplateImageFallback(),
              ),
      ),
    );
  }
}

class _ReferenceFilePicker extends StatelessWidget {
  const _ReferenceFilePicker({
    required this.imageBytes,
    required this.imageName,
    required this.isBusy,
    required this.onPick,
    required this.onClear,
  });

  final Uint8List? imageBytes;
  final String? imageName;
  final bool isBusy;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null;
    final mobile = _isMobileLayout(context);
    final detail = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          hasImage
              ? '\uCC38\uACE0 \uC774\uBBF8\uC9C0'
              : '\uC774\uBBF8\uC9C0 \uC120\uD0DD',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (hasImage && imageName?.trim().isNotEmpty == true) ...<Widget>[
          const Gap(4),
          Text(
            imageName!.trim(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.ink.withValues(alpha: 0.58),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
        const Gap(10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: isBusy ? null : onPick,
              icon: const Icon(Icons.folder_open_rounded),
              label: Text(
                hasImage
                    ? '\uB2E4\uB978 \uC774\uBBF8\uC9C0'
                    : '\uC774\uBBF8\uC9C0 \uC120\uD0DD',
              ),
            ),
            if (hasImage)
              IconButton.filledTonal(
                onPressed: isBusy ? null : onClear,
                icon: const Icon(Icons.close_rounded),
                tooltip: '\uC9C0\uC6B0\uAE30',
              ),
          ],
        ),
      ],
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onPick,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasImage
                  ? AppTheme.pastelGreen.withValues(alpha: 0.85)
                  : AppTheme.tacticalBlue.withValues(alpha: 0.28),
              width: hasImage ? 1.6 : 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.tacticalBlue.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: mobile
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _ReferenceFileThumb(imageBytes: imageBytes),
                    const Gap(10),
                    detail,
                  ],
                )
              : Row(
                  children: <Widget>[
                    _ReferenceFileThumb(imageBytes: imageBytes),
                    const Gap(14),
                    Expanded(child: detail),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ReferenceFileThumb extends StatelessWidget {
  const _ReferenceFileThumb({required this.imageBytes});

  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;
    return Ink(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: AppTheme.pastelBlue.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.22),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: bytes == null
            ? const Icon(
                Icons.add_photo_alternate_rounded,
                color: AppTheme.tacticalBlue,
                size: 34,
              )
            : Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.memory(bytes, fit: BoxFit.cover),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.86),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 15,
                          color: AppTheme.tacticalBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ReferenceImagePicker extends StatelessWidget {
  const _ReferenceImagePicker({
    required this.imageBytes,
    required this.imageName,
    required this.isBusy,
    required this.onPick,
    required this.onClear,
  });

  final Uint8List? imageBytes;
  final String? imageName;
  final bool isBusy;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null;
    final mobile = _isMobileLayout(context);
    final thumb = InkWell(
      onTap: isBusy ? null : onPick,
      borderRadius: BorderRadius.circular(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: mobile ? 96 : 82,
          height: mobile ? 96 : 82,
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.memory(imageBytes!, fit: BoxFit.cover),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.86),
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(
                            Icons.edit_rounded,
                            size: 15,
                            color: AppTheme.tacticalBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.pastelBlue.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.tacticalBlue.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_rounded,
                    color: AppTheme.tacticalBlue,
                    size: 34,
                  ),
                ),
        ),
      ),
    );
    final detail = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          hasImage
              ? '\uCC38\uACE0 \uC0AC\uC9C4 \uC120\uD0DD\uB428'
              : '\uB0B4 \uD30C\uC77C\uC5D0\uC11C \uC0AC\uC9C4 \uC120\uD0DD',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Gap(4),
        Text(
          hasImage
              ? (imageName ?? '\uC120\uD0DD\uD55C \uC774\uBBF8\uC9C0')
              : '\uC120\uD0DD \uC0AC\uD56D\uC785\uB2C8\uB2E4',
          textAlign: TextAlign.center,
          maxLines: mobile ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.ink.withValues(alpha: 0.60),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const Gap(10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: isBusy ? null : onPick,
              icon: const Icon(Icons.folder_open_rounded),
              label: Text(
                hasImage
                    ? '\uB2E4\uB978 \uC774\uBBF8\uC9C0'
                    : '\uC774\uBBF8\uC9C0 \uC120\uD0DD',
              ),
            ),
            if (hasImage)
              IconButton.filledTonal(
                onPressed: isBusy ? null : onClear,
                icon: const Icon(Icons.close_rounded),
                tooltip: '\uC9C0\uC6B0\uAE30',
              ),
          ],
        ),
      ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasImage
              ? AppTheme.pastelGreen.withValues(alpha: 0.85)
              : AppTheme.tacticalBlue.withValues(alpha: 0.28),
          width: hasImage ? 1.6 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: mobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[thumb, const Gap(12), detail],
            )
          : Row(
              children: <Widget>[
                thumb,
                const Gap(14),
                Expanded(child: detail),
              ],
            ),
    );
  }
}

class _ReferenceImagePickerLegacy extends StatelessWidget {
  const _ReferenceImagePickerLegacy({
    required this.imageBytes,
    required this.imageName,
    required this.isBusy,
    required this.onPick,
    required this.onClear,
  });

  final Uint8List? imageBytes;
  final String? imageName;
  final bool isBusy;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasImage
              ? AppTheme.pastelGreen.withValues(alpha: 0.85)
              : AppTheme.tacticalBlue.withValues(alpha: 0.28),
          width: hasImage ? 1.6 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 82,
              height: 82,
              child: hasImage
                  ? Image.memory(imageBytes!, fit: BoxFit.cover)
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppTheme.pastelBlue.withValues(alpha: 0.20),
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: AppTheme.tacticalBlue,
                        size: 34,
                      ),
                    ),
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  hasImage
                      ? '\uCC38\uACE0 \uC0AC\uC9C4 \uC120\uD0DD\uB428'
                      : '\uCC38\uACE0 \uC0AC\uC9C4\uB85C \uCE90\uB9AD\uD130 \uB9CC\uB4E4\uAE30',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Gap(4),
                Text(
                  hasImage
                      ? (imageName ?? '\uC120\uD0DD\uD55C \uC774\uBBF8\uC9C0')
                      : '\uC120\uD0DD \uC0AC\uD56D\uC785\uB2C8\uB2E4',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.ink.withValues(alpha: 0.60),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const Gap(10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: isBusy ? null : onPick,
                      icon: const Icon(Icons.photo_library_rounded),
                      label: Text(
                        hasImage
                            ? '\uB2E4\uC2DC \uC120\uD0DD'
                            : '\uC774\uBBF8\uC9C0 \uC120\uD0DD',
                      ),
                    ),
                    if (hasImage) ...<Widget>[
                      const Gap(8),
                      IconButton.filledTonal(
                        onPressed: isBusy ? null : onClear,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: '\uC9C0\uC6B0\uAE30',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterTagPicker extends StatefulWidget {
  const _CharacterTagPicker({
    required this.groups,
    required this.selectedTags,
    required this.onTagToggled,
    required this.onClear,
  });

  final Map<String, List<String>> groups;
  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;
  final VoidCallback onClear;

  @override
  State<_CharacterTagPicker> createState() => _CharacterTagPickerState();
}

class _CharacterTagPickerState extends State<_CharacterTagPicker> {
  int _groupIndex = 0;

  @override
  Widget build(BuildContext context) {
    final entries = widget.groups.entries.toList();
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    if (_groupIndex >= entries.length) {
      _groupIndex = 0;
    }
    final selectedEntry = entries[_groupIndex];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.tune_rounded,
                  color: AppTheme.tacticalBlue,
                  size: 18,
                ),
                const Gap(6),
                Text(
                  '\uD0DC\uADF8\uB85C \uC124\uC815',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                if (widget.selectedTags.isNotEmpty) ...<Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.tacticalBlue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        '${widget.selectedTags.length}\uAC1C',
                        style: const TextStyle(
                          color: AppTheme.tacticalBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const Gap(4),
                ],
                TextButton.icon(
                  onPressed: widget.selectedTags.isEmpty
                      ? null
                      : widget.onClear,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('\uCD08\uAE30\uD654'),
                ),
              ],
            ),
            const Gap(6),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: entries.length,
                separatorBuilder: (_, _) => const Gap(6),
                itemBuilder: (BuildContext context, int index) {
                  final entry = entries[index];
                  final selectedCount = entry.value
                      .where(widget.selectedTags.contains)
                      .length;
                  final active = index == _groupIndex;
                  return _PressableScale(
                    onTap: () => setState(() => _groupIndex = index),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFEAF3FF)
                            : Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active
                              ? AppTheme.tacticalBlue.withValues(alpha: 0.54)
                              : AppTheme.ink.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: active
                                    ? AppTheme.tacticalBlue
                                    : AppTheme.ink.withValues(alpha: 0.62),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Gap(5),
                            Text(
                              entry.key,
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (selectedCount > 0) ...<Widget>[
                              const Gap(5),
                              Text(
                                '$selectedCount',
                                style: const TextStyle(
                                  color: AppTheme.tacticalBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Gap(8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: selectedEntry.value.length,
                separatorBuilder: (_, _) => const Gap(6),
                itemBuilder: (BuildContext context, int index) {
                  final tag = selectedEntry.value[index];
                  final selected = widget.selectedTags.contains(tag);
                  return FilterChip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(tag, textAlign: TextAlign.center),
                    selected: selected,
                    selectedColor: AppTheme.pastelGreen.withValues(alpha: 0.72),
                    checkmarkColor: AppTheme.tacticalBlue,
                    backgroundColor: Colors.white.withValues(alpha: 0.86),
                    side: BorderSide(
                      color: selected
                          ? AppTheme.tacticalBlue.withValues(alpha: 0.62)
                          : AppTheme.ink.withValues(alpha: 0.16),
                    ),
                    onSelected: (_) => widget.onTagToggled(tag),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterTagGroup extends StatelessWidget {
  const _CharacterTagGroup({
    required this.groupNumber,
    required this.title,
    required this.tags,
    required this.selectedTags,
    required this.selectedCount,
    required this.onTagToggled,
  });

  final int groupNumber;
  final String title;
  final List<String> tags;
  final Set<String> selectedTags;
  final int selectedCount;
  final ValueChanged<String> onTagToggled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selectedCount > 0
              ? AppTheme.tacticalBlue.withValues(alpha: 0.45)
              : AppTheme.tacticalBlue.withValues(alpha: 0.14),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          visualDensity: VisualDensity.compact,
          leading: CircleAvatar(
            radius: 11,
            backgroundColor: selectedCount > 0
                ? AppTheme.tacticalBlue.withValues(alpha: 0.92)
                : AppTheme.academyLilac.withValues(alpha: 0.68),
            child: Text(
              '$groupNumber',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selectedCount > 0 ? Colors.white : AppTheme.ink,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          title: Text(
            title,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          trailing: selectedCount > 0
              ? Text(
                  '$selectedCount',
                  style: const TextStyle(
                    color: AppTheme.tacticalBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : const Icon(Icons.expand_more_rounded),
          children: <Widget>[
            SizedBox(
              height: 34,
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
                    label: Text(tag, textAlign: TextAlign.center),
                    selected: selected,
                    selectedColor: AppTheme.pastelGreen.withValues(alpha: 0.72),
                    checkmarkColor: AppTheme.tacticalBlue,
                    backgroundColor: Colors.white.withValues(alpha: 0.86),
                    side: BorderSide(
                      color: selected
                          ? AppTheme.tacticalBlue.withValues(alpha: 0.62)
                          : AppTheme.ink.withValues(alpha: 0.16),
                    ),
                    onSelected: (_) => onTagToggled(tag),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                                    ? '\uC791\uC131\uC790 \uC8FC\uC11D · $name'
                                    : '$name · ${comment.createdAt.toLocal().toString().split('.').first}',
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

class _PostImageFallback extends StatelessWidget {
  const _PostImageFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFAEC6CF), Color(0xFFB2D8B2)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_rounded,
          size: 40,
          color: AppTheme.ink.withValues(alpha: 0.56),
        ),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const Gap(10),
          Text(message),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF5B7FB7),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: mobile ? 10 : 16,
          sigmaY: mobile ? 10 : 16,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withValues(alpha: 0.92),
                const Color(0xFFF4FAFF).withValues(alpha: 0.78),
                const Color(0xFFFFF7FB).withValues(alpha: 0.64),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.tacticalBlue.withValues(
                alpha: mobile ? 0.18 : 0.30,
              ),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.ink.withValues(alpha: mobile ? 0.07 : 0.14),
                blurRadius: mobile ? 10 : 28,
                offset: Offset(0, mobile ? 4 : 16),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.86),
                blurRadius: 0,
                offset: const Offset(0, -1),
              ),
              if (!mobile)
                BoxShadow(
                  color: AppTheme.pastelRose.withValues(alpha: 0.14),
                  blurRadius: 30,
                  offset: const Offset(-10, 5),
                ),
              if (!mobile)
                BoxShadow(
                  color: AppTheme.pastelBlue.withValues(alpha: 0.17),
                  blurRadius: 30,
                  offset: const Offset(10, 5),
                ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                child: Container(
                  height: 2,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              Padding(padding: EdgeInsets.all(mobile ? 12 : 18), child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _PastelBackground extends StatelessWidget {
  const _PastelBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFF1FBFF),
            Color(0xFFF8F3FF),
            Color(0xFFFFF1F8),
            Color(0xFFF1FFF6),
          ],
          stops: <double>[0, 0.24, 0.52, 0.75, 1],
        ),
      ),
      child: CustomPaint(painter: _TechGridPainter(), child: SizedBox.expand()),
    );
  }
}

class _StorybookPaperPainter extends CustomPainter {
  const _StorybookPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (double y = 20; y < size.height; y += 34) {
      final path = Path()
        ..moveTo(0, y)
        ..cubicTo(
          size.width * 0.25,
          y - 8,
          size.width * 0.58,
          y + 8,
          size.width,
          y - 2,
        );
      canvas.drawPath(path, linePaint);
    }

    final glintPaint = Paint()
      ..color = AppTheme.signalYellow.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;
    _drawSparkle(canvas, Offset(size.width - 28, 24), 7, glintPaint);
    _drawSparkle(canvas, const Offset(24, 34), 5, glintPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryPaperLinesPainter extends CustomPainter {
  const _DiaryPaperLinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF91A9D8).withValues(alpha: 0.13)
      ..strokeWidth = 1;
    final marginPaint = Paint()
      ..color = const Color(0xFFE49AB3).withValues(alpha: 0.16)
      ..strokeWidth = 1.2;

    for (double y = 42; y < size.height; y += 32) {
      canvas.drawLine(Offset(18, y), Offset(size.width - 18, y), linePaint);
    }
    if (size.width > 120) {
      canvas.drawLine(
        const Offset(54, 18),
        Offset(54, size.height - 18),
        marginPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryStripePainter extends CustomPainter {
  const _DiaryStripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.34);
    final soft = Paint()
      ..color = const Color(0xFFAFCBF7).withValues(alpha: 0.18);
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 13, size.height), stripe);
    }
    for (double y = size.height * 0.78; y < size.height; y += 18) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 8), soft);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryLacePainter extends CustomPainter {
  const _DiaryLacePainter({required this.compact});

  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.84)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = const Color(0xFF9FC1EF).withValues(alpha: 0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final top = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.42)
      ..lineTo(0, size.height * 0.42)
      ..close();
    canvas.drawPath(top, paint);
    canvas.drawPath(top, border);

    final radius = compact ? 8.0 : 11.0;
    for (double x = radius; x < size.width; x += radius * 1.82) {
      canvas.drawCircle(Offset(x, size.height * 0.45), radius, paint);
      canvas.drawCircle(Offset(x, size.height * 0.45), radius, border);
      canvas.drawCircle(
        Offset(x, size.height * 0.45),
        radius * 0.28,
        Paint()..color = const Color(0xFFCFE2FF),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiaryLacePainter oldDelegate) {
    return oldDelegate.compact != compact;
  }
}

class _DiaryCloudPainter extends CustomPainter {
  const _DiaryCloudPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = const Color(0xFFFFFEFA)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = const Color(0xFF8DB9EF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final dash = Paint()
      ..color = const Color(0xFFB7D4F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.14, size.height * 0.56)
      ..cubicTo(
        size.width * 0.03,
        size.height * 0.48,
        size.width * 0.08,
        size.height * 0.26,
        size.width * 0.24,
        size.height * 0.30,
      )
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.06,
        size.width * 0.52,
        size.height * 0.10,
        size.width * 0.57,
        size.height * 0.30,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.20,
        size.width * 0.88,
        size.height * 0.33,
        size.width * 0.82,
        size.height * 0.53,
      )
      ..cubicTo(
        size.width * 0.94,
        size.height * 0.62,
        size.width * 0.84,
        size.height * 0.84,
        size.width * 0.66,
        size.height * 0.78,
      )
      ..cubicTo(
        size.width * 0.50,
        size.height * 0.94,
        size.width * 0.30,
        size.height * 0.84,
        size.width * 0.27,
        size.height * 0.72,
      )
      ..cubicTo(
        size.width * 0.17,
        size.height * 0.76,
        size.width * 0.08,
        size.height * 0.68,
        size.width * 0.14,
        size.height * 0.56,
      )
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);

    for (double x = size.width * 0.20; x < size.width * 0.78; x += 12) {
      canvas.drawLine(
        Offset(x, size.height * 0.70),
        Offset(x + 4, size.height * 0.70),
        dash,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryCatEarPainter extends CustomPainter {
  const _DiaryCatEarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Paint()
      ..color = const Color(0xFFFFFEFA)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = const Color(0xFFB8CBEF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final inner = Paint()
      ..color = const Color(0xFFEAF3FF)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * 0.50, 0)
      ..quadraticBezierTo(
        size.width,
        size.height * 0.58,
        size.width * 0.74,
        size.height,
      )
      ..quadraticBezierTo(size.width * 0.34, size.height * 0.82, 0, size.height)
      ..quadraticBezierTo(
        size.width * 0.10,
        size.height * 0.36,
        size.width * 0.50,
        0,
      )
      ..close();
    final innerPath = Path()
      ..moveTo(size.width * 0.50, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.62,
        size.width * 0.58,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.66,
        size.width * 0.24,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.44,
        size.width * 0.50,
        size.height * 0.22,
      )
      ..close();
    canvas.drawPath(path, outer);
    canvas.drawPath(innerPath, inner);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryCatMouthPainter extends CustomPainter {
  const _DiaryCatMouthPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.ink.withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width / 2, size.height),
      0.1,
      2.5,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
      0.55,
      2.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryCuteMouthPainter extends CustomPainter {
  const _DiaryCuteMouthPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF69A4DD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.12),
      Offset(size.width * 0.50, size.height * 0.46),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        0,
        size.height * 0.18,
        size.width * 0.50,
        size.height * 0.72,
      ),
      0.1,
      2.45,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.50,
        size.height * 0.18,
        size.width * 0.50,
        size.height * 0.72,
      ),
      0.6,
      2.45,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryCloudBasePainter extends CustomPainter {
  const _DiaryCloudBasePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = const Color(0xFFFFFEFA)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = const Color(0xFF88B8EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.70)
      ..cubicTo(
        size.width * 0.02,
        size.height * 0.38,
        size.width * 0.22,
        size.height * 0.28,
        size.width * 0.32,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.40,
        size.height * 0.02,
        size.width * 0.70,
        size.height * 0.04,
        size.width * 0.75,
        size.height * 0.40,
      )
      ..cubicTo(
        size.width * 0.92,
        size.height * 0.30,
        size.width * 1.00,
        size.height * 0.58,
        size.width * 0.88,
        size.height * 0.78,
      )
      ..lineTo(size.width * 0.16, size.height * 0.82)
      ..cubicTo(
        size.width * 0.12,
        size.height * 0.82,
        size.width * 0.09,
        size.height * 0.78,
        size.width * 0.08,
        size.height * 0.70,
      )
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiaryWhiskerPainter extends CustomPainter {
  const _DiaryWhiskerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.ink.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width, size.height * 0.50),
      Offset(0, size.height * 0.16),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height * 0.58),
      Offset(0, size.height * 0.58),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height * 0.66),
      Offset(0, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TechGridPainter extends CustomPainter {
  const _TechGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.tacticalBlue.withValues(alpha: 0.028)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _drawSparkle(Canvas canvas, Offset center, double radius, Paint paint) {
  final path = Path()
    ..moveTo(center.dx, center.dy - radius)
    ..lineTo(center.dx + radius * 0.30, center.dy - radius * 0.30)
    ..lineTo(center.dx + radius, center.dy)
    ..lineTo(center.dx + radius * 0.30, center.dy + radius * 0.30)
    ..lineTo(center.dx, center.dy + radius)
    ..lineTo(center.dx - radius * 0.30, center.dy + radius * 0.30)
    ..lineTo(center.dx - radius, center.dy)
    ..lineTo(center.dx - radius * 0.30, center.dy - radius * 0.30)
    ..close();
  canvas.drawPath(path, paint);
}

InputDecoration _inputDecoration({
  required String hintText,
  required IconData icon,
}) {
  return InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.92),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  );
}
