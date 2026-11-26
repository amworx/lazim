import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'config.dart';

/// Where an update came from and what it offers.
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.apkUrl,
    required this.notes,
    this.mandatory = false,
  });

  /// Human version, e.g. `1.2.0`.
  final String version;

  /// Monotonic build number, e.g. `12`. This is what decides "newer", not the
  /// version string: `1.10.0` sorts before `1.9.0` as text.
  final int buildNumber;

  final String apkUrl;
  final String notes;
  final bool mandatory;

  static UpdateInfo? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final version = raw['version'];
    final build = raw['buildNumber'];
    final url = raw['apkUrl'];
    if (version is! String || url is! String) return null;
    final buildNumber = build is int ? build : int.tryParse('$build');
    if (buildNumber == null) return null;
    return UpdateInfo(
      version: version,
      buildNumber: buildNumber,
      apkUrl: url,
      notes: raw['notes'] is String ? raw['notes'] as String : '',
      mandatory: raw['mandatory'] == true,
    );
  }
}

/// State of an update check, as the UI needs to render it.
class UpdateState {
  const UpdateState({
    this.available,
    this.checking = false,
    this.downloading = false,
    this.progress = 0,
    this.readyToInstallPath,
    this.error,
    this.currentVersion,
    this.currentBuild,
  });

  final UpdateInfo? available;
  final bool checking;
  final bool downloading;

  /// 0..1, or 0 when the server sent no content length.
  final double progress;

  /// Set once the APK is on disk and ready to hand to the installer.
  final String? readyToInstallPath;

  final String? error;
  final String? currentVersion;
  final int? currentBuild;

  bool get hasUpdate => available != null;

  UpdateState copyWith({
    UpdateInfo? available,
    bool? checking,
    bool? downloading,
    double? progress,
    String? readyToInstallPath,
    String? error,
    String? currentVersion,
    int? currentBuild,
    bool clearAvailable = false,
    bool clearError = false,
    bool clearReady = false,
  }) {
    return UpdateState(
      available: clearAvailable ? null : (available ?? this.available),
      checking: checking ?? this.checking,
      downloading: downloading ?? this.downloading,
      progress: progress ?? this.progress,
      readyToInstallPath:
          clearReady ? null : (readyToInstallPath ?? this.readyToInstallPath),
      error: clearError ? null : (error ?? this.error),
      currentVersion: currentVersion ?? this.currentVersion,
      currentBuild: currentBuild ?? this.currentBuild,
    );
  }
}

/// Checks for, downloads, and installs app updates.
///
/// The check reads a small JSON manifest over HTTPS:
///
/// ```json
/// {
///   "version": "1.1.0",
///   "buildNumber": 2,
///   "apkUrl": "https://example.com/lazim-1.1.0.apk",
///   "notes": "Bug fixes",
///   "mandatory": false
/// }
/// ```
///
/// Point [AppConfig.updateManifestUrl] at wherever that file is hosted (a static
/// host, GitHub Releases, Firebase Hosting). Nothing is installed without the
/// user confirming the Android install prompt.
class UpdateService {
  UpdateService({http.Client? client, MethodChannel? channel})
      : _client = client ?? http.Client(),
        _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'lazim/updater';

  final http.Client _client;
  final MethodChannel _channel;

