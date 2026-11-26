import 'package:flutter/material.dart' show Color;

import 'enums.dart';

/// A person using Lazim. Keyed by the auth provider's user id.
class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    this.email,
    this.photoUrl,
    this.locale,
  });

  final String id;
  final String displayName;
  final String? email;
  final String? photoUrl;

  /// BCP-47 tag the user last chose, e.g. `ar` or `en`.
  final String? locale;

  AppUser copyWith({String? displayName, String? photoUrl, String? locale}) => AppUser(
        id: id,
        displayName: displayName ?? this.displayName,
        email: email,
        photoUrl: photoUrl ?? this.photoUrl,
        locale: locale ?? this.locale,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'locale': locale,
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as String,
        displayName: (m['displayName'] as String?)?.trim().isNotEmpty == true
            ? m['displayName'] as String
            : 'Member',
        email: m['email'] as String?,
        photoUrl: m['photoUrl'] as String?,
        locale: m['locale'] as String?,
      );
}

/// A family group. Every need item belongs to exactly one family.
class Family {
  const Family({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
    required this.createdAt,
    this.memberCount = 0,
  });

  final String id;
  final String name;
  final String ownerId;

  /// Short code embedded in invite links, e.g. `LAZIM-7K2Q`.
  final String inviteCode;
  final DateTime createdAt;
  final int memberCount;

  Family copyWith({String? name, int? memberCount}) => Family(
        id: id,
        name: name ?? this.name,
        ownerId: ownerId,
        inviteCode: inviteCode,
        createdAt: createdAt,
        memberCount: memberCount ?? this.memberCount,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'ownerId': ownerId,
        'inviteCode': inviteCode,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'memberCount': memberCount,
      };

  factory Family.fromMap(Map<String, dynamic> m) => Family(
        id: m['id'] as String,
        name: (m['name'] as String?) ?? 'Family',
        ownerId: (m['ownerId'] as String?) ?? '',
        inviteCode: (m['inviteCode'] as String?) ?? '',
        createdAt: DateTime.tryParse((m['createdAt'] as String?) ?? '')?.toLocal() ??
            DateTime.now(),
        memberCount: (m['memberCount'] as num?)?.toInt() ?? 0,
      );
}

/// Membership record linking a user to a family.
class FamilyMember {
  const FamilyMember({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    this.photoUrl,
    this.fcmTokens = const [],
  });

  final String userId;
  final String displayName;
  final MemberRole role;
  final DateTime joinedAt;
  final String? photoUrl;

  /// Device push tokens. Stored per member so Cloud Functions can notify
  /// everyone in the family except the actor.
  final List<String> fcmTokens;

  FamilyMember copyWith({String? displayName, MemberRole? role, List<String>? fcmTokens}) =>
      FamilyMember(
        userId: userId,
        displayName: displayName ?? this.displayName,
        role: role ?? this.role,
        joinedAt: joinedAt,
        photoUrl: photoUrl,
        fcmTokens: fcmTokens ?? this.fcmTokens,
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'role': role.code,
        'joinedAt': joinedAt.toUtc().toIso8601String(),
        'photoUrl': photoUrl,
        'fcmTokens': fcmTokens,
      };

  factory FamilyMember.fromMap(Map<String, dynamic> m) => FamilyMember(
        userId: m['userId'] as String,
        displayName: (m['displayName'] as String?) ?? 'Member',
        role: MemberRole.fromCode(m['role'] as String?),
        joinedAt: DateTime.tryParse((m['joinedAt'] as String?) ?? '')?.toLocal() ??
            DateTime.now(),
        photoUrl: m['photoUrl'] as String?,
        fcmTokens: (m['fcmTokens'] as List?)?.cast<String>() ?? const [],
      );
}

/// A file or link attached to a need item.
class Attachment {
  const Attachment({
    required this.id,
    required this.kind,
    required this.name,
    required this.addedBy,
    required this.addedAt,
    this.url,
    this.storagePath,
    this.sizeBytes,
    this.blobId,
    this.mimeType,
  });

