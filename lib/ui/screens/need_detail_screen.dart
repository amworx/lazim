import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/formatting.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/attachment_preview.dart';
import '../widgets/category_picker.dart';
import '../widgets/common.dart';

/// Full detail for one item: status controls, attachments, activity trail.
class NeedDetailScreen extends ConsumerWidget {
  const NeedDetailScreen({super.key, required this.needId});

  final String needId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final item = ref.watch(needByIdProvider(needId));

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(l.errorGeneric, style: const TextStyle(fontFamily: 'Cairo')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.itemDetailTitle),
        actions: [
          IconButton(
            onPressed: () => context.push('/need/${item.id}/edit'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: l.edit,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 40),
        children: [
          _TitleBlock(item: item),
          const SizedBox(height: 18),
          _StatusActions(item: item),
          const SizedBox(height: 22),
          _DetailsCard(item: item),
          if (item.note != null && item.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _NoteCard(note: item.note!),
          ],
          const SizedBox(height: 22),
          _AttachmentsSection(item: item),
          const SizedBox(height: 22),
          _ActivitySection(item: item),
        ],
      ),
    );
  }
}

class _TitleBlock extends ConsumerWidget {
  const _TitleBlock({required this.item});
  final NeedItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(item.category.icon, size: 26, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 23,
                      height: 1.3,
                      decoration:
                          item.isDone ? TextDecoration.lineThrough : null,
                      color: item.isDone ? LazimColors.muted : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.addedBy(liveName(ref, item.createdBy, item.createdByName)),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: LazimColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusActions extends ConsumerStatefulWidget {
  const _StatusActions({required this.item});
  final NeedItem item;

  @override
  ConsumerState<_StatusActions> createState() => _StatusActionsState();
}

class _StatusActionsState extends ConsumerState<_StatusActions> {
  bool _busy = false;

  Future<void> _set(NeedStatus status) async {
    final user = ref.read(authStateProvider).value;
    if (user == null || _busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(needRepositoryProvider).changeStatus(widget.item, user, status);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _claim() async {
    final user = ref.read(authStateProvider).value;
    if (user == null || _busy) return;
    final members = ref.read(membersProvider).value ?? const <FamilyMember>[];
    final me = members.where((m) => m.userId == user.id).firstOrNull;
    setState(() => _busy = true);
    try {
      await ref.read(needRepositoryProvider).assign(widget.item, user, me);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final item = widget.item;
    final user = ref.watch(authStateProvider).value;
    final mine = user != null && item.assignedTo == user.id;

    if (item.isDone) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _busy ? null : () => _set(NeedStatus.open),
          icon: const Icon(Icons.undo_rounded, size: 19),
          label: Text(l.markOpen),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: FilledButton.icon(
            onPressed: _busy ? null : () => _set(NeedStatus.purchased),
            icon: _busy
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded, size: 20),
            label: Text(l.markPurchased),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: OutlinedButton(
            onPressed: _busy ? null : (mine ? () => _set(NeedStatus.open) : _claim),
            child: Text(mine ? l.unclaim : l.claim, style: const TextStyle(fontSize: 14)),
          ),
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.item});
  final NeedItem item;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? LazimColors.darkSurface : LazimColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? LazimColors.darkLine : LazimColors.line),
      ),
      child: Column(
        children: [
          DetailRow(
            icon: Icons.flag_outlined,
            label: l.filterStatus,
            value: item.status.label(l),
          ),
          const Divider(height: 1),
          DetailRow(
            icon: Icons.bolt_outlined,
            label: l.priorityLabel,
            value: item.priority.label(l),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sell_outlined, size: 19, color: LazimColors.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.categoryLabel,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          color: LazimColors.muted,
                        ),
                      ),
                      const SizedBox(height: 5),
                      CategoryChips(ids: item.effectiveCategoryIds, dense: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          DetailRow(
            icon: Icons.numbers_rounded,
            label: l.quantityLabel,
            value:
                '${item.quantity}${item.unit != null ? ' ${item.unit}' : ''}',
          ),
          const Divider(height: 1),
          DetailRow(
            icon: Icons.person_outline_rounded,
            label: l.assignToLabel,
            value: item.assignedToName ?? l.unassigned,
          ),
          const Divider(height: 1),
          DetailRow(
            icon: Icons.event_outlined,
            label: l.historyTitle,
            value:
                '${relativeDay(item.createdAt, l, l.localeName)} Â· ${clockTime(item.createdAt, l.localeName)}',
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? LazimColors.darkSurface : LazimColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? LazimColors.darkLine : LazimColors.line),
      ),
      child: Text(
        note,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.65),
      ),
    );
  }
}

class _AttachmentsSection extends ConsumerStatefulWidget {
  const _AttachmentsSection({required this.item});
  final NeedItem item;

  @override
  ConsumerState<_AttachmentsSection> createState() => _AttachmentsSectionState();
}

