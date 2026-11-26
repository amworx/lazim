import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import 'providers.dart';

/// Keeps the signed-in user's FCM token registered against the active family.
///
/// The Cloud Functions in `firebase/functions` look up `members/{uid}.fcmTokens`
/// to decide who to notify, so a token that is never written there means push
/// silently does nothing. This closes that loop:
///
///   * registers the current token once the user and their family are known,
///   * re-registers whenever FCM rotates the token,
///   * unregisters the old token when the active family changes, so a user who
///     switches families stops getting the old family's notifications.
///
/// Best-effort throughout: push is a nice-to-have, and a failure here must never
/// break sign-in or the list.
class PushRegistration extends Notifier<void> {
  String? _registeredFamilyId;
  String? _registeredToken;
  StreamSubscription<String>? _refreshSub;

  @override
  void build() {
    ref.onDispose(() {
      _refreshSub?.cancel();
      _refreshSub = null;
    });

    // React to auth and family changes. Both are watched, so this re-runs when
    // either resolves or changes.
    final user = ref.watch(authStateProvider).value;
    final family = ref.watch(activeFamilyProvider);

    if (user == null || family == null) {
      // Signed out or no family yet: drop the registration we were holding.
      unawaited(_release());
      return;
    }

    unawaited(_sync(user, family));

    // FCM can rotate the token at any time; keep Firestore in step.
    _refreshSub ??= ref.read(pushServiceProvider).tokenRefresh.listen((token) {
      final currentUser = ref.read(authStateProvider).value;
      final currentFamily = ref.read(activeFamilyProvider);
      if (currentUser == null || currentFamily == null) return;
      unawaited(_write(currentFamily.id, currentUser.id, token));
    });
  }

  Future<void> _sync(AppUser user, Family family) async {
    try {
      if (_registeredFamilyId != null && _registeredFamilyId != family.id) {
        await _release();
      }
      final token = await ref.read(pushServiceProvider).currentToken();
      if (token == null || token.isEmpty) return;
      await _write(family.id, user.id, token);
    } catch (_) {
      // Push is best-effort; never surface this to the user.
    }
  }

  Future<void> _write(String familyId, String userId, String token) async {
    try {
      await ref.read(familyRepositoryProvider).registerPushToken(
            familyId: familyId,
            userId: userId,
            token: token,
          );
      _registeredFamilyId = familyId;
      _registeredToken = token;
    } catch (_) {
      // Ignore: a stale token is pruned server-side by the Cloud Functions.
    }
  }

  Future<void> _release() async {
    final familyId = _registeredFamilyId;
    final token = _registeredToken;
    final user = ref.read(authStateProvider).value;
    _registeredFamilyId = null;
    _registeredToken = null;
    if (familyId == null || token == null || user == null) return;
    try {
      await ref.read(familyRepositoryProvider).unregisterPushToken(
            familyId: familyId,
            userId: user.id,
            token: token,
          );
    } catch (_) {
      // Ignore.
    }
  }
}

/// Watch this once near the root of the app to keep push registration alive.
final pushRegistrationProvider =
    NotifierProvider<PushRegistration, void>(PushRegistration.new);
