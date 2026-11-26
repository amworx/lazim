import 'dart:io';

import '../domain/enums.dart';
import '../domain/models.dart';

/// Thrown by repositories for user-presentable failures.
class LazimException implements Exception {
  LazimException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => 'LazimException($code): $message';
}

/// Authentication surface. Implemented by Firebase Auth and by a local stub.
abstract interface class AuthRepository {
  /// Emits the signed-in user, or null when signed out.
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<AppUser> signInWithGoogle();

  /// Email link / passwordless fallback for devices where Google Play Services
  /// is unavailable.
  Future<AppUser> signInWithEmail(String email, String password);

  Future<AppUser> registerWithEmail(String email, String password, String displayName);

  Future<void> signOut();

  Future<void> updateDisplayName(String displayName);
}

/// Family group surface: creation, joining, membership.
abstract interface class FamilyRepository {
  /// Families the given user belongs to.
  Stream<List<Family>> watchFamilies(String userId);

  /// Members of a family, live.
  Stream<List<FamilyMember>> watchMembers(String familyId);

  Future<Family> createFamily({required String name, required AppUser owner});

  /// Joins a family using an invite code. Returns the joined family.
  Future<Family> joinFamily({required String inviteCode, required AppUser user});

  Future<Family?> familyByInviteCode(String inviteCode);

  Future<void> renameFamily(String familyId, String name);

  Future<void> removeMember(String familyId, String userId);

  Future<void> leaveFamily(String familyId, String userId);

  /// Registers a device push token for the member.
  Future<void> registerPushToken({
    required String familyId,
    required String userId,
    required String token,
  });

  Future<void> unregisterPushToken({
    required String familyId,
    required String userId,
    required String token,
  });
}

/// The needs list itself.
abstract interface class NeedRepository {
  /// Live list of items for a family. Filtering happens client-side so the
  /// history screen stays responsive and does not need composite indexes.
  Stream<List<NeedItem>> watchNeeds(String familyId);

  Future<NeedItem> createNeed({
    required String familyId,
    required AppUser actor,
    required String title,
    String? note,
    int quantity,
    String? unit,
    required NeedPriority priority,
    required NeedCategory category,
    String? assignedTo,
    String? assignedToName,
  });

  Future<void> updateNeed(NeedItem item, AppUser actor, {Map<String, Object?> changes});

  Future<void> changeStatus(NeedItem item, AppUser actor, NeedStatus status);

  Future<void> assign(NeedItem item, AppUser actor, FamilyMember? member);

  Future<void> deleteNeed(NeedItem item, AppUser actor);

  Future<Attachment> addLink(NeedItem item, AppUser actor, {required String url, required String name});

  Future<Attachment> uploadAttachment(NeedItem item, AppUser actor, {required File file, required String name});

  Future<void> removeAttachment(NeedItem item, AppUser actor, Attachment attachment);
}

/// Local preferences: language, active family.
abstract interface class PreferencesRepository {
  String? get localeCode;
  Future<void> setLocaleCode(String code);

  String? get activeFamilyId;
  Future<void> setActiveFamilyId(String? familyId);
}

/// Push notification surface.
abstract interface class PushService {
  Future<void> initialise();
  Future<String?> currentToken();
  Stream<String> get tokenRefresh;
  Stream<Map<String, dynamic>> get onForegroundMessage;
  Future<void> requestPermission();
}
