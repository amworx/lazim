import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatting.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/category_picker.dart';
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
  late List<String> _categoryIds;
  String? _assignedTo;
  bool _busy = false;
  String? _error;

  /// Files staged while creating a new item. They are uploaded right after the
  /// item document exists, because an attachment needs a need id to hang off.
  final List<({String path, String name})> _staged = [];
  final bool _uploading = false;

  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.existing != null;

  /// The legacy single-category field is kept in sync with the first selection,
  /// so older builds and the history filter still behave.
  NeedCategory get _primaryCategory {
    if (_categoryIds.isEmpty) return NeedCategory.other;
    return NeedCategory.fromCode(_categoryIds.first);
  }

  Future<void> _stageFile() async {
    final picked = await FilePicker.pickFile(type: FileType.any);
    final path = picked?.path;
    final name = picked?.name;
    if (path == null || name == null) return;
    setState(() => _staged.add((path: path, name: name)));
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _quantity = TextEditingController(text: '${e?.quantity ?? 1}');
    _unit = TextEditingController(text: e?.unit ?? '');
    _priority = e?.priority ?? NeedPriority.normal;
    _categoryIds = e == null ? ['groceries'] : [...e.effectiveCategoryIds];
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
          'category': _primaryCategory.code,
          'categoryIds': _categoryIds,
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
        final created = await repo.createNeed(
          familyId: family.id,
          actor: user,
          title: _title.text.trim(),
          note: note,
          quantity: qty,
          unit: unit,
          priority: _priority,
          category: _primaryCategory,
          categoryIds: _categoryIds,
          assignedTo: _assignedTo,
          assignedToName: assignedName,
        );
        // Upload anything staged on the create form now that the item exists.
        for (final f in _staged) {
          try {
            await repo.uploadAttachment(created, user, file: File(f.path), name: f.name);
          } catch (_) {
            // One failed file must not lose the item the user just created.
          }
        }
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

            _Label(l.selectCategories),
            const SizedBox(height: 4),
            Text(
              l.categoriesHint,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.5,
                color: LazimColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            CategoryPicker(
              selected: _categoryIds,
              onChanged: (next) => setState(() => _categoryIds = next),
            ),
            const SizedBox(height: 22),

            // Attachments. On create the files are staged and uploaded right
            // after the item is written; on edit they go straight to the item.
            _Label(l.addAttachment),
            const SizedBox(height: 4),
            Text(
              l.attachmentsHint,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.5,
                color: LazimColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            if (_isEdit)
              _ExistingAttachments(item: widget.existing!)
            else
              _StagedAttachments(
                files: _staged,
                busy: _uploading,
                onAdd: _stageFile,
                onRemove: (i) => setState(() => _staged.removeAt(i)),
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

/// Files picked on the create form, before the item exists.
class _StagedAttachments extends StatelessWidget {
  const _StagedAttachments({
    required this.files,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });

  final List<({String path, String name})> files;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...files.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file_rounded, size: 18, color: LazimColors.muted),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      e.value.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => onRemove(e.key),
                  ),
                ],
              ),
            )),
        OutlinedButton.icon(
          onPressed: busy ? null : onAdd,
          icon: const Icon(Icons.attach_file_rounded, size: 18),
          label: Text(l.addAttachment),
        ),
      ],
    );
  }
}

/// Attachments already on an existing item, with add/remove.
class _ExistingAttachments extends ConsumerStatefulWidget {
  const _ExistingAttachments({required this.item});
  final NeedItem item;

  @override
  ConsumerState<_ExistingAttachments> createState() => _ExistingAttachmentsState();
}

class _ExistingAttachmentsState extends ConsumerState<_ExistingAttachments> {
  bool _busy = false;

  Future<void> _add() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final picked = await FilePicker.pickFile(type: FileType.any);
    final path = picked?.path;
    final name = picked?.name;
    if (path == null || name == null) return;

    if (!mounted) return;
    setState(() => _busy = true);
    final l = AppL10n.of(context);
    try {
      await ref.read(needRepositoryProvider).uploadAttachment(
            widget.item,
            user,
            file: File(path),
            name: name,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.attachmentUploadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final items = widget.item.attachments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...items.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Icon(a.kind.icon, size: 18, color: LazimColors.muted),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      a.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () async {
                      final user = ref.read(authStateProvider).value;
                      if (user == null) return;
                      await ref
                          .read(needRepositoryProvider)
                          .removeAttachment(widget.item, user, a);
                    },
                  ),
                ],
              ),
            )),
        OutlinedButton.icon(
          onPressed: _busy ? null : _add,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.attach_file_rounded, size: 18),
          label: Text(l.addAttachment),
        ),
      ],
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
