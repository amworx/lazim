import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';

/// Creates a category and returns it, or null if the user backed out.
///
/// Shared by Settings and the item editor's quick-add, so a family can create a
/// category at the moment they need it instead of leaving the form.
Future<NeedCategoryDef?> showCategoryDialog(
  BuildContext context,
  WidgetRef ref, {
  NeedCategoryDef? existing,
}) async {
  final family = ref.read(activeFamilyProvider);
  if (family == null) return null;

  final name = TextEditingController(text: existing?.name ?? '');
  var iconKey = existing?.iconKey ?? 'label';
  final l = AppL10n.of(context);

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text(existing == null ? l.addCategory : l.editCategory),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l.categoryNameLabel,
                  hintText: l.categoryNameHint,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l.categoryIconLabel,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.5,
                  color: LazimColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categoryIcons.entries.map((e) {
                  final selected = iconKey == e.key;
                  return GestureDetector(
                    onTap: () => setLocal(() => iconKey = e.key),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: selected
                              ? Theme.of(ctx).colorScheme.primary
                              : Theme.of(ctx).dividerColor,
                        ),
                      ),
                      child: Icon(
                        e.value,
                        size: 20,
                        color: selected
                            ? Theme.of(ctx).colorScheme.primary
                            : LazimColors.muted,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(80, 44)),
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: Text(l.save),
          ),
        ],
      ),
    ),
  );

  if (saved != true || name.text.trim().isEmpty) return null;

  final repo = ref.read(categoryRepositoryProvider);
  if (existing == null) {
    return repo.createCategory(
      familyId: family.id,
      name: name.text.trim(),
      iconKey: iconKey,
    );
  }
  await repo.renameCategory(family.id, existing.id, name.text.trim());
  return NeedCategoryDef(
    id: existing.id,
    name: name.text.trim(),
    iconKey: iconKey,
    colorValue: existing.colorValue,
    order: existing.order,
  );
}

/// Multi-select category chips used by the item editor.
class CategoryPicker extends ConsumerWidget {
  const CategoryPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  Future<void> _quickAdd(BuildContext context, WidgetRef ref) async {
    final created = await showCategoryDialog(context, ref);
    if (created != null) onChanged([...selected, created.id]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...categories.map((c) {
          final isSelected = selected.contains(c.id);
          return GestureDetector(
            onTap: () {
              final next = [...selected];
              if (isSelected) {
                next.remove(c.id);
              } else {
                next.add(c.id);
              }
              onChanged(next);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    categoryIconFor(c),
                    size: 16,
                    color: isSelected ? Colors.white : LazimColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    categoryLabel(c, l),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        GestureDetector(
          onTap: () => _quickAdd(context, ref),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 5),
                Text(
                  l.addCategory,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Read-only chips for a list row or detail header.
class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key, required this.ids, this.dense = true});

  final List<String> ids;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final resolve = ref.watch(categoryByIdProvider);
    if (ids.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: ids.map((id) {
        final def = resolve(id);
        return Container(
          padding: EdgeInsets.symmetric(horizontal: dense ? 7 : 9, vertical: dense ? 3 : 5),
          decoration: BoxDecoration(
            color: LazimColors.muted.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(categoryIconFor(def), size: dense ? 11 : 13, color: LazimColors.muted),
              const SizedBox(width: 4),
              Text(
                categoryLabel(def, l),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: dense ? 10.5 : 12,
                  color: LazimColors.muted,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
