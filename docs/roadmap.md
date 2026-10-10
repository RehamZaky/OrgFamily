# OrgFamily — Roadmap

Condensed from the original full product concept. Each phase should ship
as a coherent, testable release — not a partial cross-section of many
features at once.

## V1 — MVP (this build)

Local-only, single shared database, no auth.

- [x] Family members (create, avatar/color/role, "who am I" = owner) —
      avatar can now be a photo (camera/gallery) or an emoji; also carries
      optional birthday, grade, school, notes
- [x] Family points — a lightweight scoring layer (5/10/15/20 pts by task
      priority) computed from completed tasks per member, reset weekly.
      Derived from task completion only — chores (below) don't feed into
      it, on purpose (see the 2026-09-01 note there).
- [x] Responsibilities (chores) — per-member recurring items (daily /
      school days / custom weekdays) with a "done today" checkbox
      (`Responsibility.lastCompletedDate`, no per-occurrence log table).
      Built 2026-09-01 when scoping the Member Profile screen — this is
      the "chores" half of the "chores + points/rewards" V3+ item below;
      deliberately kept separate from Tasks/points rather than merged,
      since merging them wasn't asked for and would've coupled two
      independent systems. Reward redemption, chore-completion points,
      and a rewards store are still not built.
- [x] Tasks — create/edit/delete, assign, due date, priority, category,
      recurrence field (stored, not yet auto-regenerating)
- [x] Calendar — events with category, assignee, month view + day list
- [x] Shopping — multiple lists, items, purchased toggle
- [x] Home dashboard — today's priorities, upcoming events, primary
      list preview, derived activity feed
- [x] Quick Add (Task / Event / Shopping item)

## V1.1 — Usability

- [x] Notifications for due tasks / upcoming events — local-only via
      `flutter_local_notifications` (`lib/core/notifications/notification_service.dart`),
      no backend involved. Tasks notify at `dueDate`, events 15 minutes
      before `startAt`; scheduled/cancelled from `TaskRepository`/
      `EventRepository` on every add/update/complete/delete so it's
      covered regardless of which screen triggered the change. Android
      uses `inexactAllowWhileIdle` scheduling deliberately, to avoid the
      exact-alarm permission dance for what's a reminder, not an alarm
      clock. Notification firing itself needs manual on-device
      verification — not something a headless test can confirm.
- [x] Recurring tasks actually regenerate their next occurrence on
      completion — `TaskRepository.setCompleted` inserts a new pending
      task on the next daily/weekly/monthly date when a recurring task
      is completed; the completed row stays as history (unaffected point
      scoring). No schema change, per the seam already noted in
      architecture.md.
- [x] Search/filter on Tasks and Calendar — client-side filtering over
      the existing streamed lists (title/description substring search,
      category and assignee/member filters via bottom sheets).
- [x] Edit/delete flows for events (currently create-only) — event
      repository already had `updateEvent`/`deleteEvent`; this was the
      UI wiring (`EventFormScreen` now takes an `existing` event,
      `CalendarScreen` event tiles are tap-to-edit and swipe-to-delete),
      mirroring the existing Task edit/delete pattern.

## V2 — Family Cloud

The point where Firebase actually earns its place.

