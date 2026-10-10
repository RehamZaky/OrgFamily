import { after, afterEach, before, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, serverTimestamp, setDoc, Timestamp } from 'firebase/firestore';
import { createTestEnv, familyDoc } from './helpers.mjs';

// users/{uid} records which family an account belongs to, so a member can
// find it again from a new device without another invite (see
// docs/architecture.md "Family invitations" § "New devices"). It must
// never let an account claim a family it isn't a member of, and never be
// readable by anyone but its own account.
describe('users/{uid}', () => {
  let testEnv;

  before(async () => {
    testEnv = await createTestEnv('users');
  });

  afterEach(() => testEnv.clearFirestore());
  after(() => testEnv.cleanup());

  const seed = async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'families/fam-1'), familyDoc('owner-uid'));
      await setDoc(doc(ctx.firestore(), 'families/fam-1/joinedUids/joiner-uid'), {
        inviteCode: 'CODE1',
        joinedAt: Timestamp.now(),
      });
      await setDoc(doc(ctx.firestore(), 'families/fam-2'), familyDoc('other-owner'));
    });
  };

  const record = (familyId) => ({ familyId, updatedAt: serverTimestamp() });

  test('the owner can record their own family', async () => {
    await seed();
    const owner = testEnv.authenticatedContext('owner-uid');
    await assertSucceeds(setDoc(doc(owner.firestore(), 'users/owner-uid'), record('fam-1')));
  });

  test('an invite-joined member can record the family they joined', async () => {
    await seed();
    const joiner = testEnv.authenticatedContext('joiner-uid');
    await assertSucceeds(setDoc(doc(joiner.firestore(), 'users/joiner-uid'), record('fam-1')));
  });

  test('an account cannot record a family it is not a member of', async () => {
    await seed();
    const joiner = testEnv.authenticatedContext('joiner-uid');
    await assertFails(setDoc(doc(joiner.firestore(), 'users/joiner-uid'), record('fam-2')));
  });

  test('a non-member cannot record any family', async () => {
    await seed();
    const stranger = testEnv.authenticatedContext('stranger-uid');
    await assertFails(setDoc(doc(stranger.firestore(), 'users/stranger-uid'), record('fam-1')));
  });

  test('a revoked member can no longer refresh their record', async () => {
    await seed();
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/joiner-uid'), { familyId: 'fam-1' });
      await deleteDoc(doc(ctx.firestore(), 'families/fam-1/joinedUids/joiner-uid'));
    });
    const joiner = testEnv.authenticatedContext('joiner-uid');
    await assertFails(setDoc(doc(joiner.firestore(), 'users/joiner-uid'), record('fam-1')));
    // ...and the family itself is no longer readable, which is what the
    // app's membership check asks.
    await assertFails(getDoc(doc(joiner.firestore(), 'families/fam-1')));
  });

  test("nobody can write another account's record", async () => {
    await seed();
    const owner = testEnv.authenticatedContext('owner-uid');
    await assertFails(setDoc(doc(owner.firestore(), 'users/joiner-uid'), record('fam-1')));
  });

  test('extra fields are rejected', async () => {
    await seed();
    const owner = testEnv.authenticatedContext('owner-uid');
    await assertFails(
      setDoc(doc(owner.firestore(), 'users/owner-uid'), { ...record('fam-1'), role: 'admin' }),
    );
  });

  test('an account can read only its own record', async () => {
    await seed();
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/owner-uid'), { familyId: 'fam-1' });
    });
    const owner = testEnv.authenticatedContext('owner-uid');
    await assertSucceeds(getDoc(doc(owner.firestore(), 'users/owner-uid')));
    // A fresh account with no record yet can still check (gets "missing").
    const fresh = testEnv.authenticatedContext('fresh-uid');
    await assertSucceeds(getDoc(doc(fresh.firestore(), 'users/fresh-uid')));
    const joiner = testEnv.authenticatedContext('joiner-uid');
    await assertFails(getDoc(doc(joiner.firestore(), 'users/owner-uid')));
    const anon = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(anon.firestore(), 'users/owner-uid')));
  });
});
