import { after, afterEach, before, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, serverTimestamp, setDoc, Timestamp } from 'firebase/firestore';
import { createTestEnv, familyDoc } from './helpers.mjs';

// families/{familyId}/settings/{familyId}: the family's school days and
// week start (V2.2). Every member reads; only the Owner account writes.
describe('families/{familyId}/settings', () => {
  let testEnv;

  before(async () => {
    testEnv = await createTestEnv('family-settings');
  });

  afterEach(() => testEnv.clearFirestore());
  after(() => testEnv.cleanup());

  const path = 'families/fam-1/settings/fam-1';
  // As FamilySettingsSyncAdapter + the engine's updatedAt write it.
  const settings = (overrides = {}) => ({
    schoolWeekdays: [7, 1, 2, 3, 4],
    weekStartDay: 7,
    updatedAt: serverTimestamp(),
    ...overrides,
  });

  const seed = () =>
    testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'families/fam-1'), familyDoc('owner-uid'));
      await setDoc(doc(ctx.firestore(), 'families/fam-1/joinedUids/adult-uid'), {
        inviteCode: 'CODE1',
        joinedAt: Timestamp.now(),
      });
    });

  test('the Owner creates and updates the settings; every member reads them', async () => {
    await seed();
    const owner = testEnv.authenticatedContext('owner-uid').firestore();
    const adult = testEnv.authenticatedContext('adult-uid').firestore();
    await assertSucceeds(setDoc(doc(owner, path), settings()));
    await assertSucceeds(setDoc(doc(owner, path), settings({ schoolWeekdays: [1, 2, 3, 4, 5], weekStartDay: 1 })));
    await assertSucceeds(getDoc(doc(adult, path)));
    await assertSucceeds(setDoc(doc(owner, path), settings({ schoolWeekdays: [] })));
  });

  test('an Adult (even acting as the Owner on a shared phone) cannot write', async () => {
    await seed();
    const adult = testEnv.authenticatedContext('adult-uid').firestore();
    await assertFails(setDoc(doc(adult, path), settings()));
    await testEnv.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), path), settings()));
    await assertFails(setDoc(doc(adult, path), settings({ weekStartDay: 1 })));
  });

  test('a stranger can neither read nor write; nobody deletes', async () => {
    await seed();
    await testEnv.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), path), settings()));
    const stranger = testEnv.authenticatedContext('stranger-uid').firestore();
    await assertFails(getDoc(doc(stranger, path)));
    await assertFails(setDoc(doc(stranger, path), settings()));
    const owner = testEnv.authenticatedContext('owner-uid').firestore();
    await assertFails(deleteDoc(doc(owner, path)));
  });

  test('duplicate weekdays are refused', async () => {
    await seed();
    const owner = testEnv.authenticatedContext('owner-uid').firestore();
    await assertFails(setDoc(doc(owner, path), settings({ schoolWeekdays: [1, 1, 2] })));
    await assertFails(setDoc(doc(owner, path), settings({ schoolWeekdays: [7, 1, 2, 3, 4, 7] })));
  });

  test('weekdays outside 1–7, wrong types and extra keys are refused', async () => {
    await seed();
    const owner = testEnv.authenticatedContext('owner-uid').firestore();
    await assertFails(setDoc(doc(owner, path), settings({ schoolWeekdays: [0, 1] })));
    await assertFails(setDoc(doc(owner, path), settings({ schoolWeekdays: [8] })));
    await assertFails(setDoc(doc(owner, path), settings({ schoolWeekdays: ['1'] })));
    await assertFails(setDoc(doc(owner, path), settings({ schoolWeekdays: '1,2,3' })));
    await assertFails(setDoc(doc(owner, path), settings({ weekStartDay: 0 })));
    await assertFails(setDoc(doc(owner, path), settings({ weekStartDay: 8 })));
    await assertFails(setDoc(doc(owner, path), settings({ weekStartDay: '7' })));
    await assertFails(setDoc(doc(owner, path), settings({ theme: 'dark' })));
    await assertFails(setDoc(doc(owner, path), { schoolWeekdays: [1] }));
  });

  test("the document can't be stored under another id", async () => {
    await seed();
    const owner = testEnv.authenticatedContext('owner-uid').firestore();
    await assertFails(setDoc(doc(owner, 'families/fam-1/settings/fam-2'), settings()));
    await assertFails(setDoc(doc(owner, 'families/fam-1/settings/other'), settings()));
  });
});
