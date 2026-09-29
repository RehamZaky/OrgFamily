# Firestore security-rules tests

Security-rules tests for `firestore.rules`, run against the **Firebase
Local Emulator Suite** — not against the real `orgfamily-c40ae` project,
and not mocked. These are the tests referenced as the still-open roadmap
item in [docs/roadmap.md](../docs/roadmap.md) and
[docs/architecture.md](../docs/architecture.md) ("Family invitations"):
unit tests and the `fake_cloud_firestore`-based Dart tests
(`test/sync/sync_engine_test.dart`) can't exercise the real rules engine,
so this is the only place `invites/{code}` and
`families/{familyId}/joinedUids/{uid}` — the entire enforcement surface
for the invitation flow, since there's no Cloud Function backing it — are
actually verified against real rule evaluation.

## Why Node, not Dart

`cloud_firestore`/`firebase_auth` are federated plugins backed by native
platform channels (Android/iOS only in this app — see
`lib/core/auth/auth_config.dart`). They can't run under plain
`flutter test`, and a genuine device-level integration test needs a
connected Android/iOS device or emulator, which this environment doesn't
have (`flutter devices` shows only Windows desktop and browsers, both
platforms this app deliberately excludes from Firebase). Firestore
security rules themselves, however, are testable from plain Node via
`@firebase/rules-unit-testing` — the standard, official way to test rules
in isolation — which needs nothing but the Firebase CLI, Java, and Node.
This covers the rules; it does not cover the Flutter-side plugin
integration (see "What this doesn't cover" below).

## Prerequisites

- **Java 21+** on `PATH` (or `JAVA_HOME` pointed at one) — the Firestore
  emulator needs it. Check with `java -version`.
- **Firebase CLI** logged in (`firebase login`) — only needed once; the
  emulator itself never touches your real project or requires
  credentials at runtime (see "Project id" below).
- **Node.js 20+**.

## Setup (once)

```sh
cd firestore_rules_test
npm install
```

## Running

From the **repo root** (so the Firebase CLI can find `firebase.json`):

```sh
firebase emulators:exec --only firestore "npm --prefix firestore_rules_test test"
```

This starts the Firestore emulator on the port configured in
`firebase.json` (`emulators.firestore.port` — deliberately an unusual
high port, not 8080/8090, because this machine already has other local
services bound to the common ones), runs every `*.test.mjs` file in this
directory via Node's built-in test runner, then shuts the emulator back
down.

To iterate without restarting the emulator every time: start it once in
one terminal —

```sh
firebase emulators:start --only firestore
```

— and in another terminal, from `firestore_rules_test/`:

```sh
npm test
```

(`npm test` alone, without the emulator already running, will fail to
connect — `helpers.mjs` doesn't start one itself.)

## Project id

Tests run against a `demo-orgfamily-rules-test` project id
(`helpers.mjs`), which is a `@firebase/rules-unit-testing` convention: a
`demo-`-prefixed id is always treated as fully local by the emulator, no
real Firebase project or credentials required, even though
`firebase emulators:exec` itself is invoked with the real
`orgfamily-c40ae` as its default project (`.firebaserc`) — that default
only matters for commands like `firebase deploy`, never for what these
tests actually connect to.

## What's covered

- `families/{familyId}` — create-once `ownerUid`/`memberUids`
  immutability, read/update authorization via either access path.
- `families/{familyId}/tasks` (representative of every content
  subcollection, which all share one rule) — access via `memberUids` and
  via `joinedUids`, denied for a stranger.
- `invites/{code}` — create only by an existing member, `createdByUid`
  can't be forged, single-use claiming, expiry, tamper-proofing the
  claim (can't sneak in a `familyId`/`createdByUid`/`expiresAt` change
  alongside it), revocation only by the creator, `list` always denied.
  Also: `expiresAt` itself is bounded server-side at creation (must be a
  real future timestamp, capped at 30 days) — added after review found
  the rules originally trusted the client's "7 days" entirely, so a
  request bypassing the app could mint a functionally-forever invite.
- `families/{familyId}/joinedUids/{uid}` — create only when backed by an
  invite claimed by that exact uid for that exact family, immutable once
  created, uid in the path must match the caller.

## What this doesn't cover

- **Flutter-side plugin behavior** — whether `FamilyInviteRepository`
  and `SyncEngine` call the SDK correctly is covered by
  `test/sync/sync_engine_test.dart` and `test/data/*_test.dart` (using
  `fake_cloud_firestore`, not real rules) and by manual on-device
  verification. Nothing here runs Dart or the app itself.
- **True multi-device races against a real backend** — two devices
  claiming the same invite concurrently, `hasPendingWrites`/listener
  timing — those need either a real Android/iOS device driving the app
  against this same emulator, or much heavier orchestration than a rules
  test provides. Flagged as the next gap once a device/emulator is
  available.
