# OrgFamily — Architecture

## Stack

- **Flutter** (Material 3), **Riverpod** for state (`flutter_riverpod`,
  plain `Provider`/`StreamProvider` — no codegen).
- **Drift** (SQLite) as the local database — the source of truth for V1.
  `drift_flutter`'s `driftDatabase()` picks the right backend per
  platform automatically.
- **Firebase Auth** (V2) for per-adult sign-in — see "Family identity and
  authentication" below.
- **Firestore** (V2) mirrors a subset of Drift tables to the cloud once a
  family is linked — see "Firestore sync" below. Drift remains the local
  source of truth; Firestore is a sync target, not a replacement — see
  "Why local-first" below, which still holds.

## Layering

```
lib/
  core/       theme, shared widgets, enum-display and date-format extensions
  data/
    local/    Drift tables + generated database (database.g.dart)
    repositories/  one repo per table group, wraps Drift queries as
                    Streams (watch*) and Futures (add/update/delete)
    providers.dart  Provider<AppDatabase> + Provider<Repository> per repo
  features/
    family/ dashboard/ tasks/ calendar/ shopping/ quick_add/
      providers/  StreamProvider wrappers around repository watch*() calls
      screens/    ConsumerWidget/ConsumerStatefulWidget UI
  app/        MaterialApp + bottom-nav root scaffold
```

UI screens never touch Drift directly — they watch a feature provider,
which watches a repository, which watches the database. This is the seam
where a sync engine gets inserted later (see below) without touching any
screen code.

## Why local-first (V1's starting point, still true with Firestore added)

V1 deliberately shipped with no cloud sync at all, following the same
reasoning the original design doc for this project argued for — and
Firestore sync (see below) was built as a mirror *underneath* this, not
a replacement for it, so the reasoning still holds:

1. **Cost/design risk.** Firestore bills per document read/write through
   realtime listeners. Getting listener scoping wrong (e.g. "listen to
   all tasks ever") is the single biggest cost trap, and V1 usage
   patterns aren't known yet.
2. **Offline-first is the real requirement**, not "cloud sync." A family
   app has to work with a flaky connection at the dinner table. Building
   local-first from day one avoids retrofitting offline support later.
2. **YAGNI for a single-tester V1.** Multi-device sync, conflict
   resolution, and auth only matter once there's more than one device in
   the family actually using the app.

The repository layer already returns domain-shaped data (Drift's
generated row classes) rather than raw query results, so swapping the
underlying source (local DB → local DB + sync queue → Firestore-backed)
is a repository-internal change, not a UI rewrite.

## Domain models = Drift row classes (held even through Firestore sync)

The app still uses Drift's generated table row classes (`Task`, `Event`,
`FamilyMember`, `ShoppingList`, `ShoppingItem`) directly, with no
separate domain-model layer — the original design doc for this project
recommended separating domain models from persistence models
specifically *to support sync/conflict resolution*, on the assumption
that'd be worth the extra indirection once cloud sync was actually
built. In practice it wasn't needed: each `SyncAdapter`
(`lib/data/sync/adapters/`) maps a Drift row straight to its explicit
Firestore fields and back, so the row classes turned out to double as
adequate sync boundary objects on their own.

## Family identity and authentication (V2)

Three distinct identities, kept deliberately separate:

- **Firebase Auth** answers "who has access to this family" — one real
  account per adult (`FirebaseAuth` via `auth_repository.dart`).
- **`FamilyMember`** answers "who are they inside the family" — the local
  Drift row, same as always.
- **`activeMemberIdProvider`** answers "which profile is acting on this
  device right now" — a soft, local profile switcher, unrelated to auth.

