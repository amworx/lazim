import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/enums.dart';
import '../domain/models.dart';
import '../core/firebase_config.dart';
import 'repositories.dart';

const _uuid = Uuid();

/// Firestore layout
/// ---------------
/// users/{uid}                          -> AppUser
/// families/{familyId}                  -> Family
/// families/{familyId}/members/{uid}    -> FamilyMember
/// families/{familyId}/needs/{needId}   -> NeedItem
/// invites/{inviteCode}                 -> { familyId }
///
/// Needs are stored with activity inline (bounded list) which keeps reads to a
/// single document and avoids N+1 queries on the detail screen.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._db);
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AppUser _map(fb.User u) => AppUser(
        id: u.uid,
        displayName: u.displayName?.trim().isNotEmpty == true
            ? u.displayName!
            : (u.email?.split('@').first ?? 'Member'),
        email: u.email,
        photoUrl: u.photoURL,
      );

  Future<void> _ensureUserDoc(AppUser user) async {
    final ref = _db.collection('users').doc(user.id);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set(user.toMap());
    }
  }

  @override
  Stream<AppUser?> authStateChanges() => _auth.userChanges().asyncMap((u) async {
        if (u == null) return null;
        // The display name is a user-owned override: Google's name is only a
        // fallback. Read the stored value so a rename survives a restart, and
        // use userChanges() (not authStateChanges()) so an in-app rename is
        // reflected immediately in the UI.
        final mapped = await _mapWithStoredName(u);
        await _ensureUserDoc(mapped);
        return mapped;
      });

  /// Maps a Firebase user, preferring the display name saved in Firestore over
  /// the one from the Google/Auth profile.
  Future<AppUser> _mapWithStoredName(fb.User u) async {
    final base = _map(u);
    try {
      final snap = await _db.collection('users').doc(u.uid).get();
      final stored = snap.data()?['displayName'] as String?;
      if (stored != null && stored.trim().isNotEmpty) {
        return base.copyWith(displayName: stored);
      }
    } catch (_) {
      // Offline or rules hiccup: fall back to the auth profile name.
    }
    return base;
  }

  @override
  AppUser? get currentUser {
    final u = _auth.currentUser;
    if (u == null) return null;
    // Synchronous getter: the stream above carries the persisted override.
    return _map(u);
  }

  bool _googleReady = false;

  /// google_sign_in v7 is a singleton that must be initialised once before use.
  Future<void> _ensureGoogle() async {
    if (_googleReady) return;
    // serverClientId must be the web (client_type 3) OAuth client. The
    // google-services Gradle plugin normally generates a default_web_client_id
    // resource, but it is not applied here, so without this google_sign_in
    // throws a missing-client error and sign-in never opens the chooser.
    await GoogleSignIn.instance.initialize(
      serverClientId: FirebaseConfig.googleWebClientId,
    );
    _googleReady = true;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    await _ensureGoogle();
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw LazimException('Sign-in cancelled', code: 'auth/cancelled');
      }
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw LazimException('Google did not return an ID token', code: 'auth/no-token');
    }
    final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.signInWithCredential(credential);
    final user = _map(result.user!);
    await _ensureUserDoc(user);
    return user;
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = _map(result.user!);
    await _ensureUserDoc(user);
    return user;
  }

  @override
  Future<AppUser> registerWithEmail(String email, String password, String displayName) async {
    final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await result.user!.updateDisplayName(displayName);
    final user = _map(result.user!).copyWith(displayName: displayName);
    await _ensureUserDoc(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Google sign-out is best effort; Firebase sign-out is what matters.
    }
    await _auth.signOut();
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName);
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).set(
        {'displayName': displayName},
        SetOptions(merge: true),
      );
    }
  }
}

class FirebaseFamilyRepository implements FamilyRepository {
  FirebaseFamilyRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _families => _db.collection('families');

  @override
  Stream<List<Family>> watchFamilies(String userId) {
    // A user's families are found through their membership docs. We keep a
    // mirror list on the user doc to avoid a collection-group index requirement
    // on first run.
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((snap) async {
      final ids = (snap.data()?['familyIds'] as List?)?.cast<String>() ?? const <String>[];
      if (ids.isEmpty) return <Family>[];
      final futures = ids.take(20).map((id) => _families.doc(id).get());
      final docs = await Future.wait(futures);
      return docs.where((d) => d.exists).map((d) => Family.fromMap(d.data()!)).toList();
    });
  }

