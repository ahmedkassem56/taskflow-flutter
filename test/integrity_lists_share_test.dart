// LISTS CRUD integrity + SHARE flows, driven through the REAL app stack
// (TaskflowApp + ApiClient + providers) against the shared SnapshotServer.
//
// Lists cases exercise commitLag semantics: the harness computes every
// response body at request arrival, so a refresh that lands inside the
// server's commit window carries pre-commit state. The lists controller's
// gen guard + pending-rename guard must keep renames/creates/deletes
// authoritative on screen regardless.
//
// SHARE cases: the SnapshotServer's share endpoints return payloads that
// VIOLATE the server contract the app implements (see api_client.dart +
// share_link.dart / shared_list.dart — the real backend sends `url` on
// POST /api/lists/{id}/shares and `items` inside GET /api/shared/{token}):
//   * POST /api/lists/2/shares -> {token, list_id, permission, created_at}
//     (no `url`; ShareLink.fromJson does `json['url'] as String` -> throws)
//   * GET /api/shared/tok1     -> {list, permission}
//     (no `items`; SharedList.fromJson does `json['items'] as List` -> throws)
// So the raw harness can never drive the app's share dialog / share page.
// Instead of editing the helper, [ShareConformantServer] (defined below,
// additive) subclasses it and injects the two missing keys into those exact
// responses — a no-op pass-through for every other endpoint. All assertions
// still run through the real repository/controller/dialog code, and srv.log
// / srv.shares record every request on the base server.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taskflow_app/app.dart';
import 'package:taskflow_app/data/services/api_client.dart';
import 'package:taskflow_app/presentation/features/home/home_shell.dart';
import 'package:taskflow_app/presentation/features/share/share_view.dart';
import 'package:taskflow_app/presentation/providers/api_client.dart';
import 'package:taskflow_app/presentation/providers/router.dart';

import 'helpers/pump_app.dart';
import 'helpers/snapshot_server.dart';

/// SnapshotServer with the share payloads the app's models actually expect
/// (see file comment). Only rewrites:
///   * the 201 of `POST /api/lists/{id}/shares`  -> adds `url`
///   * the 200 of `GET  /api/shared/{token}`     -> adds `items`
/// Everything else passes through untouched; request logging/state mutation
/// happen in the base class before this wrapper runs.
class ShareConformantServer extends SnapshotServer {
  @override
  Future<http.Response> handle(http.Request r) async {
    final http.Response res = await super.handle(r);
    final String p = r.url.path;
    final RegExpMatch? create =
        RegExp(r'^/api/lists/(\d+)/shares$').firstMatch(p);
    if (r.method == 'POST' && create != null && res.statusCode == 201) {
      final Map<String, dynamic> body =
          jsonDecode(res.body) as Map<String, dynamic>;
      body['url'] = 'http://127.0.0.1:8000/share/${body['token']}';
      return _rewrite(res, body);
    }
    if (r.method == 'GET' &&
        p.startsWith('/api/shared/') &&
        !p.endsWith('/items') &&
        res.statusCode == 200) {
      final Map<String, dynamic> body =
          jsonDecode(res.body) as Map<String, dynamic>;
      final int listId =
          (body['list'] as Map<String, dynamic>)['id'] as int;
      body['items'] = _canonicalJson(
        items.where((Map<String, dynamic> i) => i['list_id'] == listId),
      );
      return _rewrite(res, body);
    }
    return res;
  }

  http.Response _rewrite(http.Response orig, Object body) =>
      http.Response(jsonEncode(body), orig.statusCode,
          headers: <String, String>{'content-type': 'application/json'});

  /// Mirrors the base server's canonical (done, position, id) ordering.
  List<Map<String, dynamic>> _canonicalJson(
      Iterable<Map<String, dynamic>> rows) {
    final List<Map<String, dynamic>> out =
        List<Map<String, dynamic>>.of(rows);
    out.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final bool ad = a['done'] as bool, bd = b['done'] as bool;
      if (ad != bd) return ad ? 1 : -1;
      final int ap = (a['position'] as num).toInt();
      final int bp = (b['position'] as num).toInt();
      if (ap != bp) return ap.compareTo(bp);
      return (a['id'] as int).compareTo(b['id'] as int);
    });
    return out;
  }
}

