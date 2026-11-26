import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;

import '../../core/providers.dart';
import '../../core/formatting.dart';
import '../../core/theme.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common.dart';
import '../widgets/need_card.dart';

/// The home screen: everything the family currently needs.
///
/// Supports live search, a multi-select mode with bulk complete/delete, and
/// swipe quick actions on each row (share / delete).
class NeedsListScreen extends ConsumerStatefulWidget {
  const NeedsListScreen({super.key});

  @override
  ConsumerState<NeedsListScreen> createState() => _NeedsListScreenState();
}

class _NeedsListScreenState extends ConsumerState<NeedsListScreen> {
  final _search = TextEditingController();
  String _query = '';
  final Set<String> _selected = {};
  bool _selecting = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final q = _search.text.trim().toLowerCase();
      if (q != _query && mounted) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
      if (_selected.isEmpty) _selecting = false;
    });
  }

  void _enterSelect() => setState(() {
        _selecting = true;
        _selected.clear();
      });

  void _exitSelect() => setState(() {
        _selecting = false;
        _selected.clear();
      });

  Future<void> _bulkDone(List<NeedItem> items) async {
    final user = ref.read(authStateProvider).value;
    if (user == null || _busy) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(needRepositoryProvider);
      for (final item in items) {
        if (!item.isDone) await repo.changeStatus(item, user, NeedStatus.purchased);
      }
      if (mounted) _exitSelect();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context).errorGeneric)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _bulkDelete(List<NeedItem> items) async {
    final user = ref.read(authStateProvider).value;
    if (user == null || _busy || items.isEmpty) return;
    final l = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.bulkDelete),
        content: Text(l.bulkDeleteConfirm(items.length)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              minimumSize: const Size(80, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(needRepositoryProvider);
      for (final item in items) {
        await repo.deleteNeed(item, user);
      }
      if (mounted) _exitSelect();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.errorGeneric)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareItem(NeedItem item) async {
    final l = AppL10n.of(context);
    final text = '${item.title}'
        '${item.quantity > 1 ? ' ×${item.quantity}${item.unit != null ? ' ${item.unit}' : ''}' : ''}'
        '${item.note != null && item.note!.trim().isNotEmpty ? '\n${item.note}' : ''}';
    await SharePlus.instance.share(ShareParams(text: text, title: l.appName));
  }

  Future<void> _deleteItem(NeedItem item) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final l = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.bulkDelete),
        content: Text(l.bulkDeleteConfirm(1)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              minimumSize: const Size(80, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(needRepositoryProvider).deleteNeed(item, user);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.errorGeneric)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final needsAsync = ref.watch(needsProvider);
    final active = ref.watch(activeNeedsProvider);
    final family = ref.watch(activeFamilyProvider);
    final stats = ref.watch(needStatsProvider);
    final categoryById = ref.watch(categoryByIdProvider);

    final visible = _query.isEmpty
        ? active
        : active
            .where((n) =>
                n.title.toLowerCase().contains(_query) ||
                (n.note ?? '').toLowerCase().contains(_query) ||
                n.effectiveCategoryIds.any((id) =>
                    categoryLabel(categoryById(id), l)
                        .toLowerCase()
                        .contains(_query)))
            .toList();

    final selectedItems = active.where((n) => _selected.contains(n.id)).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 450));
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  familyName: family?.name ?? l.appName,
                  selecting: _selecting,
                  onToggleSelect: _selecting ? _exitSelect : _enterSelect,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l.searchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              tooltip: l.searchClear,
                              onPressed: () => _search.clear(),
                            ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              if (!_selecting && stats.open + stats.claimed > 0)
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
                  if (visible.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: _query.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.check_circle_outline_rounded,
                        title: _query.isNotEmpty ? l.noSearchResults : l.needsEmptyTitle,
                        body: _query.isNotEmpty ? '' : l.needsEmptyBody,
                        action: _query.isNotEmpty
                            ? FilledButton(
                                onPressed: () => _search.clear(),
                                child: Text(l.searchClear),
                              )
                            : FilledButton.icon(
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
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, i) {
                        final item = visible[i];
                        if (_selecting) {
                          return _SelectableNeedCard(
                            item: item,
                            selected: _selected.contains(item.id),
                            onToggle: () => _toggleSelect(item.id),
                          );
                        }
                        return Dismissible(
                          key: ValueKey(item.id),
                          // Both directions: startToEnd reveals `background`
                          // (share), endToStart reveals `secondaryBackground`
                          // (delete). Restricting this to one direction made
                          // the other quick action unreachable.
                          direction: DismissDirection.horizontal,
                          background: _SwipeBackground(
                            color: LazimColors.clay,
                            icon: Icons.share_rounded,
                            label: l.swipeShare,
                            fromStart: true,
                          ),
                          secondaryBackground: _SwipeBackground(
                            color: Theme.of(context).colorScheme.error,
                            icon: Icons.delete_outline_rounded,
                            label: l.swipeDelete,
                            fromStart: false,
                          ),
                          confirmDismiss: (direction) async {
                            // `background` (share) is shown for startToEnd;
                            // `secondaryBackground` (delete) for endToStart.
                            // Keep the action in sync with what the user saw.
                            if (direction == DismissDirection.startToEnd) {
                              await _shareItem(item);
                              return false; // keep the row after sharing
                            }
                            await _deleteItem(item);
                            return false; // repository stream removes it
                          },
                          child: NeedCard(
                            item: item,
                            onTap: () => context.push('/need/${item.id}'),
                            onLongPress: _enterSelect,
                          ),
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
      floatingActionButton: _selecting
          ? FloatingActionButton.extended(
              onPressed: _busy ? null : () => _bulkDone(selectedItems),
              icon: const Icon(Icons.check_rounded),
              label: Text(l.bulkMarkDone),
            )
          : FloatingActionButton.extended(
              onPressed: () => context.push('/need/new'),
              icon: const Icon(Icons.add_rounded),
              label: Text(l.addNeed),
              extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
            ),
      bottomNavigationBar: _selecting
          ? _BulkBar(
              count: selectedItems.length,
              total: visible.length,
              busy: _busy,
              onSelectAll: () => setState(() => _selected.addAll(visible.map((n) => n.id))),
              onClear: _exitSelect,
              onDelete: () => _bulkDelete(selectedItems),
            )
          : null,
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.fromStart,
  });

  final Color color;
  final IconData icon;
  final String label;

  /// True when this background is revealed by dragging from the start edge.
  /// The action sits on the edge the finger comes from, so a short swipe is
  /// already enough to read what it does instead of needing a full drag.
  final bool fromStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: fromStart ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fromStart) ...[
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ] else ...[
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white, size: 22),
          ],
        ],
      ),
    );
  }
}

