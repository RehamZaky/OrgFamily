import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/data/repositories/family_invite_repository.dart';

// Rules enforcement (who may create/claim/list) is covered against the real
// emulator in firestore_rules_test/ — these only cover the repository's own
// client-side logic, which fake_cloud_firestore (no rules) is enough for.
void main() {
  late FakeFirebaseFirestore firestore;
  late FamilyInviteRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FamilyInviteRepository(firestore);
  });

  group('code formatting', () {
    test(
      'normalizeCode strips case, the display dash, spaces and punctuation',
      () {
        expect(FamilyInviteRepository.normalizeCode(' 7k9x-qprt '), '7K9XQPRT');
        expect(FamilyInviteRepository.normalizeCode('7K9X QPRT.'), '7K9XQPRT');
        expect(FamilyInviteRepository.normalizeCode('a/b'), 'AB');
      },
    );

    test('normalizeCode picks the code out of a whole pasted share message', () {
      expect(
        FamilyInviteRepository.normalizeCode(
          'Join our family on OrgFamily! Open the app, choose to join an existing '
          'family, and enter this code: 7K9X-QPRT',
        ),
        '7K9XQPRT',
      );
      expect(
        FamilyInviteRepository.normalizeCode(
          'انضم إلى عائلتنا، أدخل هذا الرمز: 7K9X-QPRT',
        ),
        '7K9XQPRT',
      );
    });

    test(
      'formatCode splits an 8-character code in half and leaves anything else alone',
      () {
        expect(FamilyInviteRepository.formatCode('7K9XQPRT'), '7K9X-QPRT');
        expect(FamilyInviteRepository.formatCode('SHORT'), 'SHORT');
      },
    );

    test('a formatted code round-trips through normalizeCode', () {
      const code = 'ABCD2345';
      expect(
        FamilyInviteRepository.normalizeCode(
          FamilyInviteRepository.formatCode(code),
        ),
        code,
      );
    });
  });

  group('createInvite', () {
    test('writes a 7-day invite and returns what it wrote', () async {
      final before = DateTime.now();
      final invite = await repo.createInvite(
        familyId: 'fam-1',
        creatorUid: 'owner-uid',
        inviterName: '  Reem  ',
      );

      expect(invite.code, hasLength(8));
      expect(invite.inviterName, 'Reem');
      expect(invite.daysLeft, 7);
      expect(
        invite.expiresAt.difference(before).inMinutes,
        within(distance: 1, from: const Duration(days: 7).inMinutes),
      );

      final data = (await firestore.doc('invites/${invite.code}').get())
          .data()!;
      expect(data['familyId'], 'fam-1');
      expect(data['createdByUid'], 'owner-uid');
      expect(data['inviterName'], 'Reem');
      expect(data['usedByUid'], isNull);
    });

    test(
      'omits inviterName entirely when there is none, and caps a long one at 80',
      () async {
        final unnamed = await repo.createInvite(
          familyId: 'fam-1',
          creatorUid: 'u',
          inviterName: ' ',
        );
        final unnamedData =
            (await firestore.doc('invites/${unnamed.code}').get()).data()!;
        expect(unnamedData.containsKey('inviterName'), isFalse);
        expect(unnamed.inviterName, isNull);

        final long = await repo.createInvite(
          familyId: 'fam-1',
          creatorUid: 'u',
          inviterName: 'x' * 200,
        );
        expect(long.inviterName, hasLength(80));
      },
    );
  });

  group('lookupInvite', () {
    test(
      'finds an invite from the dashed, lowercase form the joiner might type',
      () async {
        final created = await repo.createInvite(
          familyId: 'fam-1',
          creatorUid: 'owner-uid',
          inviterName: 'Reem',
        );
        final typed = FamilyInviteRepository.formatCode(
          created.code,
        ).toLowerCase();

        final found = await repo.lookupInvite(typed);
        expect(found, isNotNull);
        expect(found!.code, created.code);
        expect(found.familyId, 'fam-1');
        expect(found.inviterName, 'Reem');
        expect(found.isUsable, isTrue);
      },
    );

    test(
      'returns null for an unknown code, and for input with no code characters at all',
      () async {
        expect(await repo.lookupInvite('NOPE1234'), isNull);
        expect(await repo.lookupInvite(' - / '), isNull);
      },
    );
  });

  test(
    'listInvitesCreatedBy returns only that uid\'s invites, latest expiry first',
    () async {
      await firestore.doc('invites/OLDEROLD').set({
        'familyId': 'fam-1',
        'createdByUid': 'owner-uid',
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 1)),
        ),
        'usedByUid': null,
      });
      await firestore.doc('invites/NEWERNEW').set({
        'familyId': 'fam-1',
        'createdByUid': 'owner-uid',
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 6)),
        ),
        'usedByUid': null,
      });
      await firestore.doc('invites/SOMEONEE').set({
        'familyId': 'fam-1',
        'createdByUid': 'other-uid',
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 3)),
        ),
        'usedByUid': null,
      });

      final mine = await repo.listInvitesCreatedBy('owner-uid');
      expect(mine.map((i) => i.code), ['NEWERNEW', 'OLDEROLD']);
    },
  );

  group('claimInvite', () {
    Future<FamilyInvite> seedInvite() async {
      final created = await repo.createInvite(
        familyId: 'fam-1',
        creatorUid: 'owner-uid',
      );
      return (await repo.lookupInvite(created.code))!;
    }

    test('marks the invite used and grants joinedUids access', () async {
      final invite = await seedInvite();
      await repo.claimInvite(invite, 'joiner-uid');

      final after = (await repo.lookupInvite(invite.code))!;
      expect(after.usedByUid, 'joiner-uid');
      final grant = await firestore
          .doc('families/fam-1/joinedUids/joiner-uid')
          .get();
      expect(grant.data()?['inviteCode'], invite.code);
    });

    test(
      're-running for an invite the same uid already claimed finishes a missing grant',
      () async {
        final invite = await seedInvite();
        // The first claim write landed but the grant didn't.
        await firestore.doc('invites/${invite.code}').update({
          'usedByUid': 'joiner-uid',
        });
        final claimed = (await repo.lookupInvite(invite.code))!;

        await repo.claimInvite(claimed, 'joiner-uid');

        final grant = await firestore
            .doc('families/fam-1/joinedUids/joiner-uid')
            .get();
        expect(grant.exists, isTrue);
      },
    );

    test(
      're-running once fully joined is a no-op, not a second grant write',
      () async {
        final invite = await seedInvite();
        await repo.claimInvite(invite, 'joiner-uid');
        final grantRef = firestore.doc('families/fam-1/joinedUids/joiner-uid');
        final firstJoinedAt = (await grantRef.get()).data()!['joinedAt'];

        final claimed = (await repo.lookupInvite(invite.code))!;
        await repo.claimInvite(claimed, 'joiner-uid');

        expect((await grantRef.get()).data()!['joinedAt'], firstJoinedAt);
      },
    );
  });

  test(
    'daysLeft rounds up, and never reports 0 for an invite that has not expired',
    () {
      FamilyInvite expiringIn(Duration d) => FamilyInvite(
        code: 'X',
        familyId: 'f',
        expiresAt: DateTime.now().add(d),
        usedByUid: null,
      );
      expect(expiringIn(const Duration(days: 6, hours: 1)).daysLeft, 7);
      expect(expiringIn(const Duration(minutes: 5)).daysLeft, 1);
    },
  );
}
