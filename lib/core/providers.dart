import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import '../core/local_notifier.dart';
import '../data/firebase_repository.dart';
import '../data/local_repository.dart';
import '../data/repositories.dart';
import '../domain/enums.dart';
import '../domain/models.dart';

/// Overridden in main() once SharedPreferences has loaded.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

/// Overridden in main() after `Firebase.initializeApp()`.
final firebaseReadyProvider = Provider<bool>((ref) => false);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useFirebase && ref.watch(firebaseReadyProvider)) {
    return FirebaseAuthRepository(fb.FirebaseAuth.instance, FirebaseFirestore.instance);
  }
  return LocalAuthRepository(LocalStore.instance);
});

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  if (AppConfig.useFirebase && ref.watch(firebaseReadyProvider)) {
    return FirebaseFamilyRepository(FirebaseFirestore.instance);
  }
  return LocalFamilyRepository(LocalStore.instance);
});

final needRepositoryProvider = Provider<NeedRepository>((ref) {
  if (AppConfig.useFirebase && ref.watch(firebaseReadyProvider)) {
    return FirebaseNeedRepository(FirebaseFirestore.instance, FirebaseStorage.instance);
  }
  return LocalNeedRepository(LocalStore.instance);
});

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  if (AppConfig.useFirebase && ref.watch(firebaseReadyProvider)) {
    return FirebasePreferencesRepository(prefs);
  }
  return LocalPreferencesRepository(prefs);
});

final pushServiceProvider = Provider<PushService>((ref) {
  if (AppConfig.useFirebase && ref.watch(firebaseReadyProvider)) {
    return FirebasePushService();
  }
  return LocalPushService();
});

/// Signed-in user, or null.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Locale override chosen by the user.
///
/// Arabic is the app's primary language, so it is the default: an unset
/// preference resolves to `ar` no matter what the device is set to. English is
/// opt-in from Settings and persists once chosen.
final localeProvider = NotifierProvider<LocaleNotifier, String>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(preferencesRepositoryProvider).localeCode ?? 'ar';

  Future<void> set(String code) async {
    await ref.read(preferencesRepositoryProvider).setLocaleCode(code);
    state = code;
  }
}

/// Theme mode override.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, bool>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return prefs.getBool('darkMode') ?? false;
  }

  Future<void> toggle() async {
    final next = !state;
    await ref.read(sharedPrefsProvider).setBool('darkMode', next);
    state = next;
  }
}

/// The families the current user belongs to.
final familiesProvider = StreamProvider<List<Family>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const <Family>[]);
  return ref.watch(familyRepositoryProvider).watchFamilies(user.id);
});

/// The family currently in view.
final activeFamilyIdProvider = NotifierProvider<ActiveFamilyNotifier, String?>(ActiveFamilyNotifier.new);

class ActiveFamilyNotifier extends Notifier<String?> {
  @override
  String? build() {
    final stored = ref.watch(preferencesRepositoryProvider).activeFamilyId;
    final families = ref.watch(familiesProvider).value ?? const <Family>[];
    if (families.isEmpty) return stored;
    if (stored != null && families.any((f) => f.id == stored)) return stored;
    return families.first.id;
  }

  Future<void> select(String familyId) async {
    await ref.read(preferencesRepositoryProvider).setActiveFamilyId(familyId);
    state = familyId;
  }
}

final activeFamilyProvider = Provider<Family?>((ref) {
  final id = ref.watch(activeFamilyIdProvider);
  final families = ref.watch(familiesProvider).value ?? const <Family>[];
  if (id == null) return families.isEmpty ? null : families.first;
  for (final f in families) {
    if (f.id == id) return f;
  }
  return families.isEmpty ? null : families.first;
});

final membersProvider = StreamProvider<List<FamilyMember>>((ref) {
  final family = ref.watch(activeFamilyProvider);
  if (family == null) return Stream.value(const <FamilyMember>[]);
  return ref.watch(familyRepositoryProvider).watchMembers(family.id);
});

/// All needs for the active family, live.
final needsProvider = StreamProvider<List<NeedItem>>((ref) {
  final family = ref.watch(activeFamilyProvider);
  if (family == null) return Stream.value(const <NeedItem>[]);
  return ref.watch(needRepositoryProvider).watchNeeds(family.id);
});

