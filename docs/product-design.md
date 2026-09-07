# OrgFamily — Product Design

OrgFamily is a shared family organizer: one place for tasks, calendar, and
shopping lists that every family member sees and updates together. The
product thesis isn't "task manager" — it's shared family context: who
needs to do what, when, assigned to whom, and what's happening next.

## Core loop

Capture → Organize → Assign → Remind → Complete → Learn

## Navigation

Bottom nav: **Home · Tasks · Calendar · Lists · Family**, with a center
FAB for Quick Add sitting between Tasks and Calendar. Settings and About
still live behind the Home screen's drawer (hamburger icon); Family
member management moved from the drawer to its own tab (2026-09-01 —
originally a 4-tab bar with Family behind the drawer, revised to make
family member management equally discoverable as Tasks/Calendar/Lists).

## Home dashboard

The dashboard answers one question: *"What does my family need to know or
do today?"* Layout (see the reference mockup in this doc's history):

- Purple gradient header (wave-clipped bottom) with greeting, date, and a
  stats row (tasks today / events today / list count) floating on a card
  that overlaps the header.
- **Today's priorities** — up to 4 tasks due today, pending first, colored
  by priority; completed ones show a green check and strikethrough.
- **Upcoming events** and **[List name]** side by side — next 3 events,
  and pending items from the first shopping list.
- **Family activity** — a lightweight feed derived from recently
  completed tasks and recently added shopping items (no dedicated audit
  log table in V1 — see Architecture doc for why).

## Quick Add

One FAB, three destinations: Task, Event, Shopping item. Shopping item
adds directly to the first list (creating a default "Shopping" list if
none exists yet) via an inline dialog, since that's the highest-frequency
action.

## Data model (V1)

- **FamilyMember** — name, avatar emoji, color, role (owner/adult/child).
  The owner (or first member added) is treated as "you" for greetings.
- **Task** — title, description, due date, priority, category, assignee,
  completion, recurrence (stored but not yet auto-regenerated on
  completion — see Roadmap).
- **Event** — title, start/end, location, category, one assigned member.
- **ShoppingList / ShoppingItem** — a list has many items; items track
  who added them and purchased state.

## Deferred by design (not missing — deliberately out of V1)

- **Chores, points, rewards, habits, goals** — separate systems layered
  on top of Tasks later; adding them now would mean building reward logic
  before there's any evidence families want it.
- **Voice capture / Brain Dump / AI assistant** — needs a real NLU
  pipeline; V1 proves the manual data model is right before automating
  entry into it.
- **Family notes / important info vault** — needs a real security story
  (encryption at rest) before storing sensitive info; not a v1 concern.
- **Push notifications, daily briefing, evening summary** — no cloud
  backend yet to schedule/deliver them from.

See [roadmap.md](roadmap.md) for when these come back into scope, and
[architecture.md](architecture.md) for the technical reasoning behind the
local-first V1.
