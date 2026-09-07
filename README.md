# OrgFamily

A shared family organizer: tasks, calendar, and shopping lists that every
family member sees and updates together — built with Flutter.

## Features

- **Tasks** — assign to family members, set priority/category/due date,
  recurring tasks, quick-add with optional voice input
- **Calendar** — day view grouped by family member, category color-coding,
  search and filters
- **Shopping lists** — multiple lists with progress tracking
- **Family** — member profiles, weekly points, activity feed
- **Notes**, drawer-based navigation, light/dark theme, English + Arabic
  (with full RTL support)

## Status

V1 MVP — local-only (Drift/SQLite), no cloud sync yet. See
[docs/roadmap.md](docs/roadmap.md) for what's next and why cloud sync is
deliberately deferred to V2.

## Tech stack

- [Flutter](https://flutter.dev) / Dart
- [Riverpod](https://riverpod.dev) for state management
- [Drift](https://drift.simonbinder.eu) (SQLite) for local persistence
- [Lottie](https://pub.dev/packages/lottie) for empty-state animations
- `speech_to_text` for voice input

See [docs/architecture.md](docs/architecture.md) for the full breakdown and
design decisions.

## Docs

- [docs/product-design.md](docs/product-design.md) — feature scope and UI spec
- [docs/architecture.md](docs/architecture.md) — stack and design decisions
- [docs/roadmap.md](docs/roadmap.md) — phased plan

## Getting started

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerate Drift code after table changes
flutter run
```

### Running tests

```
flutter test
```

## Platforms

Primarily developed and tested for Android, with iOS, web, Windows, macOS,
and Linux scaffolding also present (via `flutter create`'s default
multi-platform support).
