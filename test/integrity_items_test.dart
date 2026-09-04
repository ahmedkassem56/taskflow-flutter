// TASK-list CRUD integrity under the server's commit-lag / snapshot races.
//
// The real backend commits mutations AFTER sending the response (FastAPI
// dependency-teardown commit), so any fetch whose read snapshot predates a
// commit delivers pre-commit state. SnapshotServer.commitLag models the
// delete-commit deferral; holdNext lets a test hold an in-flight GET (body
// computed at arrival) and deliver it late — i.e. a stale snapshot. Each case
// drives the real UI and asserts on row titles.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taskflow_app/presentation/features/home/widgets/item_row.dart';

import 'helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Finder rowText(String title) => find.descendant(
      of: find.byType(ItemRow), matching: find.text(title));

  Finder checkboxOf(String title) => find.descendant(
      of: find.byWidgetPredicate(
          (Widget w) => w is ItemRow && w.item.title == title),
      matching: find.byType(Checkbox));

  double yOf(WidgetTester tester, String title) =>
      tester.getTopLeft(find.text(title).first).dy;

  double rowHeightOf(WidgetTester tester, String title) => tester
      .getSize(find.byWidgetPredicate(
          (Widget w) => w is ItemRow && w.item.title == title))
      .height;

  testWidgets('toggle: done flip survives a stale poll snapshot (commit lag)',
      (WidgetTester tester) async {
    final srv = await pumpApp(tester);
    srv.commitLag = const Duration(milliseconds: 80);
    await openList(tester, 'Groceries'); // All filter: Milk, Eggs, Bread(done)

    expect(rowText('Milk'), findsOneWidget);
    expect(yOf(tester, 'Milk'), lessThan(yOf(tester, 'Eggs')));

    // Fire a poll whose GET arrives BEFORE the toggle (its snapshot still has
    // Milk pending) and hold its delivery until after the toggle committed.
    final Completer<void> stalePoll = srv.holdNext('GET /api/items');
    await tester.pump(const Duration(seconds: 5)); // poll tick -> GET held
    await tester.pump();

    // Toggle Milk done while that stale poll is in flight.
    await tester.tap(checkboxOf('Milk'));
    await tester.pump(); // optimistic flip + PATCH round-trip starts
    await tester.pump(const Duration(milliseconds: 120)); // commit window

    // The stale response lands now: it still shows Milk pending. It must be
    // discarded (gen guard) so the optimistic done-flip is kept.
    stalePoll.complete();
    await tester.pumpAndSettle();

    expect(
      yOf(tester, 'Eggs'),
      lessThan(yOf(tester, 'Milk')),
      reason: 'Milk must stay done (sorted below pending Eggs) once the '
          'pre-toggle poll snapshot lands',
    );
    expect(rowText('Milk'), findsOneWidget);

    // Filter semantics: Done shows Milk, Pending does not.
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(rowText('Milk'), findsOneWidget,
        reason: 'Milk must appear under the Done filter');
    await tester.tap(find.text('Pending'));
    await tester.pumpAndSettle();
    expect(rowText('Milk'), findsNothing,
        reason: 'done Milk must not appear under Pending');
    expect(rowText('Eggs'), findsOneWidget);

    // Back to All: a real post-commit poll tick must keep the toggle.
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(yOf(tester, 'Eggs'), lessThan(yOf(tester, 'Milk')),
        reason: 'post-commit poll must not revert the done flip');
    expect(
        srv.log.where((String l) => l == 'PATCH /api/items/1'), hasLength(1));
  });

  testWidgets('create: new row lands exactly once and persists (commit lag)',
      (WidgetTester tester) async {
    final srv = await pumpApp(tester);
    srv.commitLag = const Duration(milliseconds: 80);
    await openList(tester, 'Groceries');

    await quickAdd(tester, 'Oats');

    // Row appears from the POST's own 201 (commit happens after the response
    // on the real server) and must never duplicate or vanish.
    expect(rowText('Oats'), findsOneWidget,
        reason: 'new row must appear exactly once');
    expect(rowText('Milk'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 120)); // commit window
    await tester.pump(const Duration(seconds: 5)); // poll tick
    await tester.pumpAndSettle();
    expect(rowText('Oats'), findsOneWidget,
        reason: 'row must stay exactly once after polls land');
    expect(rowText('Milk'), findsOneWidget);
    expect(srv.log.where((String l) => l == 'POST /api/items'), hasLength(1));
  });

  testWidgets('edit: retitled row sticks under commit lag and later polls',
      (WidgetTester tester) async {
    final srv = await pumpApp(tester);
    srv.commitLag = const Duration(milliseconds: 80);
    await openList(tester, 'Groceries');

    // Tap the row title -> edit sheet.
    await tester.tap(rowText('Milk'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('item-title-field')), 'Milk 2%');
    await tester.tap(find.byKey(const Key('item-save-button')));
    await tester.pumpAndSettle();

    expect(rowText('Milk 2%'), findsOneWidget,
        reason: 'new title must show after save');
    expect(find.text('Milk'), findsNothing,
        reason: 'old title must be gone after save');

    // Past the commit lag and another poll tick: still the new title.
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(rowText('Milk 2%'), findsOneWidget,
        reason: 'retitle must survive later polls');
    expect(find.text('Milk'), findsNothing);
    expect(srv.log.where((String l) => l == 'PATCH /api/items/1'), hasLength(1));
  });

  testWidgets('reorder: dragged order holds under commit lag (no snap back)',
      (WidgetTester tester) async {
    final srv = await pumpApp(tester);
    srv.commitLag = const Duration(milliseconds: 80);
    await openList(tester, 'Groceries'); // list view: reorderable

    expect(yOf(tester, 'Milk'), lessThan(yOf(tester, 'Eggs')));

    // Drag Milk's handle below Eggs (id 1 = Milk in the seeded server).
    await tester.drag(
      find.byKey(const Key('row-drag-handle-1')),
      Offset(0, rowHeightOf(tester, 'Milk') * 1.6),
    );
    await tester.pumpAndSettle(); // reorder animation + PATCH + settle
    await tester.pump(const Duration(milliseconds: 120)); // commit window
    await tester.pumpAndSettle();

    expect(yOf(tester, 'Eggs'), lessThan(yOf(tester, 'Milk')),
        reason: 'drag must have moved Milk below Eggs');

    // A reconcile poll (5s tick) must not snap the order back.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(yOf(tester, 'Eggs'), lessThan(yOf(tester, 'Milk')),
        reason: 'post-reorder poll must not restore the old order');
    expect(srv.log.where((String l) => l == 'PATCH /api/items/1'), isNotEmpty);
  });

  testWidgets('rapid double-create: both rows land once (overlapping settles)',
      (WidgetTester tester) async {
    final srv = await pumpApp(tester);
    await openList(tester, 'Groceries');

    // Hold create #1's settle-refresh GET so create #2's mutation overlaps it.
    final Completer<void> hold = srv.holdNext('GET /api/items');

    await tester.enterText(find.byKey(const Key('quick-add-field')), 'Alpha');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump(); // POST #1 resolves; row inserted; settle #1 held
    expect(rowText('Alpha'), findsOneWidget);

    // Second send immediately after the first settles — no pumpAndSettle gap.
    await tester.enterText(find.byKey(const Key('quick-add-field')), 'Beta');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    expect(rowText('Beta'), findsOneWidget);

    // Release settle #1: its snapshot predates Beta (and its gen is stale),
    // so it must be discarded — not clobber the list.
    hold.complete();
    await tester.pumpAndSettle();

    expect(rowText('Alpha'), findsOneWidget,
        reason: 'first create must survive the overlapping settle');
    expect(rowText('Beta'), findsOneWidget,
        reason: 'second create must not be lost');
    expect(srv.log.where((String l) => l == 'POST /api/items'), hasLength(2));

    // Later poll tick: both still present exactly once.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(rowText('Alpha'), findsOneWidget);
    expect(rowText('Beta'), findsOneWidget);
  });

  testWidgets('delete: row stays gone under commit lag incl. later polls',
      (WidgetTester tester) async {
    final srv = await pumpApp(tester);
    srv.commitLag = const Duration(milliseconds: 60);
    await openList(tester, 'Groceries');
    expect(rowText('Eggs'), findsOneWidget);

    // The 204 returns before the commit; the delete's own settle refresh reads
    // pre-commit state (Eggs still present) and must be discarded.
    await deleteItemRow(tester, 'Eggs');
    await tester.pump(const Duration(milliseconds: 120)); // commit lands
    await tester.pumpAndSettle();
    expect(rowText('Eggs'), findsNothing,
        reason: 'deleted item must stay gone even if the settle refresh read '
            'pre-commit state');

    // A later poll reads the committed state: still gone.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(rowText('Eggs'), findsNothing,
        reason: 'later polls must not resurrect the deleted row');
    expect(srv.log.where((String l) => l == 'DELETE /api/items/2'), hasLength(1));
  });
}
