import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazim/core/providers.dart';
import 'package:lazim/domain/models.dart';
import 'package:lazim/main.dart';
import 'package:lazim/ui/screens/sign_in_screen.dart';
import 'package:lazim/ui/screens/needs_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Routing gate tests.
///
/// These exist because the app shipped a real bug: `GoRouter.redirect` ran once
/// while auth was still resolving, then never re-ran, so a signed-out user was
/// parked on `/needs` with an empty list and no way to sign in. The gate is
/// driven by `refreshListenable`; these tests fail if that wiring is removed.
///
/// Deliberately uses `pump` with fixed durations rather than `pumpAndSettle`:
/// the app runs a push-service initialise and stream subscriptions that keep a
/// frame scheduled, and `pumpAndSettle` would wait out its full timeout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Widget> harness() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        firebaseReadyProvider.overrideWithValue(false),
      ],
      child: const LazimApp(),
    );
  }

  /// Pumps a fixed number of frames so async streams and redirects settle.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('signed out lands on the sign-in screen, not the needs list',
      (tester) async {
    await tester.pumpWidget(await harness());
    await settle(tester);

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(NeedsListScreen), findsNothing);
  });

  testWidgets('signing in moves past the gate into the app', (tester) async {
    await tester.pumpWidget(await harness());
    await settle(tester);
    expect(find.byType(SignInScreen), findsOneWidget);

    // Tap the Google button. The local backend signs in synchronously and the
    // router must re-run its redirect on the new auth state.
    await tester.tap(find.byType(FilledButton).first);
    await settle(tester);

    expect(find.byType(SignInScreen), findsNothing);
  });

  test('auth stream drives the gate in both directions', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        firebaseReadyProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    // A StreamProvider only subscribes once something listens, so hold a
    // subscription open and read the emitted values off it.
    final seen = <AppUser?>[];
    final sub = container.listen(authStateProvider, (_, next) {
      if (next.hasValue) seen.add(next.value);
    }, fireImmediately: true);
    addTearDown(sub.close);

    final repo = container.read(authRepositoryProvider);

    await repo.signInWithGoogle();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(seen.last?.id, isNotNull);

    await repo.signOut();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(seen.last, isNull);
  });
}
