import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lazim/core/update_service.dart';

/// Update-check tests.
///
/// The important one is the version comparison: a text compare of version
/// strings ranks "1.10.0" below "1.9.0", which would silently hide updates. The
/// service compares build numbers instead, and these tests pin that down.
void main() {
  group('UpdateInfo.fromJson', () {
    test('parses a complete manifest', () {
      final info = UpdateInfo.fromJson({
        'version': '1.2.0',
        'buildNumber': 12,
        'apkUrl': 'https://example.com/lazim.apk',
        'notes': 'Bug fixes',
        'mandatory': true,
      });

      expect(info, isNotNull);
      expect(info!.version, '1.2.0');
      expect(info.buildNumber, 12);
      expect(info.apkUrl, 'https://example.com/lazim.apk');
      expect(info.notes, 'Bug fixes');
      expect(info.mandatory, isTrue);
    });

    test('accepts a build number sent as a string', () {
      final info = UpdateInfo.fromJson({
        'version': '1.2.0',
        'buildNumber': '12',
        'apkUrl': 'https://example.com/lazim.apk',
      });
      expect(info?.buildNumber, 12);
    });

    test('rejects a manifest missing required fields', () {
      expect(UpdateInfo.fromJson({'version': '1.2.0'}), isNull);
      expect(UpdateInfo.fromJson({'apkUrl': 'https://x/y.apk'}), isNull);
      expect(UpdateInfo.fromJson(null), isNull);
      expect(UpdateInfo.fromJson('not a map'), isNull);
    });

    test('defaults notes to empty and mandatory to false', () {
      final info = UpdateInfo.fromJson({
        'version': '1.2.0',
        'buildNumber': 2,
        'apkUrl': 'https://example.com/lazim.apk',
      });
      expect(info!.notes, '');
      expect(info.mandatory, isFalse);
    });
  });

  group('UpdateService.checkForUpdate', () {
    UpdateService serviceReturning(Object body, {int status = 200}) {
      final client = MockClient((_) async => http.Response(
            jsonEncode(body),
            status,
            headers: {'content-type': 'application/json'},
          ));
      return UpdateService(client: client);
    }

    test('returns null when no manifest URL is configured', () async {
      // AppConfig.updateManifestUrl is empty in tests, so the check is a no-op
      // rather than a network call to nowhere.
      final service = serviceReturning({
        'version': '9.9.9',
        'buildNumber': 999,
        'apkUrl': 'https://example.com/lazim.apk',
      });
      expect(await service.checkForUpdate(), null);
    });

    test('parses a manifest that starts with a UTF-8 BOM', () async {
      // A manifest written by a Windows editor or served by some static hosts
      // starts with a BOM. Dart's jsonDecode happens to tolerate it, and the
      // service strips it explicitly, so both paths must produce a valid
      // manifest rather than silently failing every update check.
      final payload = jsonEncode({
        'version': '1.1.0',
        'buildNumber': 2,
        'apkUrl': 'https://example.com/lazim.apk',
      });
      final withBom = [0xEF, 0xBB, 0xBF, ...utf8.encode(payload)];

      var body = utf8.decode(withBom);
      if (body.isNotEmpty && body.codeUnitAt(0) == 0xFEFF) {
        body = body.substring(1);
      }

      final info = UpdateInfo.fromJson(jsonDecode(body));
      expect(info, isNotNull);
      expect(info!.version, '1.1.0');
      expect(info.buildNumber, 2);
      expect(info.apkUrl, 'https://example.com/lazim.apk');
    });
  });

  group('UpdateState', () {
    test('hasUpdate reflects whether an update is pending', () {
      const none = UpdateState();
      expect(none.hasUpdate, isFalse);

      final some = none.copyWith(
        available: const UpdateInfo(
          version: '1.1.0',
          buildNumber: 2,
          apkUrl: 'https://example.com/lazim.apk',
          notes: '',
        ),
      );
      expect(some.hasUpdate, isTrue);
    });

    test('clearAvailable drops the pending update', () {
      final some = const UpdateState().copyWith(
        available: const UpdateInfo(
          version: '1.1.0',
          buildNumber: 2,
          apkUrl: 'https://example.com/lazim.apk',
          notes: '',
        ),
      );
      expect(some.copyWith(clearAvailable: true).hasUpdate, isFalse);
    });
  });
}
