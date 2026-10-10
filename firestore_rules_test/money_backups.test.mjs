import { after, afterEach, before, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { Bytes, doc, getDoc, setDoc, Timestamp } from 'firebase/firestore';
import { createTestEnv, familyDoc } from './helpers.mjs';

// Money backups and their encryption key are Owner-only: an invited Adult
// is a full family member for tasks/events/lists, but must never read the
// family's financial backups or the key that decrypts them.
describe('families/{familyId}/moneyBackups + moneyBackupKey', () => {
  let testEnv;

  before(async () => {
    testEnv = await createTestEnv('money-backups');
  });

  afterEach(() => testEnv.clearFirestore());
  after(() => testEnv.cleanup());

  const seed = () =>
    testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'families/fam-1'), familyDoc('owner-uid'));
      await setDoc(doc(ctx.firestore(), 'families/fam-1/joinedUids/adult-uid'), {
        inviteCode: 'CODE1',
        joinedAt: Timestamp.now(),
      });
    });

  const meta = { kind: 'manual', formatVersion: 1, createdByUid: 'owner-uid', chunkCount: 1 };
  const key = { key: Bytes.fromUint8Array(new Uint8Array(32)) };
  const chunk = { data: Bytes.fromUint8Array(new Uint8Array([1, 2, 3])) };

  test('the Owner can store and read the key, backups and chunks', async () => {
    await seed();
    const owner = testEnv.authenticatedContext('owner-uid').firestore();
    await assertSucceeds(setDoc(doc(owner, 'families/fam-1/moneyBackupKey/key'), key));
    await assertSucceeds(setDoc(doc(owner, 'families/fam-1/moneyBackups/b1'), meta));
    await assertSucceeds(setDoc(doc(owner, 'families/fam-1/moneyBackups/b1/chunks/0'), chunk));
    await assertSucceeds(getDoc(doc(owner, 'families/fam-1/moneyBackupKey/key')));
    await assertSucceeds(getDoc(doc(owner, 'families/fam-1/moneyBackups/b1/chunks/0')));
  });

  test('an invited Adult member can read none of it, nor write', async () => {
    await seed();
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'families/fam-1/moneyBackupKey/key'), key);
      await setDoc(doc(ctx.firestore(), 'families/fam-1/moneyBackups/b1'), meta);
      await setDoc(doc(ctx.firestore(), 'families/fam-1/moneyBackups/b1/chunks/0'), chunk);
    });
    const adult = testEnv.authenticatedContext('adult-uid').firestore();
    await assertFails(getDoc(doc(adult, 'families/fam-1/moneyBackupKey/key')));
    await assertFails(getDoc(doc(adult, 'families/fam-1/moneyBackups/b1')));
    await assertFails(getDoc(doc(adult, 'families/fam-1/moneyBackups/b1/chunks/0')));
    await assertFails(setDoc(doc(adult, 'families/fam-1/moneyBackups/b2'), meta));
    await assertFails(setDoc(doc(adult, 'families/fam-1/moneyBackupKey/key'), key));
  });

  test("another family's Owner gets nothing", async () => {
    await seed();
    await testEnv.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'families/fam-2'), familyDoc('other-owner')),
    );
    const other = testEnv.authenticatedContext('other-owner').firestore();
    await assertFails(getDoc(doc(other, 'families/fam-1/moneyBackupKey/key')));
    await assertFails(setDoc(doc(other, 'families/fam-1/moneyBackups/b1'), meta));
  });

  test('signed out: denied', async () => {
    await seed();
    const anon = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(anon, 'families/fam-1/moneyBackups/b1')));
  });
});
