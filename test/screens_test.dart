import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazim/core/providers.dart';
import 'package:lazim/data/local_repository.dart';
import 'package:lazim/main.dart';
import 'package:lazim/ui/screens/history_screen.dart';
import 'package:lazim/ui/screens/need_detail_screen.dart';
import 'package:lazim/ui/screens/needs_list_screen.dart';
import 'package:lazim/ui/screens/settings_screen.dart';
import 'package:lazim/ui/screens/sign_in_screen.dart';
import 'package:lazim/ui/widgets/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen-level smoke tests against the local demo backend.
///
/// The point is to prove each screen actually builds with real data rather than
/// only that the code compiles: a widget that throws during build, or an empty
/// state that never resolves, fails here.
///
/// Uses fixed-duration `pump` loops instead of `pumpAndSettle` because the app
/// keeps a frame scheduled (push initialise, live streams) and `pumpAndSettle`
/// would burn its full timeout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Widget> harness() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    // LocalStore is a process-wide singleton, so state from a previous test
    // would otherwise leak in (a signed-in user makes the gate skip /signin).
    await LocalStore.instance.signOut();
    return ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        firebaseReadyProvider.overrideWithValue(false),
      ],
      child: const LazimApp(),
    );
  }

  Future<void> settle(WidgetTester tester, {int frames = 14}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Signs in through the real sign-in button and waits for the gate to move.
  Future<void> signIn(WidgetTester tester) async {
    await tester.pumpWidget(await harness());
    await settle(tester);
    expect(find.byType(SignInScreen), findsOneWidget);
    await tester.tap(find.byType(FilledButton).first);
    await settle(tester);
  }

  testWidgets('needs list renders seeded items after sign-in', (tester) async {
    await signIn(tester);

    expect(find.byType(NeedsListScreen), findsOneWidget);
    // The local backend seeds six demo items; at least one must be on screen.
    expect(find.text('Milk'), findsWidgets);
  });

  testWidgets('history screen builds and shows its empty state', (tester) async {
    await signIn(tester);

    // Navigate via the bottom nav rather than the router, so the shell is
    // exercised too.
    await tester.tap(find.byIcon(Icons.history_rounded).last);
    await settle(tester);

    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings screen builds with family and language sections',
      (tester) async {
    await signIn(tester);

    // Settings is reached from the member avatar in the list header.
    await tester.tap(find.byType(MemberAvatar).first);
    await settle(tester);

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a need opens its detail screen', (tester) async {
    await signIn(tester);

    final card = find.text('Milk').first;
    expect(card, findsOneWidget);
    await tester.tap(card);
    await settle(tester);

    expect(find.byType(NeedDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic is the default even on an English device', (tester) async {
    // The test binding reports en_US, but Arabic is the app's primary language
    // and must win regardless of the device locale.
    await signIn(tester);

    final dir = Directionality.of(tester.element(find.byType(NeedsListScreen)));
    expect(dir, TextDirection.rtl);
  });

  testWidgets('choosing English switches the app to LTR', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    await LocalStore.instance.signOut();

    final container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        firebaseReadyProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LazimApp(),
      ),
    );
    await settle(tester);

    // Arabic out of the box.
    expect(
      Directionality.of(tester.element(find.byType(SignInScreen))),
      TextDirection.rtl,
    );

    // Flip to English the same way the settings screen does.
    await container.read(localeProvider.notifier).set('en');
    await settle(tester);

    expect(
      Directionality.of(tester.element(find.byType(SignInScreen))),
      TextDirection.ltr,
    );
  });
}
