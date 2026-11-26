import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/update_controller.dart';
import '../../l10n/app_localizations.dart';

/// The "App updates" block on the settings screen.
///
/// Shows the installed version, a check button, and — when an update exists —
/// the download/install action with live progress. Install permission is
/// requested before the download starts, so the user is not left waiting on a
/// file they cannot install.
class UpdateSection extends ConsumerStatefulWidget {
  const UpdateSection({super.key});

  @override
  ConsumerState<UpdateSection> createState() => _UpdateSectionState();
}

class _UpdateSectionState extends ConsumerState<UpdateSection>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may have just granted "install unknown apps" in system settings.
    // Re-check on resume so the button reflects reality instead of the stale
    // answer we got before they left.
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final theme = Theme.of(context);
    final update = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);

    final versionLabel = update.currentVersion == null
        ? '—'
        : '${update.currentVersion} (${update.currentBuild ?? 0})';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.updateCurrentVersion,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              versionLabel,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.5,
                color: LazimColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (!AppConfig.updatesEnabled)
          Text(
            l.updatesDisabled,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.5,
              color: LazimColors.muted,
              height: 1.6,
            ),
          )
        else if (update.downloading) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: update.progress == 0 ? null : update.progress,
              minHeight: 7,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.updateDownloading((update.progress * 100).round()),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.5,
              color: LazimColors.muted,
            ),
          ),
        ] else if (update.hasUpdate) ...[
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.updateAvailable(update.available!.version),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (update.available!.notes.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    update.available!.notes,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12.5,
                      color: LazimColors.muted,
                      height: 1.6,
                    ),
                  ),
                ],
                if (update.available!.mandatory) ...[
                  const SizedBox(height: 5),
                  Text(
                    l.updateMandatoryNote,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: LazimColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _install(context, controller),
            icon: const Icon(Icons.system_update_alt_rounded, size: 20),
            label: Text(
              update.readyToInstallPath == null
                  ? l.updateDownload
                  : l.updateInstall,
            ),
          ),
        ] else
          OutlinedButton.icon(
            onPressed: update.checking
                ? null
                : () => controller.check(surfaceErrors: true),
            icon: update.checking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 19),
            label: Text(
              update.checking ? l.checkingForUpdates : l.checkForUpdates,
            ),
          ),

        if (update.error != null) ...[
          const SizedBox(height: 10),
          Text(
            _errorText(l, update.error!),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.5,
              color: LazimColors.danger,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _install(BuildContext context, UpdateController controller) async {
    final l = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Read the current state through a provider read rather than the notifier's
    // protected `state` member.
    final alreadyDownloaded =
        ref.read(updateControllerProvider).readyToInstallPath != null;

    final outcome = alreadyDownloaded
        ? await controller.installReady()
        : await controller.downloadAndInstall();

    if (!mounted) return;

    switch (outcome) {
      case UpdateOutcome.permissionRequired:
        await _showPermissionDialog(l);
      case UpdateOutcome.installerOpened:
        messenger.showSnackBar(
          SnackBar(content: Text(l.updateInstallerOpened)),
        );
      case UpdateOutcome.failed:
        // The error line in the section already explains it.
        break;
      case UpdateOutcome.installed:
      case UpdateOutcome.nothingToDo:
        break;
    }
  }

  Future<void> _showPermissionDialog(AppL10n l) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.updatePermissionTitle),
        content: Text(l.updatePermissionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.updateLater),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(updateControllerProvider.notifier)
                  .requestInstallPermission();
            },
            child: Text(l.updatePermissionAction),
          ),
        ],
      ),
    );
  }

  String _errorText(AppL10n l, String key) {
    switch (key) {
      case 'updateErrorNetwork':
        return l.updateErrorNetwork;
      case 'updateErrorGeneric':
        return l.updateErrorGeneric;
      default:
        // A raw message from the native installer or the download layer. Show
        // it rather than hiding the actual cause behind a generic string.
        return key;
    }
  }
}
