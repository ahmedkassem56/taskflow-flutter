# DESIGN.md — Taskflow Flutter client (implementation contract)

Status: APPROVED direction (Riverpod/Freezed/go_router per project skill).
Derived from `SPEC.md` (R1–R5) and the *actual* backend at
`/home/hermes/projects/todo-app` (read in full: `app/main.py`,
`app/schemas.py`, `app/db.py`, `static/app.js`, `DESIGN-reorder.md`,
`DESIGN-polling.md`). Where this document and the backend disagree, the
backend wins.

## 1. Stack & constraints (fixed)

| Concern | Choice |
|---|---|
| UI | Flutter 3.47 (SDK `/home/hermes/flutter`), Material 3, web-first + Android |
| Deps | `http`, `shared_preferences`, `flutter_riverpod`, `riverpod_annotation`, `freezed_annotation`, `json_annotation`, `go_router`, `intl`; dev: `build_runner`, `freezed`, `json_serializable`, `riverpod_generator`, `mocktail`, `flutter_lints` |
| State | Riverpod: `Notifier`/`AsyncNotifier` providers per concern; codegen via `@riverpod` + Freezed models (`build_runner build`) |
| Navigation | go_router: `/` (shell: all/list views + drawer), `/share/<token>` (share mode) |
| Models | Freezed `@freezed` classes + `fromJson` via `json_serializable` (`*.g.dart`) |
| Reorder | `ReorderableListView.builder` + `ReorderableDelayedDragStartListener` (hold-to-drag) |
| API base | `String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000')` — compile-time; web dev uses `--dart-define` (CORS is `allow_origins=*`); Android emulator later overrides with `http://10.0.2.2:8000` |
| Tests | mocktail for provider/notifier unit tests; `MockClient` (http/testing) for ApiClient; widget tests with `ProviderScope` overrides |

NOTE: the box has 2GB RAM — run `build_runner` only when models/providers
change (not on every analyze), and prefer `flutter analyze` without the
codegen-heavy watcher. Generated files (`*.g.dart`, `*.freezed.dart`) are
gitignored/committed per team preference — commit them so CI/web build never
needs a codegen step.

## 2. Verified backend contract (read from code, not the old DESIGN.md)

### 2.1 Item sort — canonical, single SQL (`app/db.py` ITEM_ORDER_SQL)

```
ORDER BY i.done ASC, i.position ASC, i.id ASC
```
**Not** the priority/due-date sort of todo-app/DESIGN.md §2.0 (superseded by
DESIGN-reorder). `position` is an explicit `int` column, server-managed,
present in every Item JSON. The legacy `cmpItems` in `static/app.js` is dead
code — never re-sort client-side by priority. Client display order = server
array order, always.

### 2.2 Envelopes (exact — differ per op!)

| Call | Response |
|---|---|
| `GET /api/lists` | `200 [List,...]` (name COLLATE NOCASE, id) |
| `GET /api/items?list_id&status&q` | `200 [Item,...]` (canonical order; unknown list_id ⇒ `200 []`, NOT 404) |
| `POST /api/items` (app) / `POST /api/shared/{t}/items` | `201` **bare Item** (no envelope) |
| `PATCH .../items/{id}` **non-move** (incl. `move_to` and toggle) | `200 {"item": Item, "spawned": Item\|null}` |
| `PATCH .../items/{id}` **`move`** (up/down) | `200 {"item": Item, "swapped": Item\|null}` — NO `spawned` key |
| `DELETE .../items/{id}` / list / share | `204` **empty body** — never decode JSON |
| `GET /api/shared/{token}` | `200 {"list": List, "items": [Item...], "permission": "read"\|"edit"}` |
| `POST /api/lists/{id}/shares {"permission"}` | `201 {"token","permission","url","created_at"}` (no list_id) |
| Errors | `{"detail": "<string>"}` always; 400 malformed/`{}` patch, 403 read-only write, 404 URL resource (share: "Share link not found or revoked"), 409 body references missing list_id, 422 validation (detail = `"; ".join("loc: msg")`) |

Gotcha: `move_to` responses ride the non-move branch ⇒ key is `"spawned": null`,
never `"swapped"`. `move` boundary (no neighbor) ⇒ 200 no-op, unchanged item.
`move` swap ⇒ `"swapped"` = the neighbor (its position changed too).
Reorder ops: client sends PATCH then does a full silent refresh, so envelopes
are used only for `spawned` (toggle) — never trust them as final state.

