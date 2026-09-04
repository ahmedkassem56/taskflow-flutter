// Integrity coverage for VIEW / FILTER / SEARCH / ERROR paths, driven through
// the real widget tree against the shared SnapshotServer harness
// (test/helpers/snapshot_server.dart + pump_app.dart).
//
// Cases:
//  * All view unions every list (with list-name chips) and the drawer
//    isolates a list; back to All shows the union again. A mid-navigation
//    stale GET for the previous list must NOT clobber the new list's rows.
//  * Status filter Pending/Done/All + optimistic drop when toggling under the
//    Done filter.
//  * Debounced search: server-side q=, clear restores the full list, no-match
//    shows the empty state.
//  * Error paths: failed quick-add POST (SnackBar + typed text restored),
//    failed lists GET (last-good lists kept), failed item DELETE (SnackBar +
//    row stays).
//  * Empty states: an empty list and an empty All view.
//  * Rapid view switching after quickAdd: the new item lives in its own list
//    only, never duplicated across lists.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taskflow_app/presentation/common/empty_states.dart';

import 'helpers/pump_app.dart';
import 'helpers/snapshot_server.dart';

/// Drawer navigation that scopes the tap to the drawer, so body text behind
/// the scrim (chips, pickers, the header) can never shadow the target row.
Future<void> _navDrawer(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('drawer-button')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: find.byType(Drawer), matching: find.text(name)).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('view integrity', () {
    testWidgets(
        'All view unions lists with chips; drawer isolates; back to All restores the union',
        (WidgetTester tester) async {
      await pumpApp(tester);

      // All view: every seeded row is present once.
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);

      // List-name chips ride on the rows (scoped to the row's own key so the
      // quick-add list picker's 'Groceries' text can't pollute the count).
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<int>(1)), // Milk (Groceries)
          matching: find.text('Groceries'),
        ),
        findsOneWidget,
        reason: 'All view rows carry their list-name chip',
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<int>(4)), // Report (Work)
          matching: find.text('Work'),
        ),
        findsOneWidget,
      );
      // No reorder handles in the All view.
      expect(find.byKey(const Key('row-drag-handle-1')), findsNothing);

      // Switch into Groceries: only its rows remain, chips gone, handles on.
      await _navDrawer(tester, 'Groceries');
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Report'), findsNothing,
          reason: 'Work items must not leak into the Groceries view');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<int>(1)),
          matching: find.text('Groceries'),
        ),
        findsNothing,
        reason: 'list-name chips are an All-view affordance only',
      );
      expect(find.byKey(const Key('row-drag-handle-1')), findsOneWidget);

      // Back to All: the union (with chips again) is restored.
      await _navDrawer(tester, 'All tasks');
      expect(find.text('Report'), findsOneWidget,
          reason: 'back to All must show the cross-list union again');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<int>(4)),
          matching: find.text('Work'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('row-drag-handle-1')), findsNothing);
    });

    testWidgets(
        'mid-navigation stale GET for the previous list cannot clobber the new list (commitLag 60)',
        (WidgetTester tester) async {
      final SnapshotServer srv = await pumpApp(tester);
      srv.commitLag = const Duration(milliseconds: 60);

      // Navigate to Groceries but hold its items GET in flight, then switch
      // to Work before it lands — the classic stale-response window.
      final Completer<void> stale = srv.holdNext('GET /api/items');
      await _navDrawer(tester, 'Groceries');
      await _navDrawer(tester, 'Work');
      expect(find.text('Report'), findsOneWidget,
          reason: 'Work rows visible before the stale Groceries GET lands');

      // Release the stale Groceries response (computed at arrival = Groceries
      // rows). It must be discarded, never painted under the Work view.
      stale.complete();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Report'), findsOneWidget,
          reason: 'stale GET for the previous list must not clobber Work rows');
      expect(find.text('Milk'), findsNothing);
      expect(find.text('Eggs'), findsNothing);
      expect(find.text('Bread'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('status filter', () {
    testWidgets('Pending hides done; Done shows only done; All shows everyone',
        (WidgetTester tester) async {
      final SnapshotServer srv = await pumpApp(tester);

      await tester.tap(find.text('Pending'));
      await tester.pumpAndSettle();
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Bread'), findsNothing,
          reason: 'done rows are hidden under the Pending filter');
      expect(
        srv.log.any((String e) =>
            e.startsWith('GET /api/items') && e.contains('status=pending')),
        isTrue,
        reason: 'filter must be applied server-side via ?status=pending',
      );

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Milk'), findsNothing);
      expect(find.text('Eggs'), findsNothing);
      expect(find.text('Report'), findsNothing);
      expect(
        srv.log.any((String e) =>
            e.startsWith('GET /api/items') && e.contains('status=done')),
        isTrue,
      );

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);
    });

    testWidgets('toggling a row under the Done filter drops it optimistically',
        (WidgetTester tester) async {
      final SnapshotServer srv = await pumpApp(tester);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Bread'), findsOneWidget);

      // Tap the row's checkbox: done -> pending flips it out of the Done
      // filter immediately (optimistic, same semantics as the Pending drop).
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(srv.log, contains('PATCH /api/items/3'),
          reason: 'Bread (id 3) is PATCHed done:false');
      expect(find.text('Bread'), findsNothing,
          reason: 'an item toggled out of the active filter leaves the list');
      // No done items remain anywhere -> the Done view lands on its empty
      // state rather than a stale or blank list.
      expect(find.widgetWithText(EmptyState, 'No completed tasks'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('search', () {
    testWidgets(
        'debounced GET carries q and filters; clearing restores; no-match shows empty state',
        (WidgetTester tester) async {
      final SnapshotServer srv = await pumpApp(tester);
      final Finder search = find.byKey(const Key('filter-search'));
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);

      // Type -> 300ms debounce -> server-side ?q= fetch.
      await tester.enterText(search, 'Mil');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(
        srv.log.any((String e) =>
            e.startsWith('GET /api/items') && e.contains('q=Mil')),
        isTrue,
        reason: 'the debounced request must carry the q query param',
      );
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Eggs'), findsNothing);
      expect(find.text('Bread'), findsNothing);
      expect(find.text('Report'), findsNothing);

      // Clear via the suffix button -> debounce -> full list returns.
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);

      // A query that matches nothing shows the search empty state.
      await tester.enterText(search, 'zzz-no-such-task');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(EmptyState, 'No matching tasks'),
          findsOneWidget,
          reason: 'a no-match search must show the search empty state');
      expect(tester.takeException(), isNull);
    });
  });

  group('error paths', () {
    testWidgets('quick-add POST failure: SnackBar + typed text restored',
        (WidgetTester tester) async {
      final SnapshotServer srv = await pumpApp(tester);
      srv.failNext('POST /api/items');

      await quickAdd(tester, 'Never lands');

      expect(find.widgetWithText(SnackBar, 'boom'), findsOneWidget,
          reason: 'a failed create must never be silent');
      final TextField field = tester
          .widget<TextField>(find.byKey(const Key('quick-add-field')));
      expect(field.controller!.text, 'Never lands',
          reason: 'the composer restores the typed text so nothing is lost');
    });

    testWidgets('lists GET failure keeps last-good lists and navigation works',
        (WidgetTester tester) async {
      final SnapshotServer srv = await pumpApp(tester);
      expect(find.text('Milk'), findsOneWidget);

      srv.failNext('GET /api/lists');
      // View switches trigger a silent lists refresh (items build re-sync);
      // it fails, but the app must keep showing the last-good lists.
      await _navDrawer(tester, 'Work');
      expect(find.text('Report'), findsOneWidget,
          reason: 'navigation still works while the lists refresh fails');
      expect(find.text('Milk'), findsNothing);
      expect(tester.takeException(), isNull,
          reason: 'a failed lists refresh must not crash the app');
      expect(srv.log.where((String e) => e == 'GET /api/lists').length,
          greaterThanOrEqualTo(2),
          reason: 'boot fetch + the failed refresh both hit the wire');

      // Drawer still renders the last-good lists (no empty/error flash).
      await tester.tap(find.byKey(const Key('drawer-button')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text('Groceries')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text('Work')),
        findsOneWidget,
      );
    });

    testWidgets('item DELETE failure: SnackBar and the row stays',
        (WidgetTester tester) async {
      final SnapshotServer srv = await pumpApp(tester);
      srv.failNext('DELETE /api/items/2'); // Eggs

      await deleteItemRow(tester, 'Eggs');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SnackBar, 'boom'), findsOneWidget,
          reason: 'a failed delete must be user-visible');
      expect(find.text('Eggs'), findsOneWidget,
          reason: 'a failed delete must not remove the row optimistically');
      expect(tester.takeException(), isNull);
    });
  });

  group('empty states', () {
    testWidgets('a list with no items shows the No-tasks-yet empty state',
        (WidgetTester tester) async {
      final SnapshotServer srv = SnapshotServer()..addList('Errands');
      await pumpApp(tester, server: srv);

      await _navDrawer(tester, 'Errands');
      expect(find.widgetWithText(EmptyState, 'No tasks yet'), findsOneWidget,
          reason: 'an empty single list shows the no-tasks empty state');
      expect(find.text('Type a task below to add it.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('All view with zero items shows the All empty state',
        (WidgetTester tester) async {
      // Keep both lists (so counts/picker exist) but no items anywhere.
      final SnapshotServer srv = SnapshotServer()..items.clear();
      await pumpApp(tester, server: srv);

      expect(find.text('All tasks'), findsWidgets);
      expect(find.widgetWithText(EmptyState, 'No tasks yet'), findsOneWidget,
          reason: 'an empty All view shows the no-tasks empty state');
      expect(find.text('Type a task below to add it.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('rapid switching', () {
    testWidgets(
        'quickAdd then rapid list switch: new item is in its own list only, never duplicated',
        (WidgetTester tester) async {
      final SnapshotServer srv = await pumpApp(tester);
      srv.commitLag = const Duration(milliseconds: 60);

      await _navDrawer(tester, 'Groceries');
      await quickAdd(tester, 'Kombucha');
      expect(find.text('Kombucha'), findsOneWidget,
          reason: 'created item is visible in its own list immediately');

      // Switch away while the create's settle refresh may still be winding
      // down, then back — the item must live in Groceries only.
      await _navDrawer(tester, 'Work');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Report'), findsOneWidget,
          reason: 'Work rows show after switching away');
      expect(find.text('Kombucha'), findsNothing,
          reason: 'a Groceries item must never leak into the Work view');

      await _navDrawer(tester, 'Groceries');
      expect(find.text('Kombucha'), findsOneWidget,
          reason: 'the item is in its own list exactly once');
      expect(find.text('Report'), findsNothing);

      // And in the All union it still appears exactly once.
      await _navDrawer(tester, 'All tasks');
      expect(find.text('Kombucha'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'REAL-BUG repro: switch lists while the create settle GET is in flight — '
        'the target list must not show the previous list rows', (WidgetTester tester) async {
      // Deterministic reproduction of a pending-create-guard defect in
      // lib/presentation/providers/items.dart (_dropPreCommitSnapshots):
      // the guard registered for a just-created item is LIST-GLOBAL, so any
      // fetch of a DIFFERENT list — which legitimately cannot contain the new
      // item — is discarded as a "pre-commit snapshot". Result: after adding
      // to Groceries and immediately opening Work, the Work header renders
      // the stale Groceries rows (including the new item) until the 8s guard
      // expires. Fix direction: scope the guard to the create's own list
      // (and the All view); this test should go green once that lands.
      final SnapshotServer srv = await pumpApp(tester);
      srv.commitLag = const Duration(milliseconds: 60);

      await _navDrawer(tester, 'Groceries');
      // Hold the create's settle GET (stands in for a lagged/pre-commit
      // settle refresh on the device), then navigate away before it lands.
      final Completer<void> settle = srv.holdNext('GET /api/items');
      await quickAdd(tester, 'Kombucha');
      expect(find.text('Kombucha'), findsOneWidget);

      await _navDrawer(tester, 'Work');
      // The Work fetch fired (see log) but was discarded by the guard:
      // its response lacks the guarded Kombucha id.
      expect(find.text('Report'), findsOneWidget,
          reason: 'Work view must show Work rows, not the stale Groceries rows '
              'from the previous view — REAL BUG: pending-create guard is '
              'not list-scoped (items.dart _pendingCreateGuards)');
      expect(find.text('Kombucha'), findsNothing,
          reason: 'the Groceries item must not render under the Work header '
              '(REAL BUG, same guard)');

      // Even after the stale settle response lands nothing improves: it is
      // ctx-discarded without clearing the guard, and Work fetches keep
      // failing the guard until it expires ~8s later.
      settle.complete();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Report'), findsOneWidget,
          reason: 'REAL BUG: Work still shows stale Groceries rows after the '
              'in-flight response settles; only the guard expiry (~8s) would '
              'recover');
      expect(find.text('Kombucha'), findsNothing);
    });
  });
}
