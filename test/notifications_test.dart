import 'package:flutter_test/flutter_test.dart';
import 'package:lazim/core/local_notifier.dart';
import 'package:lazim/domain/enums.dart';
import 'package:lazim/domain/models.dart';

NeedItem needWith(String activityId, String actorId,
        {ActivityType type = ActivityType.created, String title = 'Milk'}) =>
    NeedItem(
      id: 'need-$activityId',
      familyId: 'family-1',
      title: title,
      status: NeedStatus.open,
      priority: NeedPriority.normal,
      category: NeedCategory.groceries,
      createdBy: actorId,
      createdByName: actorId,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      activity: [
        ActivityEntry(
          id: activityId,
          type: type,
          actorId: actorId,
          actorName: actorId,
          at: DateTime(2026),
        ),
      ],
    );

void main() {
  group('selectNotifications', () {
    test('first snapshot only seeds seen, shows nothing', () {
      final seen = <String>{};
      final messages = selectNotifications(
        [needWith('a1', 'wife')],
        currentUserId: 'me',
        localeCode: 'en',
        seen: seen,
        primed: false,
      );
      expect(messages, isEmpty);
      expect(seen, contains('a1'));
    });

    test('new activity by another person produces a message', () {
      final seen = <String>{'a1'};
      final messages = selectNotifications(
        [needWith('a2', 'wife', title: 'Bread')],
        currentUserId: 'me',
        localeCode: 'en',
        seen: seen,
        primed: true,
      );
      expect(messages.length, 1);
      expect(messages.first.body, contains('Bread'));
      expect(messages.first.body, contains('wife'));
      expect(seen, contains('a2'));
    });

    test('own activity never produces a message', () {
      final messages = selectNotifications(
        [needWith('a3', 'me')],
        currentUserId: 'me',
        localeCode: 'en',
        seen: <String>{},
        primed: true,
      );
      expect(messages, isEmpty);
    });

    test('already-seen activity is not announced twice', () {
      final messages = selectNotifications(
        [needWith('a4', 'wife')],
        currentUserId: 'me',
        localeCode: 'en',
        seen: <String>{'a4'},
        primed: true,
      );
      expect(messages, isEmpty);
    });

    test('Arabic locale produces Arabic notification text', () {
      final messages = selectNotifications(
        [needWith('a5', 'زوجتي', title: 'حليب')],
        currentUserId: 'me',
        localeCode: 'ar',
        seen: <String>{},
        primed: true,
      );
      expect(messages.length, 1);
      expect(messages.first.title, contains('صنف'));
      expect(messages.first.body, contains('حليب'));
    });
  });

  group('live name resolution', () {
    test('uses the resolved name instead of the stored snapshot', () {
      final messages = selectNotifications(
        [needWith('a6', 'uid-wife')],
        currentUserId: 'me',
        localeCode: 'en',
        seen: <String>{},
        primed: true,
        resolveName: (userId, fallback) =>
            userId == 'uid-wife' ? 'Renamed Person' : fallback,
      );
      expect(messages.length, 1);
      expect(messages.first.body, contains('Renamed Person'));
      expect(messages.first.body, isNot(contains('uid-wife')));
    });

    test('falls back to the stored name for a departed member', () {
      final messages = selectNotifications(
        [needWith('a7', 'uid-gone')],
        currentUserId: 'me',
        localeCode: 'en',
        seen: <String>{},
        primed: true,
        resolveName: (userId, fallback) => fallback,
      );
      expect(messages.single.body, contains('uid-gone'));
    });
  });
}