- [x] Auth (per-member sign-in, not just a local "owner" role) — email/
      password + Google sign-in for adults, wired end-to-end
      (`auth_repository.dart`, `SignInScreen`, `LinkMemberScreen`); a
      `FamilyMember` links to its Firebase account via `linkedUid`,
      `FamilyProfile` carries `familyId`/`ownerUid` (see
      [architecture.md](architecture.md)'s "Family identity and
      authentication"). Children never sign in, by design. Real app id
      (`com.orgfamily.app`) registered for both Android and iOS in the
      `orgfamily-c40ae` Firebase project via `flutterfire configure`,
      debug SHA-1 already attached for Google Sign-In on Android. Web
      deliberately excluded (`isFirebaseAuthSupportedPlatform`) — no
      product need for it. Still needs, before it's live in the field:
      the Email/Password + Google providers turned on under
      Authentication in the Firebase console (console-only toggle,
      nothing to configure in code for it).
- [x] Firestore sync behind the existing repository interfaces — screens
      needed zero changes, per plan. FamilyMembers/FamilyProfile/Tasks/
      Events/ShoppingLists/ShoppingItems/Responsibilities sync to
      `families/{familyId}/...` once the local Owner links (Responsibilities
      added 2026-10-06); Budget/Notes/SavingsGoals stay local-only (own
      future pass). See
      [architecture.md](architecture.md)'s "Firestore sync" for the full
      design — `SyncEngine`, the `SyncOutbox` durable push queue, the
      outbox failure/backoff policy, and the lifecycle wiring
      (`RootScaffold` starts/stops it on sign-in/link/sign-out). Verified
      end-to-end on a real device against the live `orgfamily-c40ae`
      Firestore project: family/member/task/event docs all synced
      correctly under the deployed security rules.
- [x] Firestore security rules keyed on `familyId` membership —
      `firestore.rules`, deployed. `ownerUid`/`memberUids` are
      create-once, immutable authorization metadata (no self-service
      join); ordinary content is read/write for any member uid, matching
      today's local no-per-role-cloud-permissions model.
- [x] Conflict resolution policy — last-write-wins on `updatedAt`
      (resolved to a Firestore server timestamp after each push, not the
      raw device clock, to avoid clock-skew bugs), plus a `deletedAt`
      soft-delete tombstone so a remote deletion can't be mistaken for
      "never uploaded" and resurrected by a later device's reconciliation
      pass.
- [x] Family invitations, multi-device sync for a *second* real adult —
      a short-lived, single-use code (top-level `invites/{code}` in
      Firestore) an existing member generates and a second adult, on
      their own fresh device with their own Firebase account, claims via
      the new `JoinFamilyScreen` (reachable from onboarding's "Join an
      existing family instead"). Claiming grants access via a
      `families/{familyId}/joinedUids/{uid}` doc rather than ever
      mutating the family doc's own create-once-immutable
      `ownerUid`/`memberUids` — see architecture.md's new "Family
      invitations" section for the full design, including why claiming
      is two sequential writes rather than one atomic transaction, and
      why `activeSyncFamilyIdProvider`'s activation gate had to change
      (a joiner never gets a local `ownerUid`) to make this possible at
      all. The security-rule surface for this flow is now verified
      against the real Firestore Local Emulator Suite (not mocked) — see
      `firestore_rules_test/` — 52 passing cases (originally 37) covering create/claim/
      expiry/single-use/tamper-proofing for `invites/{code}` and
      `joinedUids/{uid}` (including a server-side bound on `expiresAt`
      itself, added after review — the rules originally trusted the
      client's "7 days" entirely, so a request bypassing the app could
      have minted a functionally-forever invite). A pre-commit review
      pass also caught and fixed a real last-write-wins inversion in
      `recordJoin` (it stamped "now" instead of an epoch sentinel, so a
      joiner's `ownerUid` could never sync down from the real, older
      family doc — see architecture.md's "Family invitations" §"Local
      join" and the regression test in `sync_engine_test.dart`). What's
      *not* yet verified: real device-level
      races (two Android/iOS devices actually claiming the same code at
      once, `hasPendingWrites`/listener timing through the real
      `cloud_firestore` plugin) — see the next item.
- [x] Firebase-emulator-based tests for the sync engine's security rules
      — `firestore_rules_test/` (a small Node subproject using
      `@firebase/rules-unit-testing`, documented in its own README) runs
      52 rules-level tests (originally 37) against the real emulator, covering exactly
      the multi-document, rules-dependent behavior unit tests and
      `fake_cloud_firestore` can't exercise: single-use invite claiming,
      expiry, tamper-proofing, and the `joinedUids` grant's cross-document
      `get()` check. Sanity-checked by deliberately breaking the
      single-use guard in `firestore.rules` and confirming exactly one
      test failed (the one testing it) before restoring it.
      **Still open**: this only covers rules, not the Flutter/plugin
      side — see the next item.
- [ ] Device-level integration tests for the sync engine (multi-device
      scenarios through the real `cloud_firestore`/`firebase_auth`
      plugins, tombstone-doesn't-resurrect, two real devices racing an
      invite claim) — blocked on having an Android/iOS device or emulator
      available at all (`flutter devices` currently shows only Windows
      desktop and browsers, both platforms this app deliberately excludes
      from Firebase — see `isFirebaseAuthSupportedPlatform`). Current
      coverage without one: unit tests for the pure outbox failure/backoff
      logic (`test/sync/outbox_failure_policy_test.dart`), `SyncEngine`
      logic tests against `fake_cloud_firestore` (not real rules —
      `test/sync/sync_engine_test.dart`), the rules-level emulator tests
      above, and manual on-device verification for the original sync
      engine (not yet repeated for invitations).

- [x] **Money backup** (built 2026-10-06; Money itself stays
      local-only, deliberately — **backup is not sync**). Encrypted,
      versioned snapshots of the Money source tables (transactions,
      category limits, budget settings, savings goals — never derived
      totals) for disaster recovery: a new or reset phone can get its
      Money records back. Design (see `lib/data/backup/`):
  - Stored as Firestore `Bytes` chunks (~600 KB) under
    `families/{id}/moneyBackups/{backupId}` — Cloud Storage would be the
    natural home, but it requires the paid Blaze plan since 2026-02-03;
    the manifest/chunk split lets the bytes move there later without
    changing the format or the app's screens.
  - Pipeline: snapshot → versioned JSON (`formatVersion`) → gzip →
    AES-256-GCM → chunks → verify → manifest `status: complete`. Only
    complete backups are ever listed or restorable; abandoned uploads are
    cleaned up. A SHA-256 checksum is verified before decrypting.
  - Owner only — create, read, restore, delete — enforced by
    `firestore.rules` (Adults and children can't even read the
    ciphertext). Retention: automatic current + previous (made at most
    daily, only when Money changed), up to 3 manual, plus one pre-restore
    safety backup so a wrong restore can be undone.
  - **Temporary V2 security trade-off**: the family's random AES key is
    stored raw in an Owner-only Firestore document, so the Owner can
    restore on any new phone. That protects the backup bytes, but not
    against Firebase project-owner access. Wrapping the key inside
    Firestore wouldn't change that (the unwrapping key would have to be
    there too); real separation needs an Owner passphrase or a
    server-side KMS (Blaze). `encryptionVersion`/`keyVersion` are
    recorded per backup so that upgrade can come later.
- [ ] **Family Money Cloud (V2.x/V3, its own phase)**: live multi-device
      Money sync — conflict handling, transaction ownership, financial
      permissions, concurrent edits, transfer integrity, audit history.
      Deliberately separate from backup.

## V2.1 — Family communication

- [ ] Activity feed backed by a real audit log (replacing the derived
      "recent completions/additions" heuristic in V1)
- [ ] Comments/reactions on tasks and events

## V3+ — Everything else from the original concept

Deliberately not scoped in detail yet: family finance/expenses,
documents & important-info vault, points/rewards *redemption* (V1 now
has both the points stat and a real recurring-chores system, see
above — what's still missing is a rewards store and manually-awarded
points), habits, family goals, voice capture / Brain Dump, AI
assistant, daily briefing/evening summary, push notification tuning,
subscription/entitlement system, search infra (Algolia/Meilisearch),
data export, account deletion flow. Each needs its own scoping pass
when its turn comes — see the original concept conversation for the
full feature catalog per phase.

**Per-member permissions** (view/edit access gated per family member —
e.g. "can view money," "can edit family settings"): out of scope for
V1, and directly conflicts with the current architecture (see
[architecture.md](architecture.md)'s "Family identity without auth" —
V1 has no permissions system, every device sees the same database).
Also depends on the Finance/expenses feature above, which doesn't
exist yet either. Came up when scoping the Add Member screen redesign
(2026-09-01) and was deliberately left out rather than half-built.

**Responsibilities (chores) — staged plan** (agreed 2026-10-05). Kept
deliberately separate from Tasks, never converted into recurring tasks:
a *task* has a deadline, reminders, overdue state and completion
history ("finish science homework by 7 PM"); a *responsibility* is a
recurring everyday expectation that's simply done today or not ("make
your bed").
  - **V2 (in progress)**: sync through Firestore
    (`families/{id}/responsibilities`); enforce the schedule (school
    days = Sunday–Thursday; Today/Home show only what's due today, the
    member's profile shows "Next: Monday" on off-days); permissions
    (Owner/Adult create, edit, reassign and delete; a Child can tick
    only their own "done today"); delete confirmation; localized
    strings; "My responsibilities" on Home, visually distinct from
    "My tasks". Edit/reassign has its permission but no UI yet.
  - **V2.1**: completions become Family Activity events ("Mariam
    completed Feed the cat" — `entityType: responsibility` in the V2.1
    activity schema); an optional **single daily reminder** per member
    at a chosen time ("You have 3 responsibilities today 💜 Feed the
    cat, make your bed +1 more") — never one notification per chore.
  - **V3**: completion **history** — per-occurrence completion records
    instead of only `lastCompletedDate`, which can't answer "6 of 7
    days this week" — enabling weekly progress, points, streaks,
    parental approval where appropriate, rewards, and child-device
    behavior.

**Smart organization** (part of Brain Dump / AI assistant): free-text
capture that auto-routes to the right entity instead of requiring the
user to pick Task/Event/Shopping item up front —
  - a date phrase ("next Tuesday") → Calendar event
  - a family member's name ("Ahmed needs to...") → Task assigned to
    that member
  - a shopping-style phrase ("we need milk") → Shopping item
  - a reminder phrase ("remind me tomorrow") → Reminder

  Two implementation paths were discussed when this was scoped
  (2026-09-01): a **local heuristic parser** (regex/keyword date
  matching, name-matching against existing family members,
  shopping-noun detection, "remind me" phrasing — no cloud call,
  fits V1's local-first constraint) vs. the **full NLU/LLM pipeline**
  from the original concept (needs a cloud call, breaks local-first).
  Decision deferred — not yet built either way.

## Explicitly deferred infra decisions

- **Local-first architecture** (Drift as source of truth, sync layer
  added later) — decided, see [architecture.md](architecture.md); the
  sync layer landed in V2 without disturbing this (Firestore is a mirror
  underneath the repository layer, not a replacement for Drift).
- **No `go_router`** — V1 navigation is a plain `IndexedStack` + bottom
  nav plus `Navigator.push` for forms; add routing only if deep-linking
  or web URL support becomes a real requirement.
- **No domain-model layer separate from Drift rows** — held even through
  V2 sync: each `SyncAdapter` maps a Drift row directly to its Firestore
  fields, no separate domain-model layer needed to support it after all.
