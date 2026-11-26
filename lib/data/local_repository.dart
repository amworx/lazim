import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/enums.dart';
import '../domain/models.dart';
import 'repositories.dart';

const _uuid = Uuid();

/// In-memory + SharedPreferences backed implementation of the whole app.
///
/// This exists so the app is runnable, demoable and testable before a Firebase
/// project is provisioned. It implements the same contracts as the Firebase
/// backend, so switching is a one-line change in the provider graph.
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  final _auth = StreamController<AppUser?>.broadcast();
  final _families = StreamController<List<Family>>.broadcast();
  final _members = StreamController<Map<String, List<FamilyMember>>>.broadcast();
  final _needs = StreamController<Map<String, List<NeedItem>>>.broadcast();

  AppUser? _user;
  final Map<String, Family> _familyById = {};
  final Map<String, List<FamilyMember>> _membersByFamily = {};
  final Map<String, List<NeedItem>> _needsByFamily = {};
  final Map<String, String> _inviteToFamily = {};

  bool _seeded = false;

  Future<void> ensureSeeded() async {
    if (_seeded) return;
    _seeded = true;

    // Demo family so the first launch is not an empty void.
    //
    // The owner id must match the id signIn() assigns to the demo user
    // ('demo-user'). If they differ, signIn cannot recognise the demo owner as
    // already being a member and appends a second "Saffron" to the family,
    // which shows up as a duplicate chip in the assignee filter.
    final owner = const AppUser(
      id: 'demo-user',
      displayName: 'Saffron',
      email: 'demo@lazim.app',
    );
    final family = Family(
      id: 'demo-family',
      name: 'Home',
      ownerId: owner.id,
      inviteCode: 'LAZIM-DEMO',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      memberCount: 2,
    );
    _familyById[family.id] = family;
    _inviteToFamily[family.inviteCode] = family.id;
    _membersByFamily[family.id] = [
      FamilyMember(
        userId: owner.id,
        displayName: owner.displayName,
        role: MemberRole.owner,
        joinedAt: family.createdAt,
      ),
      FamilyMember(
        userId: 'demo-partner',
        displayName: 'Noor',
        role: MemberRole.member,
        joinedAt: family.createdAt.add(const Duration(days: 1)),
      ),
    ];

    final now = DateTime.now();
    _needsByFamily[family.id] = [
      _seed('Milk', NeedCategory.groceries, NeedPriority.normal, 2, 'L', owner, now, daysAgo: 1),
      _seed('Dish soap', NeedCategory.household, NeedPriority.normal, 1, null, owner, now, daysAgo: 2),
      _seed('Paracetamol', NeedCategory.pharmacy, NeedPriority.urgent, 1, 'box', owner, now, daysAgo: 0),
      _seed('Kids school notebooks', NeedCategory.kids, NeedPriority.normal, 4, null, owner, now, daysAgo: 3),
      _seed('Coffee beans', NeedCategory.groceries, NeedPriority.low, 1, 'kg', owner, now, daysAgo: 5),
      _seed('Light bulbs', NeedCategory.electronics, NeedPriority.normal, 3, null, owner, now, daysAgo: 8),
    ];
    _emitAll();
  }

  NeedItem _seed(
    String title,
    NeedCategory category,
    NeedPriority priority,
    int qty,
    String? unit,
    AppUser actor,
    DateTime now, {
    required int daysAgo,
  }) {
    final created = now.subtract(Duration(days: daysAgo, hours: 3));
    return NeedItem(
      id: _uuid.v4(),
      familyId: 'demo-family',
      title: title,
      status: NeedStatus.open,
      priority: priority,
      category: category,
      quantity: qty,
      unit: unit,
      createdBy: actor.id,
      createdByName: actor.displayName,
      createdAt: created,
      updatedAt: created,
      activity: [
        ActivityEntry(
          id: _uuid.v4(),
          type: ActivityType.created,
          actorId: actor.id,
          actorName: actor.displayName,
          at: created,
        ),
      ],
    );
  }

  void _emitAll() {
    if (!_auth.isClosed) _auth.add(_user);
    if (!_families.isClosed) {
      _families.add(_familyById.values
          .where((f) => _membersByFamily[f.id]?.any((m) => m.userId == _user?.id) ?? false)
          .toList());
    }
    if (!_members.isClosed) _members.add(Map.of(_membersByFamily));
    if (!_needs.isClosed) _needs.add(Map.of(_needsByFamily));
  }

  // ---- auth ----

  Stream<AppUser?> authStream() async* {
    yield _user;
    yield* _auth.stream;
  }

  AppUser? get user => _user;

  Future<AppUser> signIn(String displayName, {String? email}) async {
    await ensureSeeded();
    final existing = _user;
    if (existing != null) return existing;
    final user = AppUser(
      id: 'demo-user',
      displayName: displayName,
      email: email ?? 'demo@lazim.app',
    );
    _user = user;
    // Make sure the demo user is a member of the demo family so the app has
    // content immediately.
    final demo = _familyById['demo-family'];
    if (demo != null && !(_membersByFamily[demo.id]?.any((m) => m.userId == user.id) ?? false)) {
      _membersByFamily[demo.id]!.add(FamilyMember(
        userId: user.id,
        displayName: user.displayName,
        role: MemberRole.member,
        joinedAt: DateTime.now(),
      ));
      _familyById[demo.id] = demo.copyWith(memberCount: _membersByFamily[demo.id]!.length);
    }
    _emitAll();
    return user;
  }

  Future<void> signOut() async {
    _user = null;
    _emitAll();
  }

  Future<void> updateDisplayName(String name) async {
    if (_user == null) return;
    _user = _user!.copyWith(displayName: name);
    for (final list in _membersByFamily.values) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].userId == _user!.id) {
          list[i] = list[i].copyWith(displayName: name);
        }
      }
    }
    _emitAll();
  }

  // ---- families ----

  Stream<List<Family>> familiesStream(String userId) async* {
    List<Family> current() => _familyById.values
        .where((f) =>
            f.ownerId == userId ||
            (_membersByFamily[f.id]?.any((m) => m.userId == userId) ?? false))
        .toList();
    yield current();
    yield* _families.stream;
  }

  Stream<List<FamilyMember>> membersStream(String familyId) async* {
    yield _dedupe(_membersByFamily[familyId] ?? const []);
    yield* _members.stream.map(
      (m) => _dedupe(m[familyId] ?? const <FamilyMember>[]),
    );
  }

  /// One entry per user id, last write wins. Guards the UI against a family
  /// list that somehow accumulated the same member twice.
  List<FamilyMember> _dedupe(List<FamilyMember> members) {
    final byId = <String, FamilyMember>{};
    for (final m in members) {
      byId[m.userId] = m;
    }
    return byId.values.toList(growable: false);
  }

  Future<Family> createFamily(String name, AppUser owner) async {
    final family = Family(
      id: _uuid.v4(),
      name: name,
      ownerId: owner.id,
      inviteCode: _newInviteCode(),
      createdAt: DateTime.now(),
      memberCount: 1,
    );
    _familyById[family.id] = family;
    _inviteToFamily[family.inviteCode] = family.id;
    _membersByFamily[family.id] = [
      FamilyMember(
        userId: owner.id,
        displayName: owner.displayName,
        role: MemberRole.owner,
        joinedAt: DateTime.now(),
      ),
    ];
    _needsByFamily[family.id] = [];
    _emitAll();
    return family;
  }

  String _newInviteCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    final code = List.generate(6, (_) => alphabet[rnd.nextInt(alphabet.length)]).join();
    return 'LAZIM-$code';
  }

  Future<Family> joinFamily(String inviteCode, AppUser user) async {
    final id = _inviteToFamily[inviteCode.trim().toUpperCase()];
    final family = id == null ? null : _familyById[id];
    if (family == null) {
      throw LazimException('Invite code not found', code: 'invite/not-found');
    }
    final members = _membersByFamily[family.id]!;
    if (!members.any((m) => m.userId == user.id)) {
      members.add(FamilyMember(
        userId: user.id,
        displayName: user.displayName,
        role: MemberRole.member,
        joinedAt: DateTime.now(),
      ));
      _familyById[family.id] = family.copyWith(memberCount: members.length);
    }
    _emitAll();
    return _familyById[family.id]!;
  }

  Family? familyByCode(String code) {
    final id = _inviteToFamily[code.trim().toUpperCase()];
    return id == null ? null : _familyById[id];
  }

  Future<void> renameFamily(String familyId, String name) async {
    final f = _familyById[familyId];
    if (f == null) return;
    _familyById[familyId] = f.copyWith(name: name);
    _emitAll();
  }

  Future<void> removeMember(String familyId, String userId) async {
    _membersByFamily[familyId]?.removeWhere((m) => m.userId == userId);
    final f = _familyById[familyId];
    if (f != null) {
      _familyById[familyId] = f.copyWith(memberCount: _membersByFamily[familyId]?.length ?? 0);
    }
    _emitAll();
  }

  Future<void> registerToken(String familyId, String userId, String token) async {
    final list = _membersByFamily[familyId];
    if (list == null) return;
    final i = list.indexWhere((m) => m.userId == userId);
    if (i < 0) return;
    final tokens = {...list[i].fcmTokens, token}.toList();
    list[i] = list[i].copyWith(fcmTokens: tokens);
    _emitAll();
  }

  Future<void> unregisterToken(String familyId, String userId, String token) async {
    final list = _membersByFamily[familyId];
    if (list == null) return;
    final i = list.indexWhere((m) => m.userId == userId);
    if (i < 0) return;
    list[i] = list[i].copyWith(
      fcmTokens: list[i].fcmTokens.where((t) => t != token).toList(),
    );
    _emitAll();
  }

  // ---- needs ----

  Stream<List<NeedItem>> needsStream(String familyId) async* {
    List<NeedItem> sorted() {
      final list = List<NeedItem>.from(_needsByFamily[familyId] ?? const []);
      list.sort((a, b) {
        final p = b.priority.index.compareTo(a.priority.index);
        if (p != 0) return p;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    }

    yield sorted();
    yield* _needs.stream.map((m) {
      final list = List<NeedItem>.from(m[familyId] ?? const []);
      list.sort((a, b) {
        final p = b.priority.index.compareTo(a.priority.index);
        if (p != 0) return p;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  List<NeedItem> _list(String familyId) => _needsByFamily.putIfAbsent(familyId, () => []);

  void _replace(String familyId, NeedItem item) {
    final list = _list(familyId);
    final i = list.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      list[i] = item;
    } else {
      list.add(item);
    }
    _emitAll();
  }

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
    final now = DateTime.now();
    final item = NeedItem(
      id: _uuid.v4(),
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
    _replace(familyId, item);
    return item;
  }

  Future<void> updateNeed(NeedItem item, AppUser actor, Map<String, Object?> changes) async {
    var updated = item.copyWith(updatedAt: DateTime.now());
    final entry = ActivityEntry(
      id: _uuid.v4(),
      type: ActivityType.edited,
      actorId: actor.id,
      actorName: actor.displayName,
      at: DateTime.now(),
      note: changes.keys.join(', '),
    );
    updated = updated.copyWith(activity: [...item.activity, entry]);
    if (changes.containsKey('title')) {
      updated = updated.copyWith(title: changes['title'] as String?);
    }
    if (changes.containsKey('note')) {
      updated = updated.copyWith(note: changes['note'] as String?);
    }
    if (changes.containsKey('quantity')) {
      updated = updated.copyWith(quantity: (changes['quantity'] as num).toInt());
    }
    if (changes.containsKey('unit')) {
      updated = updated.copyWith(unit: changes['unit'] as String?);
    }
    if (changes.containsKey('priority')) {
      updated = updated.copyWith(priority: NeedPriority.fromCode(changes['priority'] as String?));
    }
    if (changes.containsKey('category')) {
      updated = updated.copyWith(category: NeedCategory.fromCode(changes['category'] as String?));
    }
    _replace(item.familyId, updated);
  }

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
    _replace(
      item.familyId,
      item.copyWith(
        status: status,
        updatedAt: now,
        purchasedAt: status == NeedStatus.purchased ? now : item.purchasedAt,
        activity: [...item.activity, entry],
      ),
    );
  }

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
    _replace(
      item.familyId,
      NeedItem(
        id: item.id,
        familyId: item.familyId,
        title: item.title,
        note: item.note,
        quantity: item.quantity,
        unit: item.unit,
        status: member != null && item.status == NeedStatus.open
            ? NeedStatus.claimed
            : item.status,
        priority: item.priority,
        category: item.category,
        createdBy: item.createdBy,
        createdByName: item.createdByName,
        assignedTo: member?.userId,
        assignedToName: member?.displayName,
        createdAt: item.createdAt,
        updatedAt: now,
        purchasedAt: item.purchasedAt,
        attachments: item.attachments,
        activity: [...item.activity, entry],
      ),
    );
  }

  Future<void> deleteNeed(NeedItem item, AppUser actor) async {
    _list(item.familyId).removeWhere((e) => e.id == item.id);
    _emitAll();
  }

  Future<Attachment> addAttachment(NeedItem item, AppUser actor, Attachment attachment) async {
    final updated = item.copyWith(
      attachments: [...item.attachments, attachment],
      updatedAt: DateTime.now(),
      activity: [
        ...item.activity,
        ActivityEntry(
          id: _uuid.v4(),
          type: ActivityType.attachmentAdded,
          actorId: actor.id,
          actorName: actor.displayName,
          at: DateTime.now(),
          toValue: attachment.name,
        ),
      ],
    );
    _replace(item.familyId, updated);
    return attachment;
  }

  Future<void> removeAttachment(NeedItem item, Attachment attachment) async {
    _replace(
      item.familyId,
      item.copyWith(
        attachments: item.attachments.where((a) => a.id != attachment.id).toList(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  void dispose() {
    _auth.close();
    _families.close();
    _members.close();
    _needs.close();
  }
}

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._store);
  final LocalStore _store;

  @override
  Stream<AppUser?> authStateChanges() => _store.authStream();

  @override
  AppUser? get currentUser => _store.user;

  @override
  Future<AppUser> signInWithGoogle() => _store.signIn('Saffron');

  @override
  Future<AppUser> signInWithEmail(String email, String password) =>
      _store.signIn(email.split('@').first, email: email);

  @override
  Future<AppUser> registerWithEmail(String email, String password, String displayName) =>
      _store.signIn(displayName, email: email);

  @override
  Future<void> signOut() => _store.signOut();

  @override
  Future<void> updateDisplayName(String displayName) => _store.updateDisplayName(displayName);
}

class LocalFamilyRepository implements FamilyRepository {
  LocalFamilyRepository(this._store);
  final LocalStore _store;

  @override
  Stream<List<Family>> watchFamilies(String userId) => _store.familiesStream(userId);

  @override
  Stream<List<FamilyMember>> watchMembers(String familyId) => _store.membersStream(familyId);

  @override
  Future<Family> createFamily({required String name, required AppUser owner}) =>
      _store.createFamily(name, owner);

  @override
  Future<Family> joinFamily({required String inviteCode, required AppUser user}) =>
      _store.joinFamily(inviteCode, user);

  @override
  Future<Family?> familyByInviteCode(String inviteCode) async => _store.familyByCode(inviteCode);

  @override
  Future<void> renameFamily(String familyId, String name) => _store.renameFamily(familyId, name);

  @override
  Future<void> removeMember(String familyId, String userId) =>
      _store.removeMember(familyId, userId);

  @override
  Future<void> leaveFamily(String familyId, String userId) =>
      _store.removeMember(familyId, userId);

  @override
  Future<void> registerPushToken({
    required String familyId,
    required String userId,
    required String token,
  }) =>
      _store.registerToken(familyId, userId, token);

  @override
  Future<void> unregisterPushToken({
    required String familyId,
    required String userId,
    required String token,
  }) =>
      _store.unregisterToken(familyId, userId, token);
}

class LocalNeedRepository implements NeedRepository {
  LocalNeedRepository(this._store);
  final LocalStore _store;

  @override
  Stream<List<NeedItem>> watchNeeds(String familyId) => _store.needsStream(familyId);

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
  }) =>
      _store.createNeed(
        familyId: familyId,
        actor: actor,
        title: title,
        note: note,
        quantity: quantity,
        unit: unit,
        priority: priority,
        category: category,
        assignedTo: assignedTo,
        assignedToName: assignedToName,
      );

  @override
  Future<void> updateNeed(NeedItem item, AppUser actor, {Map<String, Object?> changes = const {}}) =>
      _store.updateNeed(item, actor, changes);

  @override
  Future<void> changeStatus(NeedItem item, AppUser actor, NeedStatus status) =>
      _store.changeStatus(item, actor, status);

  @override
  Future<void> assign(NeedItem item, AppUser actor, FamilyMember? member) =>
      _store.assign(item, actor, member);

  @override
  Future<void> deleteNeed(NeedItem item, AppUser actor) => _store.deleteNeed(item, actor);

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
    return _store.addAttachment(item, actor, attachment);
  }

  @override
  Future<Attachment> uploadAttachment(NeedItem item, AppUser actor,
      {required File file, required String name}) async {
    // Local backend keeps a file:// reference so images still preview.
    final attachment = Attachment(
      id: _uuid.v4(),
      kind: AttachmentKind.fromMime(null, name),
      name: name,
      url: file.uri.toString(),
      sizeBytes: await file.length(),
      addedBy: actor.id,
      addedAt: DateTime.now(),
    );
    return _store.addAttachment(item, actor, attachment);
  }

  @override
  Future<void> removeAttachment(NeedItem item, AppUser actor, Attachment attachment) =>
      _store.removeAttachment(item, attachment);
}

class LocalPreferencesRepository implements PreferencesRepository {
  LocalPreferencesRepository(this._prefs);
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

/// No-op push service for the local backend.
class LocalPushService implements PushService {
  @override
  Future<void> initialise() async {}

  @override
  Future<String?> currentToken() async => null;

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage => const Stream.empty();

  @override
  Future<void> requestPermission() async {}
}