Only adults get real accounts; children never sign in and keep
zero-friction local profile access. A `FamilyMember` links to its
Firebase account via the nullable `linkedUid` column
(`family_members_table.dart`); `FamilyProfile` carries `familyId` (a
stable id generated once, by whichever Owner/Adult links first) and
`ownerUid` (set only once the local **Owner** specifically links, so an
Adult linking first can't accidentally become the cloud owner).

An authenticated parent can still locally switch into a child's profile
on a shared device — that's `activeMemberIdProvider` doing its normal
job, and it keeps driving today's local permission checks
(`canPerform`/`FamilyRole` in `family_permissions.dart`) exactly as
before. **Rule to hold onto for the Firestore-sync work still ahead**:
`activeMemberIdProvider` may keep driving local UI/business permissions,
but must never be trusted for cloud/server authorization — that has to
come from the authenticated Firebase `uid` and cloud family-membership
records, not the local acting-profile picker.

**V1 → V2 migration guarantee**: signing in never recreates or
duplicates an existing local family. A fresh install with no local
family requires sign-in before the first `AddMemberScreen` save (which
sets `linkedUid`/`ownerUid`/`familyId` on that first Owner). An existing
V1 install opens exactly as before; from Settings, an adult can sign in
and, via `LinkMemberScreen`, claim one of the existing unlinked
Owner/Adult members instead of a new one being created.

**Auth alone doesn't move data across devices** — signing in only
identifies *who*, it doesn't fetch or merge any family data by itself.
Firestore sync (below) is what actually moves data, and only activates
once the local Owner specifically links (not merely once a `familyId`
exists — see "Firestore sync" § security rules for why).

## Firestore sync (V2 Family Cloud)

Once the local Owner links a Firebase account, `FamilyMembers`,
`FamilyProfile`, `Tasks`, `Events`, `ShoppingLists`, and `ShoppingItems`
sync to `families/{familyId}/...` in Firestore. Budget/Notes/
Responsibilities/SavingsGoals are still local-only. Drift stays the
source of truth throughout — the app reads/writes Drift exactly as
before; Firestore is a mirror kept in sync underneath, invisible to
every screen above the repository layer (per "Why local-first" and
"Domain models" above, this is exactly the seam those sections were
written to keep open).

**Schema**: every synced table has `updatedAt` (last-write-wins) and
`deletedAt` (a soft-delete tombstone — needed because "missing
remotely" is otherwise ambiguous between "never uploaded" and "was
deleted" once there are two persisted copies of the data). `deleteX`
repository methods soft-delete; every `watchX`/`getX` query filters
`deletedAt.isNull()` so the UI is unaffected. A `SyncOutbox` table is
the durable "this write still needs to reach Firestore" queue — every
repo mutation writes its outbox row in the same Drift transaction as
the entity change, so a write and its sync intent commit atomically.

**`SyncEngine`** (`lib/data/sync/sync_engine.dart`) owns:
- **Push**: repository-internal and explicit, the same pattern
  `NotificationService` already uses — `enqueueUpsert` queues, then a
  drain pushes via `.set()` with `updatedAt: FieldValue.serverTimestamp()`,
  reading the resolved server timestamp back into the local row afterward
  so both sides always compare the same server-assigned clock (raw
  device clocks would break last-write-wins under clock skew).
- **Pull**: a `.snapshots()` listener per collection, merging incoming
  changes only when newer and only when there's no matching outbox entry
  still in flight for that entity (so a racing snapshot never clobbers
  an optimistic local write mid-push).
- **Initial reconciliation**: a one-time pass (gated by
  `FamilyProfile.initialCloudMigrationCompletedAt`, set only once every
  collection succeeds) that diffs local vs. remote and pushes/pulls
  whichever side is missing or older. "Missing remotely" only ever
  means "upload me" during this one pass — never again afterward, which
  is what stops a row deleted on another device from resurrecting here
  on a later reconnect.
- **Outbox failure policy** (`lib/data/sync/outbox_failure_policy.dart`):
  transient errors retry with capped exponential backoff indefinitely;
  permanent errors (and unclassified ones after a few attempts) stop
  retrying and surface in Settings ("Cloud sync" card) with a manual
  retry action.
- **Lifecycle**: `RootScaffold` listens to `activeSyncFamilyIdProvider`
  (signed in + linked + Owner-confirmed) and calls `start`/`stop`
  accordingly — covering app boot while already linked, pause on
  sign-out, and resume on signing back into the same family. Always
  injected as a non-null `SyncEngine` (an inert no-op instance on
  desktop or in tests), same pattern as `NotificationService`.

**Security rules** (`firestore.rules`): `ownerUid`/`memberUids` on the
family doc are create-once, immutable authorization metadata — no
self-service join in this pass, since knowing a `familyId` isn't proof
of belonging to it. Ordinary content (tasks/events/lists/items) is
read/write for any member uid, matching today's local model of no
per-role cloud permissions. One Firestore-specific wrinkle: the family
doc must be addressed via `.doc()`, never an unconstrained
`.collection('families').get()/.snapshots()` — Firestore denies a
collection *query* whose rule depends on each result's own data (it
can't prove the rule holds for every document that collection could
ever contain), even though the identical rule works fine for a `get`/
listen on one specific, known document id. The five subcollections
don't have this problem — their rule is scoped by the already-known
`familyId` path segment, not by each result's own data.

**Known gap, closed by "Family invitations" below**: a second real adult,
on their own device with their own Firebase account, couldn't join an
existing family's cloud data — membership was create-only with no
invitation flow. Multi-device sync is still separately validated using
the same authenticated uid across multiple personal devices, which needs
no invitation system at all.

## Family invitations (a second real adult joining)

A short-lived, single-use code an existing member generates so a second
real adult, on their own device with their own Firebase account, can join
this family's cloud data — without ever mutating the family doc's
`ownerUid`/`memberUids` (those stay create-once immutable, per "Security
rules" above; teaching the join path to append to that array would have
meant re-opening exactly the invariant that section exists to protect).

**Data model** (`FamilyInviteRepository`, `lib/data/repositories/`) — pure
Firestore control-plane, no local Drift table, no `SyncAdapter`:
- `invites/{code}` — top-level, not nested under `families/{familyId}`,
  because a joining device has no local `familyId` at all yet; it only
  has the code, which carries `familyId` as a field once looked up.
  Fields: `familyId`, `createdByUid`, `expiresAt` (7 days, computed
  client-side — fine here even though `updatedAt`/last-write-wins
  elsewhere deliberately avoids client clocks, since a multi-day expiry
  window swallows any realistic clock skew), `usedByUid`/`usedAt` (both
  null until claimed). `expiresAt` is also bounded server-side (must be a
  real future timestamp, capped at 30 days — `firestore.rules`) — the
  7-day figure is only the app's own default, not itself enforced by the
  rules, so a client bypassing the app entirely can't mint a
  functionally-forever invite by sending an arbitrary `expiresAt`. The 7
  vs. 30 gap is deliberate slack, not a mismatch: `Settings`' invite
  dialog always displays the *actual* `expiresAt` an invite was created
  with (`FamilyInviteRepository.createInvite` returns it alongside the
  code), never a hardcoded "7 days", specifically so the two limits are
  free to diverge without the UI silently lying.
- `families/{familyId}/joinedUids/{uid}` — what actually grants access;
  doc id is the uid itself, so membership is a plain `exists()` check,
  not a query. `isFamilyMember(familyId)` (`firestore.rules`) now checks
  `uid in memberUids OR joinedUids/{uid} exists`, short-circuited so the
  common single-owner case still costs exactly one read.

**Flow**: generating an invite (Settings → "Invite a family member") is
one write. Claiming one (`JoinFamilyScreen` →
`FamilyInviteRepository.claimInvite`) is deliberately **two sequential
writes, not one atomic transaction**: first mark the invite used, then
create the `joinedUids` doc. A failure between them leaves a
claimed-but-ungranted invite — a wasted code, recoverable by generating a
new one — rather than a security gap, which is why that was chosen over
the complexity (and rules-`get()`-ordering assumptions) of making the two
writes atomic. That assumption — and the rest of this rules surface — is
now verified against the real Firestore Local Emulator Suite, not just
argued for in this doc comment: see "Testing" below.

**Local join** (`AddMemberScreen(isFirstMember: true, joinFamilyId: ...)`,
`FamilyProfileRepository.recordJoin`): the joining device sets its local
`familyId` to the *joined* family (never mints a new one, unlike
`recordLink`) and creates its own `FamilyMember` row with `linkedUid`
set — `ownerUid` is deliberately left null, since only the real Owner's
`recordLink` ever sets it. This is why `activeSyncFamilyIdProvider`
(`lib/data/providers.dart`) no longer gates purely on `ownerUid != null`:
a joiner's local `ownerUid` only ever arrives *through* sync pulling the
family doc down, so requiring it up front would deadlock — sync could
never start for them at all. It now also activates once the signed-in uid
matches a local member's own `linkedUid`, which is true for the Owner
immediately after `recordLink` and for a joiner immediately after this
local step. Once sync starts, the existing initial reconciliation pass
(see "Firestore sync" above) does the rest unmodified: this device's only
local data is its own new member, so everything else — the rest of the
family's members, tasks, events, lists — arrives exactly the way it
already does for any fresh reconciliation.

`recordJoin` stamps this local row's `updatedAt` far in the past (an
epoch sentinel), not "now" — a bug caught by review before this shipped:
stamping "now" made the local row look newer than the real family doc's
`updatedAt` (set once, back when the Owner created it), so
`SyncEngine`'s "apply only if remote is newer" check would never apply
the real `ownerUid` — it would've stayed null on the joiner's device
forever, quietly breaking the very invariant the previous paragraph
describes. `test/sync/sync_engine_test.dart` covers this directly.

