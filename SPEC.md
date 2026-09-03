# SPEC — Taskflow Flutter client (Phase 1: Web-first, Android-ready)

Status: DRAFT for approval. Target: replace the JS PWA frontend with a Flutter
client (web + Android). Web first (this Linux box can build/test web); Android
APK via GitHub Actions later. Coexists with the JS frontend until approved.

## Goals (R1..Rn)

- R1 Flutter app (Material 3) that talks to the EXISTING FastAPI backend
  (http://127.0.0.1:8000 or a --dart-define API_BASE_URL). No backend changes
  beyond the CORS already added.
- R2 Feature parity with the JS client for personal use:
  - list views: sidebar lists + "All tasks", pending/done/all filter
  - composer: title, notes, due date, priority, quantity, recurrence
  - edit/delete items; toggle done; rename/delete lists
  - reorder via drag (handle + hold-to-drag) within a list
  - dark/light theme toggle, persisted
  - share: view a shared list (read-only or edit per token permission)
  - auto-refresh polling (5s) while visible
  - quick-add composer (type + Enter rapid entry; non-optimistic create —
    the row appears once the server commits, never flickers)
- R3 Auth/multi-user explicitly OUT of scope (later phase).
- R4 Runs on Flutter Web in Chromium here; Android project scaffolding present
  (no local APK build).
- R5 Architecture follows the project Flutter skill: layered core/data/domain/
  presentation, Riverpod state, Freezed models, go_router. Codegen via
  build_runner; generated files committed.

## Out of scope
- iOS, auth, FCM/notifications, offline sync, multi-device conflict resolution.

## Acceptance
- flutter analyze clean; flutter test passes (model/api/widget unit tests)
- flutter build web succeeds; served app can list/create/toggle/reorder a
  task against the live backend (verified E2E in Chromium)