/// Watches the live needs stream and raises a local notification for family
/// activity by other people. Free alternative to a Cloud Functions push: no
/// billing account, no worker, no service-account key.
///
/// This is a Notifier so it can hold the [LocalNotifier] instance and reset its
/// seen-set when the family changes. It is watched once near the app root.
final localNotificationsProvider =
    NotifierProvider<LocalNotificationsController, void>(
  LocalNotificationsController.new,
);

class LocalNotificationsController extends Notifier<void> {
  LocalNotifier? _notifier;
  bool _initialised = false;
  String? _lastFamilyId;

  @override
  void build() {
    // build() re-runs whenever a watched dependency changes; keep one instance
    // so the seen-set survives rebuilds (and so `late final` cannot throw).
    _notifier ??= LocalNotifier();
    final notifier = _notifier!;

    // Ask for notification permission at startup, before any family activity
    // arrives, so the system prompt is not a surprise. Guarded so rebuilds do
    // not re-request it.
    if (!_initialised) {
      _initialised = true;
      unawaited(notifier.initialise());
    }

    final user = ref.watch(authStateProvider).value;
    final family = ref.watch(activeFamilyProvider);
    final locale = ref.watch(localeProvider);
    final needs = ref.watch(needsProvider).value;

    if (user == null || family == null || needs == null) return;

    // A different family means a different activity history: forget what we
    // had seen so the first snapshot of the new family only primes the set.
    if (_lastFamilyId != family.id) {
      _lastFamilyId = family.id;
      notifier.reset();
    }

    unawaited(notifier.observe(
      needs,
      currentUserId: user.id,
      localeCode: locale,
    ));
  }
}

/// Active (not done) items, sorted for the main list.
final activeNeedsProvider = Provider<List<NeedItem>>((ref) {
  final all = ref.watch(needsProvider).value ?? const <NeedItem>[];
  final list = all.where((n) => n.status.isActive).toList();
  list.sort((a, b) {
    final p = b.priority.index.compareTo(a.priority.index);
    if (p != 0) return p;
    return b.createdAt.compareTo(a.createdAt);
  });
  return list;
});

/// Everything that is done, newest first — the history feed.
final doneNeedsProvider = Provider<List<NeedItem>>((ref) {
  final all = ref.watch(needsProvider).value ?? const <NeedItem>[];
  final list = all.where((n) => n.isDone).toList();
  list.sort((a, b) => (b.purchasedAt ?? b.updatedAt).compareTo(a.purchasedAt ?? a.updatedAt));
  return list;
});

/// History filter state.
final needFilterProvider = NotifierProvider<NeedFilterNotifier, NeedFilter>(NeedFilterNotifier.new);

class NeedFilterNotifier extends Notifier<NeedFilter> {
  @override
  NeedFilter build() => const NeedFilter();

  void update(NeedFilter Function(NeedFilter) fn) => state = fn(state);
  void clear() => state = const NeedFilter();
}

/// Done items after the filter is applied.
final filteredDoneNeedsProvider = Provider<List<NeedItem>>((ref) {
  final filter = ref.watch(needFilterProvider);
  final done = ref.watch(doneNeedsProvider);
  return filter.apply(done);
});

/// A single need by id, kept live so the detail screen reflects edits.
final needByIdProvider = Provider.family<NeedItem?, String>((ref, id) {
  final all = ref.watch(needsProvider).value ?? const <NeedItem>[];
  for (final n in all) {
    if (n.id == id) return n;
  }
  return null;
});

/// Counts used by the summary strip on the list screen.
final needStatsProvider = Provider<({int open, int claimed, int urgent, int doneThisWeek})>((ref) {
  final all = ref.watch(needsProvider).value ?? const <NeedItem>[];
  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  var open = 0, claimed = 0, urgent = 0, doneWeek = 0;
  for (final n in all) {
    switch (n.status) {
      case NeedStatus.open:
        open++;
      case NeedStatus.claimed:
        claimed++;
      default:
        break;
    }
    if (n.status.isActive && n.priority == NeedPriority.urgent) urgent++;
    if (n.status == NeedStatus.purchased &&
        (n.purchasedAt?.isAfter(weekAgo) ?? false)) {
      doneWeek++;
    }
  }
  return (open: open, claimed: claimed, urgent: urgent, doneThisWeek: doneWeek);
});
