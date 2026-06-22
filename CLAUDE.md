# travel-mate-app — CLAUDE.md

Guidance for Claude (and humans) working in this repo.

## What this is

The **Flutter client** for the Travel Mate product, targeting **Android and Web from one codebase**
(not Android-only like the sibling `family-budget-app`). The backend (Spring Boot + Spring Data JPA
+ Oracle ADB) is a **separate repo**: `vodongha/travel-mate`. This repo is frontend only — it owns
no business rules beyond input validation; the server is the source of truth (especially for money,
currency conversion, and settlement).

**UI must always be modern** (Material 3, responsive, polished) on every platform — phone, tablet,
and desktop web. Treat a responsive layout (width-capped content, adaptive navigation) as a baseline
requirement, not an afterthought.

**Status: shipped — v1.0.0 in production** (Android `vn.trippo.mate` + web https://trippo.io.vn).
All feature areas are built: auth (email + Google), trips (list grouped by year with scroll
pagination, create/detail, derived status incl. "Upcoming"), timeline (events + transport +
accommodation + places, add via a type chooser, edit/delete, attach expenses), money (multi-currency
expenses + split, budget), fund, settlement, tickets (personal + group/QR), checklist, dashboard,
report, settings/account, notifications scaffolding, in-app update. The web build is served by the
backend at the same origin. Backend spec (source of truth):
[vodongha/travel-mate › docs/SPEC.md](https://github.com/vodongha/travel-mate/blob/master/docs/SPEC.md).

## Tech stack

- **Flutter** (Material 3, modern responsive UI), latest stable — **Android + Web** from one codebase
- **Riverpod** (`AsyncNotifier`/`FamilyAsyncNotifier`) — one controller per feature, mirrors the backend service layer
- **Dio** for HTTP — a single configured client with a bearer-token + refresh interceptor
- **go_router** for navigation with an auth-aware redirect guard
- **flutter_secure_storage** for the JWT access + refresh tokens (Keychain / Keystore — never plain prefs)
- **flutter_map** (OpenStreetMap) + **latlong2** for maps; **geolocator** for "my location" + **permission_handler** for runtime camera/location permission
- **qr_flutter** to render a QR from a string; **mobile_scanner** to scan a QR into its decoded string (see "QR codes" below)
- **firebase_core** + **firebase_messaging** (FCM) for push; **google_sign_in** (+ `google_sign_in_web`) for Sign in with Google
- **in_app_update** for Google Play in-app updates; **package_info_plus** for the version shown in About
- **intl** for money/date formatting

This mirrors the sibling `family-budget-app` setup; reuse its patterns (Dio client + interceptor,
`ApiException`, secure token storage, ARB localization, responsive width-cap) where they fit.

## Money rules (must follow)

- The app **never does money arithmetic.** Balances, fund balance, settlement and converted totals
  are **derived on the backend** — the app only **formats** values it receives.
- Money is displayed with the right currency/decimals; never parse it into a lossy `double` for
  computation. Each amount carries its currency; the backend's base-currency totals come pre-computed.
- Direction (who paid, who owes) comes from the expense/settlement data, never a sign the UI invents.

## Identifiers

The API exposes only **`rid`** (UUID v7) — never an internal numeric id. Use `rid` in routes,
requests, and as keys. There is no numeric id on the client side.

## QR codes — store the string, regenerate the image

QR codes are handled as **strings, never images** (backend SPEC §2.7):

- **Saving a ticket QR:** scan it with `mobile_scanner` → take the **decoded string** → send that
  string to the backend (e.g. `qrData` on a transport/accommodation). Never upload or store the QR
  image.
- **Viewing:** read the stored string and **regenerate the QR client-side** with `qr_flutter`.
- **Invitations:** the backend returns the invite **link string** (`inviteUrl`); the app renders it
  as a QR with `qr_flutter`. Scanning an invite QR yields that link, which the app opens / posts to
  `POST /invitations/{token}/accept`.

This keeps storage small, avoids stale/huge image blobs, and lets the QR be re-rendered at any size.

## Architecture (planned)

Layered per feature, mirroring the backend `controller → service → repository`:

```
presentation (widgets) → application (Riverpod controllers) → data (repositories) → Dio → backend
```

```
lib/src/
├── core/         config · api_client (Dio) · token_storage · router · theme · money
└── features/<feature>/
    ├── domain/         immutable models with fromJson
    ├── data/           repository — the only place that touches Dio; wraps errors in ApiException
    ├── application/    Riverpod controller (AsyncNotifier) — holds state, orchestrates repos
    └── presentation/   screens (ConsumerWidget / ConsumerStatefulWidget)
```

Rules:
- **Widgets never call Dio directly.** Always go through a repository via a controller.
- **Repositories are stateless** and throw `ApiException` — never surface a raw `DioException`.
- **Controllers** own state as `AsyncValue<T>`; after a mutation that changes derived data
  (expense/fund/settlement) invalidate the affected providers (dashboard, settlement, fund, budget).

## Backend API contract (high level)

Base path **`/api/v1`**. The base URL is resolved in `AppConfig`:
- **Mobile (release):** `--dart-define=API_BASE_URL=https://trippo.io.vn` (absolute). Dev default is
  `http://10.0.2.2:8000` (Android emulator → host localhost).
- **Web:** built with `--dart-define=SAME_ORIGIN=true` → **relative** URLs, because the backend serves
  the web build at the same origin (no CORS). The backend's `deploy.yml` builds the web this way.

Full detail in the backend's `docs/SPEC.md` §4/§7.

- **Envelope:** responses are `{ data, error, meta }`; errors follow **RFC 7807** ProblemDetail
  (`{ type, title, status, detail, fieldErrors[] }`). Pagination is `?page=&size=&sort=`.
- **Resources are addressed by `rid`**, nested under trips
  (`/trips/{tripRid}/expenses`, `PATCH /expenses/{rid}`, `DELETE /expenses/{rid}` = soft delete).
- **Auth:** `POST /auth/register|login|google|refresh|verify-email|forgot-password|reset-password`;
  `GET/PATCH /users/me`; `POST /users/me/devices` (register the FCM token). JWT access + DB-stored
  refresh token (rotated each `/auth/refresh`). Store both in secure storage; on `401` try a refresh,
  then fall back to login.
- **Idempotency:** money-creating POSTs (expense, fund contribution) send a client-generated
  `Idempotency-Key` header (a UUID) so a flaky-network double-submit doesn't duplicate. Generate it
  once per logical submit and reuse it on retry.
- **Trips/members:** roles `OWNER`/`EDITOR`/`VIEWER`; ghost members (no account) can be split with;
  invite by link/QR (`POST /trips/{tripRid}/invitations`, `POST /invitations/{token}/accept`).
- **Money:** expenses carry `currency`, `amount`, `exchangeRate` (snapshot), `amountBase`; the
  server computes `amountBase`. Splits are `EQUAL`/`EXACT`/`PERCENT`/`SHARES`. An expense may attach
  to an itinerary item via `itineraryKind` (EVENT/TRANSPORT/ACCOMMODATION) + `itineraryRid`.
- **Classification:** one canonical `Category` (TRANSPORT, ACCOMMODATION, FOOD, SHOPPING, ACTIVITY,
  SIGHTSEEING, MEDICAL, PARKING, OTHER) for events/places/tickets/expenses; `TransportType` is a
  separate sub-type. See `Labels` in `core/labels.dart`.
- **Tickets:** per-member, or a **group ticket** (`shared: true`, no owner — needs EDITOR); group
  tickets appear in everyone's `/tickets/mine`.
- **Settlement:** `GET /trips/{tripRid}/settlement` → net balances + minimised transactions.
- **Dashboard/report:** `GET /trips/{tripRid}/dashboard`, `GET /trips/{tripRid}/report`.

Error codes: 400 validation, 401 unauthenticated, 403 wrong role, 404 not found / not your trip,
409 optimistic-lock conflict, 422 idempotency/payload conflict.

## Localization (i18n)

English + Vietnamese via `flutter_localizations` + ARB (`lib/l10n/app_en.arb` template +
`app_vi.arb`); `flutter gen-l10n` generates `AppLocalizations` (gitignored — regenerated on build /
in CI). Add a string to **both** ARB files. Don't hardcode user-facing text in widgets.

## Conventions

- Standard Dart: `prefer_single_quotes`, explicit return types, **always braces**.
- New screens go under `features/<feature>/presentation/` and route via `core/router.dart`.
- **Every destructive action confirms first** — any delete shows an `AlertDialog` (cancel + a red
  confirm) before calling the controller; never delete on a single tap.
- Run `dart format .` before committing — CI fails on unformatted code.

## Build & run

```bash
flutter pub get
flutter analyze                                                        # CI gate — keep clean
flutter test

# Dev
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000            # Android emulator → host
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000 # Web

# Release
flutter build appbundle --release --dart-define=API_BASE_URL=https://trippo.io.vn   # Android (Play)
flutter build web --release --dart-define=SAME_ORIGIN=true                          # Web (backend bakes this in)
```

The Play release is `vn.trippo.mate`; bump `version:` in `pubspec.yaml` (`x.y.z+build`) per upload.
The **web build is normally produced by the backend's `deploy.yml`** (it checks out this repo's
`master`), so an app-only change needs a backend redeploy to go live on https://trippo.io.vn.

**`android/` and `web/` are committed** (Android: applicationId `vn.trippo.mate`, permissions, release
signing via `android/key.properties`; Web: `index.html`, manifest, icons). Secrets stay out via
`.gitignore` (`key.properties`, `*.jks`, `local.properties`, `google-services.json`, Firebase service
accounts). Google Sign-In on a Play build needs the **App signing** key's SHA-1/SHA-256 in Firebase.

## Git workflow

Personal repo — set the **personal identity locally** (the machine's global git defaults to the
cisbox company email):

```bash
git config --local user.name "vodongha"
git config --local user.email "vodongha@hotmail.com"
```

AI-assisted commits are **authored by `vodongha`** with **Claude as the committer**:

```bash
GIT_COMMITTER_NAME="Claude Opus 4.8" GIT_COMMITTER_EMAIL="noreply@anthropic.com" \
  git commit --author="vodongha <vodongha@hotmail.com>" -m "..."
```

**develop/master model** (mirrors the other personal repos): `feature/*` and `bug/*` branch off
`develop` → PR into `develop`; `hotfix/*` branch off `master` → PR into `master`. **`master` is
release-only — never commit directly.** Cut a release by PR-ing `develop → master`, then tag it
(e.g. `v1.0.0`) for the build. `sync-develop.yml` merges `master → develop` after every push to
`master`. Merge with merge commits (no squash/rebase). Reference the backend repo when a change
tracks an API change.

## Built with

[Claude Code](https://claude.ai/code) by Anthropic. 🤖