  final String id;
  final AttachmentKind kind;
  final String name;

  /// Direct URL for links; download URL for legacy uploaded files.
  final String? url;

  /// Legacy Cloud Storage path, kept so old attachments can still be removed.
  final String? storagePath;
  final int? sizeBytes;

  /// ID of the Firestore blob document holding this file's base64 chunks.
  /// Present for files uploaded with the free Firestore-backed storage.
  final String? blobId;

  /// MIME type, needed when opening the file through the system viewer.
  final String? mimeType;
  final String addedBy;
  final DateTime addedAt;

  bool get isLink => kind == AttachmentKind.link;

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.code,
        'name': name,
        'url': url,
        'storagePath': storagePath,
        'sizeBytes': sizeBytes,
        'blobId': blobId,
        'mimeType': mimeType,
        'addedBy': addedBy,
        'addedAt': addedAt.toUtc().toIso8601String(),
      };

  factory Attachment.fromMap(Map<String, dynamic> m) => Attachment(
        id: m['id'] as String,
        kind: AttachmentKind.fromCode(m['kind'] as String?),
        name: (m['name'] as String?) ?? '',
        url: m['url'] as String?,
        storagePath: m['storagePath'] as String?,
        sizeBytes: (m['sizeBytes'] as num?)?.toInt(),
        blobId: m['blobId'] as String?,
        mimeType: m['mimeType'] as String?,
        addedBy: (m['addedBy'] as String?) ?? '',
        addedAt: DateTime.tryParse((m['addedAt'] as String?) ?? '')?.toLocal() ??
            DateTime.now(),
      );
}

/// One line in an item's history. Drives the activity timeline and the
/// "who changed what" trail.
class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorName,
    required this.at,
    this.fromValue,
    this.toValue,
    this.note,
  });

  final String id;
  final ActivityType type;
  final String actorId;
  final String actorName;
  final DateTime at;
  final String? fromValue;
  final String? toValue;
  final String? note;

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.code,
        'actorId': actorId,
        'actorName': actorName,
        'at': at.toUtc().toIso8601String(),
        'fromValue': fromValue,
        'toValue': toValue,
        'note': note,
      };

  factory ActivityEntry.fromMap(Map<String, dynamic> m) => ActivityEntry(
        id: m['id'] as String,
        type: ActivityType.fromCode(m['type'] as String?),
        actorId: (m['actorId'] as String?) ?? '',
        actorName: (m['actorName'] as String?) ?? '',
        at: DateTime.tryParse((m['at'] as String?) ?? '')?.toLocal() ?? DateTime.now(),
        fromValue: m['fromValue'] as String?,
        toValue: m['toValue'] as String?,
        note: m['note'] as String?,
      );
}

/// A category a family can file items under.
///
/// The eight built-in categories are synthesised in code and always available;
/// they are never stored, so a family that never customises anything still sees
/// the defaults and no migration is needed. Custom categories live in
/// `families/{familyId}/categories/{id}` and carry their own name and icon.
class NeedCategoryDef {
  const NeedCategoryDef({
    required this.id,
    this.name = '',
    this.builtIn,
    this.iconKey,
    this.colorValue,
    this.order = 0,
  });

  /// Stable identifier. For built-ins this is the [NeedCategory] code.
  final String id;

  /// Display name for custom categories. Empty for built-ins, which use the
  /// localised label so they translate with the app language.
  final String name;

  /// Set for the eight built-ins; null for custom categories.
  final NeedCategory? builtIn;

  /// Icon key for custom categories, resolved through [categoryIconFor].
  final String? iconKey;

  /// Optional ARGB colour for custom categories.
  final int? colorValue;

  final int order;

  bool get isBuiltIn => builtIn != null;

