// THE rename bug (web AND Android): an older in-flight GET /api/lists that
// started BEFORE a rename (carrying the pre-rename name) lands AFTER the
// rename applies → reverts the name on screen until restart. The lists
// controller must discard stale responses (last-start-wins, not
// last-arrival).
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taskflow_app/app.dart';
import 'package:taskflow_app/data/models/task_list.dart';
import 'package:taskflow_app/data/services/api_client.dart';
import 'package:taskflow_app/presentation/providers/api_client.dart';
import 'package:taskflow_app/presentation/providers/lists.dart';

String _iso(int d) => '2026-09-${d.toString().padLeft(2, '0')}T10:00:00.000000Z';
Map<String, dynamic> _list(int id, String name, int total, int pending) =>
    <String, dynamic>{
      'id': id, 'name': name, 'item_count': total, 'pending_count': pending,
      'created_at': _iso(1), 'updated_at': _iso(1)};
Map<String, dynamic> _item(int id, String title, int pos) => <String, dynamic>{
      'id': id, 'list_id': 1, 'title': title, 'notes': null, 'priority': 'none',
      'due_date': null, 'quantity': 1, 'position': pos, 'done': false,
      'recurrence': 'none', 'recurrence_interval': null,
      'created_at': _iso(2), 'updated_at': _iso(2)};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rename survives a stale pre-rename lists response landing late',
      (WidgetTester tester) async {
    var listName = 'Groceries';
    final items = <Map<String, dynamic>>[
      _item(1, 'Milk', 0), _item(2, 'Eggs', 1)];
    // When true, the NEXT /api/lists GET captures the name at request start
    // and is held until [staleGate] completes — exact control over when the
    // stale (pre-rename) response lands, so pumpAndSettle's clock cannot
    // accidentally land it before the rename finishes.
    var holdNextWithOldName = false;
    final Completer<void> staleGate = Completer<void>();

    http.Response json(Object b, [int s = 200]) => http.Response(jsonEncode(b), s,
        headers: <String, String>{'content-type': 'application/json'});

    Future<http.Response> backend(http.Request r) async {
      final String m = r.method, p = r.url.path;
      if (m == 'GET' && p == '/api/lists') {
        if (holdNextWithOldName) {
          holdNextWithOldName = false;
          final String nameAtStart = listName;
          await staleGate.future; // held until the test releases it
          return json(<Map<String, dynamic>>[
            _list(1, nameAtStart, items.length, items.length)]);
        }
        return json(<Map<String, dynamic>>[
          _list(1, listName, items.length, items.length)]);
      }
      if (m == 'GET' && p == '/api/items') return json(items);
      if (m == 'PATCH' && p == '/api/lists/1') {
        final name = (jsonDecode(r.body) as Map<String, dynamic>)['name'] as String;
        listName = name;
        return json(_list(1, name, items.length, items.length));
      }
      return json(<String, Object>{'detail': 'nf'}, 404);
    }

    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        apiClientProviderProvider.overrideWithValue(
            ApiClient('http://x', client: MockClient(backend)))
      ],
      child: const TaskflowApp(),
    ));
    await tester.pumpAndSettle();

    // Navigate into Groceries.
    await tester.tap(find.byKey(const Key('drawer-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Groceries').last);
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsWidgets);

    // Simulate a background lists refresh ALREADY IN FLIGHT (started before
    // the rename — e.g. the settle refresh of an item mutation a moment
    // earlier). Hold it 800ms; it carries the name as of its start.
    final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(TaskflowApp)));
    holdNextWithOldName = true;
    final Future<List<TaskList>?> staleRefresh =
        container.read(listsControllerProvider.notifier).refresh();
    await tester.pump(const Duration(milliseconds: 50)); // it's in flight now

    // Rename while that stale fetch is still in flight.
    await tester.tap(find.byTooltip('List actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Home');
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(find.text('Home'), findsWidgets,
        reason: 'rename applied immediately');

    // The stale pre-rename response is still held. Release it NOW (rename
    // fully applied + verified). It MUST be discarded by the client.
    staleGate.complete();
    await tester.pump();
    await staleRefresh;
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets,
        reason: 'stale pre-rename lists response must NOT revert the rename');
    expect(find.text('Groceries'), findsNothing,
        reason: 'old name must not come back after the stale response lands');
  });
}
