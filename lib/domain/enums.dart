/// Enumerations shared across the domain layer.
///
/// Every enum serialises to a stable [code] string so stored documents survive
/// renames and reordering. Never persist `index` or `name`.
library;

enum NeedStatus {
  open('open'),
  claimed('claimed'),
  purchased('purchased'),
  archived('archived');

  const NeedStatus(this.code);
  final String code;

  static NeedStatus fromCode(String? code) => NeedStatus.values.firstWhere(
        (s) => s.code == code,
        orElse: () => NeedStatus.open,
      );

  bool get isDone => this == NeedStatus.purchased || this == NeedStatus.archived;
  bool get isActive => !isDone;
}

enum NeedPriority {
  low('low'),
  normal('normal'),
  urgent('urgent');

  const NeedPriority(this.code);
  final String code;

  static NeedPriority fromCode(String? code) => NeedPriority.values.firstWhere(
        (p) => p.code == code,
        orElse: () => NeedPriority.normal,
      );
}

enum NeedCategory {
  groceries('groceries'),
  household('household'),
  pharmacy('pharmacy'),
  personal('personal'),
  kids('kids'),
  kitchen('kitchen'),
  electronics('electronics'),
  other('other');

  const NeedCategory(this.code);
  final String code;

  static NeedCategory fromCode(String? code) => NeedCategory.values.firstWhere(
        (c) => c.code == code,
        orElse: () => NeedCategory.other,
      );
}

enum MemberRole {
  owner('owner'),
  member('member');

  const MemberRole(this.code);
  final String code;

  static MemberRole fromCode(String? code) => MemberRole.values.firstWhere(
        (r) => r.code == code,
        orElse: () => MemberRole.member,
      );

  bool get canManageFamily => this == MemberRole.owner;
}

enum AttachmentKind {
  link('link'),
  image('image'),
  pdf('pdf'),
  document('document'),
  other('other');

  const AttachmentKind(this.code);
  final String code;

  static AttachmentKind fromCode(String? code) => AttachmentKind.values.firstWhere(
        (k) => k.code == code,
        orElse: () => AttachmentKind.other,
      );

  static AttachmentKind fromMime(String? mime, String fileName) {
    final m = (mime ?? '').toLowerCase();
    final ext = fileName.toLowerCase().split('.').last;
    if (m.startsWith('image/') || ['png', 'jpg', 'jpeg', 'webp', 'gif', 'heic'].contains(ext)) {
      return AttachmentKind.image;
    }
    if (m == 'application/pdf' || ext == 'pdf') return AttachmentKind.pdf;
    if (m.contains('word') || m.contains('officedocument') || ['doc', 'docx', 'rtf', 'odt'].contains(ext)) {
      return AttachmentKind.document;
    }
    return AttachmentKind.other;
  }
}

enum ActivityType {
  created('created'),
  statusChanged('status_changed'),
  edited('edited'),
  assigned('assigned'),
  attachmentAdded('attachment_added'),
  commented('commented'),
  deleted('deleted');

  const ActivityType(this.code);
  final String code;

  static ActivityType fromCode(String? code) => ActivityType.values.firstWhere(
        (t) => t.code == code,
        orElse: () => ActivityType.edited,
      );
}
