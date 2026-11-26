import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/router.dart';
import '../../core/update_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';

/// Checks for an update shortly after launch and, if one exists, shows a
/// dismissible prompt.
///
/// Deliberately quiet: the check is silent on failure, and a non-mandatory
/// update can always be postponed. A mandatory update cannot be dismissed,
/// which is the only way to force a version bump on a user.
class UpdatePrompt extends ConsumerStatefulWidget {
  const UpdatePrompt({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdatePrompt> createState() => _UpdatePromptState();
}

class _UpdatePromptState extends ConsumerState<UpdatePrompt> {
  bool _prompted = false;
  Timer? _launchTimer;

  @override
  void initState() {
    super.initState();
    // Nothing to do at all when no manifest is configured: do not schedule a
    // timer, do not touch the network.
    if (!AppConfig.updatesEnabled) return;
    // Let the first frame settle before touching the network.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // An install hands off to the system installer, which kills this process,
      // so the APK from the last update can only be cleaned up on the next
      // launch. Do that here, before the update check.
      ref.read(updateServiceProvider).cleanupDownloads();
      _checkOnLaunch();
    });
  }

  @override
  void dispose() {
    _launchTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkOnLaunch() async {
    if (!mounted) return;
    // Small delay so the launch check never competes with first-frame work.
    // Held in a field so dispose() can cancel it.
    final done = Completer<void>();
    _launchTimer = Timer(const Duration(seconds: 3), done.complete);
    await done.future;
    if (!mounted) return;
    await ref.read(updateControllerProvider.notifier).check();
    if (!mounted) return;
    _maybePrompt();
  }

  void _maybePrompt() {
    if (_prompted || !mounted) return;
    final update = ref.read(updateControllerProvider);
    if (!update.hasUpdate) return;
    _prompted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDialog());
  }

  Future<void> _showDialog() async {
    if (!mounted) return;
    final l = AppL10n.of(context);
    final info = ref.read(updateControllerProvider).available;
    if (info == null) return;

    // This widget sits in MaterialApp.builder, ABOVE the Navigator, so the
    // ambient context has no Navigator to attach a dialog to. showDialog would
    // throw "The context used to push or pop routes must be a descendant of a
    // Navigator" and the prompt would silently never appear. Use the root
    // navigator's own context instead.
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;

    await showDialog<void>(
      context: navContext,
      barrierDismissible: !info.mandatory,
      builder: (ctx) => PopScope(
        canPop: !info.mandatory,
        child: AlertDialog(
          title: Text(l.updateAvailable(info.version)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (info.notes.isNotEmpty)
                Text(
                  info.notes,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              if (info.mandatory) ...[
                const SizedBox(height: 10),
                Text(
                  l.updateMandatoryNote,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.5,
                    color: LazimColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (!info.mandatory)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l.updateLater),
              ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // Send them to Settings, where the download/install lives with
                // its progress and permission handling.
                ref.read(routerProvider).go('/settings');
              },
              child: Text(l.updateDownload),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Re-prompt if an update appears after launch (e.g. a manual check).
    ref.listen(updateControllerProvider, (prev, next) {
      if (next.hasUpdate && (prev?.hasUpdate != true)) {
        _maybePrompt();
      }
    });
    return widget.child;
  }
}
