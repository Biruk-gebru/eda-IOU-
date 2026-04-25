# EDA — Technical Reference

## Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3.x (Dart 3.8) |
| State management | Riverpod 2.x (`flutter_riverpod`, `riverpod_annotation`) |
| Backend | Supabase (PostgreSQL 17, Auth, Realtime) |
| Local cache | Hive 2 + `hive_flutter` |
| Design system | Forui 0.20 (neo-brutalist, token-based theming) |
| Notifications | `flutter_local_notifications` 18 |
| Charts | `fl_chart` |
| Fonts | Google Fonts (Inter, JetBrains Mono) |

---

## Architecture

Clean Architecture with three layers under `lib/src/`:

```
lib/src/
├── core/
│   ├── di/            # initializeDependencies() — Hive + Supabase bootstrap
│   ├── providers/     # connectivityProvider
│   ├── services/      # LocalNotificationService
│   └── utils/         # split_calculator, formatters
├── domain/
│   └── entities/      # Pure Dart data classes (fromJson / toJson)
├── data/
│   └── repositories/  # Supabase + Hive implementations
└── presentation/
    ├── app.dart        # MaterialApp + AuthGate
    ├── app_theme.dart  # FThemeData builder (light + dark)
    ├── controllers/    # AuthController
    ├── providers/      # Riverpod providers (FutureProvider, StreamProvider, StateProvider)
    └── screens/        # One folder per feature
```

Entry: `main.dart` → `initializeDependencies()` → `LocalNotificationService.init()` → `ProviderScope` → `MyApp` → `AuthGate` → `MainShell`.

---

## Environment Setup

```bash
cp .env.example .env
# Fill in:
# SUPABASE_URL=https://your-project.supabase.co
# SUPABASE_ANON_KEY=your-anon-key
# SUPABASE_REDIRECT_URL=com.example.eda://login-callback/
```

Required Supabase schema: see `SUPABASE_SETUP.md`.

---

## Build & Run

```bash
flutter pub get
flutter run

# Code generation (after editing any entity)
dart run build_runner build --delete-conflicting-outputs

# Watch mode during development
dart run build_runner watch --delete-conflicting-outputs

# Static analysis
flutter analyze

# Unit tests
flutter test
```

---

## Database Schema (key tables)

| Table | Purpose |
|-------|---------|
| `profiles` | Display name, bank account info, linked to `auth.users` |
| `groups` | Named expense groups with `join_mode` and `creator_id` |
| `group_members` | Join table: `status` (`pending`/`active`), `invited_by`, `role` |
| `transactions` | Expense records with `payer_id`, `total_amount`, `status` |
| `transaction_participants` | Per-user `amount_due` and approval state |
| `net_balances` | Pairwise running totals; `user_a < user_b` by UUID lexicographic order |
| `payment_requests` | Two-step pay: `payer_id` submits → `receiver_id` confirms |
| `settlement_requests` | Indirect payment routing (A → C to clear A→B + B→C) |
| `notifications` | In-app and push notification records with typed `payload` JSONB |

### net_balances convention
`net_amount > 0` → `user_a` owes `user_b`.  
`net_amount < 0` → `user_b` owes `user_a`.

---

## Key Patterns

**Offline-first:** All repository methods check connectivity, fall back to Hive cache, and write through on reconnect.

**Two-query group fetch:** `getGroups()` first fetches `group_members WHERE status='active'` for the current user's active group IDs, then fetches those groups directly with `.inFilter()`. This avoids a PostgREST FK-embedding RLS silent-failure bug where `groups(*)` embedding returns null when the groups SELECT policy can't see the row.

**Push notifications:** `LocalNotificationService` (static, `flutter_local_notifications`) initialises before `runApp`. `MainShell` listens to `notificationsProvider` via `ref.listen` and calls `show()` for any new unread notification ID not seen since app start. Enabled/disabled preference persisted in `flutter_secure_storage`. Tapping a system or in-app notification sets `shellTabProvider` to the appropriate tab.

**Group consent flow:** Inviting a user creates a `group_members` row with `status='pending'` and inserts a `notifications` row. The invitee sees an inbox in the Groups screen and can accept (sets `status='active'`, `joined_at`) or decline (deletes the row). The inviting user sees a `PENDING` badge on that member in the group detail view.

**Payment request RLS:** Both `payer_id = auth.uid()` and `receiver_id = auth.uid()` are allowed on INSERT, since either party may initiate (creditor requests payment; debtor marks as sent).

---

## Android

- `minSdk`: Flutter default (21)
- `compileSdk` / `targetSdk`: Flutter defaults
- Core library desugaring enabled (`isCoreLibraryDesugaringEnabled = true`, `com.android.tools:desugar_jdk_libs:2.1.4`) — required by `flutter_local_notifications` for `java.time` APIs on pre-API-26 devices.
- Deep link scheme: `com.example.eda://login-callback/` for OAuth redirect.
- Push permission: `POST_NOTIFICATIONS` declared in `AndroidManifest.xml`; runtime prompt handled by `LocalNotificationService.requestPermission()` on `MainShell` init.

---

## Commit Convention

```
feat:     new user-facing capability
fix:      bug fix
refactor: internal restructure, no behaviour change
test:     adding or updating tests
docs:     documentation only
chore:    tooling, dependencies, config
```

---

## Running Tests

```bash
flutter test                                    # all tests
flutter test test/core/split_calculator_test.dart
flutter test test/domain/entity_serialization_test.dart
```

Tests are pure Dart unit tests — no Supabase or platform channel mocks needed. Widget tests requiring platform plugins are skipped in CI.
