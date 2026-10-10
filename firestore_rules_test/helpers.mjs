import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';

const __dirname = dirname(fileURLToPath(import.meta.url));

// A `demo-` project id is a rules-unit-testing convention: the emulator
// treats it as fully local with no real Firebase project behind it at
// all, so these tests never touch (or need credentials for) the real
// `orgfamily-c40ae` project even though the emulator is started with that
// project as its default (see firebase.json/.firebaserc) — that default
// only matters for `firebase deploy`, not for what these tests connect to.
const TEST_PROJECT_PREFIX = 'demo-orgfamily-rules-test';

/** Matches firebase.json's `emulators.firestore.port` — see README.md for
 * how to start the emulator before running these tests. */
const EMULATOR_HOST = '127.0.0.1';
const EMULATOR_PORT = 18090;

/**
 * Every test *file* must pass its own unique [suffix] here — Node's test
 * runner runs separate files in parallel by default, and
 * `testEnv.clearFirestore()` wipes the *entire* emulator project, not just
 * the data one file's own testEnv wrote. With every file sharing one
 * project id, one file's `afterEach` clear could fire between another
 * file's still-in-flight write and its very next read, and that read then
 * sees a suddenly-missing document — not a clean "denied", but a rules
 * evaluator error, since `get()`/`exists()` mid-rule hit a document that
 * vanished out from under it. Scoping each file to its own project id
 * (a plain string suffix; the emulator doesn't need it pre-registered)
 * isolates their data completely, so a parallel clear can never cross
 * over.
 */
export function createTestEnv(suffix) {
  if (!suffix) {
    throw new Error(
      'createTestEnv(suffix) requires a unique suffix per test file — see the doc comment above.',
    );
  }
  return initializeTestEnvironment({
    projectId: `${TEST_PROJECT_PREFIX}-${suffix}`,
    firestore: {
      rules: readFileSync(join(__dirname, '..', 'firestore.rules'), 'utf8'),
      host: EMULATOR_HOST,
      port: EMULATOR_PORT,
    },
  });
}

/** A family doc shaped exactly the way `FamilyProfileSyncAdapter` writes
 * it (see docs/architecture.md "Firestore sync") — `ownerUid` plus a
 * `memberUids` array containing just that one uid, since that adapter
 * never grows the array itself (invitations grant access via `joinedUids`
 * instead — see "Family invitations"). */
export function familyDoc(ownerUid) {
  return { ownerUid, memberUids: [ownerUid] };
}

export function futureTimestamp(daysFromNow) {
  return new Date(Date.now() + daysFromNow * 24 * 60 * 60 * 1000);
}

export function pastTimestamp(daysAgo) {
  return new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000);
}
