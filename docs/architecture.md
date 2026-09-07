# OrgFamily — Architecture

## Stack

- **Flutter** (Material 3), **Riverpod** for state (`flutter_riverpod`,
  plain `Provider`/`StreamProvider` — no codegen).
- **Drift** (SQLite) as the local database — the source of truth for V1.
  `drift_flutter`'s `driftDatabase()` picks the right backend per
  platform automatically.
- No Firebase / cloud yet. See "Why local-first" below.

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

## Family identity without auth

There's no login in V1. The **owner** role (or the first member added, if
no owner is set) is treated as "you" for the dashboard greeting and as
the default "added by" on new shopping items. This is a placeholder for
real auth in Phase 2, not a permissions system — every family member's
device currently sees the same local database.

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
