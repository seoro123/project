// ignore_for_file: unused_element

import 'dart:async';
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
import '../../../diary/data/models/diary_album_model.dart';
import '../../../diary/data/models/diary_model.dart';
import '../../../diary/data/models/diary_panel_model.dart';
import '../../../diary/data/repositories/supabase_diary_repository.dart';
import '../../../persona/data/models/persona_model.dart';
import '../../../persona/data/repositories/supabase_persona_repository.dart';
import '../../data/models/diary_comment_model.dart';
import '../../data/models/social_feed_item_model.dart';
import '../../data/repositories/supabase_feed_repository.dart';

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
    return 'Gemini 이미지 생성 한도/결제 오류입니다. API 키가 속한 Google Cloud 프로젝트에 결제 계정이 연결됐는지 확인하고, 결제 직후라면 몇 분 뒤 다시 시도해 주세요.';
  }
  if (lower.contains('insufficient_quota') ||
      lower.contains('exceeded your current quota')) {
    return 'AI 사용 한도 또는 결제 반영 문제입니다. 현재 사용하는 API 키의 프로젝트 결제/쿼터를 확인해 주세요.';
  }
  if (lower.contains('billing') || lower.contains('payment required')) {
    return 'AI 결제 설정을 확인해 주세요. Gemini API 결제/키가 현재 프로젝트에 연결되어 있어야 합니다.';
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
    return 'Supabase Edge Function Secret의 GEMINI_API_KEY와 IMAGE_PROVIDER 설정을 확인해 주세요.';
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
        onSearchChanged: (_) => setState(() {}),
        onTagToggled: _toggleTag,
        onFilterPressed: () {
          setState(() => _showTagFilter = !_showTagFilter);
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
          if (_tabIndex == 0) const SafeArea(child: _ProfileMenuButton()),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFDFF).withValues(alpha: 0.92),
              border: Border(
                top: BorderSide(
                  color: AppTheme.tacticalBlue.withValues(alpha: 0.42),
                ),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppTheme.graphite.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
                BoxShadow(
                  color: AppTheme.pastelRose.withValues(alpha: 0.14),
                  blurRadius: 34,
                  offset: const Offset(-18, -8),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: _tabIndex,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (int index) {
                setState(() => _tabIndex = index);
              },
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.dashboard_rounded),
                  label: 'Social',
                ),
                NavigationDestination(
                  icon: Icon(Icons.face_retouching_natural_rounded),
                  label: '\uCE90\uB9AD\uD130',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_stories_rounded),
                  label: 'Diary',
                ),
              ],
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
    required this.onSearchChanged,
    required this.onTagToggled,
    required this.onFilterPressed,
    required this.onFeedChanged,
  });

  final int refreshTick;
  final TextEditingController searchController;
  final Set<String> selectedTags;
  final bool showTagFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onTagToggled;
  final VoidCallback onFilterPressed;
  final VoidCallback onFeedChanged;

  @override
  Widget build(BuildContext context) {
    const tags = <String>[
      'healing',
      'comic',
      'fantasy',
      'rpg',
      'cafe',
      'rain',
      'daily',
      'reaction',
      'school',
      'romance',
      'serious',
      'anime',
      '3d',
      'chibi',
      'sitcom',
      'monologue',
    ];

    return CustomScrollView(
      slivers: <Widget>[
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
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          textAlign: TextAlign.center,
                          onChanged: onSearchChanged,
                          decoration: _inputDecoration(
                            hintText: 'Search users or titles',
                            icon: Icons.search_rounded,
                          ),
                        ),
                      ),
                      const Gap(10),
                      FilledButton.icon(
                        onPressed: onFilterPressed,
                        icon: Icon(
                          showTagFilter
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.tune_rounded,
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
                          label: Text('#$tag'),
                          onDeleted: () => onTagToggled(tag),
                        );
                      }).toList(),
                    ),
                  ],
                  if (showTagFilter) ...<Widget>[
                    const Gap(12),
                    _SocialTagFilterPanel(
                      tags: tags,
                      selectedTags: selectedTags,
                      onTagToggled: onTagToggled,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
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
                        message: 'Loading shared diaries',
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
                      maxCrossAxisExtent: 280,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 22,
                      itemCount: posts.length,
                      itemBuilder: (BuildContext context, int index) {
                        return _DimensionalCardSlot(
                          index: index,
                          depth: 1.0,
                          child: _PostCard(
                            post: posts[index],
                            aspectRatio: _postAspectRatio(index),
                            onChanged: onFeedChanged,
                          ),
                        );
                      },
                    );
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
    );
  }

  double _postAspectRatio(int index) {
    const rhythm = <double>[0.86, 0.94, 0.86, 0.94];
    return rhythm[index % rhythm.length];
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

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: PopupMenuButton<String>(
          tooltip: 'Profile',
          offset: const Offset(0, 48),
          onSelected: (String value) async {
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
              color: Colors.white.withValues(alpha: 0.86),
              border: Border.all(color: const Color(0xFF9FC4FF)),
              borderRadius: BorderRadius.circular(999),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppTheme.tacticalBlue.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
              ),
            ),
          ),
        ),
      ),
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
    return SizedBox(
      height: 156,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          border: Border.all(color: const Color(0xFFC7DFFF)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 10, 18, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((String tag) {
                final selected = selectedTags.contains(tag);
                return FilterChip(
                  label: Text('#$tag'),
                  selected: selected,
                  selectedColor: AppTheme.pastelGreen,
                  onSelected: (_) => onTagToggled(tag),
                );
              }).toList(),
            ),
          ),
        ),
      ),
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
  final PageController _controller = PageController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _albumController = TextEditingController();
  final Map<String, String> _albumIdsByTitle = <String, String>{};
  final Map<String, String> _templateIdsByName = <String, String>{};
  final Map<String, int> _albumDiaryCounts = <String, int>{};
  final Map<String, List<DiaryModel>> _albumDiariesByTitle =
      <String, List<DiaryModel>>{};
  final List<DiaryPanelModel> _generatedPanels = <DiaryPanelModel>[];
  final List<String> _generatedImageUrls = <String>[];

  int _page = 0;
  String _template = '';
  String _album = '\uC77C\uC0C1 \uAE30\uB85D';
  String _weather = 'sunny';
  String _saveMode = 'archive';
  String _webtoonFormat = '\uADF8\uB9BC \uAC15\uC870';
  String _artStyle = '\uCF54\uBBF9\uC2A4 \uC2A4\uD0C0\uC77C';
  String _artSubStyle = 'LD';
  String _genre = '\uC77C\uC0C1/\uCF54\uBBF9';
  String _genreSubtype = '\uD559\uAD50';
  bool _isSaving = false;
  bool _isLoadingArchive = false;
  bool _isLoadingTemplates = false;
  String? _selectedArchiveAlbum;

  final List<String> _albums = <String>[
    '\uC77C\uC0C1 \uAE30\uB85D',
    '\uD559\uAD50',
    '\uBE44\uACF5\uAC1C',
  ];
  final List<String> _templates = <String>[];

  @override
  void initState() {
    super.initState();
    unawaited(_loadAlbums());
    unawaited(_loadDiaryTemplates());
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
    return Padding(
      padding: const EdgeInsets.all(18),
      child: _DiaryFigmaFrame(
        title: _title,
        onClose: () => _go(0),
        child: PageView(
          controller: _controller,
          onPageChanged: (int value) => setState(() => _page = value),
          children: <Widget>[
            _DiaryOpenPage(
              onArchive: () {
                unawaited(_loadAlbums());
                _go(8);
              },
              onStart: () => _go(1),
            ),
            _DiaryWriteScreen(
              titleController: _titleController,
              bodyController: _bodyController,
              tagController: _tagController,
              weather: _weather,
              onWeatherChanged: (String value) {
                setState(() => _weather = value);
              },
              onBack: () => _go(0),
              onNext: () => _go(2),
            ),
            _DiaryTagScreen(
              topLabel:
                  '\uC6D0\uD558\uB294 \uC77C\uAE30 \uD45C\uD604 \uBC29\uC2DD\uC744 \uACE8\uB77C \uC8FC\uC138\uC694',
              bottomLabel: '\uC7A5\uB974 \uD0DC\uADF8',
              cards: const <_FigmaCardData>[
                _FigmaCardData('\uADF8\uB9BC \uAC15\uC870', 'image'),
                _FigmaCardData('\uBB38\uB2F5\uD615', 'Q&A'),
                _FigmaCardData('\uB9AC\uC561\uC158 \uAC15\uC870', 'reaction'),
              ],
              onSelected: (String value) {
                setState(() => _webtoonFormat = value);
              },
              onBack: () => _go(1),
              onNext: () => _go(3),
              showSkip: true,
            ),
            _DiaryTagScreen(
              topLabel:
                  '\uC6D0\uD558\uB294 \uD558\uC704 \uADF8\uB9BC\uCCB4\uB97C \uACE8\uB77C \uC8FC\uC138\uC694',
              bottomLabel: '\uC544\uD2B8 \uC2A4\uD0C0\uC77C \uD0DC\uADF8',
              cards: const <_FigmaCardData>[
                _FigmaCardData(
                  '\uCF54\uBBF9\uC2A4 \uC2A4\uD0C0\uC77C',
                  'comics',
                ),
                _FigmaCardData(
                  '\uC77C\uBCF8 \uC560\uB2C8 \uC2A4\uD0C0\uC77C',
                  'anime',
                ),
                _FigmaCardData(
                  '\uCE90\uB9AD\uD130 \uBC0F \uC2E4\uC0AC \uC2A4\uD0C0\uC77C',
                  'character',
                ),
              ],
              onSelected: _selectArtStyle,
              onBack: () => _go(2),
              onNext: () => _go(4),
            ),
            _DiaryTagScreen(
              topLabel:
                  '\uC6D0\uD558\uB294 \uD558\uC704 \uADF8\uB9BC\uCCB4\uB97C \uACE8\uB77C \uC8FC\uC138\uC694',
              bottomLabel:
                  '\uC544\uD2B8 \uC2A4\uD0C0\uC77C \uD558\uC704 \uD0DC\uADF8',
              cards: _artSubStyleCards,
              onSelected: (String value) {
                setState(() => _artSubStyle = value);
              },
              onBack: () => _go(3),
              onNext: () => _go(5),
            ),
            _DiaryTagScreen(
              topLabel:
                  '\uC6D0\uD558\uB294 \uC7A5\uB974 \uD0DC\uADF8\uB97C \uACE8\uB77C \uC8FC\uC138\uC694',
              bottomLabel: '\uC7A5\uB974 \uD0DC\uADF8',
              cards: const <_FigmaCardData>[
                _FigmaCardData('\uC77C\uC0C1/\uCF54\uBBF9', 'daily'),
                _FigmaCardData('\uC2DC\uB9AC\uC5B4\uC2A4', 'serious'),
                _FigmaCardData('\uD310\uD0C0\uC9C0/\uC561\uC158', 'action'),
                _FigmaCardData('\uD790\uB9C1/\uB85C\uB9E8\uC2A4', 'healing'),
              ],
              onSelected: _selectGenre,
              onBack: () => _go(4),
              onNext: () => _go(6),
            ),
            _DiaryTagScreen(
              topLabel:
                  '\uC120\uD0DD\uD55C \uC7A5\uB974\uC758 \uD558\uC704 \uD0DC\uADF8\uB97C \uACE8\uB77C \uC8FC\uC138\uC694',
              bottomLabel: '\uC7A5\uB974 \uD558\uC704 \uD0DC\uADF8',
              cards: _genreSubtypeCards,
              onSelected: (String value) {
                setState(() => _genreSubtype = value);
              },
              onBack: () => _go(5),
              onNext: () => _go(7),
              showSkip: true,
            ),
            _DiaryFinalScreen(
              template: _template,
              templates: _templates,
              album: _album,
              albums: _albums,
              saveMode: _saveMode,
              titleText: _titleController.text,
              weather: _weather,
              artStyle: _artStyle,
              artSubStyle: _artSubStyle,
              genre: _genre,
              genreSubtype: _genreSubtype,
              keywordTags: _keywordTags(),
              isSaving: _isSaving,
              onSaveModeChanged: (String value) {
                setState(() => _saveMode = value);
              },
              onTemplateChanged: (String value) {
                setState(() => _template = value);
              },
              onAlbumChanged: (String value) {
                setState(() => _album = value);
              },
              onCreateAlbum: _createAlbum,
              onGenerate: _saveDiary,
              onBack: () => _go(6),
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
              onRefresh: _loadAlbums,
            ),
            _GeneratedDiarySlideScreen(
              panels: _generatedPanels,
              imageUrls: _generatedImageUrls,
              onBack: () => _go(7),
              onDone: () {
                if (_saveMode == 'share') {
                  widget.onSharedDiaryCreated();
                  _go(0);
                } else {
                  _go(8);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String get _title {
    return switch (_page) {
      0 => '\uB3CC\uBC14(\uC5F4\uAE30)',
      1 => '\uC77C\uAE30(\uC791\uC131)',
      2 => '\uC77C\uAE30(\uC720\uD615 \uD0DC\uADF8)',
      3 => '\uC77C\uAE30(\uC544\uD2B8 \uC2A4\uD0C0\uC77C \uD0DC\uADF8)',
      4 =>
        '\uC77C\uAE30(\uC544\uD2B8 \uC2A4\uD0C0\uC77C \uD558\uC704 \uD0DC\uADF8)',
      5 => '\uC77C\uAE30(\uC7A5\uB974 \uD0DC\uADF8)',
      6 => '\uC77C\uAE30(\uC7A5\uB974 \uD558\uC704 \uD0DC\uADF8)',
      8 => '\uC544\uCE74\uC774\uBE0C',
      9 => '\uC77C\uAE30(\uC0DD\uC131 \uACB0\uACFC)',
      _ => '\uC77C\uAE30(\uCD5C\uC885 \uC124\uC815)',
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
      final albums = await repository.fetchMyAlbums(user.id);
      if (!mounted || albums.isEmpty) {
        if (mounted) {
          setState(() => _isLoadingArchive = false);
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
        _album = _albums.first;
        _selectedArchiveAlbum ??= _albums.first;
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
      final myTemplates = visibleTemplates
          .where((PersonaModel template) => template.userId == user.id)
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _templates
          ..clear()
          ..addAll(
            myTemplates.map((PersonaModel template) => template.name).toSet(),
          );
        _templateIdsByName
          ..clear()
          ..addEntries(
            myTemplates.map(
              (PersonaModel template) => MapEntry(template.name, template.id),
            ),
          );
        if (_templates.isEmpty) {
          _template = '';
        } else if (!_templates.contains(_template)) {
          _template = _templates.first;
        }
        _isLoadingTemplates = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _templates.clear();
          _templateIdsByName.clear();
          if (_templates.isEmpty) {
            _template = '';
          } else if (!_templates.contains(_template)) {
            _template = _templates.first;
          }
          _isLoadingTemplates = false;
        });
      }
    }
  }

  void _createAlbum(String title) {
    unawaited(_createAlbumAsync(title));
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
      var personaId = _templateIdsByName[_template];
      if (personaId == null) {
        await _loadDiaryTemplates();
        personaId = _templateIdsByName[_template];
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
        genre: _selectedGenre(),
        genreSubtype: _selectedGenreSubtype(),
        keywordTags: _keywordTags(),
        personaId: personaId,
        isPublic: _saveMode == 'share',
      );
      var panels = await repository.fetchDiaryPanels(diary.id);
      panels = await _drawFinalSpeechBubbles(
        repository: repository,
        userId: user.id,
        diaryId: diary.id,
        panels: panels,
      );
      final finalImageUrls = panels
          .map((DiaryPanelModel panel) => panel.imageUrl)
          .whereType<String>()
          .where((String url) => url.trim().isNotEmpty)
          .toList();
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
            <String>{
              ...finalImageUrls,
              ...panels
                  .map((DiaryPanelModel panel) => panel.imageUrl)
                  .whereType<String>(),
            }.where((String url) => url.trim().isNotEmpty),
          );
      });

      _showMessage(
        _saveMode == 'share'
            ? '\uACF5\uC720 \uC77C\uAE30\uB85C \uC800\uC7A5\uB410\uC2B5\uB2C8\uB2E4. \uC18C\uC15C \uD53C\uB4DC\uC5D0 \uD45C\uC2DC\uB429\uB2C8\uB2E4.'
            : '\uC77C\uAE30\uAC00 \uC568\uBC94\uC5D0 \uC18C\uC7A5\uB410\uC2B5\uB2C8\uB2E4.',
      );
      if (_saveMode == 'share') {
        widget.onSharedDiaryCreated();
      }
      _go(9);
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
  }) async {
    final renderedPanels = <DiaryPanelModel>[];
    for (final panel in panels) {
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
    final textRect = _dialogueTextRect(
      width: width,
      height: height,
      prompt: prompt,
      text: text,
    );
    final bubbleRect = textRect
        .inflate(width * 0.055)
        .intersect(
          Rect.fromLTWH(
            width * 0.02,
            height * 0.02,
            width * 0.96,
            height * 0.94,
          ),
        );
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
      maxLines: 5,
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
    final bubbleWidth = width * (0.56 + lengthFactor * 0.24);
    final bubbleHeight = height * (0.16 + lengthFactor * 0.13);
    final marginX = width * 0.06;
    final topY = height * 0.08;
    final sideY = height * 0.32;
    final bottomY = height * 0.62;
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
      return candidates[3];
    }
    if (prompt.contains('right_side')) {
      return candidates[4];
    }
    if (prompt.contains('bottom_left')) {
      return candidates[5];
    }
    if (prompt.contains('bottom_right')) {
      return candidates[6];
    }
    return candidates[2];
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
    final tailWidth = width * 0.08;
    final tailHeight = height * 0.05;
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
        maxLines: 5,
      )..layout(maxWidth: maxWidth);
      if (painter.height <= maxHeight && !painter.didExceedMaxLines) {
        return size;
      }
    }
    return imageWidth * 0.026;
  }

  List<String> _keywordTags() {
    return _tagController.text
        .split(RegExp(r'[\s,]+'))
        .map((String tag) => tag.trim().replaceFirst('#', ''))
        .where((String tag) => tag.isNotEmpty)
        .toSet()
        .toList();
  }

  WebtoonFormat _selectedWebtoonFormat() {
    return switch (_webtoonFormat) {
      '\uBB38\uB2F5\uD615' => WebtoonFormat.qaSlide,
      '\uB9AC\uC561\uC158 \uAC15\uC870' => WebtoonFormat.reactionFocus,
      _ => WebtoonFormat.imageFocus,
    };
  }

  DiaryArtStyle _selectedArtStyle() {
    if (_artStyle == '\uCF54\uBBF9\uC2A4 \uC2A4\uD0C0\uC77C') {
      return _artSubStyle == 'SD'
          ? DiaryArtStyle.comicsSd
          : DiaryArtStyle.comicsLd;
    }
    if (_artStyle == '\uC77C\uBCF8 \uC560\uB2C8 \uC2A4\uD0C0\uC77C') {
      return _artSubStyle == 'SD'
          ? DiaryArtStyle.animeSd
          : DiaryArtStyle.animeLd;
    }
    return _artSubStyle == '3D'
        ? DiaryArtStyle.realistic3d
        : DiaryArtStyle.simple2d;
  }

  DiaryGenre _selectedGenre() {
    return switch (_genre) {
      '\uC2DC\uB9AC\uC5B4\uC2A4' => DiaryGenre.serious,
      '\uD310\uD0C0\uC9C0/\uC561\uC158' => DiaryGenre.fantasyAction,
      '\uD790\uB9C1/\uB85C\uB9E8\uC2A4' => DiaryGenre.healingRomance,
      _ => DiaryGenre.dailyComic,
    };
  }

  String _selectedGenreSubtype() {
    return switch (_genreSubtype) {
      '\uD559\uAD50' => 'school',
      '\uC2DC\uD2B8\uCF64' => 'sitcom',
      '\uB2E4\uD050\uBA58\uD130\uB9AC' => 'documentary',
      '\uBAA8\uB180\uB85C\uADF8' => 'monologue',
      'RPG' => 'rpg',
      '\uC5F4\uD608\uBB3C' => 'hot_blooded',
      '\uCCAD\uCD98\uBB3C' => 'youth',
      '\uC77C\uC0C1 \uD790\uB9C1' => 'daily_healing',
      _ => _genreSubtype,
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.center)),
    );
  }

  List<_FigmaCardData> get _artSubStyleCards {
    if (_artStyle ==
        '\uCE90\uB9AD\uD130 \uBC0F \uC2E4\uC0AC \uC2A4\uD0C0\uC77C') {
      return const <_FigmaCardData>[
        _FigmaCardData('\uB2E8\uC21C \uCE90\uB9AD\uD130', 'simple'),
        _FigmaCardData('3D', '3D'),
      ];
    }

    return const <_FigmaCardData>[
      _FigmaCardData('LD', 'LD'),
      _FigmaCardData('SD', 'SD'),
    ];
  }

  List<_FigmaCardData> get _genreSubtypeCards {
    return switch (_genre) {
      '\uC2DC\uB9AC\uC5B4\uC2A4' => const <_FigmaCardData>[
        _FigmaCardData('\uB2E4\uD050\uBA58\uD130\uB9AC', 'docu'),
        _FigmaCardData('\uBAA8\uB180\uB85C\uADF8', 'mono'),
      ],
      '\uD310\uD0C0\uC9C0/\uC561\uC158' => const <_FigmaCardData>[
        _FigmaCardData('RPG', 'RPG'),
        _FigmaCardData('\uC5F4\uD608\uBB3C', 'hot'),
      ],
      '\uD790\uB9C1/\uB85C\uB9E8\uC2A4' => const <_FigmaCardData>[
        _FigmaCardData('\uCCAD\uCD98\uBB3C', 'youth'),
        _FigmaCardData('\uC77C\uC0C1 \uD790\uB9C1', 'heal'),
      ],
      _ => const <_FigmaCardData>[
        _FigmaCardData('\uD559\uAD50', 'school'),
        _FigmaCardData('\uC2DC\uD2B8\uCF64', 'sitcom'),
      ],
    };
  }

  void _selectArtStyle(String value) {
    setState(() {
      _artStyle = value;
      _artSubStyle =
          value == '\uCE90\uB9AD\uD130 \uBC0F \uC2E4\uC0AC \uC2A4\uD0C0\uC77C'
          ? '\uB2E8\uC21C \uCE90\uB9AD\uD130'
          : 'LD';
    });
  }

  void _selectGenre(String value) {
    setState(() {
      _genre = value;
      _genreSubtype = _genreSubtypeCards.first.label;
    });
  }

  void _go(int page) {
    Feedback.forTap(context);
    SystemSound.play(SystemSoundType.click);
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
    );
  }
}