  Color? get color => colorValue == null ? null : Color(colorValue!);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'colorValue': colorValue,
        'order': order,
      };

  factory NeedCategoryDef.fromMap(Map<String, dynamic> m) => NeedCategoryDef(
        id: (m['id'] as String?) ?? '',
        name: (m['name'] as String?) ?? '',
        iconKey: m['iconKey'] as String?,
        colorValue: (m['colorValue'] as num?)?.toInt(),
        order: (m['order'] as num?)?.toInt() ?? 0,
      );

  /// The eight defaults, in display order.
  static List<NeedCategoryDef> get builtIns => [
        for (var i = 0; i < NeedCategory.values.length; i++)
          NeedCategoryDef(
            id: NeedCategory.values[i].code,
            builtIn: NeedCategory.values[i],
            order: i,
          ),
      ];
}

/// The core entity: one thing the home needs.
class NeedItem {
  const NeedItem({
    required this.id,
    required this.familyId,
    required this.title,
    required this.status,
    required this.priority,
    required this.category,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.categoryIds = const [],
    this.note,
    this.quantity = 1,
    this.unit,
    this.assignedTo,
    this.assignedToName,
    this.purchasedAt,
    this.attachments = const [],
    this.activity = const [],
  });

  final String id;
  final String familyId;
  final String title;
  final String? note;
  final int quantity;
  final String? unit;
  final NeedStatus status;
  final NeedPriority priority;

  /// Legacy single category, kept so documents written before multi-category
  /// support still read correctly. New writes set both this (to the first
  /// selected category) and [categoryIds].
  final NeedCategory category;

  /// Every category this item belongs to, by [NeedCategoryDef.id]. Empty on
  /// documents written before multi-category support, in which case
  /// [effectiveCategoryIds] falls back to [category].
  final List<String> categoryIds;

  /// Category ids to display and filter on, tolerating legacy documents.
  List<String> get effectiveCategoryIds =>
      categoryIds.isNotEmpty ? categoryIds : [category.code];

  bool hasCategory(String id) => effectiveCategoryIds.contains(id);
  final String createdBy;
  final String createdByName;
  final String? assignedTo;
  final String? assignedToName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? purchasedAt;
  final List<Attachment> attachments;
  final List<ActivityEntry> activity;

  bool get isDone => status.isDone;

  /// Days since the item was added, used for the "stale" nudge on the list.
  int get ageInDays => DateTime.now().difference(createdAt).inDays;

  NeedItem copyWith({
    String? title,
    String? note,
    int? quantity,
    String? unit,
    NeedStatus? status,
    NeedPriority? priority,
    NeedCategory? category,
    List<String>? categoryIds,
    String? assignedTo,
    String? assignedToName,
    DateTime? updatedAt,
    DateTime? purchasedAt,
    List<Attachment>? attachments,
    List<ActivityEntry>? activity,
  }) =>
      NeedItem(
        id: id,
        familyId: familyId,
        title: title ?? this.title,
        note: note ?? this.note,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        category: category ?? this.category,
        categoryIds: categoryIds ?? this.categoryIds,
        createdBy: createdBy,
        createdByName: createdByName,
        assignedTo: assignedTo ?? this.assignedTo,
        assignedToName: assignedToName ?? this.assignedToName,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        purchasedAt: purchasedAt ?? this.purchasedAt,
        attachments: attachments ?? this.attachments,
        activity: activity ?? this.activity,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'familyId': familyId,
        'title': title,
        'note': note,
        'quantity': quantity,
        'unit': unit,
        'status': status.code,
        'priority': priority.code,
        'category': category.code,
        'categoryIds': effectiveCategoryIds,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'assignedTo': assignedTo,
        'assignedToName': assignedToName,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'purchasedAt': purchasedAt?.toUtc().toIso8601String(),
        'attachments': attachments.map((a) => a.toMap()).toList(),
        'activity': activity.map((a) => a.toMap()).toList(),
      };

