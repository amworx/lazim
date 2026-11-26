import 'package:flutter_test/flutter_test.dart';
import 'package:lazim/domain/enums.dart';
import 'package:lazim/domain/models.dart';

void main() {
  group('NeedFilter', () {
    NeedItem item({
      required String id,
      NeedStatus status = NeedStatus.open,
      NeedCategory category = NeedCategory.groceries,
      NeedPriority priority = NeedPriority.normal,
      String? assignedTo,
      String title = 'Milk',
      String? note,
      DateTime? createdAt,
    }) {
      final at = createdAt ?? DateTime(2026, 11, 1);
      return NeedItem(
        id: id,
        familyId: 'f1',
        title: title,
        note: note,
        status: status,
        priority: priority,
        category: category,
        createdBy: 'u1',
        createdByName: 'Saffron',
        assignedTo: assignedTo,
        createdAt: at,
        updatedAt: at,
      );
    }

    final items = [
      item(id: '1', title: 'Milk', category: NeedCategory.groceries),
      item(
        id: '2',
        title: 'Dish soap',
        category: NeedCategory.household,
        status: NeedStatus.purchased,
        priority: NeedPriority.urgent,
      ),
      item(
        id: '3',
        title: 'Paracetamol',
        category: NeedCategory.pharmacy,
        assignedTo: 'u2',
        createdAt: DateTime(2026, 11, 10),
      ),
    ];

    test('empty filter returns everything', () {
      expect(const NeedFilter().apply(items).length, 3);
      expect(const NeedFilter().isEmpty, isTrue);
    });

    test('filters by status', () {
      final result = const NeedFilter(statuses: {NeedStatus.purchased}).apply(items);
      expect(result.map((e) => e.id), ['2']);
    });

    test('filters by category', () {
      final result = const NeedFilter(categories: {NeedCategory.pharmacy}).apply(items);
      expect(result.map((e) => e.id), ['3']);
    });

    test('filters by priority', () {
      final result = const NeedFilter(priorities: {NeedPriority.urgent}).apply(items);
      expect(result.map((e) => e.id), ['2']);
    });

    test('filters by assignee', () {
      final result = const NeedFilter(assigneeId: 'u2').apply(items);
      expect(result.map((e) => e.id), ['3']);
    });

    test('filters by date range inclusively', () {
      final result = const NeedFilter(
        from: null,
        to: null,
      ).copyWith(from: DateTime(2026, 11, 5), to: DateTime(2026, 11, 10)).apply(items);
      expect(result.map((e) => e.id), ['3']);
    });

    test('search matches title and note, case-insensitively', () {
      final withNote = [
        ...items,
        item(id: '4', title: 'Batteries', note: 'AA size for the remote'),
      ];
      expect(const NeedFilter(query: 'milk').apply(withNote).map((e) => e.id), ['1']);
      expect(const NeedFilter(query: 'REMOTE').apply(withNote).map((e) => e.id), ['4']);
    });

    test('combines filters', () {
      final result = const NeedFilter(
        statuses: {NeedStatus.open},
        categories: {NeedCategory.pharmacy},
      ).apply(items);
      expect(result.map((e) => e.id), ['3']);
    });

    test('activeCount reflects distinct filter groups', () {
      const f = NeedFilter(
        statuses: {NeedStatus.open},
        categories: {NeedCategory.groceries},
        query: 'milk',
      );
      expect(f.activeCount, 3);
      expect(f.isEmpty, isFalse);
    });
  });

  group('enum serialisation', () {
    test('unknown codes fall back safely', () {
      expect(NeedStatus.fromCode('nonsense'), NeedStatus.open);
      expect(NeedStatus.fromCode(null), NeedStatus.open);
      expect(NeedPriority.fromCode('nonsense'), NeedPriority.normal);
      expect(NeedCategory.fromCode('nonsense'), NeedCategory.other);
      expect(MemberRole.fromCode('nonsense'), MemberRole.member);
    });

    test('round-trips through code', () {
      for (final s in NeedStatus.values) {
        expect(NeedStatus.fromCode(s.code), s);
      }
      for (final c in NeedCategory.values) {
        expect(NeedCategory.fromCode(c.code), c);
      }
    });
  });

  group('NeedItem serialisation', () {
    test('survives a map round-trip', () {
      final original = NeedItem(
        id: 'n1',
        familyId: 'f1',
        title: 'Milk',
        note: 'Full fat',
        quantity: 2,
        unit: 'L',
        status: NeedStatus.claimed,
        priority: NeedPriority.urgent,
        category: NeedCategory.groceries,
        createdBy: 'u1',
        createdByName: 'Saffron',
        assignedTo: 'u2',
        assignedToName: 'Noor',
        createdAt: DateTime(2026, 11, 1, 10, 30),
        updatedAt: DateTime(2026, 11, 2, 11, 0),
        attachments: [
          Attachment(
            id: 'a1',
            kind: AttachmentKind.link,
            name: 'Product page',
            url: 'https://example.com/milk',
            addedBy: 'u1',
            addedAt: DateTime(2026, 11, 1),
          ),
        ],
        activity: [
          ActivityEntry(
            id: 'e1',
            type: ActivityType.created,
            actorId: 'u1',
            actorName: 'Saffron',
            at: DateTime(2026, 11, 1),
          ),
        ],
      );

      final restored = NeedItem.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.note, original.note);
      expect(restored.quantity, 2);
      expect(restored.unit, 'L');
      expect(restored.status, NeedStatus.claimed);
      expect(restored.priority, NeedPriority.urgent);
      expect(restored.category, NeedCategory.groceries);
      expect(restored.assignedToName, 'Noor');
      expect(restored.attachments.single.url, 'https://example.com/milk');
      expect(restored.activity.single.type, ActivityType.created);
      expect(restored.createdAt.toUtc(), original.createdAt.toUtc());
    });
  });

  group('AttachmentKind', () {
    test('detects kind from mime and extension', () {
      expect(AttachmentKind.fromMime('image/png', 'a.png'), AttachmentKind.image);
      expect(AttachmentKind.fromMime(null, 'scan.PDF'), AttachmentKind.pdf);
      expect(AttachmentKind.fromMime(null, 'list.docx'), AttachmentKind.document);
      expect(
        AttachmentKind.fromMime(
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'x'),
        AttachmentKind.document,
      );
      expect(AttachmentKind.fromMime(null, 'archive.zip'), AttachmentKind.other);
    });
  });

  group('status semantics', () {
    test('done states are terminal, active states are not', () {
      expect(NeedStatus.purchased.isDone, isTrue);
      expect(NeedStatus.archived.isDone, isTrue);
      expect(NeedStatus.open.isActive, isTrue);
      expect(NeedStatus.claimed.isActive, isTrue);
      expect(NeedStatus.open.isDone, isFalse);
    });
  });
}