class _DiaryFigmaFrame extends StatelessWidget {
  const _DiaryFigmaFrame({
    required this.title,
    required this.child,
    required this.onClose,
  });

  final String title;
  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFEFF),
        border: Border.all(color: const Color(0xFFD2E3FA), width: 1.8),
        borderRadius: BorderRadius.circular(2),
        boxShadow: <BoxShadow>[
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
          const Positioned.fill(child: _FigmaPastelWash()),
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
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.tacticalBlue,
                          border: Border(
                            bottom: BorderSide(
                              color: AppTheme.tacticalBlue.withValues(
                                alpha: 0.54,
                              ),
                            ),
                          ),
                          boxShadow: <BoxShadow>[
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
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            shadows: <Shadow>[
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
                    if (title != '\uB3CC\uBC14(\uC5F4\uAE30)')
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.cancel_rounded),
                          color: Colors.white,
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

class _DiaryOpenPage extends StatelessWidget {
  const _DiaryOpenPage({required this.onArchive, required this.onStart});

  final VoidCallback onArchive;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 28, 48, 34),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final compact = constraints.maxWidth < 620;
          final cards = <Widget>[
            _FigmaGradientButton(
              title: 'ARCHIVE',
              subtitle: '\uADF8\uB3D9\uC548\uC758 \uAE30\uB85D',
              colors: const <Color>[Color(0xFFF09AB8), Color(0xFFFFC7B0)],
              icon: Icons.inventory_2_rounded,
              onTap: onArchive,
            ),
            _FigmaGradientButton(
              title: 'RECORDING START',
              subtitle: '\uC77C\uAE30 \uC791\uC131 \uC2DC\uC791',
              colors: const <Color>[Color(0xFF8FB8F8), Color(0xFF8FE0A1)],
              icon: Icons.edit_note_rounded,
              onTap: onStart,
            ),
          ];

          if (compact) {
            return Column(
              children: <Widget>[
                Expanded(child: cards.first),
                const Gap(16),
                Expanded(child: cards.last),
              ],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(child: cards.first),
              const Gap(32),
              Expanded(child: cards.last),
            ],
          );
        },
      ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(44, 18, 44, 20),
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
                              const Gap(12),
                              SizedBox(
                                height: 330,
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
              const Gap(14),
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
                '\uC624\uB298\uC758 \uC7A5\uBA74\uC744 \uC801\uC5B4 \uC8FC\uC138\uC694',
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
                '#\uC911\uC694 \uD0DC\uADF8',
              ).copyWith(contentPadding: const EdgeInsets.all(16)),
            ),
          ),
          const Gap(8),
          SizedBox(
            height: 44,
            child: Center(
              child: Text(
                '\uD0DC\uADF8\uB294 \uC778\uBB3C, \uAC10\uC815, \uC7A5\uC18C\uB97C \uACE0\uC815\uD558\uB294 \uC6A9\uB3C4\uC785\uB2C8\uB2E4.',
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(46, 8, 46, 18),
      child: Column(
        children: <Widget>[
          _FigmaPill(text: topLabel),
          const Gap(16),
          Expanded(
            child: Row(
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
          const Gap(8),
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
    required this.template,
    required this.templates,
    required this.album,
    required this.albums,
    required this.saveMode,
    required this.titleText,
    required this.weather,
    required this.artStyle,
    required this.artSubStyle,
    required this.genre,
    required this.genreSubtype,
    required this.keywordTags,
    required this.isSaving,
    required this.onSaveModeChanged,
    required this.onTemplateChanged,
    required this.onAlbumChanged,
    required this.onCreateAlbum,
    required this.onGenerate,
    required this.onBack,
    required this.isLoadingTemplates,
    required this.previewImageUrls,
  });

  final String template;
  final List<String> templates;
  final String album;
  final List<String> albums;
  final String saveMode;
  final String titleText;
  final String weather;
  final String artStyle;
  final String artSubStyle;
  final String genre;
  final String genreSubtype;
  final List<String> keywordTags;
  final bool isSaving;
  final bool isLoadingTemplates;
  final List<String> previewImageUrls;
  final ValueChanged<String> onSaveModeChanged;
  final ValueChanged<String> onTemplateChanged;
  final ValueChanged<String> onAlbumChanged;
  final ValueChanged<String> onCreateAlbum;
  final VoidCallback onGenerate;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final hasTemplates = templates.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(46, 8, 46, 18),
      child: Column(
        children: <Widget>[
          const _FigmaPill(
            text: '\uCE90\uB9AD\uD130 / \uC800\uC7A5 \uBC29\uC2DD',
          ),
          const Gap(12),
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: _DiaryWebtoonPreviewCard(
                      imageUrls: previewImageUrls,
                      isLoading: isSaving,
                    ),
                  ),
                  const Gap(18),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        _FigmaSmallField(
                          text:
                              "\uC81C\uBAA9 : ${titleText.trim().isEmpty ? '\uC81C\uBAA9 \uC5C6\uC74C' : titleText.trim()}",
                        ),
                        const Gap(10),
                        _FigmaSmallField(
                          text: '\uB0A0\uC528 : ${_weatherLabel(weather)}',
                        ),
                        const Gap(10),
                        _FigmaSmallField(
                          text:
                              '\uC120\uD0DD\uD55C \uC544\uD2B8\uC2A4\uD0C0\uC77C : $artStyle',
                        ),
                        const Gap(10),
                        _FigmaSmallField(
                          text:
                              '\uC120\uD0DD\uD55C \uD558\uC704\uD0DC\uADF8 : $artSubStyle',
                        ),
                        const Gap(10),
                        _FigmaSmallField(
                          text: '\uC120\uD0DD\uD55C \uC7A5\uB974 : $genre',
                        ),
                        const Gap(10),
                        _FigmaSmallField(
                          text:
                              '\uC120\uD0DD\uD55C \uC7A5\uB974 \uD558\uC704\uD0DC\uADF8 : $genreSubtype',
                        ),
                        const Gap(10),
                        _FigmaSmallField(
                          text:
                              "\uC911\uC694 \uD0DC\uADF8 : ${keywordTags.isEmpty ? '\uC5C6\uC74C' : keywordTags.map((String tag) => '#$tag').join(' ')}",
                        ),
                        const Gap(10),
                        _TemplateChoiceSelector(
                          selected: template,
                          templates: templates,
                          onChanged: onTemplateChanged,
                          isLoading: isLoadingTemplates,
                        ),
                        const Gap(10),
                        _SaveModeSelector(
                          selected: saveMode,
                          onChanged: onSaveModeChanged,
                        ),
                        if (saveMode == 'archive') ...<Widget>[
                          const Gap(10),
                          _FigmaDropdown(
                            label:
                                '\uC18C\uC7A5\uD560 \uC568\uBC94 \uC120\uD0DD',
                            value: album,
                            values: albums,
                            onChanged: onAlbumChanged,
                          ),
                          const Gap(8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _showAlbumDialog(context),
                              icon: const Icon(Icons.create_new_folder_rounded),
                              label: const Text('\uC0C8 \uC568\uBC94'),
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
          const Gap(10),
          Row(
            children: <Widget>[
              _FigmaBackButton(onTap: onBack),
              const Spacer(),
              FilledButton(
                onPressed: isSaving || !hasTemplates ? null : onGenerate,
                child: Text(
                  !hasTemplates
                      ? '\uCE90\uB9AD\uD130 \uD544\uC694'
                      : isSaving
                      ? '\uC800\uC7A5 \uC911...'
                      : saveMode == 'share'
                      ? '\uACF5\uC720\uB85C \uC800\uC7A5'
                      : '\uC18C\uC7A5\uC73C\uB85C \uC800\uC7A5',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAlbumDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('\uC0C8 \uC568\uBC94 \uB9CC\uB4E4\uAE30'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '\uC568\uBC94 \uC774\uB984',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('\uCDE8\uC18C'),
            ),
            FilledButton(
              onPressed: () {
                onCreateAlbum(controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('\uB9CC\uB4E4\uAE30'),
            ),
          ],
        );
      },
    );
  }
}

class _DiaryWebtoonPreviewCard extends StatelessWidget {
  const _DiaryWebtoonPreviewCard({
    required this.imageUrls,
    required this.isLoading,
  });

  final List<String> imageUrls;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final imageUrl = imageUrls.isEmpty ? null : imageUrls.first;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        border: Border.all(color: const Color(0xFF9FC4FF), width: 1.5),
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
              const _FigmaEmptyCard(
                data: _FigmaCardData('\uBBF8\uB9AC\uBCF4\uAE30', 'image'),
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
                bottom: 8,
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

class _GeneratedDiarySlideScreen extends StatefulWidget {
  const _GeneratedDiarySlideScreen({
    required this.panels,
    required this.imageUrls,
    required this.onBack,
    required this.onDone,
  });

  final List<DiaryPanelModel> panels;
  final List<String> imageUrls;
  final VoidCallback onBack;
  final VoidCallback onDone;

  @override
  State<_GeneratedDiarySlideScreen> createState() =>
      _GeneratedDiarySlideScreenState();
}

class _GeneratedDiarySlideScreenState
    extends State<_GeneratedDiarySlideScreen> {
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
}

class _PanelSlideData {
  const _PanelSlideData({
    required this.imageUrl,
    required this.index,
    this.panelType,
    this.dialogue,
    this.prompt,
    this.tags = const <String>[],
  });

  final String imageUrl;
  final int index;
  final String? panelType;
  final String? dialogue;
  final String? prompt;
  final List<String> tags;

  static List<_PanelSlideData> fromPanels({
    required List<DiaryPanelModel> panels,
    required List<String> fallbackImageUrls,
  }) {
    final slides =
        panels
            .where(
              (DiaryPanelModel panel) =>
                  panel.imageUrl != null && panel.imageUrl!.trim().isNotEmpty,
            )
            .map(
              (DiaryPanelModel panel) => _PanelSlideData(
                imageUrl: panel.imageUrl!,
                index: panel.panelOrder,
                panelType: panel.panelType,
                dialogue: panel.dialogue,
                prompt: panel.prompt,
                tags: _extractPanelTags(panel.prompt),
              ),
            )
            .toList()
          ..sort(
            (_PanelSlideData a, _PanelSlideData b) =>
                a.index.compareTo(b.index),
          );

    if (slides.isNotEmpty) {
      return slides;
    }

    return fallbackImageUrls
        .where((String url) => url.trim().isNotEmpty)
        .toList()
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
  });

  final String url;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return fallback;
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
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
            return Image.memory(bytes, fit: BoxFit.cover);
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

class _TemplateChoiceSelector extends StatelessWidget {
  const _TemplateChoiceSelector({
    required this.selected,
    required this.templates,
    required this.onChanged,
    this.isLoading = false,
  });

  final String selected;
  final List<String> templates;
  final ValueChanged<String> onChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const _FigmaTinyTag(text: '\uCE90\uB9AD\uD130 \uC120\uD0DD'),
        const Gap(8),
        if (isLoading) ...<Widget>[
          const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          const Gap(8),
        ],
        if (templates.isEmpty)
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
        else
          Row(
            children: templates.map((String template) {
              final isSelected = selected == template;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _PressableScale(
                    onTap: () => onChanged(template),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFDDEBFF)
                            : Colors.white.withValues(alpha: 0.62),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6EA3FF)
                              : const Color(0xFF9FC4FF),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            template,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF5B8EEB),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
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

class _SaveModeSelector extends StatelessWidget {
  const _SaveModeSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const <ButtonSegment<String>>[
        ButtonSegment<String>(
          value: 'share',
          icon: Icon(Icons.ios_share_rounded),
          label: Text('\uACF5\uC720'),
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
    );
  }
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
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(46, 18, 46, 24),
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
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: _figmaField('\uC568\uBC94 \uC774\uB984'),
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
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.15,
                        ),
                    itemCount: albums.length,
                    itemBuilder: (BuildContext context, int index) {
                      final albumTitle = albums[index];
                      final diaryCount = albumDiaryCounts[albumTitle] ?? 0;
                      return InkWell(
                        onTap: () {
                          onAlbumSelected(albumTitle);
                          _showAlbumDiariesDialog(context, albumTitle);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.64),
                            border: Border.all(color: const Color(0xFF9FC4FF)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  albumTitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF6EA3FF),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Gap(6),
                                Text(
                                  '$diaryCount diary',
                                  style: const TextStyle(
                                    color: Color(0xFF9AA8C4),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        albumTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        unawaited(onRefresh());
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: '\uC0C8\uB85C\uACE0\uCE68',
                    ),
                  ],
                ),
                const Gap(10),
                if (isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (diaries.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        '\uC774 \uC568\uBC94\uC5D0 \uC18C\uC7A5\uD55C \uC77C\uAE30\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: diaries.length,
                      separatorBuilder: (_, _) => const Gap(10),
                      itemBuilder: (BuildContext context, int index) {
                        final diary = diaries[index];
                        return _ArchiveDiaryTile(diary: diary);
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
}

class _ArchiveDiaryTile extends StatelessWidget {
  const _ArchiveDiaryTile({required this.diary});

  final DiaryModel diary;

  @override
  Widget build(BuildContext context) {
    final title = diary.title?.trim().isNotEmpty == true
        ? diary.title!.trim()
        : '\uC81C\uBAA9 \uC5C6\uB294 \uC77C\uAE30';
    final dateText = diary.diaryAt == null
        ? ''
        : '${diary.diaryAt!.year}.${diary.diaryAt!.month.toString().padLeft(2, '0')}.${diary.diaryAt!.day.toString().padLeft(2, '0')}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        border: Border.all(color: const Color(0xFFC7DFFF)),
        borderRadius: BorderRadius.circular(8),
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
                imageUrl: diary.imageUrls.isEmpty
                    ? null
                    : diary.imageUrls.first,
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
          ],
        ),
      ),
    );
  }
}

class _ArchiveDiaryPreview extends StatelessWidget {
  const _ArchiveDiaryPreview({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
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
              color: AppTheme.ink.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 13),
            ),
            BoxShadow(
              color: colors.first.withValues(alpha: 0.24),
              blurRadius: 24,
              offset: const Offset(-8, 6),
            ),
            BoxShadow(
              color: colors.last.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(8, 5),
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
            const Positioned.fill(child: _CornerBrackets()),
            if (icon != null)
              Positioned(
                right: -7,
                bottom: -11,
                child: Icon(
                  icon,
                  size: 76,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const Gap(6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w800,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        border: Border.all(color: const Color(0xFFC3DAFF), width: 1.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.09),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: const Color(0xFFE2EFFF).withValues(alpha: 0.58),
            blurRadius: 18,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.52),
                      Colors.transparent,
                      const Color(0xFFF3FAFF).withValues(alpha: 0.34),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(padding: const EdgeInsets.all(14), child: child),
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
      child: Column(
        children: <Widget>[
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.50),
                border: Border.all(color: const Color(0xFF9FC4FF), width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: <Widget>[
                  const Positioned.fill(child: _CornerBrackets()),
                  Center(
                    child: Text(
                      data.placeholder,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF75A8FF),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(8),
          Text(
            data.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.graphite,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
    hintStyle: const TextStyle(color: Color(0xFF9BB8E8)),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.86),
    contentPadding: const EdgeInsets.all(12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFC3DAFF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFC3DAFF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFF83A9ED), width: 1.7),
    ),
  );
}

class _FigmaCardData {
  const _FigmaCardData(this.label, this.placeholder);

  final String label;
  final String placeholder;
}

class _TemplatePage extends StatefulWidget {
  const _TemplatePage();

  @override
  State<_TemplatePage> createState() => _TemplatePageState();
}

class _TemplatePageState extends State<_TemplatePage> {
  final TextEditingController _memoController = TextEditingController();
  final Set<String> _selectedTags = <String>{};
  int _step = 0;
  String _mode = 'prose';
  String _templateName = '\uB098\uC758 \uCE90\uB9AD\uD130';
  String _generatedPrompt = '';
  String? _templatePreviewImageUrl;
  String _templateSaveMode = 'share';
  String _templateScope = 'mine';
  bool _isSaving = false;
  int _templateRefreshTick = 0;

  static const List<String> _tags = <String>[
    '\uBC1D\uC740 \uD53C\uBD80',
    '\uAC80\uC740 \uBA38\uB9AC',
    '\uAC08\uC0C9 \uBA38\uB9AC',
    '\uB2E8\uBC1C',
    '\uAE34 \uBA38\uB9AC',
    '\uD478\uB978 \uB208',
    '\uAC08\uC0C9 \uB208',
    '\uC67C\uCABD \uD558\uC774\uB77C\uC774\uD2B8',
    '\uCC28\uBD84\uD568',
    '\uC7A5\uB09C\uC2A4\uB7EC\uC6C0',
    '\uD6C4\uB4DC',
    '\uAD50\uBCF5',
  ];

  @override
  void dispose() {
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '\uCE90\uB9AD\uD130',
            style: TextStyle(
              color: Color(0xFF6EA3FF),
              fontWeight: FontWeight.w900,
            ),
          ),
          const Gap(12),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<String>(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.tacticalBlue.withValues(alpha: 0.96);
                  }
                  return AppTheme.academyLilac.withValues(alpha: 0.42);
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
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
                  const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'mine',
                  icon: Icon(Icons.bookmark_rounded),
                  label: Text('\uB0B4 \uCE90\uB9AD\uD130'),
                ),
                ButtonSegment<String>(
                  value: 'others',
                  icon: Icon(Icons.public_rounded),
                  label: Text('\uACF5\uC720 \uCE90\uB9AD\uD130'),
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
          const Gap(12),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                border: Border.all(color: const Color(0xFFE6F0FF)),
              ),
              child: Stack(
                children: <Widget>[
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
                            return const Center(
                              child: CircularProgressIndicator(),
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
                          final cards = <Widget>[
                            if (_templateScope == 'mine')
                              _TemplateGalleryCard(
                                title: 'create new\n\uCE90\uB9AD\uD130',
                                isCreateCard: true,
                                onTap: () => setState(() => _step = 1),
                              ),
                            ...templates.map(
                              (PersonaModel template) => _TemplateGalleryCard(
                                title: template.name,
                                badge: template.isPublic
                                    ? '\uACF5\uC720'
                                    : '\uC18C\uC7A5',
                                imageUrl:
                                    template.imageUrl ?? template.baseImageUrl,
                                onTap: () {
                                  _showTemplateDetail(context, template);
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
                              ),
                            );
                          }

                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(42, 34, 42, 34),
                            child: Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                runAlignment: WrapAlignment.center,
                                spacing: 30,
                                runSpacing: 34,
                                children: cards.indexed
                                    .map(
                                      ((int, Widget) entry) => SizedBox(
                                        width: 176,
                                        height: 236,
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
                          );
                        },
                  ),
                ],
              ),
            ),
          ),
        ],
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
        .toList();
  }

  Widget _buildModeSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 26),
      child: _DiaryFigmaFrame(
        title: '\uCE90\uB9AD\uD130 \uB9CC\uB4E4\uAE30',
        onClose: () => setState(() => _step = 0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(46, 28, 46, 34),
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
                  onTap: () {
                    setState(() {
                      _mode = 'prose';
                      _step = 2;
                    });
                  },
                ),
                _FigmaGradientButton(
                  title: 'TAG START',
                  subtitle: '\uD0DC\uADF8\uB85C \uB9CC\uB4E4\uAE30',
                  icon: Icons.grid_view_rounded,
                  colors: const <Color>[
                    AppTheme.pastelBlue,
                    AppTheme.pastelGreen,
                  ],
                  onTap: () {
                    setState(() {
                      _mode = 'tags';
                      _step = 2;
                    });
                  },
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 26),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: _GlassPanel(
            child: Padding(
              padding: const EdgeInsets.all(22),
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
                          _mode == 'prose'
                              ? '\uC904\uAE00\uB85C \uCE90\uB9AD\uD130 \uB9CC\uB4E4\uAE30'
                              : '\uD0DC\uADF8\uB85C \uCE90\uB9AD\uD130 \uB9CC\uB4E4\uAE30',
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
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final compact = constraints.maxWidth < 760;
                      final editor = Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          TextField(
                            textAlign: TextAlign.center,
                            onChanged: (String value) {
                              if (value.trim().isNotEmpty) {
                                setState(() => _templateName = value.trim());
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: '\uCE90\uB9AD\uD130 \uC774\uB984',
                              hintText:
                                  '\uC608: \uB098\uC758 \uB9C8\uBC95\uC0AC \uCE90\uB9AD\uD130',
                            ),
                          ),
                          const Gap(16),
                          if (_mode == 'prose')
                            SizedBox(
                              height: 260,
                              child: TextField(
                                controller: _memoController,
                                textAlign: TextAlign.center,
                                textAlignVertical: TextAlignVertical.top,
                                expands: true,
                                maxLines: null,
                                decoration: const InputDecoration(
                                  alignLabelWithHint: true,
                                  labelText:
                                      '\uCE90\uB9AD\uD130 \uC124\uC815 \uBA54\uBAA8',
                                  hintText:
                                      '\uC678\uD615, \uC131\uACA9, \uC758\uC0C1, \uD45C\uC815 \uD2B9\uC9D5\uC744 \uC790\uC720\uB86D\uAC8C \uC801\uC5B4 \uC8FC\uC138\uC694.',
                                ),
                              ),
                            )
                          else
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: _tags.map((String tag) {
                                final selected = _selectedTags.contains(tag);
                                return FilterChip(
                                  label: Text(tag, textAlign: TextAlign.center),
                                  selected: selected,
                                  selectedColor: AppTheme.pastelGreen
                                      .withValues(alpha: 0.72),
                                  checkmarkColor: AppTheme.tacticalBlue,
                                  onSelected: (_) => _toggleTemplateTag(tag),
                                );
                              }).toList(),
                            ),
                          const Gap(18),
                          _SaveModeSelector(
                            selected: _templateSaveMode,
                            onChanged: (String value) {
                              setState(() => _templateSaveMode = value);
                            },
                          ),
                          const Gap(18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isSaving ? null : _createTemplate,
                              icon: const Icon(Icons.auto_awesome_rounded),
                              label: Text(
                                _isSaving
                                    ? '\uC800\uC7A5 \uC911...'
                                    : '\uCE90\uB9AD\uD130 \uC800\uC7A5',
                              ),
                            ),
                          ),
                        ],
                      );

                      final preview = _TemplatePreview(
                        name: _templateName,
                        tags: _selectedTags.toList(),
                        prompt: _generatedPrompt,
                        imageUrl: _templatePreviewImageUrl,
                        isLoading: _isSaving,
                      );

                      if (compact) {
                        return Column(
                          children: <Widget>[
                            editor,
                            const Gap(22),
                            SizedBox(height: 320, child: preview),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: 6, child: editor),
                          const Gap(22),
                          Expanded(
                            flex: 4,
                            child: SizedBox(height: 520, child: preview),
                          ),
                        ],
                      );
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

  void _toggleTemplateTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _createTemplate() async {
    final memo = _memoController.text.trim();
    final tagPrompt = _selectedTags.join(', ');
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
      _generatedPrompt = prompt;
      _templatePreviewImageUrl = null;
    });

    try {
      final user = await _ensureSupabaseUserProfile();
      final repository = SupabasePersonaRepository(Supabase.instance.client);
      final persona = await repository.createPersonaTemplate(
        userId: user.id,
        name: _templateName.trim().isEmpty
            ? '\uACF5\uC720 \uCE90\uB9AD\uD130'
            : _templateName.trim(),
        appearanceDescription: prompt,
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
        templateVisibility: _templateSaveMode == 'share' ? 'public' : 'private',
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
          _generatedPrompt = '';
          _templateSaveMode = 'share';
          _memoController.clear();
          _selectedTags.clear();
        }
      });
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
                const Gap(12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      template.appearanceDescription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(height: 1.45),
                    ),
                  ),
                ),
                if (isMine) ...<Widget>[
                  const Gap(12),
                  FilledButton.icon(
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
              ],
            ),
          ),
        );
      },
    );
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
    return SizedBox(
      width: double.infinity,
      child: _PressableScale(
        onTap: onTap ?? () {},
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.tacticalBlue.withValues(alpha: 0.50),
              width: 1.3,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.ink.withValues(alpha: 0.20),
                blurRadius: 20,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: AppTheme.pastelRose.withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(-6, 6),
              ),
              BoxShadow(
                color: AppTheme.pastelBlue.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(6, 4),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.86),
                blurRadius: 0,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            child: Stack(
              children: <Widget>[
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
                const Positioned.fill(child: _CornerBrackets()),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (badge != null) ...<Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: _FigmaTinyTag(text: badge!),
                      ),
                      const Gap(6),
                    ],
                    if (isCreateCard) ...<Widget>[
                      const Icon(
                        Icons.add_rounded,
                        size: 66,
                        color: AppTheme.tacticalBlue,
                      ),
                      const Gap(18),
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
                      const Gap(10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: isCreateCard ? 50 : 42,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            title,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.tacticalBlue,
                              fontSize: 18,
                              height: 1.04,
                              fontStyle: FontStyle.italic,
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

class _TemplatePreview extends StatelessWidget {
  const _TemplatePreview({
    required this.name,
    required this.tags,
    required this.prompt,
    this.imageUrl,
    this.isLoading = false,
  });

  final String name;
  final List<String> tags;
  final String prompt;
  final String? imageUrl;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        border: Border.all(color: const Color(0xFF9FC4FF), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  border: Border.all(color: const Color(0xFFACCCFF)),
                ),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? _StorageAwareImage(
                        url: imageUrl!,
                        fallback: const _TemplateImageFallback(),
                      )
                    : Center(
                        child: isLoading
                            ? const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  CircularProgressIndicator(strokeWidth: 2),
                                  Gap(12),
                                  Text(
                                    '\uCE90\uB9AD\uD130 \uC774\uBBF8\uC9C0\uB97C \uC0DD\uC131\uD558\uB294 \uC911...',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF75A8FF),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'image',
                                style: TextStyle(
                                  color: Color(0xFF75A8FF),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
              ),
            ),
            const Gap(12),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
            const Gap(8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map((String tag) => _FigmaTinyTag(text: tag))
                  .toList(),
            ),
            const Gap(12),
            Text(
              prompt.isEmpty
                  ? '\uCE90\uB9AD\uD130 \uBBF8\uB9AC\uBCF4\uAE30\uB294 \uC124\uC815\uC744 \uC785\uB825\uD558\uBA74 \uD45C\uC2DC\uB429\uB2C8\uB2E4.'
                  : prompt,
              style: const TextStyle(color: Color(0xFF5B7FB7), height: 1.35),
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
  late int _likeCount = widget.post.likeCount;
  late int _commentCount = widget.post.commentCount;
  bool _isLiking = false;
  bool _isDeleting = false;

  bool get _isMine {
    return Supabase.instance.client.auth.currentUser?.id == widget.post.userId;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.post.title?.trim().isNotEmpty == true
        ? widget.post.title!.trim()
        : '\uC81C\uBAA9 \uC5C6\uB294 \uC77C\uAE30';

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
                    aspectRatio: widget.aspectRatio,
                    child: _PressableScale(
                      onTap: _showDiaryImages,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          _StorageAwareImage(
                            url: widget.post.firstImageUrl ?? '',
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
                          if (widget.post.imageUrls.length > 1)
                            Positioned(
                              left: 8,
                              bottom: 8,
                              child: _StatusChip(
                                icon: Icons.view_carousel_rounded,
                                label: '${widget.post.imageUrls.length} CUTS',
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
                        const Gap(4),
                        Text(
                          '@${widget.post.username}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.ink.withValues(alpha: 0.58),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Gap(8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              <String>{
                                ...widget.post.keywordTags,
                                ...widget.post.emotionTags,
                              }.map((String tag) {
                                return _FigmaTinyTag(text: '#$tag');
                              }).toList(),
                        ),
                        const Gap(10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            _PressableScale(
                              onTap: _isLiking ? () {} : _toggleLike,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(
                                    Icons.favorite_rounded,
                                    size: 18,
                                    color: AppTheme.pastelRose,
                                  ),
                                  const Gap(4),
                                  Text('$_likeCount'),
                                ],
                              ),
                            ),
                            const Gap(18),
                            _PressableScale(
                              onTap: _showComments,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(
                                    Icons.chat_bubble_rounded,
                                    size: 18,
                                    color: AppTheme.tacticalBlue,
                                  ),
                                  const Gap(4),
                                  Text('$_commentCount'),
                                ],
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

  void _showDiaryImages() {
    final fallbackUrls = {
      ...widget.post.imageUrls,
      if (widget.post.imageUrls.isEmpty &&
          widget.post.firstImageUrl?.isNotEmpty == true)
        widget.post.firstImageUrl!,
    }.toList();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.88,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: FutureBuilder<List<DiaryPanelModel>>(
              future: SupabaseFeedRepository(
                Supabase.instance.client,
              ).fetchDiaryPanels(widget.post.id),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<DiaryPanelModel>> snapshot,
                  ) {
                    final panels = snapshot.data ?? const <DiaryPanelModel>[];
                    final urls = panels.isEmpty
                        ? fallbackUrls
                        : panels
                              .map((DiaryPanelModel panel) => panel.imageUrl)
                              .whereType<String>()
                              .where((String url) => url.trim().isNotEmpty)
                              .toList();

                    return Column(
                      children: <Widget>[
                        Text(
                          widget.post.title?.trim().isNotEmpty == true
                              ? widget.post.title!.trim()
                              : '\uC81C\uBAA9 \uC5C6\uB294 \uC77C\uAE30',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const Gap(12),
                        Expanded(
                          child:
                              snapshot.connectionState ==
                                  ConnectionState.waiting
                              ? const Center(child: CircularProgressIndicator())
                              : _ImageUrlSlideDeck(
                                  imageUrls: urls,
                                  panels: panels,
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
                          return ListTile(
                            title: Text(
                              comment.content,
                              textAlign: TextAlign.center,
                            ),
                            subtitle: Text(
                              comment.createdAt
                                  .toLocal()
                                  .toString()
                                  .split('.')
                                  .first,
                              textAlign: TextAlign.center,
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
                      child: const Text('\uCDE8\uC18C'),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
              color: AppTheme.tacticalBlue.withValues(alpha: 0.30),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.ink.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.86),
                blurRadius: 0,
                offset: const Offset(0, -1),
              ),
              BoxShadow(
                color: AppTheme.pastelRose.withValues(alpha: 0.14),
                blurRadius: 30,
                offset: const Offset(-10, 5),
              ),
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
              Padding(padding: const EdgeInsets.all(18), child: child),
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
