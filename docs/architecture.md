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
- **`actingMemberProvider`** answers "which profile is acting on this
  device right now" — who performed a family action
  (`createdByMemberId`, `completedByMemberId`, budget/goal authorship),
  who the greeting and drawer show, and whose role local permissions use.
  Unrelated to cloud authority.

Only adults get real accounts; children never sign in and keep
zero-friction local profile access. A `FamilyMember` links to its
Firebase account via the nullable `linkedUid` column
(`family_members_table.dart`); `FamilyProfile` carries `familyId` (a
stable id generated once, by whichever Owner/Adult links first) and
`ownerUid` (set only once the local **Owner** specifically links, so an
Adult linking first can't accidentally become the cloud owner).

**Resolving the acting member** (`family_providers.dart`):
`authenticatedMemberProvider` is the profile whose `linkedUid` is the
signed-in uid. `actingMemberProvider` is, in order: an explicit drawer
pick (`activeMemberIdProvider`) — honoured only while the account that
made it (`activeMemberPickUidProvider`, persisted alongside it) is still
signed in — then the authenticated member, then, only when signed out (a
local-only family or V1 data), the legacy Owner fallback. A signed-in
account with no linked profile is *unresolved*: no acting member, and
`activeRoleProvider` gives it the most restricted role, never the
Owner's. That Owner fallback used to apply to signed-in accounts too,
which is how an invited adult whose join never set an active profile
appeared as — and had the local permissions of — the family Owner, and
saved tasks with no creator. Joining (or creating the first Owner) now
sets the active profile explicitly, and resolving by `linkedUid` repairs
already-installed apps with no manual step.

An authenticated parent can still locally switch into a child's profile
on a shared device — that's the explicit pick doing its normal job, and
it keeps driving local permission checks (`canPerform`/`FamilyRole` in
`family_permissions.dart`). **Rule to hold onto**: the acting member may
drive local UI/business permissions and "who did this" fields, but must
never be trusted for cloud/server authorization — that comes from the
authenticated Firebase `uid` and cloud family-membership records. (V3's
paired child devices are where a child actor becomes server-verifiable.)

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
`FamilyProfile`, `Tasks`, `Events`, `ShoppingLists`, `ShoppingItems`
and `Responsibilities` sync to `families/{familyId}/...` in Firestore.
Budget/Notes/SavingsGoals are still local-only.

The one-time initial reconciliation is tracked **per collection**
(`FamilyProfile.reconciledEntityTypes`), so a collection that starts
syncing after the family first linked — Responsibilities, in schema 17 —
gets its own first pass (uploading what was only ever local) while
collections that finished theirs are never re-reconciled, which would
re-upload rows deleted elsewhere. A family that finished the original
all-at-once pass is treated as having reconciled every collection that
pass covered (`legacyReconciledEntityTypes`). Drift stays the
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
  device clocks would break last-write-wins under clock skew). Each
  outbox row records the account that made the change (`originUid`), and
  a drain only ever pushes rows made by the account syncing right now —
  see "Who may sync, and changes made while not syncing" below.
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
- **Listener recovery**: every listener has an `onError`. Firestore ends
  a listener's stream after an error, so the engine tears all of them
  down and reattaches them with backoff (5s → 15s → 1m → every 5m;
  immediately on app resume), and shows the error in the Cloud sync card
  until a snapshot arrives again. A `permission-denied` (from a listener
  or a push) also fires `SyncEngine.accessDenied`, which makes the app
  re-check membership with Firestore. Plain connectivity loss never
  errors a listener — Firestore keeps it alive offline and resumes it.
