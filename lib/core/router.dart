import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../ui/screens/family_setup_screen.dart';
import '../ui/screens/history_screen.dart';
import '../ui/screens/need_detail_screen.dart';
import '../ui/screens/need_editor_screen.dart';
import '../ui/screens/needs_list_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/sign_in_screen.dart';
import '../ui/shell.dart';

/// Root navigator key. Exposed so widgets that live above the Navigator (the
/// MaterialApp.builder, where the update prompt sits) can still show dialogs.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// App router with an auth gate and invite-link capture.
///
/// Invite links look like `lazim://join/LAZIM-ABC123`. The `/join/:code` route
/// carries the code into family setup, which prefills and submits it. There is
/// no https link: Lazim hosts no domain, so invitations are shared as a code.
final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = rootNavigatorKey;

  // GoRouter evaluates `redirect` once and then only when told to. Auth and the
  // family list both resolve asynchronously, so without a refresh signal the
  // router would decide the route while auth was still loading and then never
  // revisit it — leaving a signed-out user parked on /needs.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.listen(familiesProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/needs',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final user = auth.value;
      final familiesAsync = ref.read(familiesProvider);
      final families = familiesAsync.value;
      final path = state.uri.path;

      final joining = path.startsWith('/join/');
      final onSignIn = path == '/signin';
      final onSetup = path == '/setup';

      if (auth.isLoading && user == null) return null;

      if (user == null) {
        if (joining || onSignIn) return null;
        return '/signin';
      }

      // Wait for the family list before deciding where to send a signed-in user.
      if (familiesAsync.isLoading && families == null) return null;

      if ((families == null || families.isEmpty) && !onSetup && !joining) {
        return '/setup';
      }

      if ((onSignIn || onSetup) && families != null && families.isNotEmpty) {
        return '/needs';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/signin', builder: (_, _) => const SignInScreen()),
      GoRoute(
        path: '/setup',
        builder: (_, state) => FamilySetupScreen(
          prefillCode: state.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: '/join/:code',
        builder: (_, state) => FamilySetupScreen(
          prefillCode: state.pathParameters['code'],
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/needs', builder: (_, _) => const NeedsListScreen()),
          GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
        ],
      ),
      GoRoute(path: '/need/new', builder: (_, _) => const NeedEditorScreen()),
      GoRoute(
        path: '/need/:id/edit',
        builder: (_, state) {
          final item = ref.read(needByIdProvider(state.pathParameters['id']!));
          return NeedEditorScreen(existing: item);
        },
      ),
      GoRoute(
        path: '/need/:id',
        builder: (_, state) => NeedDetailScreen(needId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );
});