  factory NeedItem.fromMap(Map<String, dynamic> m) => NeedItem(
        id: m['id'] as String,
        familyId: (m['familyId'] as String?) ?? '',
        title: (m['title'] as String?) ?? '',
        note: m['note'] as String?,
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        unit: m['unit'] as String?,
        status: NeedStatus.fromCode(m['status'] as String?),
        priority: NeedPriority.fromCode(m['priority'] as String?),
        category: NeedCategory.fromCode(m['category'] as String?),
        categoryIds: ((m['categoryIds'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        createdBy: (m['createdBy'] as String?) ?? '',
        createdByName: (m['createdByName'] as String?) ?? '',
        assignedTo: m['assignedTo'] as String?,
        assignedToName: m['assignedToName'] as String?,
        createdAt: DateTime.tryParse((m['createdAt'] as String?) ?? '')?.toLocal() ??
            DateTime.now(),
        updatedAt: DateTime.tryParse((m['updatedAt'] as String?) ?? '')?.toLocal() ??
            DateTime.now(),
        purchasedAt: DateTime.tryParse((m['purchasedAt'] as String?) ?? '')?.toLocal(),
        attachments: ((m['attachments'] as List?) ?? const [])
            .map((e) => Attachment.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        activity: ((m['activity'] as List?) ?? const [])
            .map((e) => ActivityEntry.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// Filter state for the history screen. Kept as a value object so it can be
/// serialised, compared and tested independently of the UI.
class NeedFilter {
  const NeedFilter({
    this.statuses = const {},
    this.categories = const {},
    this.priorities = const {},
    this.assigneeId,
    this.from,
    this.to,
    this.query = '',
  });

  final Set<NeedStatus> statuses;
  final Set<String> categories;
  final Set<NeedPriority> priorities;
  final String? assigneeId;
  final DateTime? from;
  final DateTime? to;
  final String query;

  bool get isEmpty =>
      statuses.isEmpty &&
      categories.isEmpty &&
      priorities.isEmpty &&
      assigneeId == null &&
      from == null &&
      to == null &&
      query.trim().isEmpty;

  int get activeCount =>
      (statuses.isEmpty ? 0 : 1) +
      (categories.isEmpty ? 0 : 1) +
      (priorities.isEmpty ? 0 : 1) +
      (assigneeId == null ? 0 : 1) +
      (from == null && to == null ? 0 : 1) +
      (query.trim().isEmpty ? 0 : 1);

  NeedFilter copyWith({
    Set<NeedStatus>? statuses,
    Set<String>? categories,
    Set<NeedPriority>? priorities,
    String? assigneeId,
    bool clearAssignee = false,
    DateTime? from,
    DateTime? to,
    bool clearDates = false,
    String? query,
  }) =>
      NeedFilter(
        statuses: statuses ?? this.statuses,
        categories: categories ?? this.categories,
        priorities: priorities ?? this.priorities,
        assigneeId: clearAssignee ? null : (assigneeId ?? this.assigneeId),
        from: clearDates ? null : (from ?? this.from),
        to: clearDates ? null : (to ?? this.to),
        query: query ?? this.query,
      );

  /// Applies the filter to a list. Used by the local backend and as a fallback
  /// on the Firebase backend where composite indexes may not exist yet.
  List<NeedItem> apply(Iterable<NeedItem> items) {
    final q = query.trim().toLowerCase();
    return items.where((item) {
      if (statuses.isNotEmpty && !statuses.contains(item.status)) return false;
      if (categories.isNotEmpty &&
          !item.effectiveCategoryIds.any(categories.contains)) {
        return false;
      }
      if (priorities.isNotEmpty && !priorities.contains(item.priority)) return false;
      if (assigneeId != null && item.assignedTo != assigneeId) return false;
      if (from != null && item.createdAt.isBefore(from!)) return false;
      if (to != null && item.createdAt.isAfter(to!.add(const Duration(days: 1)))) {
        return false;
      }
      if (q.isNotEmpty) {
        final hay = '${item.title} ${item.note ?? ''}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }
}