  /// Reads the installed version. Cached after the first call.
  Future<({String version, int build})> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return (
      version: info.version,
      build: int.tryParse(info.buildNumber) ?? 0,
    );
  }

  /// Fetches the manifest and returns it only if it is newer than what is
  /// installed. Returns null when up to date, when the manifest is unreachable,
  /// or when the response is not valid.
  Future<UpdateInfo?> checkForUpdate() async {
    final url = AppConfig.updateManifestUrl;
    if (url.isEmpty) return null;

    final current = await currentVersion();

    final response = await _client
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) return null;

    // Some static hosts (and anything written by a Windows editor) prepend a
    // UTF-8 BOM. jsonDecode rejects it, so strip it before parsing.
    var body = utf8.decode(response.bodyBytes);
    if (body.isNotEmpty && body.codeUnitAt(0) == 0xFEFF) {
      body = body.substring(1);
    }

    final decoded = jsonDecode(body);
    final info = UpdateInfo.fromJson(decoded);
    if (info == null) return null;

    // Build number decides. A version string comparison would rank 1.10 below
    // 1.9.
    if (info.buildNumber <= current.build) return null;
    return info;
  }

  /// Downloads the APK to app-private storage and returns its path.
  ///
  /// [onProgress] receives 0..1. The file lands in the `updates` subdirectory
  /// that the FileProvider exposes, which is why the path must stay under it.
  ///
  /// Uses getApplicationSupportDirectory(), NOT getApplicationDocumentsDirectory().
  /// On Android the documents directory is `app_flutter/`, which is outside
  /// getFilesDir() and therefore outside the FileProvider's `<files-path>` root:
  /// getUriForFile would throw "Failed to find configured root". The support
  /// directory maps to getFilesDir(), which is exactly what the provider exposes.
  Future<String> download(
    UpdateInfo info, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final updatesDir = Directory('${dir.path}/updates');
    if (!updatesDir.existsSync()) {
      await updatesDir.create(recursive: true);
    }

    final target = File('${updatesDir.path}/lazim-${info.buildNumber}.apk');
    // A previous partial download must not be resumed as if it were complete.
    if (target.existsSync()) await target.delete();

    final request = http.Request('GET', Uri.parse(info.apkUrl));
    final response = await _client.send(request).timeout(
          const Duration(minutes: 5),
        );
    if (response.statusCode != 200) {
      throw const UpdateException('The update download failed.');
    }

    final total = response.contentLength ?? 0;
    var received = 0;
    final sink = target.openWrite();
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
    } finally {
      await sink.flush();
      await sink.close();
    }

    // A truncated download that still "succeeds" would fail at install time
    // with a confusing parse error, so check the size when the server told us.
    if (total > 0 && received != total) {
      await target.delete();
      throw const UpdateException('The update download was incomplete.');
    }

    onProgress?.call(1);
    return target.path;
  }

  /// Deletes downloaded APKs left behind by earlier updates.
  ///
  /// A debug APK is ~180 MB, so leaving them around quietly eats the user's
  /// storage. Called after a successful install and on startup, because the
  /// install intent hands off to the system installer and the app is killed
  /// before it can clean up in the same run.
  Future<void> cleanupDownloads() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final updatesDir = Directory('${dir.path}/updates');
      if (!updatesDir.existsSync()) return;
      await for (final entity in updatesDir.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.apk')) {
          await entity.delete();
        }
      }
    } catch (_) {
      // Best effort: a stale download is not worth surfacing to the user.
    }
  }

  /// True when Android already allows this app to install packages.
  Future<bool> canInstall() async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('canInstallPackages');
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Opens the system "Install unknown apps" screen for Lazim.
  ///
  /// Returns true when the permission was already granted. When it returns
  /// false the user has been sent to settings; re-check with [canInstall] after
  /// the app resumes.
  Future<bool> requestInstallPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final granted = await _channel.invokeMethod<bool>('requestInstallPermission');
      return granted ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Hands the APK to the system installer. The user confirms in the Android
  /// dialog; this returns once the installer has been launched, not installed.
  Future<void> install(String apkPath) async {
    if (!Platform.isAndroid) {
      throw const UpdateException('Installing an update is Android only.');
    }
    try {
      await _channel.invokeMethod<bool>('installApk', {'path': apkPath});
    } on PlatformException catch (e) {
      throw UpdateException(e.message ?? 'The installer could not be opened.');
    } on MissingPluginException {
      throw const UpdateException('The installer is unavailable on this build.');
    }
  }
}

class UpdateException implements Exception {
  const UpdateException(this.message);
  final String message;

  @override
  String toString() => message;
}
