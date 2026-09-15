# OrgFamily — Architecture

## Stack

- **Flutter** (Material 3), **Riverpod** for state (`flutter_riverpod`,
  plain `Provider`/`StreamProvider` — no codegen).
- **Drift** (SQLite) as the local database — the source of truth for V1.
  `drift_flutter`'s `driftDatabase()` picks the right backend per
  platform automatically.
- **Firebase Auth** (V2) for per-adult sign-in — see "Family identity and
  authentication" below. No Firestore/cloud data sync yet; Drift is
  still the source of truth. See "Why local-first" below.

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

## Why local-first for V1 (no Firestore yet)

Deliberately deferred, following the same reasoning the original design
doc for this project argued for:

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

## Domain models = Drift row classes (for now)

V1 does *not* introduce a separate domain-model layer distinct from
Drift's generated table row classes (`Task`, `Event`, `FamilyMember`,
`ShoppingList`, `ShoppingItem`) — using them directly in the UI is a
deliberate simplification while the app is local-only. The original
design doc for this project recommended separating domain models from
persistence models specifically *to support sync/conflict resolution*;
that becomes worth the extra indirection when Phase 2 (cloud sync) is
actually being built, not before.

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

**Auth doesn't move data across devices yet.** Drift stays the local
source of truth this pass — signing in on a second device only
identifies *who*, it doesn't fetch or merge any family data there. That
starts with Firestore sync (next roadmap item), not this one.

## Testing

`test/widget_test.dart` overrides `databaseProvider` with
`AppDatabase.forTesting(NativeDatabase.memory())` — an in-memory Drift
database — so widget tests don't touch disk or need platform channels.
`AppDatabase` has a `forTesting(super.executor)` constructor specifically
for this.

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
