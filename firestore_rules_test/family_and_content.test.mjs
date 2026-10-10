import { after, afterEach, before, describe, test } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { createTestEnv, familyDoc } from './helpers.mjs';

describe('families/{familyId} — create, read, update, delete', () => {
  let testEnv;

  before(async () => {
    testEnv = await createTestEnv('family-and-content');
  });

  afterEach(() => testEnv.clearFirestore());
  after(() => testEnv.cleanup());

  test('the linking owner can create the family doc with themselves as sole member', async () => {
    const owner = testEnv.authenticatedContext('owner-uid');
    await assertSucceeds(
      setDoc(doc(owner.firestore(), 'families/fam-1'), familyDoc('owner-uid')),
    );
  });

  test('create is denied if ownerUid does not match the caller', async () => {
    const owner = testEnv.authenticatedContext('owner-uid');
    await assertFails(
      setDoc(doc(owner.firestore(), 'families/fam-1'), familyDoc('someone-else-uid')),
    );
  });

  test('create is denied if memberUids is anything but [ownerUid] alone', async () => {
    const owner = testEnv.authenticatedContext('owner-uid');
    await assertFails(
      setDoc(doc(owner.firestore(), 'families/fam-1'), {
        ownerUid: 'owner-uid',
        memberUids: ['owner-uid', 'someone-else-uid'],
      }),
    );
  });

  test('an unauthenticated caller cannot create a family doc', async () => {
    const anon = testEnv.unauthenticatedContext();
    await assertFails(setDoc(doc(anon.firestore(), 'families/fam-1'), familyDoc('owner-uid')));
  });

  test('a member (by memberUids) can read the family doc; a stranger cannot', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'families/fam-1'), familyDoc('owner-uid'));
    });

    const owner = testEnv.authenticatedContext('owner-uid');
    await assertSucceeds(getDoc(doc(owner.firestore(), 'families/fam-1')));

    const stranger = testEnv.authenticatedContext('stranger-uid');
    await assertFails(getDoc(doc(stranger.firestore(), 'families/fam-1')));
  });

  test('ownerUid and memberUids are immutable on update, even by the owner', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'families/fam-1'), familyDoc('owner-uid'));
    });
    const owner = testEnv.authenticatedContext('owner-uid');

    await assertFails(
      updateDoc(doc(owner.firestore(), 'families/fam-1'), { ownerUid: 'someone-else-uid' }),
    );
    await assertFails(
      updateDoc(doc(owner.firestore(), 'families/fam-1'), {
        memberUids: ['owner-uid', 'someone-else-uid'],
      }),
    );
  });

  test('the family doc can never be deleted', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'families/fam-1'), familyDoc('owner-uid'));
    });
    const owner = testEnv.authenticatedContext('owner-uid');
    await assertFails(deleteDoc(doc(owner.firestore(), 'families/fam-1')));
  });
});

describe('families/{familyId}/tasks — content is member-only, via either access path', () => {
  let testEnv;

  before(async () => {
    testEnv = await createTestEnv('family-and-content');
  });

  afterEach(() => testEnv.clearFirestore());
  after(() => testEnv.cleanup());

  const seedFamilyAndTask = async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'families/fam-1'), familyDoc('owner-uid'));
      await setDoc(doc(ctx.firestore(), 'families/fam-1/tasks/task-1'), {
        title: 'Buy milk',
        updatedAt: serverTimestamp(),
      });
    });
  };

  test('the owner (via memberUids) can read and write tasks', async () => {
    await seedFamilyAndTask();
    const owner = testEnv.authenticatedContext('owner-uid');
    await assertSucceeds(getDoc(doc(owner.firestore(), 'families/fam-1/tasks/task-1')));
    await assertSucceeds(
      setDoc(doc(owner.firestore(), 'families/fam-1/tasks/task-2'), {
        title: 'Second task',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('a joined-via-invite adult (via joinedUids, not memberUids) can also read and write tasks',
    async () => {
      await seedFamilyAndTask();
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'families/fam-1/joinedUids/adult-uid'), {
          inviteCode: 'IRRELEVANT-FOR-THIS-TEST',
          joinedAt: serverTimestamp(),
        });
      });

      const adult = testEnv.authenticatedContext('adult-uid');
      await assertSucceeds(getDoc(doc(adult.firestore(), 'families/fam-1/tasks/task-1')));
      await assertSucceeds(
        setDoc(doc(adult.firestore(), 'families/fam-1/tasks/task-3'), {
          title: 'Third task',
          updatedAt: serverTimestamp(),
        }),
      );
    });

  test('a stranger — neither in memberUids nor joinedUids — is denied', async () => {
    await seedFamilyAndTask();
    const stranger = testEnv.authenticatedContext('stranger-uid');
    await assertFails(getDoc(doc(stranger.firestore(), 'families/fam-1/tasks/task-1')));
    await assertFails(
      setDoc(doc(stranger.firestore(), 'families/fam-1/tasks/task-4'), {
        title: 'Should not be allowed',
        updatedAt: serverTimestamp(),
      }),
    );
  });
});
