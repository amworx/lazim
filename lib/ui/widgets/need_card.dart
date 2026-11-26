import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import 'common.dart';

/// The main list row. Tap opens detail; the trailing control completes the item
/// in one gesture — that is the whole point of the app, so it gets the biggest
/// touch target on the row.
class NeedCard extends ConsumerWidget {
  const NeedCard({super.key, required this.item, this.onTap});

  final NeedItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final done = item.isDone;

    final (statusFg, statusBg) = switch (item.status) {
      NeedStatus.open => (LazimColors.clayDeep, LazimColors.claySoft),
      NeedStatus.claimed => (LazimColors.amber, LazimColors.amberSoft),
      NeedStatus.purchased => (LazimColors.sage, LazimColors.sageSoft),
      NeedStatus.archived => (LazimColors.muted, const Color(0xFFF0EDEB)),
    };

    return Semantics(
      button: true,
      label: '${item.title}, ${item.status.label(l)}',
      child: Material(
        color: isDark ? LazimColors.darkSurface : LazimColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.priority == NeedPriority.urgent && !done
                    ? LazimColors.clay.withValues(alpha: 0.45)
                    : (isDark ? LazimColors.darkLine : LazimColors.line),
                width: item.priority == NeedPriority.urgent && !done ? 1.4 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryBadge(category: item.category, done: done),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 15.5,
                                height: 1.35,
                                decoration: done ? TextDecoration.lineThrough : null,
                                color: done ? LazimColors.muted : null,
                              ),
                            ),
                          ),
                          if (item.quantity > 1) ...[
                            const SizedBox(width: 8),
                            Text(
                              '×${item.quantity}${item.unit != null ? ' ${item.unit}' : ''}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: LazimColors.muted,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (item.note != null && item.note!.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: LazimColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusPill(
                            label: item.status.label(l),
                            foreground: statusFg,
                            background: statusBg,
                            dense: true,
                          ),
                          if (item.priority == NeedPriority.urgent && !done)
                            StatusPill(
                              label: l.priorityUrgent,
                              foreground: LazimColors.danger,
                              background: LazimColors.dangerSoft,
                              icon: Icons.bolt_rounded,
                              dense: true,
                            ),
                          if (item.attachments.isNotEmpty)
                            _MetaChip(
                              icon: Icons.attach_file_rounded,
                              text: '${item.attachments.length}',
                            ),
                          _MetaChip(
                            icon: Icons.schedule_rounded,
                            text: relativeDay(item.createdAt, l, l.localeName),
                          ),
                          if (item.assignedToName != null)
                            _MetaChip(
                              icon: Icons.person_outline_rounded,
                              text: item.assignedToName!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _CompleteButton(item: item),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category, required this.done});

  final NeedCategory category;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: done
            ? scheme.onSurface.withValues(alpha: 0.05)
            : scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        category.icon,
        size: 21,
        color: done ? LazimColors.muted : scheme.primary,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: LazimColors.muted),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11.5,
            color: LazimColors.muted,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

/// One-tap complete. Toggles between "mark purchased" and "reopen".
class _CompleteButton extends ConsumerStatefulWidget {
  const _CompleteButton({required this.item});
  final NeedItem item;

  @override
  ConsumerState<_CompleteButton> createState() => _CompleteButtonState();
}

class _CompleteButtonState extends ConsumerState<_CompleteButton> {
  bool _busy = false;

  Future<void> _toggle() async {
    final user = ref.read(authStateProvider).value;
    if (user == null || _busy) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(needRepositoryProvider);
      final next = widget.item.isDone ? NeedStatus.open : NeedStatus.purchased;
      await repo.changeStatus(widget.item, user, next);
      if (mounted) {
        final l = AppL10n.of(context);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                next == NeedStatus.purchased
                    ? '${widget.item.title} — ${l.statusPurchased}'
                    : '${widget.item.title} — ${l.markOpen}',
              ),
              duration: const Duration(milliseconds: 1600),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = widget.item.isDone;

    return Semantics(
      button: true,
      label: done ? AppL10n.of(context).markOpen : AppL10n.of(context).markPurchased,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Material(
          color: done
              ? LazimColors.sage.withValues(alpha: 0.14)
              : scheme.primary.withValues(alpha: 0.08),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _toggle,
            child: _busy
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    done ? Icons.undo_rounded : Icons.check_rounded,
                    size: 22,
                    color: done ? LazimColors.sage : scheme.primary,
                  ),
          ),
        ),
      ),
    );
  }
}
