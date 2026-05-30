# EDA

**Split expenses. Track debts. Get paid back.**

EDA is a Flutter-based mobile app for tracking shared expenses and settling debts within friend groups, dorms, or households — built for the Ethiopian market with support for CBE, Telebirr, and Zemen bank verification.

<p align="center">
  <img src="https://img.shields.io/badge/version-1.2.0-blue" alt="Version" />
  <img src="https://img.shields.io/badge/platform-Android-3DDC84?logo=android" alt="Android" />
  <img src="https://img.shields.io/badge/built%20with-Flutter-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/backend-Supabase-3ECF8E?logo=supabase" alt="Supabase" />
</p>

---

## Features

### Expense splitting
Create an expense, add the people involved, and split it equally or by custom amounts. Everyone gets notified instantly. Balances update in real time across all devices.

### Group debt management
Organize recurring expenses into groups — rent, groceries, trips. Each group has a live **debt graph** that visualizes who owes whom with directed arrows and amounts. When a chain exists (Abel owes you, you owe Meron), EDA surfaces a **"Route It"** option: Abel pays Meron directly, two debts clear in one tap, and the graph animates the change.

### SMS-verified payments
When marking a payment as sent, EDA scans your SMS inbox for the matching bank transaction (CBE, Telebirr, or Zemen) and attaches the reference automatically. You pick the send time from a date picker with a 12-hour window, and each reference can only be used once — duplicates are rejected.

### Smart settlement routing
EDA uses BFS depth-2 routing to find indirect payment paths through your group. Instead of everyone paying everyone, debts are routed through intermediaries — fewer transfers, faster settlement, no money passing through middlemen.

### Real-time sync
All balances, payment statuses, and group memberships sync in real time via Supabase subscriptions. When someone confirms a payment on their phone, your balance updates immediately.

---

## Tech stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter (Dart) |
| Architecture | Clean Architecture (domain / data / presentation) |
| State management | Riverpod |
| Backend | Supabase (Auth, Postgres, Realtime, RPC) |
| Auth | Email/password, Google OAuth |
| Notifications | Local + push via `flutter_local_notifications` |
| SMS parsing | Regex-based parser for CBE, Telebirr, Zemen |
| UI style | Neo-brutalist with dark mode support |

---

## Project structure

```
lib/src/
  core/           — constants, DI, providers, services, utils
  data/           — remote datasources and repository implementations
  domain/         — entities and business logic
  presentation/
    controllers/  — UI controllers
    providers/    — Riverpod providers
    screens/      — auth, home, groups, personal, payments,
                    settlements, stats, settings, notifications
    widgets/      — debt graph, neo button, sparkline, skeleton loaders
```

---

## Getting started

### Prerequisites
- Flutter SDK (3.x+)
- Android Studio or VS Code with Flutter extension
- A Supabase project with Auth, Realtime, and RPC enabled

### Setup

```bash
git clone https://github.com/Biruk-gebru/eda-IOU-private.git
cd eda-IOU-private
```

Create a `.env` file in the project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

Then run:

```bash
flutter pub get
flutter run
```

---

## How it works

### Splitting an expense
1. Tap **New IOU**, add the people involved, enter the total, and choose equal or custom split.
2. Everyone gets notified. Balances update instantly.

### Settling a debt
1. Open **Personal**, find the person, and mark the payment as sent.
2. EDA scans your SMS for the matching bank transaction and attaches the reference.
3. The other person confirms receipt. Balance drops to zero.

### Routing through a group
1. Open the group's **Settle** tab — the debt graph shows all edges.
2. EDA highlights routing opportunities where indirect paths exist.
3. Tap **Route It** — both edges reduce by the routed amount atomically.

---

## Team

| Name | Role |
|------|------|
| **Binyamin** | UI/UX design, Supabase integration, frontend |
| **Biruk (Brook)** | Architecture, backend logic, features |
| **Henock** | Features and testing |

---

## License

MIT
