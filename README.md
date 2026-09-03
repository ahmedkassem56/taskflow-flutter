# Taskflow — Flutter Client (Web + Android)

The Flutter companion to the **Taskflow** list app (todo, shopping, groceries,
and any other item tracking) — a **Material 3** client built with **Riverpod +
Freezed + go_router**, targeting **Flutter Web** and **Android**. It talks to
the same FastAPI + SQLite backend as the original PWA.

> **✦ Authored entirely by Hermes Agent (Nous Research) running DeepSeek-V4-Flash.**
> Requirements, design, implementation, testing, and this repository were
> produced autonomously by the agent — no human-written application code.

## Screenshots

_(Add light / dark / mobile captures here as the UI is polished.)_

## Features

- **Multiple lists** — All-tasks inbox + per-list views, create/rename/delete
- **Items** with title, notes, priority (none/low/medium/high), due date, quantity (×2 milk)
- **Recurring tasks** — daily, weekly, monthly, custom interval; completing one spawns the next
- **Filters & search** — pending/done/all segments, debounced server-side search
- **Reorder** — up/down arrows **and** hold-to-drag (Sortable-class feel), within a list only
- **Link sharing** — open shared lists read-only or editable (token-based, same as the web app)
- **Live sync** — 5-second polling while visible; mutations settle with an authoritative refresh
- **Light & dark themes** — Material 3 color schemes, persisted, system-default aware
- **Responsive** — NavigationRail on wide screens, drawer + hamburger on narrow
- **Persistence** — last-opened view + theme via shared_preferences

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.47 (Material 3), web-first + Android |
| State | Riverpod 3 (codegen) |
| Models | Freezed + json_serializable (generated files committed) |
| Navigation | go_router (`/`, `/share/:token`) |
| Networking | `http` (ApiClient, per-op whitelist bodies) |
| Backend | Existing Taskflow FastAPI + SQLite server |
| Tests | flutter_test + mocktail (19 tests: models, API client, reorder math, polling, widgets) |

## Quickstart

### Web (dev)

```bash
cd taskflow_app
flutter pub get
# point at your Taskflow backend (default: http://127.0.0.1:8000)
flutter run -d chrome --dart-define=API_BASE_URL=http://192.168.1.110:8000
```

### Web (release build)

```bash
flutter build web --dart-define=API_BASE_URL=http://192.168.1.110:8000
# serve build/web/ with any static server
```

### Android

```bash
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.110:8000
# APK: build/app/outputs/flutter-apk/app-debug.apk
```

> The **API base URL is baked at build time**. For a phone on the same LAN as
> the server, use the server's LAN IP (e.g. `http://192.168.1.110:8000`) —
> **not** `127.0.0.1`, which points at the phone itself. Android cleartext HTTP
> is enabled in the manifest for dev builds.

### Android via GitHub Actions

The repo ships a workflow (`.github/workflows/android-build.yml`) that builds
a debug APK on every push to `main`, or manually from the **Actions** tab —
the `api_base_url` input lets you set the server address without a code change.
Download the APK from the run's **Artifacts**.

## Tests

```bash
flutter analyze
flutter test
```

## Backend API

The backend is unchanged from the Taskflow web app — REST JSON under `/api`:

| Method & path | Purpose |
|---|---|
| `GET/POST /api/lists`, `PATCH/DELETE /api/lists/{id}` | List CRUD |
| `GET/POST /api/items`, `PATCH/DELETE /api/items/{id}` | Item CRUD + toggle done (recurrence spawn) |
| `POST /api/lists/{id}/shares`, `DELETE /api/shares/{token}` | Share links |
| `GET /api/shared/{token}` + item writes | Shared-list access (permission-gated) |
| `GET /api/health` | Liveness/database check |

Errors are always `{"detail": "<string>"}` with proper HTTP status codes.

## Project layout

```
lib/
  core/router/        go_router setup
  data/
    models/           Freezed models (TaskList, TaskItem, SharedList…)
    repositories/     Thin typed wrapper over the API
    services/         ApiClient + ApiException
  presentation/
    common/           Empty states, dialogs, formatting
    features/         home/, items/, share/ (feature modules)
    providers/        Riverpod: theme, lists, items, view, share, mutation bus
  main.dart           Bootstrap (ProviderScope + MaterialApp.router)
test/                 Model, API-client, state, and widget tests
SPEC.md               Requirements specification
DESIGN.md             Implementation contract
.github/workflows/    Android APK CI
```

## License

MIT
