import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:org_family/data/repositories/cloud_membership_repository.dart';

FirebaseException _denied() =>
    FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');

/// Server answers are simulated — the rules producing them are exercised
/// against the emulator by firestore_rules_test/.
void main() {
  late FakeFirebaseFirestore firestore;
  late CloudMembershipRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = CloudMembershipRepository(firestore);
  });

  group('findFamily (new-device restore)', () {
    test('no record: no family', () async {
      expect(await repo.findFamily('fresh'), isNull);
    });

    test('a member finds their family and its owner', () async {
      await firestore.doc('users/reem').set({'familyId': 'fam-1'});
      await firestore.doc('families/fam-1').set({'ownerUid': 'kareem'});
      final found = await repo.findFamily('reem');
      expect(found?.familyId, 'fam-1');
      expect(found?.ownerUid, 'kareem');
    });

    test("a revoked member's stale record means no family, and is cleared", () async {
      await firestore.doc('users/reem').set({'familyId': 'fam-1'});
      await firestore.doc('families/fam-1').set({'ownerUid': 'kareem'});
      whenCalling(Invocation.method(#get, null))
          .on(firestore.doc('families/fam-1'))
          .thenThrow(_denied());

      expect(await repo.findFamily('reem'), isNull);
      expect((await firestore.doc('users/reem').get()).exists, isFalse);
    });

    test('any other failure is reported, never mistaken for "no family"', () async {
      await firestore.doc('users/reem').set({'familyId': 'fam-1'});
      whenCalling(Invocation.method(#get, null))
          .on(firestore.doc('families/fam-1'))
          .thenThrow(FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'));

      expect(() => repo.findFamily('reem'), throwsA(isA<FirebaseException>()));
    });
  });

  group('verify', () {
    test('readable family: member', () async {
      await firestore.doc('families/fam-1').set({'ownerUid': 'kareem'});
      expect(await repo.verify('fam-1'), MembershipStatus.member);
    });

    test('denied: not a member', () async {
      whenCalling(Invocation.method(#get, null))
          .on(firestore.doc('families/fam-1'))
          .thenThrow(_denied());
      expect(await repo.verify('fam-1'), MembershipStatus.notMember);
    });

    test('offline: unknown', () async {
      whenCalling(Invocation.method(#get, null))
          .on(firestore.doc('families/fam-1'))
          .thenThrow(FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'));
      expect(await repo.verify('fam-1'), MembershipStatus.unknown);
    });
  });
}
