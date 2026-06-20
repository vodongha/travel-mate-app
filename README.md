# TravelMate — App (Android + Web)

[![Flutter](https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20Web-success)](https://flutter.dev/multi-platform)

The Flutter client for **[travel-mate](https://github.com/vodongha/travel-mate)** — a group-trip
planning & shared-expense manager. It runs on **Android and Web** from one codebase (not Android-only
like family-budget-app), with a **modern, responsive UI** on every screen size. The app talks to the
Spring Boot + Oracle ADB backend over its REST API: plan a trip, see the timeline, track budget vs
actual spending, manage the shared fund, and view who-owes-whom settlement.

> Backend lives in a separate repo: **[vodongha/travel-mate](https://github.com/vodongha/travel-mate)**.
> This repo is the mobile frontend only — the server is the source of truth (especially for money).

> **Status:** **M9 in progress** — the Flutter project exists for **Android + Web**. Done: the core
> layer (Dio + auth/refresh interceptor, secure token storage, go_router guard, Material 3 theme,
> en/vi localization) and the first slices — **auth** (login/register) and **trips** (list / create /
> detail). More feature screens land in follow-up slices. The backend (M1–M8) is complete.

---

## Planned features

| Area | What it does |
|---|---|
| **Auth** | Email/password + **Sign in with Google** → JWT (access + refresh). Email verify & password reset. Token in the OS secure store, auto-resumed on launch. |
| **Trips** | Create/join trips (link or QR invite), roles `OWNER`/`EDITOR`/`VIEWER`. Split with **ghost members** who don't have the app. |
| **Timeline** | Events, transport, accommodation on a per-trip timeline; places on an **OpenStreetMap** map (`flutter_map`). |
| **Checklist** | Per-trip to-dos with optional assignee. |
| **Budget vs actual** | Planned budget per category vs real expenses; multi-currency with snapshot rates. |
| **Expenses & split** | Add an expense in any currency; split `EQUAL`/`EXACT`/`PERCENT`/`SHARES`. |
| **Shared fund** | Contributions + fund expenses; derived fund balance. |
| **Settlement** | Per-member net balance + minimised who-owes-whom transaction list. |
| **Dashboard & report** | Countdown, budget/fund summary, next event; end-of-trip report. |
| **Notifications** | Push reminders (pre-trip 30/7/1 days, event/check-in, debt) via FCM. |
| **Localization** | English + Tiếng Việt, follows the device language. |

---

## Money rule

Amounts are **`BigDecimal`-precise on the backend**; the app only ever *formats* money, never does
balance arithmetic. Settlement, fund balance and all converted totals are **derived on the backend**.
Direction comes from the expense data, not a sign in the UI.

---

## QR codes — stored as strings, not images

Ticket/booking QR codes are handled as **strings**: scan with `mobile_scanner` → send the **decoded
string** to the backend → on view, **regenerate the QR client-side** with `qr_flutter`. The server
never stores a QR image (backend SPEC §2.7). Trip invitations work the same way — the backend returns
an invite link string the app renders as a QR.

---

## Tech stack (planned — mirrors family-budget-app)

| Concern | Choice |
|---|---|
| Framework | Flutter (Material 3, modern responsive UI) — **Android + Web** |
| State | Riverpod (`AsyncNotifier`) — one controller per feature |
| HTTP | Dio (one configured client + bearer-token interceptor) |
| Routing | go_router (auth-aware redirect guard) |
| Secure storage | flutter_secure_storage (Keychain / Keystore) |
| Maps | `flutter_map` (OpenStreetMap tiles) |
| QR | `qr_flutter` (render from string) + `mobile_scanner` (scan → string) |
| Push | `firebase_messaging` (FCM) |
| Localization | flutter_localizations + ARB (`lib/l10n`) |
| Auth | google_sign_in |
| Formatting | intl |

---

## Architecture (planned)

A layered slice per feature, mirroring the backend's `controller → service → repository`:

```
presentation (widgets) → application (Riverpod controllers) → data (repositories) → Dio → backend
```

```
lib/src/
├── core/         config · api_client (Dio) · token_storage · router · theme · money
└── features/<feature>/
    ├── domain/         immutable models with fromJson
    ├── data/           repository — the only place that touches Dio; wraps errors in ApiException
    ├── application/    Riverpod controller (AsyncNotifier)
    └── presentation/   screens (ConsumerWidget / ConsumerStatefulWidget)
```

---

## Quick start (once scaffolded)

```bash
flutter create --platforms=android,web .   # ONE-TIME: generate platform folders (keeps lib/, pubspec.yaml)
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000            # Android emulator → host localhost
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000 # Web
flutter analyze
flutter test
dart format .
```

Make sure the **backend is running** first (see the travel-mate repo).

---

## Git workflow

Two long-lived branches (mirrors the other personal repos): `feature/*` and `bug/*` branch off
`develop` → PR into `develop`; `hotfix/*` branch off `master` → PR into `master`. **`master` is
release-only — never commit directly.** Cut a release by PR-ing `develop → master`, then tag it for
the build. `sync-develop.yml` merges `master → develop` after every push to `master`. See
[CLAUDE.md](CLAUDE.md) for identity & co-authorship.

---

## License

[MIT](LICENSE)

---

## Built with

[Claude Code](https://claude.ai/code) by Anthropic. 🤖
