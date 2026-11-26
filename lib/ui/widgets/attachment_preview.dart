import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';

/// Caches attachment bytes per attachment id so a list of thumbnails does not
/// re-read Firestore on every rebuild.
final attachmentBytesProvider =
    FutureProvider.family<Uint8List?, ({String needId, String attachmentId})>(
  (ref, key) async {
    final item = ref.watch(needByIdProvider(key.needId));
    if (item == null) return null;
    Attachment? target;
    for (final a in item.attachments) {
      if (a.id == key.attachmentId) target = a;
    }
    if (target == null) return null;
    return ref.read(needRepositoryProvider).readAttachmentBytes(item, target);
  },
);

/// A square image thumbnail for an attachment, or a typed icon tile when the
/// attachment is not an image. Tapping opens the full-screen viewer.
class AttachmentThumb extends ConsumerWidget {
  const AttachmentThumb({
    super.key,
    required this.item,
    required this.attachment,
    this.size = 64,
    this.onTap,
  });

  final NeedItem item;
  final Attachment attachment;
  final double size;
  final VoidCallback? onTap;

  bool get _isImage => attachment.kind == AttachmentKind.image;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(10);

    Widget content;
    if (_isImage) {
      final bytes = ref.watch(attachmentBytesProvider(
        (needId: item.id, attachmentId: attachment.id),
      ));
      content = bytes.when(
        loading: () => _placeholder(scheme, const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        )),
        error: (_, _) => _placeholder(scheme, _icon(scheme)),
        data: (data) {
          if (data == null || data.isEmpty) return _placeholder(scheme, _icon(scheme));
          return ClipRRect(
            borderRadius: radius,
            child: Image.memory(
              data,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          );
        },
      );
    } else {
      content = _placeholder(scheme, _icon(scheme));
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: size, height: size, child: content),
    );
  }

  Widget _icon(ColorScheme scheme) => Icon(
        attachment.kind.icon,
        size: size * 0.36,
        color: scheme.primary,
      );

  Widget _placeholder(ColorScheme scheme, Widget child) => Container(
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: child,
      );
}

/// Full-screen image viewer with pinch-zoom and a close button.
class AttachmentImageViewer extends ConsumerWidget {
  const AttachmentImageViewer({
    super.key,
    required this.item,
    required this.attachment,
  });

  final NeedItem item;
  final Attachment attachment;

  static Future<void> show(
    BuildContext context,
    NeedItem item,
    Attachment attachment,
  ) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, _, _) =>
            AttachmentImageViewer(item: item, attachment: attachment),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final bytes = ref.watch(attachmentBytesProvider(
      (needId: item.id, attachmentId: attachment.id),
    ));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: bytes.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Text(
                    l.attachmentOpenFailed,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                  ),
                ),
                data: (data) {
                  if (data == null || data.isEmpty) {
                    return Center(
                      child: Text(
                        l.attachmentOpenFailed,
                        style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                      ),
                    );
                  }
                  return InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5,
                    child: Center(child: Image.memory(data, fit: BoxFit.contain)),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                tooltip: l.cancel,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Text(
                attachment.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cairo',
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal strip of attachment thumbnails for a list row.
class AttachmentStrip extends ConsumerWidget {
  const AttachmentStrip({super.key, required this.item, this.size = 46});

  final NeedItem item;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = item.attachments;
    if (items.isEmpty) return const SizedBox.shrink();
    final shown = items.take(4).toList();
    final extra = items.length - shown.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...shown.map((a) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 5),
              child: AttachmentThumb(
                item: item,
                attachment: a,
                size: size,
                onTap: a.kind == AttachmentKind.image
                    ? () => AttachmentImageViewer.show(context, item, a)
                    : null,
              ),
            )),
        if (extra > 0)
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LazimColors.muted.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '+$extra',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: LazimColors.muted,
              ),
            ),
          ),
      ],
    );
  }
}

/// Grid of attachment thumbnails used on the item detail screen.
class AttachmentGrid extends ConsumerWidget {
  const AttachmentGrid({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onRemove,
  });

  final NeedItem item;
  final void Function(Attachment) onOpen;
  final void Function(Attachment) onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: item.attachments.map((a) {
        final isImage = a.kind == AttachmentKind.image;
        return SizedBox(
          width: 96,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AttachmentThumb(
                    item: item,
                    attachment: a,
                    size: 96,
                    onTap: () {
                      if (isImage) {
                        AttachmentImageViewer.show(context, item, a);
                      } else {
                        onOpen(a);
                      }
                    },
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 16,
                      tooltip: l.delete,
                      onPressed: () => onRemove(a),
                      icon: const Icon(Icons.cancel_rounded),
                      color: LazimColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                a.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: LazimColors.muted,
                ),
              ),
              if (a.sizeBytes != null)
                Text(
                  formatBytes(a.sizeBytes),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: LazimColors.muted,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