### 2.3 Position/reorder semantics (DESIGN-reorder §1.2–1.4)

- Groups = same `(list_id, done)`, ordered by `(position, id)`.
- Create and recurrence-spawn insert at **pending-top**: shift group +1, insert `position = 0`.
- `move: up|down` swaps positions with the adjacent same-group neighbor; at a group edge ⇒ 200 no-op.
- `move_to: K` reorders the item to ordinal K within its group; K out of range clamps to the last slot; K == current ⇒ no-op (no `updated_at` bump); every rewritten row gets a bump. `move`/`move_to` are **mutually exclusive with every other PATCH field** (422) and with each other.
- `done: true` on `done=false` + `recurrence != none` spawns one occurrence (next_due anchored on pre-spawn due_date, else created_at date). `done:true` when already done ⇒ idempotent no-op (no spawn). `done:false` never spawns. Completed occurrence stays visible.
- Shared `PATCH`/`POST`/`DELETE` (/api/shared/{t}/...) forbid `list_id` in the body (extra=forbid ⇒ 422) and scope rows to the shared list; read-only token ⇒ 403 on any write. `move`/`move_to` work on shared **edit** lists via the same `_apply_item_patch`.

### 2.4 Validation gotchas (schemas.py — `extra="forbid"` everywhere)

- Request bodies may contain ONLY the documented keys — never echo server fields (`id`, `position`, `created_at`, `updated_at`, `item_count`, counts).
- `due_date`: strict calendar `YYYY-MM-DD` (rejects `2026-02-30`) or null (null clears). `quantity`: number > 0, never null, serializes int-when-integral (`2`, not `2.0`). `notes`: string ≤5000 or null.
- `recurrence_interval`: int ≥1, required iff `recurrence=="custom"`; must be **null** otherwise — on PATCH switching away from custom, client must send `recurrence_interval: null` in the same body or get 422 (merged-state rule).
- Empty `{}` PATCH ⇒ 400 "No fields to update".
- Timestamps: `created_at`/`updated_at` = UTC `%Y-%m-%dT%H:%M:%S.%fZ` (fixed width, lexicographically sortable). `due_date` is a date-only string, never a time.

## 3. Data model — `lib/data/models/` (Freezed + json_serializable)

Enums (wire values lowercase, stored as strings in JSON): `Priority {none,low,medium,high}`,
`Recurrence {none,daily,weekly,monthly,custom}`, `StatusFilter {all,pending,done}`.

`@freezed` classes (each `with _$X`, `factory X.fromJson` → `_$XFromJson`):

| Class | Fields (Dart type) |
|---|---|
| `TaskList` | `id int`, `name String`, `itemCount int`, `pendingCount int`, `createdAt DateTime`, `updatedAt DateTime` |
| `TaskItem` | `id int`, `listId int`, `title String`, `notes String?`, `priority Priority`, `dueDate String?` (YYYY-MM-DD — keep as String; compare/format lexicographically, no tz math), `quantity num`, `position int`, `done bool`, `recurrence Recurrence`, `recurrenceInterval int?`, `createdAt DateTime`, `updatedAt DateTime` |
| `SharedList` | `list TaskList`, `items List<TaskItem>`, `permission String` (`bool get canEdit`) |
| `ShareLink` | `token, permission, url String`, `createdAt DateTime` |
| `ItemEnvelope` | `item TaskItem`, `spawned TaskItem?`, `swapped TaskItem?` — parse whichever key is present |

Parsing rules: `DateTime.parse` handles the `Z`+microseconds timestamps
natively (returns UTC). `dueDate`: `json['due_date'] as String?` — **never**
`DateTime.parse` it (date-only parses as local midnight on web; string
compare is the safe due-kind test: `< today` overdue, `== today`, else
future, with `today` built from a local `DateTime.now()` formatted
YYYY-MM-DD). `quantity` stays `num` (jsonDecode yields `int` for `2`,
`double` for `0.5`). Unknown JSON keys ignored on read (server may add
fields); unknown enums → fall back to `none` + tolerate (defensive).
`toJson` exists ONLY for Freezed serialization of outbound whitelists;
request bodies are built per-op by `ApiClient` whitelist methods so
server-owned fields can't leak.

