import { after, afterEach, before, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';
import { createTestEnv, familyDoc, futureTimestamp, pastTimestamp } from './helpers.mjs';

// See docs/architecture.md "Family invitations" for the design under test:
// a short-lived, single-use code an existing member creates so a second
// real adult can join. These rules are the whole enforcement surface for
// that flow — there's no Cloud Function backing it — so every branch here
// is a real authorization boundary, not a nice-to-have.
describe('invites/{code}', () => {
  let testEnv;

  before(async () => {
    testEnv = await createTestEnv('invites');
  });

  afterEach(() => testEnv.clearFirestore());
  after(() => testEnv.cleanup());

  const seedFamily = async (familyId, ownerUid) => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `families/${familyId}`), familyDoc(ownerUid));
    });
  };

  const validInvite = (overrides = {}) => ({
    familyId: 'fam-1',
    createdByUid: 'owner-uid',
    expiresAt: Timestamp.fromDate(futureTimestamp(7)),
    usedByUid: null,
    usedAt: null,
    ...overrides,
  });

  describe('create', () => {
    test('an existing member can create an invite for their own family', async () => {
      await seedFamily('fam-1', 'owner-uid');
      const owner = testEnv.authenticatedContext('owner-uid');
      await assertSucceeds(
        setDoc(doc(owner.firestore(), 'invites/CODE1'), validInvite()),
      );
    });

    test('a joined-via-invite member (not just the original owner) can also create one', async () => {
      await seedFamily('fam-1', 'owner-uid');
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'families/fam-1/joinedUids/adult-uid'), {
          inviteCode: 'SOME-OTHER-CODE',
        });
      });
      const adult = testEnv.authenticatedContext('adult-uid');
      await assertSucceeds(
        setDoc(doc(adult.firestore(), 'invites/CODE2'), validInvite({ createdByUid: 'adult-uid' })),
      );
    });

    test('a non-member of the named family cannot create an invite for it', async () => {
      await seedFamily('fam-1', 'owner-uid');
      const stranger = testEnv.authenticatedContext('stranger-uid');
      await assertFails(
        setDoc(
          doc(stranger.firestore(), 'invites/CODE3'),
          validInvite({ createdByUid: 'stranger-uid' }),
        ),
      );
    });

    test('createdByUid must match the caller — cannot forge someone else as the creator', async () => {
      await seedFamily('fam-1', 'owner-uid');
      const owner = testEnv.authenticatedContext('owner-uid');
      await assertFails(
        setDoc(
          doc(owner.firestore(), 'invites/CODE4'),
          validInvite({ createdByUid: 'someone-else-uid' }),
        ),
      );
    });

    test('usedByUid must start null — cannot create an already-claimed-looking invite', async () => {
      await seedFamily('fam-1', 'owner-uid');
      const owner = testEnv.authenticatedContext('owner-uid');
      await assertFails(
        setDoc(
          doc(owner.firestore(), 'invites/CODE5'),
          validInvite({ usedByUid: 'pre-filled-uid' }),
        ),
      );
    });

    // Regression: expiresAt used to be trusted entirely from the client
    // (FamilyInviteRepository always sends "now + 7 days", but nothing
    // stopped a direct setDoc bypassing the app from sending anything at
    // all) — the claim rule only checks `request.time < expiresAt`, so an
    // unbounded expiresAt would have been valid forever.
    test('expiresAt already in the past is rejected at creation', async () => {
      await seedFamily('fam-1', 'owner-uid');
      const owner = testEnv.authenticatedContext('owner-uid');
      await assertFails(
        setDoc(
          doc(owner.firestore(), 'invites/CODE-PAST'),
          validInvite({ expiresAt: Timestamp.fromDate(pastTimestamp(1)) }),
        ),
      );
    });

    test('expiresAt far beyond the 30-day cap is rejected, even though it is in the future',
      async () => {
        await seedFamily('fam-1', 'owner-uid');
        const owner = testEnv.authenticatedContext('owner-uid');
        await assertFails(
          setDoc(
            doc(owner.firestore(), 'invites/CODE-FAR'),
            validInvite({ expiresAt: Timestamp.fromDate(futureTimestamp(365)) }),
          ),
        );
      });

    test('expiresAt missing entirely is rejected, not treated as "never expires"', async () => {
      await seedFamily('fam-1', 'owner-uid');
      const owner = testEnv.authenticatedContext('owner-uid');
      const { expiresAt: _omitted, ...withoutExpiresAt } = validInvite();
      await assertFails(setDoc(doc(owner.firestore(), 'invites/CODE-NOEXP'), withoutExpiresAt));
    });

    test('an unauthenticated caller cannot create an invite', async () => {
      await seedFamily('fam-1', 'owner-uid');
      const anon = testEnv.unauthenticatedContext();
      await assertFails(setDoc(doc(anon.firestore(), 'invites/CODE6'), validInvite()));
    });
  });

  describe('get / list', () => {
    test('any signed-in user can get an invite by its exact code, even a non-member', async () => {
      await seedFamily('fam-1', 'owner-uid');
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'invites/CODE7'), validInvite());
      });
      const joiner = testEnv.authenticatedContext('joiner-uid');
      await assertSucceeds(getDoc(doc(joiner.firestore(), 'invites/CODE7')));
    });

    test('an unauthenticated caller cannot even look up a code', async () => {
      await seedFamily('fam-1', 'owner-uid');
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'invites/CODE8'), validInvite());
      });
      const anon = testEnv.unauthenticatedContext();
      await assertFails(getDoc(doc(anon.firestore(), 'invites/CODE8')));
    });

    test('listing the invites collection is always denied, even for the family that owns one',
      async () => {
        await seedFamily('fam-1', 'owner-uid');
        await testEnv.withSecurityRulesDisabled(async (ctx) => {
          await setDoc(doc(ctx.firestore(), 'invites/CODE9'), validInvite());
        });
        const owner = testEnv.authenticatedContext('owner-uid');
        await assertFails(getDocs(collection(owner.firestore(), 'invites')));
      });
  });

  describe('update (claiming)', () => {
    test('an unclaimed, unexpired invite can be claimed by a different uid', async () => {
      await seedFamily('fam-1', 'owner-uid');
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'invites/CODE10'), validInvite());
      });
      const joiner = testEnv.authenticatedContext('joiner-uid');
      await assertSucceeds(
        updateDoc(doc(joiner.firestore(), 'invites/CODE10'), {
          usedByUid: 'joiner-uid',
          usedAt: Timestamp.now(),
        }),
      );
    });

    test('an already-claimed invite cannot be claimed again, by anyone — single use', async () => {
      await seedFamily('fam-1', 'owner-uid');
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(
          doc(ctx.firestore(), 'invites/CODE11'),
          validInvite({ usedByUid: 'first-joiner-uid', usedAt: Timestamp.now() }),
        );
      });
      const secondJoiner = testEnv.authenticatedContext('second-joiner-uid');
      await assertFails(
        updateDoc(doc(secondJoiner.firestore(), 'invites/CODE11'), {
          usedByUid: 'second-joiner-uid',
          usedAt: Timestamp.now(),
        }),
      );
      // Not even a retry by the uid that legitimately claimed it first.
      const firstJoiner = testEnv.authenticatedContext('first-joiner-uid');
      await assertFails(
        updateDoc(doc(firstJoiner.firestore(), 'invites/CODE11'), {
          usedByUid: 'first-joiner-uid',
          usedAt: Timestamp.now(),
        }),
      );
    });

    test('an expired invite cannot be claimed', async () => {
      await seedFamily('fam-1', 'owner-uid');
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(
          doc(ctx.firestore(), 'invites/CODE12'),
          validInvite({ expiresAt: Timestamp.fromDate(pastTimestamp(1)) }),
        );
      });
      const joiner = testEnv.authenticatedContext('joiner-uid');
      await assertFails(
        updateDoc(doc(joiner.firestore(), 'invites/CODE12'), {
          usedByUid: 'joiner-uid',
          usedAt: Timestamp.now(),
        }),
      );
    });

    test('a claim cannot also tamper with familyId, createdByUid, or expiresAt', async () => {
      await seedFamily('fam-1', 'owner-uid');
      await seedFamily('fam-hijack', 'owner-uid');
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'invites/CODE13'), validInvite());
      });
      const joiner = testEnv.authenticatedContext('joiner-uid');

      await assertFails(
        updateDoc(doc(joiner.firestore(), 'invites/CODE13'), {
          usedByUid: 'joiner-uid',
          usedAt: Timestamp.now(),
          familyId: 'fam-hijack',
        }),
      );
      await assertFails(
        updateDoc(doc(joiner.firestore(), 'invites/CODE13'), {
          usedByUid: 'joiner-uid',
          usedAt: Timestamp.now(),
          createdByUid: 'joiner-uid',
        }),
      );
      await assertFails(
        updateDoc(doc(joiner.firestore(), 'invites/CODE13'), {
          usedByUid: 'joiner-uid',
          usedAt: Timestamp.now(),
          expiresAt: Timestamp.fromDate(futureTimestamp(365)),
        }),
      );
    });

    test('a claim can only stamp the caller\'s own uid, not someone else\'s', async () => {
      await seedFamily('fam-1', 'owner-uid');
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'invites/CODE14'), validInvite());
      });
      const joiner = testEnv.authenticatedContext('joiner-uid');
      await assertFails(
        updateDoc(doc(joiner.firestore(), 'invites/CODE14'), {
          usedByUid: 'someone-else-entirely',
          usedAt: Timestamp.now(),
        }),
      );
    });
  });

  describe('delete (revoking)', () => {
    test('the creator can revoke their own unused invite', async () => {
      await seedFamily('fam-1', 'owner-uid');
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'invites/CODE15'), validInvite());
      });
      const owner = testEnv.authenticatedContext('owner-uid');
      await assertSucceeds(deleteDoc(doc(owner.firestore(), 'invites/CODE15')));
    });

    test('a different member of the same family cannot revoke someone else\'s invite', async () => {
      await seedFamily('fam-1', 'owner-uid');
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'families/fam-1/joinedUids/adult-uid'), {
          inviteCode: 'IRRELEVANT',
        });
        await setDoc(doc(ctx.firestore(), 'invites/CODE16'), validInvite());
      });
      const adult = testEnv.authenticatedContext('adult-uid');
      await assertFails(deleteDoc(doc(adult.firestore(), 'invites/CODE16')));
    });
  });
});
