# TapTracker

Flutter (iOS/Android) credit card SOA tracker focused on the Philippine market.

## Included foundations

- Cubit-based state management (`flutter_bloc`)
- Secure settings/password vault (`flutter_secure_storage` + shared preferences)
- Local in-app repositories for cards, statements, transactions, reminders, and analytics
- Chart visualization for spending (`fl_chart`)
- Reminder scheduling scaffold (`flutter_local_notifications`)
- Feature tabs covering:
  - Onboarding/security
  - Statement ingestion and parse verification
  - Card profile management
  - Statement/transaction management
  - Analytics/insights
  - Payment reminders
  - Data management/export/settings

## Run

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter test
```
