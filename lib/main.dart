import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config.dart';
import 'core/firebase_config.dart';
import 'core/providers.dart';
import 'core/push_registration.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'data/local_repository.dart';
import 'l10n/app_localizations.dart';
import 'ui/widgets/update_prompt.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  var firebaseReady = false;
  if (AppConfig.useFirebase) {
    try {
      // Options are passed explicitly rather than relying on the
      // google-services Gradle plugin, which is not applied here. Without this
      // Firebase.initializeApp() throws and the app silently falls back to the
      // local backend, which looks like "sign-in is broken".
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: FirebaseConfig.apiKey,
          appId: FirebaseConfig.appId,
          messagingSenderId: FirebaseConfig.messagingSenderId,
          projectId: FirebaseConfig.projectId,
          storageBucket: FirebaseConfig.storageBucket,
        ),
      );
      firebaseReady = true;
    } catch (_) {
      // A bad config must not brick the app: fall back to the local backend so
      // the build still runs.
      firebaseReady = false;
    }
  } else {
    await LocalStore.instance.ensureSeeded();
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        firebaseReadyProvider.overrideWithValue(firebaseReady),
      ],
      child: const LazimApp(),
    ),
  );
}

class LazimApp extends ConsumerStatefulWidget {
  const LazimApp({super.key});

  @override
  ConsumerState<LazimApp> createState() => _LazimAppState();
}

class _LazimAppState extends ConsumerState<LazimApp> {
  @override
  void initState() {
    super.initState();
    // Push setup is best-effort; a failure here must not block the UI.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushServiceProvider).initialise().catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep push-token registration alive for the app's lifetime. Watched (not
    // read) so it is not disposed while the app is running; it reacts to auth
    // and family changes on its own.
    ref.watch(pushRegistrationProvider);
    // Free local notifications from the live Firestore listener. No Cloud
    // Functions or billing account needed; see LocalNotifier for the tradeoff.
    ref.watch(localNotificationsProvider);

    final router = ref.watch(routerProvider);
    final localeCode = ref.watch(localeProvider);
    final dark = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Lazim',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: LazimTheme.light(),
      darkTheme: LazimTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(localeCode),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Clamp text scaling so the layout survives extreme accessibility
        // settings without breaking the cards.
        final scale = MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          // Wraps the whole app so the launch update check has a Navigator and
          // a ScaffoldMessenger to work with.
          child: UpdatePrompt(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