- **Lifecycle**: `RootScaffold` listens to `activeSyncProvider` (signed
  in as an account Firestore admits to this family — see below) and
  calls `start(familyId, uid)`/`stop` accordingly — covering app boot
  while already linked, pause on sign-out, and resume on signing back
  into the same family. It also keeps the engine told who is signed in
  (`setSignedInUid`), so changes made while not syncing still record
  their origin. Always
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
  elsewhere deliberately avoids client clocks, since the rules allow for
  skew, below), `usedByUid`/`usedAt` (both null until claimed), and an
  optional `inviterName` (the inviter's own member name, ≤80 chars) —
  the joiner can't read the family doc or its members before joining, so
  this is the only way the confirm step can say "Join Reem's family?".
  `keys().hasOnly` rejects any other field. **7 days is enforced
  server-side, not just the app's default**: `firestore.rules` requires
  `expiresAt` to be in the future and at most 7 days + 1 hour past
  `request.time` — the hour is clock-skew slack for a device running
  fast, not extra validity. `FamilyInviteRepository._validity` and that
  cap must change together. (The cap was originally a looser 30 days,
  which let a client bypassing the app mint month-long invites while the
  app said 7; tightened to match.) The invite screen still displays the
  `expiresAt` the invite was actually created with, never a hardcoded
  "7 days".
  Codes are 8 characters from a 32-symbol alphabet, displayed as
  `XXXX-XXXX`; `FamilyInviteRepository.normalizeCode` strips the dash
  (and case, spaces, anything non-alphanumeric) on the way back in.
  `list` is allowed only for a query filtered to
  `createdByUid == <caller>` — Settings → Invite → "Manage invites" shows
  (and can revoke) the caller's own invites; nobody can enumerate anyone
  else's.
- `families/{familyId}/joinedUids/{uid}` — what actually grants access;
  doc id is the uid itself, so membership is a plain `exists()` check,
  not a query. `isFamilyMember(familyId)` (`firestore.rules`) now checks
  `uid in memberUids OR joinedUids/{uid} exists`, short-circuited so the
  common single-owner case still costs exactly one read.

**Flow**: generating an invite (Settings → "Invite a family member" →
`InviteFamilyMemberScreen`) is one write. Joining is two screens:
`JoinFamilyScreen` only *looks the code up* and rejects unknown, used,
or expired ones; `JoinFamilyConfirmScreen` shows who invited you and
claims only when the joiner taps "Join family" — so a valid code for the
wrong family can still be backed out of before the irreversible,
single-use claim. Claiming (`FamilyInviteRepository.claimInvite`) is
deliberately **two sequential
writes, not one atomic transaction**: first mark the invite used, then
create the `joinedUids` doc. A failure between them leaves a
claimed-but-ungranted invite — a wasted code, recoverable by generating a
new one — rather than a security gap, which is why that was chosen over
the complexity (and rules-`get()`-ordering assumptions) of making the two
writes atomic. `claimInvite` is also safe to re-run for an invite the
same uid already claimed (backing out of profile setup, or retrying
after the second write failed): it skips the claim and writes the grant
only if it's missing, and `JoinFamilyScreen` lets a code through when
it's "used" by the caller themselves for exactly this reason. That
assumption — and the rest of this rules surface — is
now verified against the real Firestore Local Emulator Suite, not just
argued for in this doc comment: see "Testing" below.

**Local join** (`AddMemberScreen(isFirstMember: true, joinFamilyId: ...)`,
`FamilyProfileRepository.recordJoin`): the joining device sets its local
`familyId` to the *joined* family (never mints a new one, unlike
`recordLink`) and creates its own `FamilyMember` row with `linkedUid`
set — `ownerUid` is deliberately left null, since only the real Owner's
`recordLink` ever sets it, and a joiner's local `ownerUid` only ever
arrives *through* sync pulling the family doc down. `recordJoin` instead
records the joiner in `FamilyProfile.joinedUid`, which is what lets their
sync start before that (see "Who may sync" below). Once sync starts, the
existing initial reconciliation pass
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

### Who may sync, and changes made while not syncing

Firestore admits exactly two kinds of account to a family: its owner
(`ownerUid` on the family doc) and an account holding a
`joinedUids/{uid}` grant. `cloudAccessProvider` (`lib/data/providers.dart`)
mirrors that, and sync runs only for those accounts — signing in alone,
or having a local member linked to the account (`LinkMemberScreen` on a
device that already has the family), is not enough. That gap is what
let a second adult signing in on the owner's phone start a sync whose
every read and write was denied.

**Firestore is the authority; the device only caches it.** The owner is
trusted locally (`ownerUid` is immutable server-side). A joined member's
local `FamilyProfile.joinedUid` is a cache: honoured optimistically so
sync can start offline, but re-checked with Firestore every session and
after every `permission-denied` (`membershipVerificationProvider`, via
`CloudMembershipRepository.verify` — the family doc is readable exactly
when the caller is a member, so one read answers it). A "no" clears the
cache and stops sync, so a revoked grant (there's no revoke action in the
app yet; the console or Admin SDK can delete a `joinedUids` doc) takes
effect without the device ever uploading again. A "yes" with no local
record (a join from before the record existed) records one. A
non-member sees "Not syncing this family" in Settings, with an Enter
code action; claiming an invite for the family already on the device
just records the grant (no duplicate profile), and a code for a
*different* family is refused before it's spent.

**Changes made while not syncing are kept, not uploaded blindly.** While
the device's family is in the cloud but this device isn't syncing as a
member (signed out, or signed in as a non-member), `enqueueUpsert` still
queues every change — as `SyncOutboxStatus.held`, tagged with whoever
was signed in (`originUid`, null if nobody). Held rows never drain on
their own. Nor does a row queued under a different account than the one
syncing now: signing in never makes someone else's changes upload under
your account. Both kinds show in Settings as "N changes to review".

Reviewing never uploads blindly. A push is a plain `.set()`, so
uploading a days-old held change would overwrite whatever newer
information the family has stored since. `SyncEngine.inspectReview`
first reads each entity's live cloud version (from the server, never the
cache — offline, the review can't proceed) and classifies it: not in the
cloud yet, changed here after the cloud version, **the cloud has a newer
version**, already in sync, or gone from this phone (a sub-second
difference counts as in sync, so device clock skew doesn't decide). Per
entity, the member picks **Upload** (take it on as their own; it drains
normally), **Use cloud** (the cloud version replaces this phone's copy),
or **Phone only** (dropped from the queue; the edit stays in the local
database). The defaults only upload what can't overwrite newer
information — anything the cloud has a newer version of defaults to the
cloud version. "Keep all on this phone" needs no cloud check, so it works
offline. Until resolved, the rows also keep incoming remote updates from
overwriting those local edits.
Rows queued before origins were recorded (schema v16) have no
attributable origin, so the migration holds all of them for review.

### New devices

Membership belongs to the account, not the device. While syncing,
`SyncEngine` keeps `users/{uid}` = `{familyId}`; the rules let an account
read only its own record and write it only naming a family it's
currently a member of, so it can't point at someone else's family and a
revoked member can't refresh it. It only names the family — reading the
family still goes through the membership rules. After sign-in on a
device with no local family, `SignInScreen` looks that record up and, if
found, `FamilyProfileRepository.recordRestore` points the device at the
family (as owner or joined member, matching the family doc) and starts
sync, whose initial reconciliation downloads everything. No invite is
needed, and onboarding never offers to create a duplicate family while
the download is in flight. A failed lookup is shown with a retry rather
than treated as "no family".

## Money backup (V2)

Money (transactions, category limits, budget settings, savings goals)
stays **local-only** — Drift is its only source of truth and it is not
synced. It is instead *backed up*: `MoneyBackupCodec` turns the source
tables into a versioned, gzipped, AES-256-GCM-encrypted snapshot, and
`MoneyBackupRepository` stores it as Firestore `Bytes` chunks behind an
`uploading` → `complete` manifest, Owner-only (see `firestore.rules`).
Restoring replaces this device's Money tables in one transaction, after
downloading, checksumming, decrypting and validating the whole backup
and saving a safety backup of the current data first. `MoneyAutoBackup`
runs from `RootScaffold` on the Owner's phone at most daily, skipping the
upload when the content hash is unchanged. Key handling is a documented
temporary trade-off — see docs/roadmap.md "Money backup".

## Family activity log (V2.1)

`FamilyActivities` (Drift) mirrors `families/{familyId}/activities`. The
repositories record an entry through `ActivityLog` **inside the same
transaction** as the change it describes (task created/assigned/
completed, event created/changed/cancelled, shopping item added/bought/
removed, member joined, responsibility done), so the entry and the change
commit together and the entry's id is fixed then — a retry re-sends the
same document. `RootScaffold` keeps the log's actor current: the signed-in
`actorUid` (verified by the rules) and the acting member (`actorMemberId`,
"on behalf of" data until children have accounts). A recurring task's
next occurrence isn't logged — it's not a family action.

- **Order**: `occurredAt` is a server timestamp, set on the first upload
  and read back by the engine's normal post-push read; the rules require
  `occurredAt == request.time` on create and allow nothing but an
  unchanged re-send afterwards — no rewrite, re-timing or delete. An entry
  with no server time yet is checked for in the cloud before it's sent,
  so a retry whose first attempt landed reads it back instead.
- **Once-only completions**: a task occurrence has at most one
  `task.completed` entry (id `task.completed:<taskId>`; each recurring
  occurrence is its own task), a responsibility at most one
  `responsibility.completed` per local day (id
  `responsibility.completed:<id>:<yyyy-MM-dd>`). Untick and re-tick finds
  the id already on the phone and records nothing. Two phones recording
  it before syncing write the same document: the later upload finds it
  stored (checked before sending) and adopts it — or, uploading at the
  same instant, is refused by the rules and adopts it then — so no
  duplicate and no failed row. Other entries keep random ids.
- **Read-back race** (all entities): an upload's read-back isn't applied
  if the entity changed locally again while it was in flight — it would
  overwrite the newer change (e.g. resurrect something deleted right
  after being added); the newer change's own upload follows.
- **Authorship and linkage** (rules): `actorUid` is the writer;
  `actorMemberId` is null, the writer's own member, or an account-less
  member (a child on a shared phone) — never an adult linked to another
  account. The entry must be a supported type describing an existing
  entity of the matching kind. The entity's *state* (e.g. completed) is
  deliberately not checked: any member can already write that state
  directly, and an offline complete-then-undo would get a genuine entry
  rejected for good. V3's child/device entries need a rules change (not
  a schema change).
- **Upload order**: the engine drains the outbox in queue order and
  holds an entry back while a change queued before it — its entity, or
  its acting member — hasn't uploaded yet, so a failed or retrying change
  never gets its entry rejected; both go once the change does.
- **Window**: `ActivitySyncAdapter` is a `WindowedSyncAdapter`, so the
  engine listens to and reconciles only the last 30 days of the
  collection rather than the whole, ever-growing history.
- **Review**: an entry made while not syncing is held like any other
  change, but never listed on its own — `resolveReview` applies the
  decision on the entity it describes to it (upload together; keep both
  on the phone; or drop it when the cloud version wins). An uploaded
  entry made under another account is re-credited to the uploader's uid
  (the rules only accept an entry from the account it names).
  Reconciling a collection for the first time also skips changes that
  are awaiting review, rather than uploading them behind the review.
- **Forward compatibility**: `type`/`entityType` are open strings and
  readers skip types they don't know, so V3's child entries (`actorKind:
  child`, `actorDeviceId`, `state`, `relatedActivityId`) need neither a
  schema nor a rules change. Entity types use `SyncEntityType` names.
- **UI**: `familyActivityProvider(days)` merges the log with history
  derived from completed tasks and added items, skipping any the log
  already has for that same task or item. Sentences carry the member's
  name as a placeholder, so Arabic can use neutral passive phrasing
  ("تم إكمال مهمة … بواسطة مريم") that fits every member without a
  gender field. The Home card and Family screen show the latest four;
  `FamilyActivityScreen` has the weekly summary, member/type filters, day
  groups and "Show older activity".

## Settings and preferences (V2.2)

- **Per phone** (`AppPreferences`, SharedPreferences): theme, language,
  start tab, time format, and reminder choices keyed by member
  (`reminders.<memberId>.*`). Reminders belong to the phone's own person
  (`reminderOwnerProvider`: the signed-in account's own profile, or the
  Owner's in an all-local family) — **never the acting profile**, so
  switching into a child's profile neither schedules nor cancels anything.
  Loaded in `main()` before `runApp`, so the first frame already has the
  saved theme/language. The start tab is read once in
  `RootScaffold.initState` (rebuilds never reset navigation); Money falls
  back to Home for a profile that can't see it without touching the saved
  choice. The time format drives `MediaQuery.alwaysUse24HourFormat` (time
  pickers) and every formatted time (`formatTime`, `TimeFormatting`).
- **Reminders**: the task default only pre-fills *new* tasks
  (`defaultTaskReminder`; date-only tasks keep the 9 AM on-the-day
  reminder). The event offset re-arms this phone's notifications
  (`EventRepository.resyncReminders`); shared events never change. The
  daily responsibilities reminder (`DailyResponsibilityReminders`) is a
  rolling 7-day plan in fixed per-date slots — today names what's left,
  later days use generic text; every plan cancels all slots first, so an
  account/profile switch leaves nothing of the previous person's. Re-planned
  on any input change (`dailyReminderInputsProvider`), on resume and start.
- **Family schedule** (shared, Owner-only): `FamilySettings` →
  `families/{id}/settings/{id}`, its own document (older builds overwrite
  the family doc with a full `set()`). No row/document = defaults
  (Sun–Thu school days, week starts Sunday) and nothing is uploaded until
  the Owner saves; a pending local edit is never overwritten by the cloud
  copy (listener and first reconciliation both check). The Owner check is
  the signed-in account (`ownerUid`), never the acting profile. A queued
  settings change from another account (Owner edits offline, signs out,
  someone else signs in) is excluded from review and "keep on this phone"
  (`SyncEngine._needsReview`) — it waits, untouched, and uploads when the
  Owner's account syncs again. School days
  decide when "School days" chores are due; the week start drives the
  calendar's first column, "this week" stats and the activity summary; the
  calendar's weekend shading is unchanged.

## Drawer screens (V2.3)

**My reminders** (`lib/features/reminders/`) lists what this phone will
notify for, computed — not read back from the plugin — by
`planPhoneReminders` from the same rules that schedule them:
`taskNotificationAt` (used by `TaskRepository`), `eventNotificationAt`
(used by `NotificationService.scheduleEventReminder`) and
`planDailyResponsibilityReminders`, over the same records (every phone
schedules every family task and event). A test compares the list with what
the scheduler actually scheduled. **Mine** is `reminderOwnerProvider`'s —
the signed-in adult's linked profile, never the acting one — plus
unassigned tasks and events with no members (whole-family); **Everyone** is
all of them. Each notification is keyed by entity (or daily slot), so it
appears once. `NotificationService.notificationsEnabled()` drives the
"notifications are off" warning (Android `areNotificationsEnabled`, iOS
`checkPermissions`; null elsewhere = no warning).

**Family insights** (`lib/features/family/insights/`) counts, over the
Family Activity items (log plus history derived from tasks/shopping):
distinct tasks completed, distinct responsibility-and-day completions,
distinct shopping items added and bought, and event entries
(created/changed/cancelled). Repeats — legacy random ids, a log entry and
its derived twin, two phones — count once, credited to the first. Member
bars count only tasks and responsibilities. A period is compared with the
same stretch of the previous one ("so far"), and only if this phone's
earliest log entry is no later than the previous period's start;
otherwise "Not enough history" — the log began with V2.1 and a phone that
joined later only received 30 days. No money.

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