/// Pumps TaskflowApp starting on the share route (mirrors the app router's
/// `/share/:token` route — the real app reaches it only via a boot-time URL,
/// which widget tests cannot set).
Future<void> pumpShareApp(
  WidgetTester tester,
  SnapshotServer srv,
  String location,
) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final GoRouter router = GoRouter(
    initialLocation: location,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeShell(),
      ),
      GoRoute(
        path: '/share/:token',
        builder: (BuildContext context, GoRouterState state) =>
            SharePage(token: state.pathParameters['token'] ?? ''),
      ),
    ],
  );
  await tester.pumpWidget(ProviderScope(
    overrides: [
      apiClientProviderProvider.overrideWithValue(
          ApiClient('http://x', client: MockClient(srv.handle))),
      routerProviderProvider.overrideWithValue(router),
    ],
    child: const TaskflowApp(),
  ));
  await tester.pumpAndSettle();
}

/// Past-the-lag + one 5s poll tick pump (fires the items controller's
/// periodic refresh so any pre-commit state would have to surface now).
Future<void> pumpPastLagAndPoll(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 120)); // commit window
  await tester.pump(const Duration(seconds: 5)); // poll tick
  await tester.pumpAndSettle();
}

Future<void> openDrawer(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('drawer-button')));
  await tester.pumpAndSettle();
}

