# JAY-JAY MEDICAL — Tablet Inventory (Flutter + Upstash Redis)

Mobile + tablet application for a medical shop to track tablets purchased by
multiple clients, with batch numbers, quantities, manufacturers, and expiry
dates. Highlights what is expiring within the next 7 days.

The Flutter app talks to a small **Vercel serverless API** at `../api/`,
which reads and writes an **Upstash Redis** database. The app does not
contact Upstash directly — the REST token stays on Vercel.

## Architecture

```
 ┌────────────┐  HTTPS  ┌─────────────────────────┐  HTTPS  ┌──────────────┐
 │ Flutter    │────────▶│ Vercel API              │────────▶│ Upstash      │
 │ (this dir) │         │  /api/tablets           │         │ Redis        │
 └────────────┘         │  /api/tablets/[id]      │         └──────────────┘
                        └─────────────────────────┘
```

- Polling refresh every 10 s + immediate refresh after every mutation.
- Optional shared bearer token (`API_TOKEN`) gates the API.
- No real-time stream, no per-user auth, single-trusted-user assumption.

## Features

- **Dashboard** — stat cards (total, active, expiring ≤7 days, expired),
  amber banner with chips for everything expiring this week, filterable +
  paginated records list (15/page).
- **Add / Edit** — autocompleted tablet + manufacturer, batch (#-prefixed),
  quantity, client, optional manufacturing date, start and expiry dates with
  inline validation.
- **By Tablet** — aggregated view grouping by `(tabletName, manufacturer)`
  with batches / total qty / expiring / expired / earliest-expiry, drill-down
  to filtered dashboard.
- **Responsive** — table layout ≥720 px, card layout <720 px.

## Prerequisites

- [Flutter 3.x (stable channel)](https://docs.flutter.dev/get-started/install)
- Node.js 18+ (for the API backend)
- A Vercel project with the **Upstash for Redis** integration connected (it
  auto-injects `KV_REST_API_URL` and `KV_REST_API_TOKEN`).

## One-time backend setup

The backend lives at the **repo root**, not inside this folder. From the
repo root:

```bash
npm install                  # installs @upstash/redis
vercel link                  # one-time, links to your Vercel project
vercel env pull .env.local   # optional, lets you run `vercel dev` locally
```

Connect the Upstash database to the project in the Vercel dashboard:
**Storage → Upstash for Redis → Connect to Project**. That writes the
`KV_REST_API_URL` and `KV_REST_API_TOKEN` env vars automatically.

**Optional but recommended:** lock the API down by setting one more env var:

```bash
vercel env add API_TOKEN              # paste a random string (e.g. `openssl rand -hex 32`)
```

If `API_TOKEN` is set, every request to `/api/tablets*` must send
`Authorization: Bearer <token>`. If it's unset, the API is open — fine for
testing, **never** for a public URL.

Deploy:

```bash
vercel --prod
# → outputs https://<your-app>.vercel.app
```

Quick smoke test:
```bash
curl https://<your-app>.vercel.app/api/tablets \
  -H "Authorization: Bearer <API_TOKEN>"   # → {"tablets":[]}
```

## Run the Flutter app

From inside `jay_jay_medical/`:

```bash
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=https://<your-app>.vercel.app \
  --dart-define=API_TOKEN=<the-same-token-you-set-on-vercel>
```

Omit `API_TOKEN` only if you also omitted it on Vercel.

If `flutter create` needs to regenerate the native platform folders
(android/, ios/), run it inside this directory once before `flutter run`:
```bash
flutter create --org com.jayjaymedical --project-name jay_jay_medical .
```

## Run the unit tests

```bash
flutter test
```

Tests cover:
- `status_utils_test.dart` — expiring/expired/active boundaries.
- `date_utils_test.dart` — `toUtcMidnight`, `dueInDaysLabel` rendering.
- `validators_test.dart` — required, integer ≥ 1, end-after-start,
  mfg-on-or-before-end.
- `grouping_test.dart` — two clients of the same tablet collapse into one
  group with summed quantities and a deduplicated client list.

## API

| Method | Path                  | Body                  | Returns                          |
| ------ | --------------------- | --------------------- | -------------------------------- |
| GET    | `/api/tablets`        |                       | `{ tablets: Tablet[] }`          |
| POST   | `/api/tablets`        | Tablet (no `id`)      | `Tablet` (with `id` & timestamps), 201 |
| PUT    | `/api/tablets/:id`    | Tablet (no `id`)      | `Tablet`, 200                    |
| DELETE | `/api/tablets/:id`    |                       | 204                              |

A `Tablet` body looks like:
```json
{
  "clientName": "Maria",
  "tabletName": "Paracetamol",
  "manufacturer": "Acme",
  "batchNumber": "B0421",
  "quantity": 50,
  "startDate": "2026-05-18T00:00:00.000Z",
  "endDate": "2026-08-18T00:00:00.000Z",
  "manufacturingDate": "2026-01-10T00:00:00.000Z"
}
```

Dates are ISO-8601 strings normalized to UTC midnight server-side.

## Redis key layout

```
tablet:<uuid>     →  JSON-serialized Tablet (no `id` inside)
tablets:index     →  SET of all uuids
```

Listing is `SMEMBERS tablets:index` followed by a single `MGET` of every
document — efficient for the single-shop scale this app targets.

## Project layout

```
lib/
  main.dart                 # ProviderScope + MaterialApp.router
  config.dart               # API_BASE_URL / API_TOKEN from --dart-define
  app/
    router.dart             # go_router routes
    theme.dart              # AppColors, AppTextStyles, ThemeData
  models/
    tablet.dart             # Tablet model + JSON (de)serialization
  services/
    tablets_repository.dart # HTTP client for the Vercel API
  providers/
    filters_provider.dart
    tablets_providers.dart  # polling StreamProvider + derived selectors
  screens/
    splash_screen.dart
    dashboard_screen.dart
    tablet_form_screen.dart
    grouped_screen.dart
  widgets/
    app_bar_brand.dart
    stat_card.dart
    pill.dart
    data_row.dart
    expiring_banner.dart
    filter_card.dart
    pager.dart
    empty_state.dart
    brand_gradient_button.dart
  utils/
    date_utils.dart
    status_utils.dart
    grouping.dart
    validators.dart
test/
  status_utils_test.dart
  date_utils_test.dart
  validators_test.dart
  grouping_test.dart
```

Backend (at the repo root, NOT in this folder):

```
api/
  tablets.js                # GET (list) + POST (create)
  tablets/[id].js           # GET (one) + PUT (update) + DELETE
  _lib/
    redis.js
    auth.js
    cors.js
    tablet.js               # server-side validation + normalization
package.json                # Node deps (@upstash/redis)
vercel.json                 # rewrites /api/* through; everything else → landing page
```

## Screenshots

After your first successful `flutter run`, capture one screenshot of each
screen on a phone-sized device and one on a tablet-sized device, then drop
them in this section.

| Screen | Phone | Tablet |
| ------ | ----- | ------ |
| Splash | `docs/splash-phone.png` | `docs/splash-tablet.png` |
| Dashboard | `docs/dashboard-phone.png` | `docs/dashboard-tablet.png` |
| Add / Edit | `docs/form-phone.png` | `docs/form-tablet.png` |
| By Tablet | `docs/grouped-phone.png` | `docs/grouped-tablet.png` |

To capture from an Android emulator:
```bash
adb exec-out screencap -p > docs/dashboard-phone.png
```

From the iOS simulator: `Cmd-S` (saves to ~/Desktop).

## Scaling notes

The dashboard, stats, grouped view, and autocomplete sets are all derived
client-side from a single `tabletsStreamProvider` that polls
`GET /api/tablets`. This is fine up to ~1000 documents. Beyond that:
- Add server-side filtering (`/api/tablets?status=expiring&search=...`)
  and pagination.
- Replace polling with Server-Sent Events or a WebSocket if multi-device
  sync becomes required.

## License

Private — internal use at JAY-JAY MEDICAL.