## Testing

`test/widget_test.dart` overrides `databaseProvider` with
`AppDatabase.forTesting(NativeDatabase.memory())` — an in-memory Drift
database — so widget tests don't touch disk or need platform channels.
`AppDatabase` has a `forTesting(super.executor)` constructor specifically
for this. `test/sync/sync_engine_test.dart` layers `fake_cloud_firestore`
on top of the same in-memory Drift setup to exercise `SyncEngine`'s pull/
push/reconciliation logic without a real backend — but `fake_cloud_firestore`
doesn't enforce security rules at all, so it can't say anything about
whether `firestore.rules` itself is correct.

**Firestore security-rules tests** (`firestore_rules_test/`, its own
README has full instructions): a small Node subproject using
`@firebase/rules-unit-testing`, run against the real Firestore Local
Emulator Suite — not mocked, not the live `orgfamily-c40ae` project. This
is the only layer that actually exercises `firestore.rules`' rule
evaluation, and is what verifies the "Family invitations" design above:
34 tests covering `families/{familyId}` (create-once immutability, read/
write via either access path), `invites/{code}` (creation gated on
membership, single-use claiming, expiry, tamper-proofing), and
`families/{familyId}/joinedUids/{uid}` (the cross-document `get()` check
that ties a grant to an actually-claimed invite). Sanity-checked by
deliberately removing the single-use guard from `firestore.rules` and
confirming exactly one test failed — the one testing it — before
restoring it, so these aren't vacuously passing.

