/// Build-time configuration for Lazim.
///
/// The app defaults to the Firebase backend (`lazim-51935`). Run with
/// `--dart-define=LAZIM_BACKEND=local` for the offline demo backend.
class AppConfig {
  const AppConfig._();

  /// `local` or `firebase`.
  ///
  /// Defaults to `firebase` now that a real project (`lazim-51935`) is wired up:
  /// shared lists and Google sign-in only work against the cloud. Pass
  /// `--dart-define=LAZIM_BACKEND=local` to run the offline demo instead.
  static const String backend = String.fromEnvironment(
    'LAZIM_BACKEND',
    defaultValue: 'firebase',
  );

  static bool get useFirebase => backend == 'firebase';

  /// Public base URL used to build family invite links.
  ///
  /// Deliberately EMPTY by default. There is no hosted domain for Lazim, and an
  /// earlier placeholder (`lazim.app`) turned out to be a domain registered by
  /// an unrelated party, so links built from it reached nobody. With no base
  /// set, [inviteLink] returns null and the share text sends the invite CODE,
  /// which is what actually works: the other person types it into
  /// "Join a family".
  ///
  /// Set this only once you own a domain and host `assetlinks.json` there:
  /// `--dart-define=LAZIM_INVITE_BASE=https://yourdomain/join`.
  static const String inviteBase = String.fromEnvironment(
    'LAZIM_INVITE_BASE',
    defaultValue: '',
  );

  /// A tappable invite URL, or null when no invite domain is configured.
  static String? inviteLink(String code) =>
      inviteBase.isEmpty ? null : '$inviteBase/$code';

  /// HTTPS URL of the update manifest JSON.
  ///
  /// Empty by default, which disables update checks entirely: a fresh clone
  /// with no hosting set up should not sit there failing a network call on every
  /// launch. Point it at a static file when you have somewhere to publish
  /// builds, e.g. `--dart-define=LAZIM_UPDATE_MANIFEST=https://yourhost/update.json`.
  static const String updateManifestUrl = String.fromEnvironment(
    'LAZIM_UPDATE_MANIFEST',
    defaultValue: '',
  );

  /// Whether the app should look for updates at all.
  static bool get updatesEnabled => updateManifestUrl.isNotEmpty;
}