## 4. API client — `lib/api/api_client.dart`

`ApiClient(String baseUrl, {http.Client? client})` (client injectable; `http/testing` MockClient for tests). One method per endpoint in §2 table. All request bodies built from whitelists:

- `createItemBody(listId, title, notes, priority, dueDate, quantity, recurrence, interval)` — create keys only.
- `patchBody(fields...)` — only fields the caller changed (partial update); never nulls except `due_date`/`notes`/`recurrence_interval` clears.
- Shared variants drop `list_id` by construction.
- Reorder: `patchItem(id, {'move': 'up'|'down'})` or `{'move_to': k}` alone.

Response handling: 204 → null (no decode); else decode JSON; non-2xx → throw `ApiException(status, detail)` where `detail` is `json['detail']` if a string else `'Request failed ($status)'`; transport errors (SocketException/ClientException/TimeoutException) → `ApiException(0, 'Cannot reach the server. Check your connection.')`. GETs get a generous timeout (10s); UI shows `ApiException.detail` in a SnackBar, never raw.

## 5. State — Riverpod providers (`lib/presentation/providers/`)

Riverpod codegen (`@riverpod` notifiers) with a `ProviderContainer`-friendly
design so tests override providers with mocks. Split by concern:

```dart
@riverpod class ApiClientProvider …            // http.Client injectable; baseUrl from config
@riverpod class ThemeController extends Notifier<ThemeMode> …   // persists 'taskflow.theme'
@riverpod class ListsController extends Notifier<AsyncValue<List<TaskList>>> …
@riverpod class ItemsController extends AsyncNotifier<List<TaskItem>> …
      // holds current fetch: view(all|list(id)), status, q (debounced 300ms);
      // fetch uses server-side params (list_id/status/q); stale-gen guard; 5s poll tick
@riverpod class ViewController extends Notifier<ViewState> …    // current view + mode
      // ViewState (Freezed): {mode: app|share, view: all|list(id)}; persisted 'taskflow.view'
@riverpod class ShareController extends AsyncNotifier<SharedList> …  // /api/shared/{token}
@riverpod class MutationBus extends Notifier<int> …    // mutating counter + _gen for staleness
@riverpod class RouterProvider …                      // go_router, watches ViewController/Share
```

State machine (concise):
```
mode:      app | share                    (share ⇐ token on boot/route/paste)
view:      all | list(listId)             (app mode only)
status:    all | pending | done
query:     String                         (debounced 300ms)
lists:     List<TaskList>                 (app mode)
items:     List<TaskItem>                 (display list)
share:     SharedList?                    (share mode)
loading:   bool · error: String?          (first-load + error states)
dialogOpen: bool · rearrangeActive: bool · mutating: int · _gen: int
themeMode: ThemeMode (light|dark|system)
```

View transitions: select list → set view, refetch `lists + items(list_id,
status, q)`; select All → refetch without `list_id`; boot: restore persisted
view (only if that list still exists, else All); after every lists refresh,
if the current `listId` vanished → switch to All. Deleting the current list
also → All. Share boot: if current URL (path `/share/<token>` or fragment
`#/share/<token>`, else pasted token) → `mode=share`, `GET /api/shared/{token}`.

### 5.1 Fetch policy

- App mode: **server-side** filtering — one `GET /api/items` with `list_id` (list view only), `status` (only when ≠ all), `q` (when non-empty). Status change / debounced query change → refetch. Sidebar counts come from `GET /api/lists` (refetched in the same parallel batch).
- Share mode: `GET /api/shared/{token}` returns **all** items (no status/q params exist) → filter `status`/`q` **client-side** over `share.items`, exactly like JS `shareFilteredItems()`.
- Initial load and every manual refresh: `Promise`-style parallel fetch of lists + items; `loading=true` only on first load / view switch (skeleton rows), never on background polls.

### 5.2 Polling (5s) that never clobbers mutation state

