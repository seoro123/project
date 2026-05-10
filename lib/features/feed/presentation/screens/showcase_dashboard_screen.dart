import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../diary/data/models/diary_model.dart';
import '../providers/showcase_data_provider.dart';

class ShowcaseDashboardScreen extends ConsumerWidget {
  const ShowcaseDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(showcaseProfileProvider);
    final personas = ref.watch(showcasePersonasProvider);
    final diaries = ref.watch(showcaseDiariesProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              AppTheme.pastelBlue.withValues(alpha: 0.32),
              const Color(0xFFF8FCF8),
              AppTheme.pastelGreen.withValues(alpha: 0.26),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            profile.displayName ?? profile.username,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                          ),
                          const Gap(8),
                          Text(profile.bio ?? ''),
                          const Gap(12),
                          Text('페르소나 ${personas.length}개'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childCount: diaries.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _ShowcaseDiaryCard(diary: diaries[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShowcaseDiaryCard extends StatelessWidget {
  const _ShowcaseDiaryCard({required this.diary});

  final DiaryModel diary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              diary.summary ?? diary.content,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const Gap(10),
            Text(diary.content),
            const Gap(10),
            Text('상태: ${diary.generationStatus.value}'),
            Text('Seed: ${diary.generationSeed ?? '-'}'),
          ],
        ),
      ),
    );
  }
}
