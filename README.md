# Budget Tracker

A mobile, offline-first personal budgeting app: manual expense/income
logging, category spending breakdowns, and 50/30/20 savings guidance.
No bank linking, no cloud sync — everything is stored locally on-device.

## Stack

- Flutter (iOS/Android)
- [drift](https://drift.simonbinder.eu/) over SQLite for local storage
- [flutter_riverpod](https://riverpod.dev/) for state management
- [fl_chart](https://pub.dev/packages/fl_chart) for the spending breakdown chart

## Structure

```
lib/
  app/            # app shell, routing, Riverpod providers
  core/           # constants (default categories, guidelines) and utils
  data/
    database/     # drift tables, DAOs, generated code
    repositories/ # thin wrappers around DAOs (id generation, etc.)
  domain/
    models/       # plain result types (SpendingSummary, etc.)
    services/     # pure business logic: breakdown + 50/30/20 recommendation
  features/       # one folder per screen/flow
  widgets/        # shared reusable widgets
```

`domain/services` has no database or widget dependencies, so the
spending-breakdown and savings-recommendation logic is unit tested
directly (see `test/domain/`).

## Development

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after editing drift tables
flutter test
flutter run
```

## Status

**Phase 1 (in progress):** manual transaction entry, categories,
spending dashboard, 50/30/20 recommendations.

**Phase 2 (not started):** camera-based receipt capture with on-device
OCR, merchant-to-category learning.

A `recurring_bills` table exists in the schema for a future recurring
bills feature, but there's no UI or due-date reminders for it yet.