`Timer.periodic(5s)` tick → **skip** when ANY of: a fetch already in flight; page not visible (`WidgetsBindingObserver.didChangeAppLifecycleState` — Flutter web reports `hidden` for backgrounded tabs; fire one immediate tick on return to `resumed`); `dialogOpen` (any modal/sheet/dialog open); `rearrangeActive`; `mutating > 0` (a mutation is in flight); `pointerDown` (a drag/scroll gesture is active — a rebuild would kill an in-progress drag); and an additional `_mutationGrace` window of **1.2s after any mutation ends** — a poll started during/just after a write can carry a SQLite pre-commit read-snapshot (the connection's snapshot predates the commit) and clobber the committed state; the mutation's own settle refresh is the authority in that window.

Staleness guard: each fetch captures `_gen`; mutations increment `_gen` when they start **and when they end**. A poll/refresh response is **discarded** if `_gen` changed while it was in flight (a mutation started mid-fetch — its state must win until its own settle-refresh; or a mutation ended — the poll may be carrying a pre-commit snapshot). On settle of every mutation → one authoritative silent refresh (live-sync latency ≤ mutation duration + one RTT, not 5s).

### 5.3 Mutations

- **Toggle done (the only optimistic op):** flip `done` locally + rebuild display order, disable that row's checkbox, `mutating++`, `_gen++` (begin). On response: replace item from `envelope.item`; if `envelope.spawned != null`, insert it at the **top of the pending block** and toast `Repeats <formatted due>`; silent refresh. On error: revert the flip, toast `detail`, silent refresh. (`_gen++` on end too.)
- **Create (quick-add):** POST first, then the row appears **immediately from the POST's own 201 response body** (the server returns the created item — no second round-trip is required for visibility). The composer clears its field instantly on submit (rapid entry), and the insert is context-guarded (same list/filter/query, item visible, id not already present). A background silent refresh then reconciles counts/order — never on the user's path. Client-side: no placeholder, no pending map, no merge machinery — the row exists only once the server has committed it, so **no poll, lifecycle rebuild, or stale snapshot can ever make it flash or lag**. (This replaces the earlier "await POST then refresh" variant, whose visible latency depended on a second GET; and the pre-clean "optimistic placeholder" variant, whose races required merge funnels.)
- **Edit / delete / rename list / delete list / share ops:** no optimism — await + silent refresh (progress state on the submit button). Matches the JS client.
- All mutations go through the right path: shared view ⇒ `/api/shared/{token}/...` (no `list_id` in bodies); app ⇒ `/api/items` etc.

## 6. File layout (skill: core/data/domain/presentation + feature modules)

```
lib/main.dart                 bootstrap: ProviderScope, ensureInitialized, SharedPreferences
                              (fallback in-memory), MaterialApp.router(routerProvider)
lib/app.dart                  TaskflowApp: theme (ThemeController), go_router
lib/config.dart               apiBaseUrl const (String.fromEnvironment), pollInterval=5s const
lib/theme.dart                light/dark ColorScheme (indigo accent #5E6AD2/#6B77E0, calm neutrals),
                              Material 3
lib/core/router/app_router.dart   go_router: '/' HomeShell; '/share/:token' ShareRoute
lib/core/theme/app_theme.dart     (alias re-export of theme.dart if desired)
lib/data/models/*.dart        Freezed models: task_list.dart, task_item.dart, shared_list.dart,
                              share_link.dart, item_envelope.dart, enums.dart (+ *.g.dart)
lib/data/repositories/taskflow_repository.dart   wraps ApiClient: typed methods the controllers
                              call (thin; keeps API shapes out of providers)
lib/data/services/api_client.dart    ApiClient + ApiException + whitelist body builders
lib/presentation/providers/*.dart    Riverpod providers: api_client, theme, lists, items,
                              view_controller, share_controller, mutation_bus, router
lib/presentation/common/*.dart  shared widgets (empty states, skeleton, confirm dialog, trace overlay)
lib/presentation/features/home/home_shell.dart   responsive Scaffold: rail (≥1000px)
                              / AppBar+Drawer; quick-add composer is the primary add (no FAB)
lib/presentation/features/home/app_view.dart     All/List view: header, filter bar, list,
                              pinned QuickAddBar (submits to ItemsController.createItem)
lib/presentation/features/share/share_view.dart  share header, read-only UI when permission=read
lib/presentation/features/items/item_edit_sheet.dart  create/edit dialog (title, notes, date,
                              priority, quantity, recurrence + interval, list picker in All view)
lib/presentation/features/home/widgets/list_sidebar.dart   nav: All tasks + lists + New list
lib/presentation/features/home/widgets/item_row.dart      checkbox/title/chips/trailing drag handle
lib/presentation/features/home/widgets/item_list_view.dart  hairline-divided reorderable list;
                              drag handle (immediate) + hold-to-drag; optional ScrollController
lib/presentation/features/home/widgets/quick_add_bar.dart  inline composer: title field + send,
                              list picker in All view, busy spinner, error toast; field never
                              disabled so the keyboard stays up; scrolls list to top on add
lib/presentation/features/home/widgets/filter_bar.dart    SegmentedButton + search (debounced)
lib/presentation/features/share/share_dialog.dart         create/revoke share
lib/core/trace_log.dart, lib/presentation/common/trace_overlay.dart  debug-only (TRACE_ADD define)
test/models_test.dart         fromJson: timestamps w/ 'Z'+micros, null dates, qty int/float, unknown keys
test/api_client_test.dart     MockClient: envelopes per §2.2, 204-no-body, ApiException detail mapping
test/state_test.dart          reorder ordinal math, done-boundary clamp, poll merge staleness, share filter
test/widget_test.dart         smoke: shell renders, toggle calls PATCH (ProviderScope overrides)
```

## 7. Widget tree

```
ProviderScope
└─ TaskflowApp (MaterialApp.router, theme from ThemeController, title 'Taskflow')
   └─ HomeShell (Scaffold)                     mode=share ⇒ ShareView; else AppView
      ├─ width ≥1000: NavigationRail (extended)      <1000: Drawer + AppBar hamburger
      │   └─ ListSidebar: All tasks | lists… | New list
      ├─ AppBar: brand, search (narrow screens), theme toggle
      └─ body
         ├─ AppView (Column)
         │   ├─ view header: 'All tasks'/'<list>' + counts · filter SegmentedButton
         │   │   · actions: rename/share/delete (list view)
         │   ├─ Expanded: loading ? skeleton
         │   │   : items.isEmpty ? EmptyState : ReorderableListView.builder
         │   │        (item ⇒ ItemRow(key: ValueKey(id), onTap→edit sheet), hairline dividers)
         │   └─ QuickAddBar (pinned, never a modal — rapid entry)
         └─ ShareView (Column)
             ├─ identity header: list name + 'Read-only'/'Can edit' badge + Open Taskflow
             ├─ filter SegmentedButton + search (client-side)
             └─ list as above; read-only ⇒ rows without drag handles, no long-press drag
```

ReorderableListView details: `buildDefaultDragHandles: false`; every row wrapped in `ReorderableDelayedDragStartListener(index: i, child: ItemRow(...))` (hold ~500ms starts drag; short tap still opens edit), with a **trailing six-dot drag handle** (`ReorderableDragStartListener`, immediate drag, `Icons.drag_indicator`) — present whenever reorder is permitted (list view in app mode; shared view with `permission=edit`), absent in All view, read-only shares, and while `query != ''`. Rows are separated by hairline dividers (indented under the checkbox, none after the last row).

## 8. Reorder mapping (drag → server ordinals)

**Permitted only when** `(mode==app && view==list) || (mode==share && share.canEdit)`, and `query == ''` (search hides rows, so visible ordinals ≠ server group ordinals — the JS client misses this guard; it is a deliberate fix here, not parity). Status filter pending/done is fine (whole visible list == one group). **Never in All view** (cross-list position is meaningless).

Because server order is authoritative and client order is always the server array order, the visible list == the server's `(position,id)` order of every **visible** group row. With `query==''` every group row is visible, so:

- **Drag (ReorderableListView `onReorder(oldIndex, newIndex)`):** `newIndex > oldIndex ⇒ newIndex--` (post-removal index). Let `g` = display rows with `done == dragged.done` (in order), `oldOrd = indexOf(dragged)` in `g`. Target ordinal `k` = number of g-rows that precede position `newIndex` in the post-removal list; clamp `k` to `[0, g.length-1]`. If `k == oldOrd` ⇒ nothing to do (still silent-refresh). Else: optimistically rebuild `g` (remove at `oldOrd`, insert at `k`) and setState (other group unchanged), then `PATCH {'move_to': k}`; on error roll back the saved snapshot; always finish with a silent refresh (server truth — it also re-bumps positions and may clamp differently).
- **Done-group boundary rule (filter=all):** dragging a pending row down into the done block clamps `k` to the last pending ordinal; the on-drop rebuild snaps it back under the last pending row (the row may momentarily animate into done territory — ReorderableListView has no drop veto; the synchronous rebuild + refresh corrects it in the same frame cycle). Cross-group moves are impossible server-side (`move_to` is same-group only) — the clamp guarantees the PATCH never crosses. Same for done rows dragged up.
- Poll is suppressed during the gesture and the PATCH (`pointerDown`, `mutating>0`), so no rebuild can kill a drag or clobber the optimistic order.

## 9. Theme, persistence, API base URL

- **Theme:** `theme.dart` builds Material 3 `ColorScheme`s from the backend's design tokens (light bg `#FAFAFB`/dark `#0F0F13`, accent indigo `#5E6AD2`/`#6B77E0`, priority colors `#E5484D`/`#B25E09`/`#30A46C`). Toggle cycles light→dark→system. 
- **Persistence:** `shared_preferences` (web ⇒ localStorage, Android ⇒ SharedPreferences) for `taskflow.theme` and `taskflow.view` (last list). `getInstance()` wrapped in try/catch — on failure (private mode) fall back to in-memory defaults; never crash. Keys namespaced `taskflow.*`.
- **API base URL:** `lib/config.dart`:
  ```dart
  const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000');
  ```
  Trailing `/` stripped. Run web with `flutter run -d chrome --dart-define=API_BASE_URL=…` (cross-origin from the dev server is fine — backend CORS `allow_origins=["*"]`; keep `127.0.0.1` to match the backend's bind). Android: `--dart-define=API_BASE_URL=http://10.0.2.2:8000` for the emulator. Share links: display the server-provided `url` verbatim (`http://<base>/share/<token>` — the JS PWA route; the Flutter app opens shares by token in-app, parsed from its own URL or pasted).

## 10. Contract gotchas checklist (design-time traps)

1. Sort is `done, position, id` — priority/due_date play no part; never sort client-side by priority.
2. Item JSON includes `position`; server-owned fields (`id`, `position`, timestamps, counts) must never be echoed into POST/PATCH bodies (`extra="forbid"` ⇒ 422).
3. Envelope shape differs: toggle/edit → `{item, spawned}`; `move` → `{item, swapped}` (no `spawned` key); **`move_to` → `{item, spawned: null}`**; POST create → bare Item; DELETE → 204 empty.
4. New items + recurrence spawns land at **pending-top**, not appended.
5. `move` at group edge = 200 no-op (not an error); `move_to` K clamps to last slot; K==current no-op.
6. `move`/`move_to` cannot combine with any other PATCH field (422); PATCH `{}` ⇒ 400.
7. `done:true` when already done never spawns (idempotent double-click guard); spawn only on false→true with recurrence ≠ none; completed occurrence stays visible.
8. Recurrence interval: required iff custom; sending it while non-custom (or failing to clear it when leaving custom) ⇒ 422 merged-state rule.
9. Shared writes forbid `list_id` entirely; read-only token ⇒ 403; shared item PATCH targets must belong to the shared list (else 404).
10. `due_date` is a date-only string — lexicographic compare for overdue/today/future; parse timestamps with `DateTime.parse` (handles `Z` + micros).
11. `q`/`status` are server-side in app mode, but the shared endpoint has no such params — client-side filter there.
12. Unknown `list_id` on GET ⇒ `200 []`; 409 (not 404) when a POST/PATCH body references a missing list.
13. GET /api/items for All view omits `list_id`; cross-list display order is backend-arbitrary — never attempt reorder there.
14. Reorder disabled whenever search text is non-empty (hidden rows break ordinal mapping).
15. API responses are `Cache-Control: no-store`; Flutter's `http` doesn't cache, but never rely on browser caching either — always refetch on view change.

## 11. Acceptance mapping (SPEC R5)

`flutter analyze` clean · `flutter test` (model parse, envelope/client via MockClient, reorder ordinal math incl. boundary clamp, poll staleness, widget smoke) · `flutter build web` · E2E in Chromium against the live backend: list/create/toggle(+spawn toast)/reorder-arrow/drag/share-readonly/5s two-tab live-sync.