class _AttachmentsSectionState extends ConsumerState<_AttachmentsSection> {
  bool _uploading = false;

  Future<void> _pickFile() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final file = await FilePicker.pickFile(type: FileType.any);
    final path = file?.path;
    final name = file?.name;
    if (path == null || name == null) return;

    setState(() => _uploading = true);
    try {
      await ref.read(needRepositoryProvider).uploadAttachment(
            widget.item,
            user,
            file: File(path),
            name: name,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context).attachmentUploadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _addLink() async {
    final l = AppL10n.of(context);
    final url = TextEditingController();
    final label = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.addLink),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: url,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: l.linkUrlLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: label,
              decoration: InputDecoration(labelText: l.linkNameLabel),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(80, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.save),
          ),
        ],
      ),
    );

    if (ok != true) return;
    var raw = url.text.trim();
    if (raw.isEmpty) return;
    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      raw = 'https://$raw';
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    await ref.read(needRepositoryProvider).addLink(
          widget.item,
          user,
          url: raw,
          name: label.text.trim().isEmpty ? raw : label.text.trim(),
        );
  }

  Future<void> _open(Attachment a) async {
    final l = AppL10n.of(context);

    // Firestore-backed files: read the bytes and hand them to the native
    // bridge, which writes a temp file and opens it with the system viewer.
    if (a.blobId != null) {
      try {
        final bytes = await ref
            .read(needRepositoryProvider)
            .readAttachmentBytes(widget.item, a);
        if (bytes == null || bytes.isEmpty) {
          throw StateError('No attachment bytes available');
        }
        await const MethodChannel('lazim/updater').invokeMethod<bool>(
          'openAttachment',
          {
            'name': a.name,
            'mimeType': a.mimeType ?? 'application/octet-stream',
            'bytes': Uint8List.fromList(bytes),
          },
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.attachmentOpenFailed)),
          );
        }
      }
      return;
    }

    // Plain links (and legacy Storage URLs) open directly in the browser.
    final raw = a.url?.trim();
    if (raw == null || raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null || (!uri.hasScheme && !raw.startsWith('https://'))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.attachmentOpenFailed)),
        );
      }
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      final browserOk =
          await launchUrl(uri, mode: LaunchMode.platformDefault) ||
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (!browserOk && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.attachmentOpenFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final items = widget.item.attachments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l.attachmentsTitle,
          action: Row(
            children: [
              IconButton(
                onPressed: _uploading ? null : _addLink,
                icon: const Icon(Icons.add_link_rounded, size: 20),
                tooltip: l.addLink,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: _uploading ? null : _pickFile,
                icon: _uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.attach_file_rounded, size: 20),
                tooltip: l.addFile,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Text(
              l.noAttachments,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: LazimColors.muted,
              ),
            ),
          )
        else
          AttachmentGrid(
            item: widget.item,
            onOpen: _open,
            onRemove: (a) async {
              final user = ref.read(authStateProvider).value;
              if (user == null) return;
              await ref
                  .read(needRepositoryProvider)
                  .removeAttachment(widget.item, user, a);
            },
          ),
      ],
    );
  }
}



/// Resolves a user id to the name the family currently sees.
///
/// Activity entries and item headers store the author name as a snapshot at
/// write time. When somebody renames themselves those snapshots go stale, so
/// every render resolves the id against the live member roster and only falls
/// back to the stored snapshot for people who have left the family.
String liveName(WidgetRef ref, String userId, String fallback) {
  if (userId.isEmpty) return fallback;
  final members = ref.watch(membersProvider).value ?? const <FamilyMember>[];
  for (final m in members) {
    if (m.userId == userId) return m.displayName;
  }
  return fallback;
}

class _ActivitySection extends ConsumerWidget {
  const _ActivitySection({required this.item});
  final NeedItem item;

  String _describe(ActivityEntry e, AppL10n l, String name) {
    return switch (e.type) {
      ActivityType.created => l.activityCreated(name),
      ActivityType.statusChanged => l.activityStatusChanged(
          name,
          NeedStatus.fromCode(e.fromValue).label(l),
          NeedStatus.fromCode(e.toValue).label(l),
        ),
      ActivityType.assigned => l.activityAssigned(name, e.toValue ?? ''),
      ActivityType.attachmentAdded => l.activityAttachment(name, e.toValue ?? ''),
      _ => l.activityEdited(name),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final entries = [...item.activity]..sort((a, b) => b.at.compareTo(a.at));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l.activityTitle),
        ...entries.map((e) {
          final name = liveName(ref, e.actorId, e.actorName);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MemberAvatar(name: name, size: 28),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _describe(e, l, name),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13.5,
                              height: 1.5,
                            ),
                      ),
                      Text(
                        '${relativeDay(e.at, l, l.localeName)} · ${clockTime(e.at, l.localeName)}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          color: LazimColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
