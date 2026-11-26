import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/enums.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';

class NotificationMessage {
  const NotificationMessage({required this.title, required this.body});
  final String title;
  final String body;
}

/// Pure selection logic behind [LocalNotifier.observe].
///
/// Returns the messages that should be shown for activity by other people that
/// was not already in [seen], and records every activity ID observed into
/// [seen]. When [primed] is false it only seeds [seen] from the snapshot and
/// returns nothing, so opening the app never replays old history as a burst.
List<NotificationMessage> selectNotifications(
  List<NeedItem> needs, {
  required String currentUserId,
  required String localeCode,
  required Set<String> seen,
  required bool primed,
  String Function(String userId, String fallback)? resolveName,
}) {
  if (!primed) {
    for (final need in needs) {
      for (final entry in need.activity) {
        seen.add(entry.id);
      }
    }
    return const <NotificationMessage>[];
  }

  final l = lookupAppL10n(Locale(localeCode));
  final messages = <NotificationMessage>[];
  for (final need in needs) {
    for (final entry in need.activity) {
      if (!seen.add(entry.id)) continue;
      // Never notify about your own actions, including pending local writes.
      if (entry.actorId.isEmpty || entry.actorId == currentUserId) continue;

      // Prefer the live display name so a rename does not leave old snapshots
      // showing in notifications.
      final actorName =
          resolveName?.call(entry.actorId, entry.actorName) ?? entry.actorName;

      final title = switch (entry.type) {
        ActivityType.created => l.notifNewItemTitle,
        ActivityType.statusChanged => l.notifStatusTitle,
        _ => l.notifStatusTitle,
      };
      final body = switch (entry.type) {
        ActivityType.created =>
          l.notifNewItemBody(actorName, need.title),
        ActivityType.statusChanged => l.notifStatusBody(
            actorName,
            need.title,
            _statusLabel(l, NeedStatus.fromCode(entry.toValue)),
          ),
        _ => l.notifStatusBody(
            actorName, need.title, l.notifStatusTitle),
      };
      messages.add(NotificationMessage(title: title, body: body));
    }
  }
  return messages;
}

String _statusLabel(AppL10n l, NeedStatus status) => switch (status) {
      NeedStatus.open => l.statusOpen,
      NeedStatus.claimed => l.statusClaimed,
      NeedStatus.purchased => l.statusPurchased,
      NeedStatus.archived => l.statusArchived,
    };

/// Free, zero-backend notifications for family activity.
///
/// Firebase Cloud Messaging delivery is free, but the "send on Firestore write"
/// trigger (Cloud Functions) requires a Blaze billing account. This service
/// avoids that entirely: the app already listens to the needs collection live,
/// so we show a LOCAL notification when that listener sees a new activity entry
/// written by somebody else.
///
/// Tradeoff, stated plainly: this fires while the app process is alive. It is
/// not a true push to a force-killed app. For a family needs list that is the
/// normal case, and it costs nothing and needs no account beyond the Firebase
/// project already in place.
class LocalNotifier {
  LocalNotifier({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  /// Activity entry IDs already announced. Seeded from the first snapshot so
  /// opening the app never replays old history as a burst of notifications.
  final Set<String> _seen = <String>{};
  bool _primed = false;

  /// True while the app is in the foreground. Activity is then visible on the
  /// screen the user is already looking at, so posting a system notification
  /// would only leave a tray entry they have to dismiss by hand.
  bool _foreground = true;

  /// Called by the app lifecycle observer. Coming back to the foreground also
  /// clears whatever was left in the tray, so the user never has to swipe them
  /// away manually after seeing the change in the app.
  Future<void> setForeground(bool foreground) async {
    _foreground = foreground;
    if (foreground) await clearAll();
  }

  /// Dismisses every notification this app posted.
  Future<void> clearAll() async {
    try {
      await initialise();
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Lazim notification clear skipped: $e');
    }
  }

  /// Reset when the active family changes, so a different family's history does
  /// not get compared against the previous family's seen set.
  void reset() {
    _seen.clear();
    _primed = false;
  }

  Future<void> initialise() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(android: android),
        onDidReceiveNotificationResponse: (response) {
          // Tapping the notification opens the app; the launcher intent already
          // routes to the needs list, so there is no extra payload to handle.
          debugPrint('Lazim notification tapped: ${response.payload}');
        },
      );

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            'lazim_activity',
            'Family activity',
            description: 'New items and status changes from your family',
            importance: Importance.high,
          ),
        );
      }
      _ready = true;
    } catch (e) {
      // No plugin implementation in widget tests, or the device denied the
      // permission. Notifications are best-effort; never break the app.
      debugPrint('Lazim notification init skipped: $e');
    }
  }

  /// Inspect a fresh needs snapshot and show notifications for new activity
  /// entries authored by someone other than [currentUserId].
  Future<void> observe(
    List<NeedItem> needs, {
    required String currentUserId,
    required String localeCode,
    String Function(String userId, String fallback)? resolveName,
  }) async {
    final messages = selectNotifications(
      needs,
      currentUserId: currentUserId,
      localeCode: localeCode,
      seen: _seen,
      primed: _primed,
      resolveName: resolveName,
    );
    if (!_primed) {
      _primed = true;
      return;
    }
    // While the app is on screen the change is already visible in the list, so
    // posting a notification would just add a tray entry to dismiss later.
    if (_foreground) return;
    for (final message in messages) {
      await _show(message.title, message.body);
    }
  }

  Future<void> _show(String title, String body) async {
    try {
      await initialise();
      await _plugin.show(
        id: DateTime.now().microsecondsSinceEpoch % 0x7fffffff,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'lazim_activity',
            'Family activity',
            channelDescription: 'New items and status changes from your family',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      // Notifications are best-effort: never break the list because a device
      // denied the permission or the plugin could not show the notification.
      debugPrint('Lazim local notification skipped: $e');
    }
  }
}
