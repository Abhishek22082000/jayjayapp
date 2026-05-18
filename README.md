# JAY-JAY MEDICAL — Tablet Inventory

[![Flutter CI](https://github.com/Abhishek22082000/jayjayapp/actions/workflows/flutter.yml/badge.svg)](https://github.com/Abhishek22082000/jayjayapp/actions/workflows/flutter.yml)

Flutter mobile app + Vercel serverless API + Upstash Redis. Tracks tablets
purchased by clients, with batch numbers, quantities, manufacturers, and
expiry dates. Highlights what is expiring within the next 7 days.

## Repo layout

```
.
├── api/                  # Vercel serverless functions (Node 18, @upstash/redis)
│   ├── tablets.js        #   GET /api/tablets, POST /api/tablets
│   ├── tablets/[id].js   #   GET/PUT/DELETE /api/tablets/:id
│   └── _lib/             #   shared helpers: Redis client, auth, CORS, validation
├── jay_jay_medical/      # Flutter app (Android, iOS, responsive phone/tablet)
├── package.json          # Node deps for api/ — Vercel installs these
├── vercel.json           # routes /api/* through, everything else → landing page
└── .vercelignore         # excludes jay_jay_medical/ from the Vercel deploy
```

## Quick start

### 1. Deploy the API to Vercel

```bash
npm install
vercel link
vercel --prod
```

Connect your Upstash for Redis database to the Vercel project — that
auto-injects `KV_REST_API_URL` and `KV_REST_API_TOKEN`. Optionally set
`API_TOKEN` on Vercel to gate every request with a shared bearer token.

### 2. Run the Flutter app

```bash
cd jay_jay_medical
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=https://<your-app>.vercel.app \
  --dart-define=API_TOKEN=<same-token-if-you-set-one>
```

Full Flutter docs (architecture, screens, tests, screenshot capture) live in
[`jay_jay_medical/README.md`](jay_jay_medical/README.md).

## Architecture

```
 ┌────────────┐  HTTPS  ┌─────────────────────────┐  HTTPS  ┌──────────────┐
 │ Flutter    │────────▶│ Vercel API              │────────▶│ Upstash      │
 │ app        │         │  /api/tablets           │         │ Redis        │
 └────────────┘         │  /api/tablets/[id]      │         └──────────────┘
                        └─────────────────────────┘
```

- Polling refresh every 10 s + immediate refresh after every mutation.
- Optional shared bearer token (`API_TOKEN`) gates the API.
- Single-trusted-user assumption (shop owner). No per-user auth.

## Data model

```
tablet:<uuid>     →  JSON-serialized Tablet (no `id` inside)
tablets:index     →  SET of all uuids
```

`Tablet` shape:
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

## Continuous integration

[`.github/workflows/flutter.yml`](.github/workflows/flutter.yml) runs on every
push to `main`, every pull request, and on manual dispatch:

1. **Analyze & Test** — `flutter analyze` + `flutter test` against the
   stable Flutter channel on Ubuntu.
2. **Build Android APK** — scaffolds `android/` on the fly (the folder is
   intentionally kept out of git to keep the repo slim), then runs
   `flutter build apk --release`. The resulting APK is uploaded as a
   GitHub Actions artifact named `jayjay-medical-<commit-sha>-apk` and
   retained for 30 days.

### Configure the build-time secrets (one-time)

The APK that CI builds needs to know which Vercel URL to talk to. On
GitHub, go to **Settings → Secrets and variables → Actions → New repository
secret** and add:

| Secret name      | Value                                    |
| ---------------- | ---------------------------------------- |
| `API_BASE_URL`   | `https://<your-app>.vercel.app`          |
| `API_TOKEN`      | The same shared secret you set on Vercel (optional — only if you also set `API_TOKEN` server-side) |

After adding them, re-run the latest workflow (Actions → Flutter CI →
Re-run all jobs) to produce an APK pointing at production.

### Download the APK

After a green CI run on `main`, open the run summary → **Artifacts** →
download `jayjay-medical-<sha>-apk.zip`. Unzip and install on Android
with `adb install app-release.apk`, or sideload via file manager.

## License

Private — internal use at JAY-JAY MEDICAL.
