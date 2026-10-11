import { after, afterEach, before, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';
import { createTestEnv, familyDoc } from './helpers.mjs';

// families/{familyId}/activities/{id}: the V2.1 family activity log.
// Members read; an entry is created once by the account it names (with the
// server's time), on behalf of its own or an account-less member, about a
// real entity of the right kind — and never rewritten or deleted.
describe('families/{familyId}/activities', () => {
  let testEnv;

  before(async () => {
    testEnv = await createTestEnv('activities');
  });

  afterEach(() => testEnv.clearFirestore());
  after(() => testEnv.cleanup());

  // Shaped exactly as ActivitySyncAdapter + the engine's _pushOne write it.
  const entry = (actorUid) => ({
    type: 'task.completed',
    actorKind: 'adult',
    actorUid,
    actorMemberId: 'm-mariam',
    actorDeviceId: null,
    entityType: 'task',
    entityId: 't1',
    state: null,
    relatedActivityId: null,
    metadata: { title: 'Feed the cat', assigneeId: 'm-mariam' },
    schemaVersion: 1,
    createdAt: Timestamp.now(),
    occurredAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });

  const path = 'families/fam-1/activities/a1';

  const seed = () =>
    testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'families/fam-1'), familyDoc('owner-uid'));
      await setDoc(doc(ctx.firestore(), 'families/fam-1/joinedUids/joiner-uid'), {
        inviteCode: 'CODE1',
        joinedAt: Timestamp.now(),
      });
      const fs = ctx.firestore();
      // Kareem (owner account) and Reem (joiner account) are linked
      // adults; Mariam is a child with no account.
      await setDoc(doc(fs, 'families/fam-1/members/m-kareem'), { name: 'Kareem', linkedUid: 'owner-uid' });
      await setDoc(doc(fs, 'families/fam-1/members/m-reem'), { name: 'Reem', linkedUid: 'joiner-uid' });
      await setDoc(doc(fs, 'families/fam-1/members/m-mariam'), { name: 'Mariam', linkedUid: null });
      await setDoc(doc(fs, 'families/fam-1/tasks/t1'), { title: 'Feed the cat', isCompleted: true });
    });

  test('a member records their own entry, and every member reads it', async () => {
    await seed();
    const joiner = testEnv.authenticatedContext('joiner-uid').firestore();
    const owner = testEnv.authenticatedContext('owner-uid').firestore();
    await assertSucceeds(setDoc(doc(joiner, path), entry('joiner-uid')));
    await assertSucceeds(getDoc(doc(owner, path)));
    await assertSucceeds(getDocs(collection(owner, 'families/fam-1/activities')));
  });

  test('an entry made while signed out (no actorUid) can be uploaded', async () => {
    await seed();
    const owner = testEnv.authenticatedContext('owner-uid').firestore();
    await assertSucceeds(setDoc(doc(owner, path), entry(null)));
  });

  test('cannot record an entry in another account’s name', async () => {
    await seed();
    const joiner = testEnv.authenticatedContext('joiner-uid').firestore();
    await assertFails(setDoc(doc(joiner, path), entry('owner-uid')));
  });

  test('occurredAt must be the server time, not the device clock', async () => {
    await seed();
    const owner = testEnv.authenticatedContext('owner-uid').firestore();
    await assertFails(
      setDoc(doc(owner, path), { ...entry('owner-uid'), occurredAt: Timestamp.now() }),
    );
  });

  test('unknown fields, a bad actorKind or oversized metadata are refused', async () => {
    await seed();
    const owner = testEnv.authenticatedContext('owner-uid').firestore();
    await assertFails(setDoc(doc(owner, path), { ...entry('owner-uid'), amount: 500 }));
    await assertFails(setDoc(doc(owner, path), { ...entry('owner-uid'), actorKind: 'admin' }));
    const big = Object.fromEntries([...Array(21).keys()].map((i) => [`k${i}`, i]));
    await assertFails(setDoc(doc(owner, path), { ...entry('owner-uid'), metadata: big }));
    await assertFails(setDoc(doc(owner, path), { ...entry('owner-uid'), metadata: 'x' }));
  });

  test('an adult may act as themselves or an account-less child', async () => {
    await seed();
    const owner = testEnv.authenticatedContext('owner-uid').firestore();
    await assertSucceeds(setDoc(doc(owner, path), { ...entry('owner-uid'), actorMemberId: 'm-kareem' }));
    await assertSucceeds(
      setDoc(doc(owner, 'families/fam-1/activities/a2'), { ...entry('owner-uid'), actorMemberId: 'm-mariam' }),
    );
    await assertSucceeds(
      setDoc(doc(owner, 'families/fam-1/activities/a3'), { ...entry('owner-uid'), actorMemberId: null }),
    );
  });

  test("cannot claim another adult's member, or a member that doesn't exist", async () => {
    await seed();
    const joiner = testEnv.authenticatedContext('joiner-uid').firestore();
    await assertFails(setDoc(doc(joiner, path), { ...entry('joiner-uid'), actorMemberId: 'm-kareem' }));
    await assertFails(setDoc(doc(joiner, path), { ...entry('joiner-uid'), actorMemberId: 'm-ghost' }));
  });

  test('the entry must describe a real entity of its own kind', async () => {
    await seed();
    const owner = testEnv.authenticatedContext('owner-uid').firestore();
    await assertFails(setDoc(doc(owner, path), { ...entry('owner-uid'), entityId: 'no-such-task' }));
    // task.completed about an event id / with entityType event: mismatched.
    await assertFails(setDoc(doc(owner, path), { ...entry('owner-uid'), entityType: 'event' }));
    await assertFails(setDoc(doc(owner, path), { ...entry('owner-uid'), entityType: 'invites' }));
  });

  test('unsupported types, child or device entries wait for V3', async () => {
    await seed();
    const owner = testEnv.authenticatedContext('owner-uid').firestore();
    await assertFails(
      setDoc(doc(owner, path), { ...entry('owner-uid'), type: 'task.submitted_for_approval' }),
    );
    await assertFails(setDoc(doc(owner, path), { ...entry('owner-uid'), actorKind: 'child' }));
    await assertFails(setDoc(doc(owner, path), { ...entry('owner-uid'), actorDeviceId: 'device-1' }));
  });

  test('a sync retry may re-send the same entry', async () => {
    await seed();
    const owner = testEnv.authenticatedContext('owner-uid').firestore();
    const data = entry('owner-uid');
    await assertSucceeds(setDoc(doc(owner, path), data));
    // Retry before the read-back: same fields, fresh server sentinels.
    await assertSucceeds(setDoc(doc(owner, path), data));
    // Retry after the read-back: the stored occurredAt is sent back as is.
    const stored = (await getDoc(doc(owner, path))).data();
    await assertSucceeds(setDoc(doc(owner, path), { ...data, occurredAt: stored.occurredAt }));
  });

  test('an entry cannot be rewritten, backdated or deleted', async () => {
    await seed();
    const owner = testEnv.authenticatedContext('owner-uid').firestore();
    await assertSucceeds(setDoc(doc(owner, path), entry('owner-uid')));
    await assertFails(updateDoc(doc(owner, path), { metadata: { title: 'Something else' } }));
    await assertFails(updateDoc(doc(owner, path), { actorMemberId: 'm-kareem' }));
    await assertFails(
      updateDoc(doc(owner, path), { occurredAt: Timestamp.fromDate(new Date(2020, 0, 1)) }),
    );
    await assertFails(deleteDoc(doc(owner, path)));
  });

  test('a non-member can neither read nor write; signed out is denied', async () => {
    await seed();
    await testEnv.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), path), { ...entry('owner-uid'), occurredAt: Timestamp.now() }),
    );
    const stranger = testEnv.authenticatedContext('stranger-uid').firestore();
    await assertFails(getDoc(doc(stranger, path)));
    await assertFails(
      setDoc(doc(stranger, 'families/fam-1/activities/a2'), entry('stranger-uid')),
    );
    const anon = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(anon, path)));
  });
});
