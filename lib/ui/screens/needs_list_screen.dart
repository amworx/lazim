import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common.dart';
import '../widgets/need_card.dart';

/// The home screen: everything the family currently needs.
class NeedsListScreen extends ConsumerWidget {
  const NeedsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final needsAsync = ref.watch(needsProvider);
    final active = ref.watch(activeNeedsProvider);
    final family = ref.watch(activeFamilyProvider);
    final stats = ref.watch(needStatsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            // Streams are live; this just gives the pull gesture something to do.
            await Future<void>.delayed(const Duration(milliseconds: 450));
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(familyName: family?.name ?? l.appName),
              ),
              if (stats.open + stats.claimed > 0)
                SliverToBoxAdapter(child: _StatsStrip(stats: stats)),
              needsAsync.when(
                loading: () => const SliverToBoxAdapter(child: LoadingList()),
                error: (e, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: l.errorGeneric,
                    body: l.errorNetwork,
                    action: FilledButton(
                      onPressed: () => ref.invalidate(needsProvider),
                      child: Text(l.retry),
                    ),
                  ),
                ),
                data: (_) {
                  if (active.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.check_circle_outline_rounded,
                        title: l.needsEmptyTitle,
                        body: l.needsEmptyBody,
                        action: FilledButton.icon(
                          onPressed: () => context.push('/need/new'),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(l.addFirstNeed),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                    sliver: SliverList.separated(
                      itemCount: active.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, i) {
                        final item = active[i];
                        return NeedCard(
                          item: item,
                          onTap: () => context.push('/need/${item.id}'),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/need/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.addNeed),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.familyName});

  final String familyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;
    final families = ref.watch(familiesProvider).value ?? const <Family>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.needsTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 27),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.home_rounded, size: 13, color: LazimColors.muted),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        familyName,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: LazimColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (families.length > 1) const _FamilySwitcher(),
          const SizedBox(width: 6),
          if (user != null)
            GestureDetector(
              onTap: () => context.push('/settings'),
              child: MemberAvatar(
                name: user.displayName,
                photoUrl: user.photoUrl,
                size: 40,
              ),
            ),
        ],
      ),
    );
  }
}

class _FamilySwitcher extends ConsumerWidget {
  const _FamilySwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final families = ref.watch(familiesProvider).value ?? const <Family>[];
    final active = ref.watch(activeFamilyProvider);

    return PopupMenuButton<String>(
      tooltip: '',
      icon: const Icon(Icons.swap_horiz_rounded, size: 22),
      onSelected: (id) => ref.read(activeFamilyIdProvider.notifier).select(id),
      itemBuilder: (context) => families
          .map((f) => PopupMenuItem(
                value: f.id,
                child: Row(
                  children: [
                    Icon(
                      f.id == active?.id
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(f.name),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.stats});

  final ({int open, int claimed, int urgent, int doneThisWeek}) stats;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          _Stat(
            value: '${stats.open}',
            label: l.statusOpen,
            color: LazimColors.clay,
          ),
          const SizedBox(width: 8),
          if (stats.claimed > 0) ...[
            _Stat(
              value: '${stats.claimed}',
              label: l.statusClaimed,
              color: LazimColors.amber,
            ),
            const SizedBox(width: 8),
          ],
          if (stats.urgent > 0) ...[
            _Stat(
              value: '${stats.urgent}',
              label: l.priorityUrgent,
              color: LazimColors.danger,
            ),
            const SizedBox(width: 8),
          ],
          if (stats.doneThisWeek > 0)
            _Stat(
              value: '${stats.doneThisWeek}',
              label: l.statusPurchased,
              color: LazimColors.sage,
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: color.withValues(alpha: 0.85),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
