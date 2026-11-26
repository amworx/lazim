import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config.dart';
import 'update_service.dart';

/// The update service, overridable in tests.
final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

/// Update state for the settings screen and the launch check.
final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

class UpdateController extends Notifier<UpdateState> {
  @override
  UpdateState build() {
    // Seed the current version so the settings screen can show it without
    // waiting for a network round trip.
    _loadCurrentVersion();
    return const UpdateState();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final current = await ref.read(updateServiceProvider).currentVersion();
      state = state.copyWith(
        currentVersion: current.version,
        currentBuild: current.build,
      );
    } catch (_) {
      // Non-fatal: the version row just stays blank.
    }
  }

  /// Checks the manifest. Silent on failure unless [surfaceErrors] is set, so a
  /// background check at launch never nags the user about a flaky network.
  Future<void> check({bool surfaceErrors = false}) async {
    if (!AppConfig.updatesEnabled) return;
    if (state.checking || state.downloading) return;

    state = state.copyWith(checking: true, clearError: true);
    try {
      final info = await ref.read(updateServiceProvider).checkForUpdate();
      state = state.copyWith(
        checking: false,
        available: info,
        clearAvailable: info == null,
      );
    } catch (e) {
      state = state.copyWith(
        checking: false,
        error: surfaceErrors ? _message(e) : null,
        clearError: !surfaceErrors,
      );
    }
  }

  /// Downloads the pending update, then installs it.
  ///
  /// Returns a short status the caller can show: `installed` when the installer
  /// was launched, `permission` when the user must grant install permission
  /// first, or `failed`.
  Future<UpdateOutcome> downloadAndInstall() async {
    final info = state.available;
    if (info == null) return UpdateOutcome.nothingToDo;

    final service = ref.read(updateServiceProvider);

    // Ask for install permission before spending bandwidth on the download.
    if (!await service.canInstall()) {
      await service.requestInstallPermission();
      return UpdateOutcome.permissionRequired;
    }

    state = state.copyWith(
      downloading: true,
      progress: 0,
      clearError: true,
      clearReady: true,
    );
    try {
      final path = await service.download(
        info,
        onProgress: (p) {
          // Guard against a rebuild storm from a fast stream of chunks.
          if ((p - state.progress).abs() >= 0.01 || p >= 1) {
            state = state.copyWith(progress: p);
          }
        },
      );
      state = state.copyWith(downloading: false, readyToInstallPath: path);
      await service.install(path);
      return UpdateOutcome.installerOpened;
    } catch (e) {
      state = state.copyWith(
        downloading: false,
        error: _message(e),
      );
      return UpdateOutcome.failed;
    }
  }

  /// Re-checks install permission, for use when the app resumes from the system
  /// settings screen.
  Future<bool> canInstall() => ref.read(updateServiceProvider).canInstall();

  /// Sends the user to the system screen where they grant install permission.
  Future<void> requestInstallPermission() =>
      ref.read(updateServiceProvider).requestInstallPermission();

  /// Installs an APK that was already downloaded.
  Future<UpdateOutcome> installReady() async {
    final path = state.readyToInstallPath;
    if (path == null) return UpdateOutcome.nothingToDo;
    try {
      await ref.read(updateServiceProvider).install(path);
      return UpdateOutcome.installerOpened;
    } catch (e) {
      state = state.copyWith(error: _message(e));
      return UpdateOutcome.failed;
    }
  }

  void dismiss() {
    state = state.copyWith(clearAvailable: true, clearError: true);
  }

  String _message(Object e) {
    if (e is UpdateException) return e.message;
    final s = e.toString().toLowerCase();
    if (s.contains('socket') || s.contains('network') || s.contains('host')) {
      return 'updateErrorNetwork';
    }
    return 'updateErrorGeneric';
  }
}

enum UpdateOutcome { installed, installerOpened, permissionRequired, nothingToDo, failed }
