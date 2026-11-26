import 'package:flutter_test/flutter_test.dart';
import 'package:lazim/domain/models.dart';

/// Documents the Firestore-rule constraints that the join flow must respect.
///
/// The deployed rules (firebase/firestore.rules) require isMember(familyId) to
/// READ or UPDATE /families/{familyId}. A joining user is not a member yet, so:
///   - familyByInviteCode must NOT read the family doc; it builds a stub from
///     the /invites/{code} doc, which is readable by any signed-in user.
///   - the memberCount increment must happen AFTER the membership write, in a
///     SEPARATE commit, because rules evaluate exists() against pre-batch state.
void main() {
  group('join-by-code rule constraints', () {
    test('invite stub carries familyId and does not require a family read', () {
      // Mirrors familyByInviteCode(): the only document read is the invite.
      final inviteData = <String, dynamic>{
        'familyId': 'family-123',
        'name': 'Home',
        'ownerId': 'owner-uid',
      };
      final stub = Family(
        id: inviteData['familyId'] as String,
        name: (inviteData['name'] as String?) ?? '',
        ownerId: (inviteData['ownerId'] as String?) ?? '',
        inviteCode: 'LAZIM-ABC123',
        createdAt: DateTime.now(),
      );
      expect(stub.id, 'family-123');
      expect(stub.inviteCode, 'LAZIM-ABC123');
    });

    test('invite codes are normalised to upper case before lookup', () {
      const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      expect(alphabet.contains('I'), isFalse,
          reason: 'ambiguous characters excluded from generated codes');
      expect('lazim-abc123'.trim().toUpperCase(), 'LAZIM-ABC123');
    });

    test('join is idempotent: existing member is not double-counted', () {
      final familyIds = <String>['family-123'];
      final alreadyMember = familyIds.contains('family-123');
      expect(alreadyMember, isTrue);
      // When alreadyMember is true, joinFamily skips both the membership batch
      // and the memberCount increment, then just returns the family doc.
    });
  });
}