Future<void> closeDrawer(WidgetTester tester) async {
  // Tap the modal scrim right of the 304px drawer (dragging the drawer body
  // is not reliably claimed by the DrawerController in tests).
  await tester.tapAt(const Offset(370, 300));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LISTS CRUD integrity', () {
    testWidgets('rename survives commitLag: header + sidebar show the new '
        'name and it never reverts after polls', (WidgetTester tester) async {
      final SnapshotServer srv = await pumpApp(tester);
      srv.commitLag = const Duration(milliseconds: 60);

      await openList(tester, 'Groceries');
      expect(find.text('Groceries'), findsWidgets);

      await renameCurrentList(tester, 'Errands');
      await tester.pump(const Duration(milliseconds: 60)); // lag window

      // Header shows the new name immediately (local apply of the PATCH).
      expect(find.text('Errands'), findsOneWidget,
          reason: 'renamed list must show its new name in the header');
      expect(find.text('Groceries'), findsNothing,
          reason: 'old name must be gone from the header');

      // Sidebar (drawer) reflects the rename too.
      await openDrawer(tester);
      expect(
        find.descendant(
            of: find.byType(Drawer), matching: find.text('Errands')),
        findsOneWidget,
        reason: 'renamed list must appear in the sidebar');
      expect(
        find.descendant(
            of: find.byType(Drawer), matching: find.text('Groceries')),
        findsNothing,
        reason: 'old name must be gone from the sidebar');
      await closeDrawer(tester);

      // Survive a full poll cycle (and then some): no pre-commit snapshot
      // may roll the name back.
      await pumpPastLagAndPoll(tester);
      expect(find.text('Errands'), findsOneWidget,
          reason: 'rename must persist after polls (no revert)');
      expect(find.text('Groceries'), findsNothing);
      expect(srv.lists.singleWhere((Map<String, dynamic> l) =>
          l['id'] == 1)['name'], 'Errands');
      expect(srv.log, contains('PATCH /api/lists/1'));
    });

    testWidgets('rapid rename A->B: two overlapping renames settle on B and '
        'A never resurfaces', (WidgetTester tester) async {
      final SnapshotServer srv = await pumpApp(tester);
      srv.commitLag = const Duration(milliseconds: 60);
      await openList(tester, 'Groceries');

      // Hold the FIRST rename's settle refresh in flight (its response body
      // is computed at arrival and carries name 'A').
      final Completer<void> gate = srv.holdNext('GET /api/lists');

      // Rename 1 -> 'A', leaving its settle refresh held.
      await tester.tap(find.byTooltip('List actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'A');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('A'), findsWidgets,
          reason: 'first rename applied locally before its refresh lands');

      // Rename 2 -> 'B' while rename 1's refresh is STILL in flight.
      await tester.tap(find.byTooltip('List actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'B');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('B'), findsWidgets,
          reason: 'second rename applied locally');

      // Release rename 1's stale (pre-B) refresh. The gen guard must
      // discard it — it must not resurrect 'A'.
      gate.complete();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('B'), findsWidgets,
          reason: 'overlapping rename must settle on the LAST name');
      expect(find.text('A'), findsNothing,
          reason: 'stale refresh from the first rename must not revert UI');

      // Poll cycle: 'A' must never resurface.
      await pumpPastLagAndPoll(tester);
      expect(find.text('B'), findsWidgets);
      expect(find.text('A'), findsNothing);
      expect(srv.lists.singleWhere((Map<String, dynamic> l) =>
          l['id'] == 1)['name'], 'B');
    });

    testWidgets('delete a NON-current list from the sidebar: it and its items '
        'leave the UI and do not come back after polls',
        (WidgetTester tester) async {
      final SnapshotServer srv = await pumpApp(tester);
      srv.commitLag = const Duration(milliseconds: 60);
      // Boot view is All tasks. Bring the items list to a settled,
      // post-poll state first so Work's item is deterministically on screen
      // (its disappearance after the delete is what this test proves).
      await pumpPastLagAndPoll(tester);
      expect(find.text('Report'), findsOneWidget);

      await openDrawer(tester);
      // Scoped finder: Work row's own overflow button (drawer rows all share
      // the 'List actions' tooltip, so scope to Work's row Material).
      final Finder drawer = find.byType(Drawer);
      final Finder workRow = find
          .ancestor(
            of: find.descendant(of: drawer, matching: find.text('Work')),
            matching: find.byType(Material),
          )
          .first;
      await tester.tap(
          find.descendant(of: workRow, matching: find.byTooltip('List actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();
      // Confirm dialog ('Delete list?' -> Delete).
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Sidebar no longer lists Work; Groceries remains.
      expect(
        find.descendant(of: drawer, matching: find.text('Work')),
        findsNothing,
        reason: 'deleted list must leave the sidebar');
      expect(
        find.descendant(of: drawer, matching: find.text('Groceries')),
        findsOneWidget);
      expect(srv.lists, hasLength(1));
      expect(srv.log, contains('DELETE /api/lists/2'));
      await closeDrawer(tester);

      // Items from the deleted list vanish from the All view once the next
      // fetch runs (the client never fabricates rows; the server dropped
      // Work + its items at the DELETE).
      await pumpPastLagAndPoll(tester);
      expect(find.text('Report'), findsNothing,
          reason: 'items of a deleted list must vanish from the All view');
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
      // Another poll cycle: nothing resurrects.
      await pumpPastLagAndPoll(tester);
      expect(find.text('Report'), findsNothing);
      expect(
        find.descendant(
            of: find.byType(Drawer), matching: find.text('Work')),
        findsNothing,
        reason: 'deleted list must not come back after polls');
    });

    testWidgets('delete the CURRENT list from the header: the app falls back '
        'to All tasks', (WidgetTester tester) async {
      final SnapshotServer srv = await pumpApp(tester);
      srv.commitLag = const Duration(milliseconds: 60);
      await openList(tester, 'Groceries');
      expect(find.text('Groceries'), findsWidgets);

      // Header 'List actions' popup -> Delete.
      await tester.tap(find.byTooltip('List actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete')); // confirm dialog
      await tester.pumpAndSettle();

      // Fell back to All tasks; the list is gone from the server.
      expect(find.text('All tasks'), findsWidgets,
          reason: 'deleting the current list must fall back to the All view');
      expect(find.text('Groceries'), findsNothing,
          reason: 'deleted current list must be gone');
      expect(srv.lists.singleWhere((Map<String, dynamic> l) =>
          l['id'] == 2)['name'], 'Work');
      expect(srv.log, contains('DELETE /api/lists/1'));

      // All view now shows only the surviving list's items.
      await pumpPastLagAndPoll(tester);
      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Milk'), findsNothing,
          reason: 'items of the deleted current list must vanish');
      expect(find.text('All tasks'), findsWidgets);
      expect(find.text('Groceries'), findsNothing);
    });

    testWidgets('create a list under commitLag: it appears in the sidebar and '
        'stays', (WidgetTester tester) async {
      final SnapshotServer srv = await pumpApp(tester);
      srv.commitLag = const Duration(milliseconds: 60);

      await openDrawer(tester);
      await tester.tap(find.byKey(const Key('new-list-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('list-name-field')), 'Household');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
            of: find.byType(Drawer), matching: find.text('Household')),
        findsOneWidget,
        reason: 'created list must appear in the sidebar');
      expect(srv.lists.last['name'], 'Household');
      expect(srv.log, contains('POST /api/lists'));

      // Past the commit lag and through poll cycles: it must stay.
      await pumpPastLagAndPoll(tester);
      expect(
        find.descendant(
            of: find.byType(Drawer), matching: find.text('Household')),
        findsOneWidget,
        reason: 'created list must not vanish after polls');
      expect(srv.lists, hasLength(3));
    });
  });

  group('SHARE flows', () {
    testWidgets('create a share link then revoke it (dialog round trip + '
        'server state)', (WidgetTester tester) async {
      final SnapshotServer srv = await pumpApp(
        tester,
        server: ShareConformantServer(),
      );
      srv.commitLag = const Duration(milliseconds: 60);
      await openList(tester, 'Work');
      expect(find.text('Work'), findsWidgets);

      // Header 'List actions' -> Share -> dialog.
      await tester.tap(find.byTooltip('List actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(find.text('Share list'), findsOneWidget);
      expect(find.text('Anyone with the link can view "Work".'), findsOneWidget);

      // Create an edit link.
      await tester.tap(find.byKey(const Key('share-create-button')));
      await tester.pumpAndSettle();

      // Server recorded the POST and created a second share (seed has tok1
      // for Work already).
      expect(srv.log, contains('POST /api/lists/2/shares'));
      expect(srv.shares, hasLength(2));
      final String token = srv.shares.last['token'] as String;
      expect(token, 'tok2');
      // Dialog shows the new link URL (captured from the 201 payload).
      expect(find.textContaining('/share/$token'), findsOneWidget,
          reason: 'created share link must be listed in the dialog');

      // Revoke it through the dialog.
      await tester.tap(find.byTooltip('Revoke link'));
      await tester.pumpAndSettle();

      expect(srv.log, contains('DELETE /api/shares/$token'));
      expect(srv.shares, hasLength(1),
          reason: 'revoked share must be gone from the server');
      expect(find.text('Share link revoked'), findsOneWidget,
          reason: 'revoke must surface UI feedback');
      expect(find.textContaining('/share/$token'), findsNothing,
          reason: 'revoked link must leave the dialog');
    });

    testWidgets('open a shared list (edit token): list name, items and '
        'edit affordances render from GET /api/shared/{token}',
        (WidgetTester tester) async {
      final ShareConformantServer srv = ShareConformantServer();
      // Seed share: tok1 -> list 2 (Work), edit.
      await pumpShareApp(tester, srv, '/share/tok1');

      expect(srv.log, contains('GET /api/shared/tok1'));
      expect(find.text('Work'), findsWidgets,
          reason: 'shared list name must render in the app bar/header');
      expect(find.text('Can edit'), findsOneWidget,
          reason: 'edit token renders the Can edit badge');
      expect(find.text('Report'), findsOneWidget,
          reason: 'shared list items must render');
      expect(find.byKey(const Key('share-add-button')), findsOneWidget,
          reason: 'edit tokens get the add-task affordance');
    });

    testWidgets('open a shared list (read token): read-only chrome, no '
        'write affordances', (WidgetTester tester) async {
      final ShareConformantServer srv = ShareConformantServer();
      srv.addShare(1, 'read'); // tok2 -> list 1 (Groceries), read-only
      await pumpShareApp(tester, srv, '/share/tok2');

      expect(srv.log, contains('GET /api/shared/tok2'));
      expect(find.text('Groceries'), findsWidgets);
      expect(find.text('Read-only'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
      expect(find.byKey(const Key('share-add-button')), findsNothing,
          reason: 'read-only tokens must not offer to add tasks');
    });
  });
}
