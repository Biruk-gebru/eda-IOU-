# EDA — IoU Expense Tracker

A Flutter mobile app for tracking shared expenses, approvals, and payments between users. Groups and individuals can track who owes whom, approve transactions, and confirm payments.

## Stack

- **Frontend:** Flutter (Clean Architecture)
- **State management:** Riverpod
- **Backend:** Supabase (PostgreSQL + Auth + Realtime)
- **Local cache:** Hive
- **Design system:** Forui (monochromatic, Material 3)

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.x
- A Supabase project with the schema from `SUPABASE_SETUP.md`

### Environment Setup

Copy `.env.example` to `.env` and fill in your credentials:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_REDIRECT_URL=com.example.eda://login-callback/
```

### Run

```bash
flutter pub get
flutter run
```

### Code Generation (after editing Freezed models)

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Features

- Google OAuth + email/password authentication
- Onboarding: display name, Ethiopian bank account info
- Create and manage groups; add members by name search
- Create transactions with equal or custom splits
- Participant approval flow (majority vote, 48 h timeout)
- Pairwise net balance tracking (atomic Postgres RPC)
- Payment requests with two-step confirmation
- Settlement / redirect payment flow (A pays C to clear A→B and B→C)
- Real-time in-app notifications (Supabase Realtime)
- Offline support via Hive cache
- Dark and light mode

## Sprint Status

| Sprint | Description | Status |
|--------|-------------|--------|
| 0 | Scaffold, entities, Supabase wired, OAuth | ✅ Complete |
| 1 | All screens, repositories, Riverpod providers | ✅ Complete |
| 2 | Transaction create/vote/apply RPC | ✅ Complete |
| 3 | Net balance netting, personal tab | ✅ Complete |
| 4 | Payment requests + confirmation RPC | ✅ Complete |
| 5 | Settlement flow, notifications, polish | ✅ Complete |

## Project Structure

```
lib/src/
├── core/          # DI, Supabase config, connectivity
├── domain/        # Entities (Freezed), repository interfaces
├── data/          # Repository implementations, Supabase datasource
└── presentation/  # Screens, Riverpod providers, controllers, theme
```

## Key Conventions

- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`
- Currency: ETB (Ethiopian Birr)
- Timestamps: UTC stored, locale-displayed
- `net_balances` ordering: `user_a < user_b` (lexicographic UUID)
