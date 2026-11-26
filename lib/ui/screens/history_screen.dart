import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/formatting.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common.dart';
import '../widgets/need_card.dart';

/// Completed items with a full filter set.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final filter = ref.watch(needFilterProvider);
    final results = ref.watch(filteredDoneNeedsProvider);
    final all = ref.watch(doneNeedsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.historyTitle),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () => _showFilters(context, ref),
                icon: const Icon(Icons.tune_rounded),
                tooltip: l.filters,
              ),
              if (!filter.isEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${filter.activeCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: all.isEmpty
          ? EmptyState(
              icon: Icons.history_rounded,
              title: l.historyEmptyTitle,
              body: l.historyEmptyBody,
            )
          : Column(
              children: [
                if (!filter.isEmpty)
                  _ActiveFilterBar(filter: filter, resultCount: results.length),
                Expanded(
                  child: results.isEmpty
                      ? EmptyState(
                          icon: Icons.filter_alt_off_rounded,
                          title: l.noResultsTitle,
                          body: l.noResultsBody,
                          action: OutlinedButton(
                            onPressed: () =>
                                ref.read(needFilterProvider.notifier).clear(),
                            child: Text(l.clearFilters),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                          itemCount: results.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 9),
                          itemBuilder: (context, i) {
                            final item = results[i];
                            return NeedCard(
                              item: item,
                              onTap: () => context.push('/need/${item.id}'),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showFilters(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _FilterSheet(),
    );
  }
}

class _ActiveFilterBar extends ConsumerWidget {
  const _ActiveFilterBar({required this.filter, required this.resultCount});

  final NeedFilter filter;
  final int resultCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.resultsCount(resultCount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LazimColors.muted,
                    fontSize: 13,
                  ),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(needFilterProvider.notifier).clear(),
            child: Text(l.clearFilters, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late NeedFilter _draft;
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(needFilterProvider);
    _search = TextEditingController(text: _draft.query);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _draft.from != null && _draft.to != null
          ? DateTimeRange(start: _draft.from!, end: _draft.to!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          datePickerTheme: DatePickerThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() => _draft = _draft.copyWith(from: range.start, to: range.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final theme = Theme.of(context);
    final members = ref.watch(membersProvider).value ?? const <FamilyMember>[];
    final categories = ref.watch(categoriesProvider);
    final dateFmt = DateFormat.yMMMd(l.localeName);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(child: Text(l.filters, style: theme.textTheme.titleLarge)),
                  TextButton(
                    onPressed: () {
                      _search.clear();
                      setState(() => _draft = const NeedFilter());
                    },
                    child: Text(l.clearFilters),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      labelText: l.filterSearch,
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                    onChanged: (v) => setState(() => _draft = _draft.copyWith(query: v)),
                  ),
                  const SizedBox(height: 22),

                  _FilterGroup(
                    title: l.filterStatus,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: NeedStatus.values.map((s) {
                        final sel = _draft.statuses.contains(s);
                        return _Chip(
                          label: s.label(l),
                          selected: sel,
                          onTap: () => setState(() {
                            final next = {..._draft.statuses};
                            sel ? next.remove(s) : next.add(s);
                            _draft = _draft.copyWith(statuses: next);
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _FilterGroup(
                    title: l.filterCategory,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((c) {
                        final sel = _draft.categories.contains(c.id);
                        return _Chip(
                          label: categoryLabel(c, l),
                          icon: categoryIconFor(c),
                          selected: sel,
                          onTap: () => setState(() {
                            final next = {..._draft.categories};
                            sel ? next.remove(c.id) : next.add(c.id);
                            _draft = _draft.copyWith(categories: next);
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _FilterGroup(
                    title: l.filterPriority,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: NeedPriority.values.map((p) {
                        final sel = _draft.priorities.contains(p);
                        return _Chip(
                          label: p.label(l),
                          selected: sel,
                          onTap: () => setState(() {
                            final next = {..._draft.priorities};
                            sel ? next.remove(p) : next.add(p);
                            _draft = _draft.copyWith(priorities: next);
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (members.length > 1) ...[
                    _FilterGroup(
                      title: l.filterAssignee,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: members.map((m) {
                          final sel = _draft.assigneeId == m.userId;
                          return _Chip(
                            label: m.displayName,
                            selected: sel,
                            onTap: () => setState(() {
                              _draft = sel
                                  ? _draft.copyWith(clearAssignee: true)
                                  : _draft.copyWith(assigneeId: m.userId);
                            }),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  _FilterGroup(
                    title: l.filterDateRange,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: _pickDates,
                            icon: const Icon(Icons.date_range_rounded, size: 18),
                            label: Text(
                              _draft.from != null && _draft.to != null
                                  ? '${dateFmt.format(_draft.from!)} — ${dateFmt.format(_draft.to!)}'
                                  : l.filterDateRange,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (_draft.from != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () =>
                                setState(() => _draft = _draft.copyWith(clearDates: true)),
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FilledButton(
                onPressed: () {
                  ref.read(needFilterProvider.notifier).update((_) => _draft);
                  Navigator.of(context).pop();
                },
                child: Text(l.applyFilters),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: LazimColors.muted,
              ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? scheme.primary : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: selected ? Colors.white : LazimColors.muted),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
