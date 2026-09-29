import { after, afterEach, before, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, setDoc, Timestamp, updateDoc } from 'firebase/firestore';
import { createTestEnv, familyDoc, futureTimestamp } from './helpers.mjs';

// families/{familyId}/joinedUids/{uid} is what actually grants a
// joined-via-invite adult access (see docs/architecture.md "Family
// invitations") — the family doc's own memberUids never grows. This is
// the second half of the claim flow's enforcement, deliberately checked
// as a separate write from the invites/{code} claim tested in
// invites.test.mjs (the two are sequential, not one atomic transaction —
// see FamilyInviteRepository.claimInvite's doc comment for why).
describe('families/{familyId}/joinedUids/{uid}', () => {
  let testEnv;

  before(async () => {
    testEnv = await createTestEnv('joined-uids');
  });

  afterEach(() => testEnv.clearFirestore());
  after(() => testEnv.cleanup());

  const seedFamilyAndClaimedInvite = async ({
    familyId = 'fam-1',
    ownerUid = 'owner-uid',
    code = 'CODE1',
    claimedByUid = 'joiner-uid',
  } = {}) => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `families/${familyId}`), familyDoc(ownerUid));
      await setDoc(doc(ctx.firestore(), `invites/${code}`), {
        familyId,
        createdByUid: ownerUid,
        expiresAt: Timestamp.fromDate(futureTimestamp(7)),
        usedByUid: claimedByUid,
        usedAt: Timestamp.now(),
      });
    });
  };

  test('create succeeds when the referenced invite was claimed by this exact uid for this family',
    async () => {
      await seedFamilyAndClaimedInvite();
      const joiner = testEnv.authenticatedContext('joiner-uid');
      await assertSucceeds(
        setDoc(doc(joiner.firestore(), 'families/fam-1/joinedUids/joiner-uid'), {
          inviteCode: 'CODE1',
          joinedAt: Timestamp.now(),
        }),
      );
    });

  test('create is denied if the invite was never claimed at all (usedByUid still null)', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'families/fam-1'), familyDoc('owner-uid'));
      await setDoc(doc(ctx.firestore(), 'invites/CODE2'), {
        familyId: 'fam-1',
        createdByUid: 'owner-uid',
        expiresAt: Timestamp.fromDate(futureTimestamp(7)),
        usedByUid: null,
        usedAt: null,
      });
    });
    const joiner = testEnv.authenticatedContext('joiner-uid');
    await assertFails(
      setDoc(doc(joiner.firestore(), 'families/fam-1/joinedUids/joiner-uid'), {
        inviteCode: 'CODE2',
        joinedAt: Timestamp.now(),
      }),
    );
  });

  test('create is denied if the invite was claimed by a different uid than the caller', async () => {
    await seedFamilyAndClaimedInvite({ claimedByUid: 'someone-else-uid' });
    const joiner = testEnv.authenticatedContext('joiner-uid');
    await assertFails(
      setDoc(doc(joiner.firestore(), 'families/fam-1/joinedUids/joiner-uid'), {
        inviteCode: 'CODE1',
        joinedAt: Timestamp.now(),
      }),
    );
  });

  test('create is denied if the invite was actually claimed for a different family', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'families/fam-1'), familyDoc('owner-uid'));
      await setDoc(doc(ctx.firestore(), 'families/fam-decoy'), familyDoc('other-owner-uid'));
      await setDoc(doc(ctx.firestore(), 'invites/CODE3'), {
        familyId: 'fam-decoy',
        createdByUid: 'other-owner-uid',
        expiresAt: Timestamp.fromDate(futureTimestamp(7)),
        usedByUid: 'joiner-uid',
        usedAt: Timestamp.now(),
      });
    });
    const joiner = testEnv.authenticatedContext('joiner-uid');
    await assertFails(
      // Trying to use a code claimed for fam-decoy to grant access to fam-1.
      setDoc(doc(joiner.firestore(), 'families/fam-1/joinedUids/joiner-uid'), {
        inviteCode: 'CODE3',
        joinedAt: Timestamp.now(),
      }),
    );
  });

  test('a caller cannot grant joinedUids access to a different uid than their own', async () => {
    await seedFamilyAndClaimedInvite({ claimedByUid: 'joiner-uid' });
    const joiner = testEnv.authenticatedContext('joiner-uid');
    await assertFails(
      setDoc(doc(joiner.firestore(), 'families/fam-1/joinedUids/someone-else-uid'), {
        inviteCode: 'CODE1',
        joinedAt: Timestamp.now(),
      }),
    );
  });

  test('a joinedUids doc can never be updated once created', async () => {
    await seedFamilyAndClaimedInvite();
    const joiner = testEnv.authenticatedContext('joiner-uid');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'families/fam-1/joinedUids/joiner-uid'), {
        inviteCode: 'CODE1',
        joinedAt: Timestamp.now(),
      });
    });
    await assertFails(
      updateDoc(doc(joiner.firestore(), 'families/fam-1/joinedUids/joiner-uid'), {
        inviteCode: 'SOME-OTHER-CODE',
      }),
    );
  });

  test('a joinedUids doc can never be deleted (membership doesn\'t expire this way)', async () => {
    await seedFamilyAndClaimedInvite();
    const joiner = testEnv.authenticatedContext('joiner-uid');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'families/fam-1/joinedUids/joiner-uid'), {
        inviteCode: 'CODE1',
        joinedAt: Timestamp.now(),
      });
    });
    await assertFails(deleteDoc(doc(joiner.firestore(), 'families/fam-1/joinedUids/joiner-uid')));
  });

  test('an already-joined adult can read joinedUids docs; a stranger cannot', async () => {
    await seedFamilyAndClaimedInvite();
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'families/fam-1/joinedUids/joiner-uid'), {
        inviteCode: 'CODE1',
        joinedAt: Timestamp.now(),
      });
    });

    const joiner = testEnv.authenticatedContext('joiner-uid');
    await assertSucceeds(getDoc(doc(joiner.firestore(), 'families/fam-1/joinedUids/joiner-uid')));

    const stranger = testEnv.authenticatedContext('stranger-uid');
    await assertFails(getDoc(doc(stranger.firestore(), 'families/fam-1/joinedUids/joiner-uid')));
  });
});
