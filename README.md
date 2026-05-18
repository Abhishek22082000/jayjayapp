# JAY-JAY MEDICAL — Tablet Inventory (Flutter)

[![Flutter CI](https://github.com/Abhishek22082000/jayjayapp/actions/workflows/flutter.yml/badge.svg)](https://github.com/Abhishek22082000/jayjayapp/actions/workflows/flutter.yml)

Flutter mobile app for JAY-JAY MEDICAL. Tracks tablets purchased by clients,
with batch numbers, quantities, manufacturers, and expiry dates. Highlights
what is expiring within the next 7 days.

This repo holds **only the Flutter client**. The backend it talks to lives
in a separate Next.js + Upstash Redis project (the `jayjaymedical` repo,
deployed to Vercel). One Upstash database backs both the Next.js web UI
and this mobile app, so edits made in either client appear live in the
other after the next poll.

## Repo layout

```
.
├── .github/workflows/flutter.yml   # CI: analyze, test, build Android APK
└── jay_jay_medical/                # Flutter app
```

## Quick start

```bash
cd jay_jay_medical
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=https://<your-medical-vercel-url>
```

The `<your-medical-vercel-url>` is the URL of the `jayjaymedical` Vercel
deployment (the Next.js project). The mobile app talks to its
`/api/tablets` endpoints.

Full Flutter docs live in [`jay_jay_medical/README.md`](jay_jay_medical/README.md).

## Architecture

```
 ┌────────────┐                       ┌────────────────────────┐
 │ Flutter    │──────HTTPS──────────▶ │ jayjaymedical (Vercel) │
 │ app (this  │   /api/tablets        │   Next.js + @upstash/  │
 │ repo)      │                       │   redis                │
 └────────────┘                       └─────────┬──────────────┘
                                                │
                                                ▼
                                       ┌────────────────────┐
                                       │ Upstash Redis      │
                                       │ key: "tablets"     │
                                       └────────▲───────────┘
                                                │
 ┌────────────┐                                 │
 │ Next.js    │──────────HTTPS──────────────────┘
 │ web UI     │
 │ (same      │
 │ Vercel)    │
 └────────────┘
```

- Flutter polls `GET /api/tablets` every 10 s and refreshes immediately
  after every mutation.
- Dates are serialized as `YYYY-MM-DD` strings on both sides so the
  Next.js web form and the Flutter form write identical shapes.
- No per-user auth. Single-trusted-user assumption (the shop owner).

## CI

[`.github/workflows/flutter.yml`](.github/workflows/flutter.yml) runs on
every push and PR touching `jay_jay_medical/`:

1. **Analyze & Test** — `flutter analyze` + `flutter test` on Flutter
   stable.
2. **Build Android APK** — scaffolds `android/` on the fly, then runs
   `flutter build apk --release`. APK uploaded as a GitHub Actions
   artifact named `jayjay-medical-<sha>-apk` and retained for 30 days.

### Build-time secrets

Set on GitHub → **Settings → Secrets and variables → Actions**:

| Secret | Required? | Value |
| ------ | --------- | ----- |
| `API_BASE_URL` | Yes (for a working APK) | Your `jayjaymedical` Vercel URL |
| `API_TOKEN` | Only if you add bearer-token auth to the backend later | Matching shared secret |

Re-run the latest workflow after adding secrets to get an APK that's
wired up to production.

### Downloading the APK

Actions → latest green run → **Artifacts** →
`jayjay-medical-<sha>-apk.zip` → unzip → `adb install app-release.apk`.

## License

Private — internal use at JAY-JAY MEDICAL.
