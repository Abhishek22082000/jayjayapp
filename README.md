# JAY-JAY MEDICAL — Tablet Inventory

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

## License

Private — internal use at JAY-JAY MEDICAL.
