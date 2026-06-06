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

part 'pinterest_home/social_page.dart';
part 'pinterest_home/diary_page.dart';
part 'pinterest_home/shared_widgets.dart';
part 'pinterest_home/template_page.dart';
part 'pinterest_home/post_card.dart';
part 'pinterest_home/shared_visuals.dart';

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
