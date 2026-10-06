import { after, afterEach, before, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, Timestamp } from 'firebase/firestore';
import { createTestEnv, familyDoc } from './helpers.mjs';

// families/{familyId}/responsibilities/{id}: per-member chores, synced so a
// chore assigned on one phone (and ticked "done today" on another) is the
// same everywhere. Member-only, through either access path, like tasks.
describe('families/{familyId}/responsibilities', () => {
  let testEnv;

  before(async () => {
    testEnv = await createTestEnv('responsibilities');
  });

  afterEach(() => testEnv.clearFirestore());
  after(() => testEnv.cleanup());

  const chore = {
    memberId: 'm-mariam',
    title: 'Feed the cat',
    recurrence: 'daily',
    customWeekdays: null,
    lastCompletedDate: null,
    createdAt: Timestamp.now(),
    deletedAt: null,
    updatedAt: Timestamp.now(),
  };

  const seed = () =>
    testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'families/fam-1'), familyDoc('owner-uid'));
      await setDoc(doc(ctx.firestore(), 'families/fam-1/joinedUids/joiner-uid'), {
        inviteCode: 'CODE1',
        joinedAt: Timestamp.now(),
      });
    });

  test('the owner can write and read a chore', async () => {
    await seed();
    const owner = testEnv.authenticatedContext('owner-uid').firestore();
    await assertSucceeds(setDoc(doc(owner, 'families/fam-1/responsibilities/r1'), chore));
    await assertSucceeds(getDoc(doc(owner, 'families/fam-1/responsibilities/r1')));
  });

  test('an invite-joined member can tick a chore done', async () => {
    await seed();
    const joiner = testEnv.authenticatedContext('joiner-uid').firestore();
    await assertSucceeds(
      setDoc(doc(joiner, 'families/fam-1/responsibilities/r1'), {
        ...chore,
        lastCompletedDate: Timestamp.now(),
      }),
    );
  });

  test('a non-member can neither read nor write', async () => {
    await seed();
    await testEnv.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'families/fam-1/responsibilities/r1'), chore),
    );
    const stranger = testEnv.authenticatedContext('stranger-uid').firestore();
    await assertFails(getDoc(doc(stranger, 'families/fam-1/responsibilities/r1')));
    await assertFails(setDoc(doc(stranger, 'families/fam-1/responsibilities/r2'), chore));
  });

  test('signed out: denied', async () => {
    await seed();
    const anon = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(anon, 'families/fam-1/responsibilities/r1')));
  });
});