One non-obvious gotcha if this suite grows: Node's test runner runs
separate test *files* in parallel by default, and
`testEnv.clearFirestore()` wipes an entire emulator *project*, not just
whatever one file's own `testEnv` wrote — so every file must call
`createTestEnv()` with its own unique project-id suffix (see
`helpers.mjs`), or one file's `clearFirestore()` can wipe a document out
from under another file's still-in-flight test, surfacing as a confusing
rules-evaluation error (a `get()`/`exists()` mid-rule hitting a document
that just vanished) rather than an obvious "wrong data" failure.

**What's still not covered by anything above**: real device-level
behavior through the actual `cloud_firestore`/`firebase_auth` Flutter
plugins — two physical/emulated devices racing to claim the same invite,
`hasPendingWrites` timing, the live listener under real network
conditions. That needs an Android or iOS device/emulator driving the
actual app against this same Firestore emulator, which is a materially
bigger lift than the rules tests above (this is exactly why they were
built first) and isn't set up yet — see docs/roadmap.md.

## Roadmap-relevant seams already in place

- `Event`/`Task`/`ShoppingItem` all carry a `memberId`/`assigneeId`/
  `addedById` foreign key already, so a per-member activity feed (or
  future push notifications: "assigned to you") doesn't need a schema
  migration.

## Local notifications (V1.1)

`lib/core/notifications/notification_service.dart` wraps
`flutter_local_notifications` behind a plain class exposed via
`notificationServiceProvider`, injected into `TaskRepository`/
`EventRepository` the same way `AppDatabase` is — repositories schedule
and cancel reminders internally on add/update/complete/delete, so no
screen has to remember to do it. `NotificationService.init()` runs once
in `main.dart` before `runApp`. Tests substitute a `FakeNotificationService`
(see `test/fakes/`) rather than exercising the real plugin, since platform
notification channels aren't available under `flutter_test`.