  @override
  Stream<List<FamilyMember>> watchMembers(String familyId) => _families
      .doc(familyId)
      .collection('members')
      .snapshots()
      .map((s) => s.docs.map((d) => FamilyMember.fromMap(d.data())).toList());

  @override
  Future<Family> createFamily({required String name, required AppUser owner}) async {
    final inviteCode = await _newInviteCode();
    final ref = _families.doc();
    final family = Family(
      id: ref.id,
      name: name,
      ownerId: owner.id,
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
      memberCount: 1,
    );
    final batch = _db.batch();
    batch.set(ref, family.toMap());
    batch.set(ref.collection('members').doc(owner.id), FamilyMember(
      userId: owner.id,
      displayName: owner.displayName,
      role: MemberRole.owner,
      joinedAt: DateTime.now(),
    ).toMap());
    batch.set(_db.collection('invites').doc(inviteCode), {'familyId': ref.id});
    batch.set(
      _db.collection('users').doc(owner.id),
      {
        'familyIds': FieldValue.arrayUnion([ref.id]),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
    return family;
  }

  Future<String> _newInviteCode() async {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = DateTime.now().microsecondsSinceEpoch;
    for (var attempt = 0; attempt < 6; attempt++) {
      final seed = rnd + attempt * 7919;
      final code = 'LAZIM-${List.generate(6, (i) => alphabet[(seed >> (i * 3)) % alphabet.length]).join()}';
      final exists = await _db.collection('invites').doc(code).get();
      if (!exists.exists) return code;
    }
    throw LazimException('Could not allocate an invite code', code: 'family/invite');
  }

  @override
  Future<Family?> familyByInviteCode(String inviteCode) async {
    final code = inviteCode.trim().toUpperCase();
    final invite = await _db.collection('invites').doc(code).get();
    if (!invite.exists) return null;
    final data = invite.data();
    final familyId = data?['familyId'] as String?;
    if (familyId == null) return null;
    // The family document is member-only, so a not-yet-joined user CANNOT read
    // it here (the rules deny it). Return a lightweight stub from the invite;
    // joinFamily() reads the real document after membership is granted.
    return Family(
      id: familyId,
      name: (data?['name'] as String?) ?? '',
      ownerId: (data?['ownerId'] as String?) ?? '',
      inviteCode: code,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Family> joinFamily({required String inviteCode, required AppUser user}) async {
    final stub = await familyByInviteCode(inviteCode);
    if (stub == null) {
      throw LazimException('Invite code not found', code: 'invite/not-found');
    }
    final familyId = stub.id;

    // Idempotency: don't double-count if the user already belongs. The user
    // doc is readable by its owner, so this check is allowed pre-join.
    final me = await _db.collection('users').doc(user.id).get();
    final ids = (me.data()?['familyIds'] as List?)?.cast<String>() ?? const <String>[];
    final alreadyMember = ids.contains(familyId);

    if (!alreadyMember) {
      // Phase 1: membership + the user's family mirror. Neither write needs
      // isMember(): the member doc is written by the user themselves
      // (memberId == uid) and the user doc is their own.
      final batch = _db.batch();
      batch.set(
        _families.doc(familyId).collection('members').doc(user.id),
        FamilyMember(
          userId: user.id,
          displayName: user.displayName,
          role: MemberRole.member,
          joinedAt: DateTime.now(),
        ).toMap(),
      );
      batch.set(
        _db.collection('users').doc(user.id),
        {'familyIds': FieldValue.arrayUnion([familyId])},
        SetOptions(merge: true),
      );
      await batch.commit();

      // Phase 2: now a member, so the family-doc update is permitted. Rules
      // cannot see same-batch writes, which is why this cannot live in the
      // batch above. Best-effort: membership is what matters, the count is a
      // display detail.
      try {
        await _families.doc(familyId).update({'memberCount': FieldValue.increment(1)});
      } catch (_) {}
    }

    // Now allowed: the user is a member of this family.
    final doc = await _families.doc(familyId).get();
    if (!doc.exists) {
      throw LazimException('Invite code not found', code: 'invite/not-found');
    }
    return Family.fromMap(doc.data()!);
  }

  @override
  Future<void> renameFamily(String familyId, String name) =>
      _families.doc(familyId).update({'name': name});

  @override
  Future<void> removeMember(String familyId, String userId) async {
    final batch = _db.batch();
    batch.delete(_families.doc(familyId).collection('members').doc(userId));
    batch.update(_families.doc(familyId), {'memberCount': FieldValue.increment(-1)});
    batch.set(
      _db.collection('users').doc(userId),
      {
        'familyIds': FieldValue.arrayRemove([familyId]),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  @override
  Future<void> leaveFamily(String familyId, String userId) => removeMember(familyId, userId);

  @override
  Future<void> registerPushToken({
    required String familyId,
    required String userId,
    required String token,
  }) =>
      _families.doc(familyId).collection('members').doc(userId).set(
        {
          'fcmTokens': FieldValue.arrayUnion([token]),
        },
        SetOptions(merge: true),
      );

  @override
  Future<void> unregisterPushToken({
    required String familyId,
    required String userId,
    required String token,
  }) =>
      _families.doc(familyId).collection('members').doc(userId).set(
        {
          'fcmTokens': FieldValue.arrayRemove([token]),
        },
        SetOptions(merge: true),
      );
}

class FirebaseNeedRepository implements NeedRepository {
  FirebaseNeedRepository(this._db, this._storage);
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _needs(String familyId) =>
      _db.collection('families').doc(familyId).collection('needs');

  @override
  Stream<List<NeedItem>> watchNeeds(String familyId) => _needs(familyId)
      .orderBy('createdAt', descending: true)
      .limit(500)
      .snapshots()
      .map((s) => s.docs.map((d) => NeedItem.fromMap(d.data())).toList());

  @override
  Future<NeedItem> createNeed({
    required String familyId,
    required AppUser actor,
    required String title,
    String? note,
    int quantity = 1,
    String? unit,
    required NeedPriority priority,
    required NeedCategory category,
    String? assignedTo,
    String? assignedToName,
  }) async {
    final ref = _needs(familyId).doc();
    final now = DateTime.now();
    final item = NeedItem(
      id: ref.id,
      familyId: familyId,
      title: title,
      note: note,
      quantity: quantity,
      unit: unit,
      status: NeedStatus.open,
      priority: priority,
      category: category,
      createdBy: actor.id,
      createdByName: actor.displayName,
      assignedTo: assignedTo,
      assignedToName: assignedToName,
      createdAt: now,
      updatedAt: now,
      activity: [
        ActivityEntry(
          id: _uuid.v4(),
          type: ActivityType.created,
          actorId: actor.id,
          actorName: actor.displayName,
          at: now,
        ),
      ],
    );
    await ref.set(item.toMap());
    return item;
  }

  @override
  Future<void> updateNeed(NeedItem item, AppUser actor,
      {Map<String, Object?> changes = const {}}) async {
    final entry = ActivityEntry(
      id: _uuid.v4(),
      type: ActivityType.edited,
      actorId: actor.id,
      actorName: actor.displayName,
      at: DateTime.now(),
      note: changes.keys.join(', '),
    );
    await _needs(item.familyId).doc(item.id).update({
      ...changes,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'activity': FieldValue.arrayUnion([entry.toMap()]),
    });
  }

  @override
  Future<void> changeStatus(NeedItem item, AppUser actor, NeedStatus status) async {
    if (item.status == status) return;
    final now = DateTime.now();
    final entry = ActivityEntry(
      id: _uuid.v4(),
      type: ActivityType.statusChanged,
      actorId: actor.id,
      actorName: actor.displayName,
      at: now,
      fromValue: item.status.code,
      toValue: status.code,
    );
    await _needs(item.familyId).doc(item.id).update({
      'status': status.code,
      'updatedAt': now.toUtc().toIso8601String(),
      if (status == NeedStatus.purchased) 'purchasedAt': now.toUtc().toIso8601String(),
      'activity': FieldValue.arrayUnion([entry.toMap()]),
    });
  }

  @override
  Future<void> assign(NeedItem item, AppUser actor, FamilyMember? member) async {
    final now = DateTime.now();
    final entry = ActivityEntry(
      id: _uuid.v4(),
      type: ActivityType.assigned,
      actorId: actor.id,
      actorName: actor.displayName,
      at: now,
      toValue: member?.displayName,
    );
    await _needs(item.familyId).doc(item.id).update({
      'assignedTo': member?.userId,
      'assignedToName': member?.displayName,
      if (member != null && item.status == NeedStatus.open) 'status': NeedStatus.claimed.code,
      'updatedAt': now.toUtc().toIso8601String(),
      'activity': FieldValue.arrayUnion([entry.toMap()]),
    });
  }

  @override
  Future<void> deleteNeed(NeedItem item, AppUser actor) async {
    for (final a in item.attachments) {
      final path = a.storagePath;
      if (path != null) {
        try {
          await _storage.ref(path).delete();
        } catch (_) {
          // Orphaned blobs are acceptable; the document is the source of truth.
        }
      }
    }
    await _needs(item.familyId).doc(item.id).delete();
  }

  @override
  Future<Attachment> addLink(NeedItem item, AppUser actor,
      {required String url, required String name}) async {
    final attachment = Attachment(
      id: _uuid.v4(),
      kind: AttachmentKind.link,
      name: name,
      url: url,
      addedBy: actor.id,
      addedAt: DateTime.now(),
    );
    await _appendAttachment(item, actor, attachment);
    return attachment;
  }

  @override
  Future<Attachment> uploadAttachment(NeedItem item, AppUser actor,
      {required File file, required String name}) async {
    final path = 'families/${item.familyId}/needs/${item.id}/${_uuid.v4()}_$name';
    final ref = _storage.ref(path);
    final task = await ref.putFile(file);
    final url = await task.ref.getDownloadURL();
    final attachment = Attachment(
      id: _uuid.v4(),
      kind: AttachmentKind.fromMime(null, name),
      name: name,
      url: url,
      storagePath: path,
      sizeBytes: await file.length(),
      addedBy: actor.id,
      addedAt: DateTime.now(),
    );
    await _appendAttachment(item, actor, attachment);
    return attachment;
  }

  Future<void> _appendAttachment(NeedItem item, AppUser actor, Attachment attachment) async {
    final entry = ActivityEntry(
      id: _uuid.v4(),
      type: ActivityType.attachmentAdded,
      actorId: actor.id,
      actorName: actor.displayName,
      at: DateTime.now(),
      toValue: attachment.name,
    );
    await _needs(item.familyId).doc(item.id).update({
      'attachments': FieldValue.arrayUnion([attachment.toMap()]),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'activity': FieldValue.arrayUnion([entry.toMap()]),
    });
  }

  @override
  Future<void> removeAttachment(NeedItem item, AppUser actor, Attachment attachment) async {
    final path = attachment.storagePath;
    if (path != null) {
      try {
        await _storage.ref(path).delete();
      } catch (_) {
        // Ignore missing blob.
      }
    }
    await _needs(item.familyId).doc(item.id).update({
      'attachments': FieldValue.arrayRemove([attachment.toMap()]),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

class FirebasePreferencesRepository implements PreferencesRepository {
  FirebasePreferencesRepository(this._prefs);
  final SharedPreferences _prefs;

  @override
  String? get localeCode => _prefs.getString('locale');

  @override
  Future<void> setLocaleCode(String code) => _prefs.setString('locale', code);

  @override
  String? get activeFamilyId => _prefs.getString('activeFamily');

  @override
  Future<void> setActiveFamilyId(String? familyId) async {
    if (familyId == null) {
      await _prefs.remove('activeFamily');
    } else {
      await _prefs.setString('activeFamily', familyId);
    }
  }
}

class FirebasePushService implements PushService {
  final _foreground = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Future<void> initialise() async {
    FirebaseMessaging.onMessage.listen((m) {
      _foreground.add({
        'title': m.notification?.title,
        'body': m.notification?.body,
        'data': m.data,
      });
    });
    // Cache the token as it is issued so currentToken() can return it.
    FirebaseMessaging.instance.onRegistered.listen((token) => _lastToken = token);
  }

  @override
  Future<String?> currentToken() async {
    // v17 replaced getToken() with register(); the token arrives via onRegistered.
    await FirebaseMessaging.instance.register();
    return _lastToken;
  }

  String? _lastToken;

  @override
  Stream<String> get tokenRefresh => FirebaseMessaging.instance.onRegistered;

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage => _foreground.stream;

  @override
  Future<void> requestPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}
