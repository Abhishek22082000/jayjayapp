# JAY-JAY MEDICAL — Tablet Inventory (Flutter)

Mobile + tablet application for a medical shop to track tablets purchased by
multiple clients, with batch numbers, quantities, manufacturers, and expiry
dates. Highlights what is expiring within the next 7 days.

The app talks to the **existing `jayjaymedical` Next.js + Upstash deployment
on Vercel** — see the top-level [README](../README.md) for the overall
architecture. This document covers only the Flutter side.

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
- The `jayjaymedical` Vercel deployment running (Next.js API + Upstash KV).

## Run

```bash
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=https://<your-medical-vercel-url>
```

If `flutter create` needs to scaffold the native platform folders
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

## API contract

The Flutter HTTP client targets the `jayjaymedical` Next.js routes:

| Method | Path                  | Returns                                  |
| ------ | --------------------- | ---------------------------------------- |
| GET    | `/api/tablets`        | `{ tablets: Tablet[] }`                  |
| POST   | `/api/tablets`        | `{ tablet: Tablet }`, 201                |
| GET    | `/api/tablets/:id`    | `{ tablet: Tablet }`, 200                |
| PUT    | `/api/tablets/:id`    | `{ tablet: Tablet }`, 200                |
| DELETE | `/api/tablets/:id`    | 204                                      |

`Tablet` payload (dates are `YYYY-MM-DD` strings, matching the Next.js web
form's `<input type="date">` output):
```json
{
  "clientName": "Maria",
  "tabletName": "Paracetamol",
  "manufacturer": "Acme",
  "batchNumber": "B0421",
  "quantity": 50,
  "startDate": "2026-05-18",
  "endDate": "2026-08-18",
  "manufacturingDate": "2026-01-10"
}
```

The Flutter app pins date-only strings to **UTC midnight** when parsing,
so calendar math (expiring / expired) is stable regardless of device
timezone.

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
    tablets_repository.dart # HTTP client for the Next.js API
  providers/
    filters_provider.dart
    tablets_providers.dart  # polling StreamProvider + derived selectors
  screens/
    splash_screen.dart
    dashboard_screen.dart
    tablet_form_screen.dart
    grouped_screen.dart
  widgets/
    app_bar_brand.dart, stat_card.dart, pill.dart, data_row.dart,
    expiring_banner.dart, filter_card.dart, pager.dart, empty_state.dart,
    brand_gradient_button.dart
  utils/
    date_utils.dart, status_utils.dart, grouping.dart, validators.dart
test/
  status_utils_test.dart, date_utils_test.dart, validators_test.dart,
  grouping_test.dart
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

## License

Private — internal use at JAY-JAY MEDICAL.
