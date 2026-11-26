/// Firebase project configuration.
///
/// These values are the public client identifiers from `google-services.json`
/// (project `lazim-51935`). They are not secrets: the API key is a public client
/// key, and access is controlled by Firestore security rules and Firebase Auth,
/// not by hiding this file. Committing it is normal for Firebase Android apps.
///
/// Why hardcoded instead of `flutterfire configure`: the old Lazim project
/// already has a working Firebase setup, and reusing it means the existing
/// Google sign-in client, the registered release SHA-1, and the deployed
/// Firestore rules all keep working. `flutterfire configure` would generate a
/// `firebase_options.dart` with the same values, so this is that file, written
/// by hand and pinned to the project that is already live.
class FirebaseConfig {
  const FirebaseConfig._();

  static const String apiKey = 'AIzaSyCUZFKxGHPCvlDns0uvmHTDP9dl5Gc9SCM';
  static const String appId = '1:1040471265195:android:648557b2ee00f9ce280cee';
  static const String messagingSenderId = '1040471265195';
  static const String projectId = 'lazim-51935';
  static const String storageBucket = 'lazim-51935.firebasestorage.app';

  /// The web (client_type 3) OAuth client from `google-services.json`.
  ///
  /// google_sign_in 7.x needs this passed explicitly as `serverClientId` unless
  /// the google-services Gradle plugin generates a `default_web_client_id`
  /// resource. We do not apply that plugin (Firebase is initialised from Dart),
  /// so without this the sign-in flow fails with a missing-client error.
  static const String googleWebClientId =
      '1040471265195-3nugj06dhgl04tuj2dk5b5n3bkbhke77.apps.googleusercontent.com';
}
