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
- [ ] Firestore sync behind the existing repository interfaces —
      screens should need zero changes
- [ ] Family invitations, multi-device sync
- [ ] Firestore security rules keyed on `familyId` membership
- [ ] Conflict resolution policy (last-write-wins + `updatedAt`/`version`
      fields, per the original design doc)

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
  added later) — decided, see [architecture.md](architecture.md).
- **No `go_router`** — V1 navigation is a plain `IndexedStack` + bottom
  nav plus `Navigator.push` for forms; add routing only if deep-linking
  or web URL support becomes a real requirement.
- **No domain-model layer separate from Drift rows** — revisit when V2
  sync/conflict-resolution work starts.
