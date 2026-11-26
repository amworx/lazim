import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatting.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common.dart';

/// Add or edit an item. A full page rather than a sheet: the form has enough
/// fields that a sheet would fight the keyboard on small phones.
class NeedEditorScreen extends ConsumerStatefulWidget {
  const NeedEditorScreen({super.key, this.existing});

  final NeedItem? existing;

  @override
  ConsumerState<NeedEditorScreen> createState() => _NeedEditorScreenState();
}

class _NeedEditorScreenState extends ConsumerState<NeedEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late final TextEditingController _quantity;
  late final TextEditingController _unit;

  late NeedPriority _priority;
  late NeedCategory _category;
  String? _assignedTo;
  bool _busy = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _quantity = TextEditingController(text: '${e?.quantity ?? 1}');
    _unit = TextEditingController(text: e?.unit ?? '');
    _priority = e?.priority ?? NeedPriority.normal;
    _category = e?.category ?? NeedCategory.groceries;
    _assignedTo = e?.assignedTo;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _quantity.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = ref.read(authStateProvider).value;
    final family = ref.read(activeFamilyProvider);
    if (user == null || family == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final repo = ref.read(needRepositoryProvider);
      final qty = int.tryParse(_quantity.text.trim()) ?? 1;
      final unit = _unit.text.trim().isEmpty ? null : _unit.text.trim();
      final note = _note.text.trim().isEmpty ? null : _note.text.trim();

      if (_isEdit) {
        final existing = widget.existing!;
        await repo.updateNeed(existing, user, changes: {
          'title': _title.text.trim(),
          'note': note,
          'quantity': qty,
          'unit': unit,
          'priority': _priority.code,
          'category': _category.code,
        });
        if (_assignedTo != existing.assignedTo) {
          final members = ref.read(membersProvider).value ?? const <FamilyMember>[];
          FamilyMember? target;
          for (final m in members) {
            if (m.userId == _assignedTo) target = m;
          }
          await repo.assign(existing, user, target);
        }
      } else {
        final members = ref.read(membersProvider).value ?? const <FamilyMember>[];
        String? assignedName;
        for (final m in members) {
          if (m.userId == _assignedTo) assignedName = m.displayName;
        }
        await repo.createNeed(
          familyId: family.id,
          actor: user,
          title: _title.text.trim(),
          note: note,
          quantity: qty,
          unit: unit,
          priority: _priority,
          category: _category,
          assignedTo: _assignedTo,
          assignedToName: assignedName,
        );
      }
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/needs');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = AppL10n.of(context).errorGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final user = ref.read(authStateProvider).value;
    if (user == null || widget.existing == null) return;
    final l = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(widget.existing!.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: LazimColors.danger,
              minimumSize: const Size(88, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(needRepositoryProvider).deleteNeed(widget.existing!, user);
    if (mounted) context.go('/needs');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final theme = Theme.of(context);
    final members = ref.watch(membersProvider).value ?? const <FamilyMember>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l.edit : l.addNeed),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded, color: LazimColors.danger),
              tooltip: l.delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
          children: [
            TextFormField(
              controller: _title,
              autofocus: !_isEdit,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 17),
              decoration: InputDecoration(
                labelText: l.needTitleLabel,
                hintText: l.needTitleHint,
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? l.requiredField : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _note,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.noteLabel,
                hintText: l.noteHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 22),

            _Label(l.quantityLabel),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: TextFormField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null || n < 1) return '1+';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _unit,
                    decoration: InputDecoration(hintText: l.unitHint),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            _Label(l.priorityLabel),
            const SizedBox(height: 8),
            Row(
              children: NeedPriority.values.map((p) {
                final selected = _priority == p;
                final color = switch (p) {
                  NeedPriority.low => LazimColors.sage,
                  NeedPriority.normal => LazimColors.clay,
                  NeedPriority.urgent => LazimColors.danger,
                };
                return Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: p == NeedPriority.urgent ? 0 : 8,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withValues(alpha: 0.13)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? color : theme.dividerColor,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          p.label(l),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: selected ? color : LazimColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            _Label(l.categoryLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: NeedCategory.values.map((c) {
                final selected = _category == c;
                final scheme = theme.colorScheme;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected ? scheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: selected ? scheme.primary : theme.dividerColor,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          c.icon,
                          size: 16,
                          color: selected ? Colors.white : LazimColors.muted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          c.label(l),
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
              }).toList(),
            ),
            const SizedBox(height: 22),

            if (members.length > 1) ...[
              _Label(l.assignToLabel),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _assignedTo,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(l.unassigned)),
                  ...members.map((m) => DropdownMenuItem(
                        value: m.userId,
                        child: Row(
                          children: [
                            MemberAvatar(
                              name: m.displayName,
                              photoUrl: m.photoUrl,
                              size: 24,
                            ),
                            const SizedBox(width: 9),
                            Flexible(
                              child: Text(
                                m.displayName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                onChanged: (v) => setState(() => _assignedTo = v),
              ),
              const SizedBox(height: 22),
            ],

            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: LazimColors.danger,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
            ],

            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: LazimColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
    );
  }
}