class _SelectableNeedCard extends StatelessWidget {
  const _SelectableNeedCard({
    required this.item,
    required this.selected,
    required this.onToggle,
  });

  final NeedItem item;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)
          : (isDark ? LazimColors.darkSurface : LazimColors.surface),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? Theme.of(context).colorScheme.primary : LazimColors.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulkBar extends StatelessWidget {
  const _BulkBar({
    required this.count,
    required this.total,
    required this.busy,
    required this.onSelectAll,
    required this.onClear,
    required this.onDelete,
  });

  final int count;
  final int total;
  final bool busy;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: LazimColors.line)),
        ),
        child: Row(
          children: [
            Text(
              l.selectedCount(count),
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (count < total)
              TextButton(onPressed: onSelectAll, child: Text(l.selectAll)),
            IconButton(
              onPressed: busy || count == 0 ? null : onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: Theme.of(context).colorScheme.error,
              tooltip: l.bulkDelete,
            ),
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
              tooltip: l.clearSelection,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.familyName,
    required this.selecting,
    required this.onToggleSelect,
  });

  final String familyName;
  final bool selecting;
  final VoidCallback onToggleSelect;

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
                  selecting ? l.selectMode : l.needsTitle,
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
          if (!selecting && families.length > 1) const _FamilySwitcher(),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onToggleSelect,
            icon: Icon(selecting ? Icons.close_rounded : Icons.checklist_rounded),
            tooltip: selecting ? l.clearSelection : l.selectMode,
          ),
          if (!selecting && user != null)
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
          _Stat(value: '${stats.open}', label: l.statusOpen, color: LazimColors.clay),
          const SizedBox(width: 8),
          if (stats.claimed > 0) ...[
            _Stat(value: '${stats.claimed}', label: l.statusClaimed, color: LazimColors.amber),
            const SizedBox(width: 8),
          ],
          if (stats.urgent > 0) ...[
            _Stat(value: '${stats.urgent}', label: l.priorityUrgent, color: LazimColors.danger),
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
