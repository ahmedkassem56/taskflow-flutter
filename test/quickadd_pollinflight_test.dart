// THE basic-use-case reproduction: user adds a task while a 5s poll fetch is
// in flight. createItem's settle refresh must NOT be skipped by _fetchInFlight
// and must NOT wait for the next poll tick — the row must appear promptly.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taskflow_app/app.dart';
import 'package:taskflow_app/data/services/api_client.dart';
import 'package:taskflow_app/presentation/providers/api_client.dart';
import 'package:taskflow_app/presentation/features/home/widgets/item_row.dart';

String _iso(int d) => '2026-09-${d.toString().padLeft(2, '0')}T10:00:00.000000Z';
Map<String, dynamic> _list(int id, int total, int pending) => <String, dynamic>{
      'id': id, 'name': 'Groceries', 'item_count': total, 'pending_count': pending,
      'created_at': _iso(1), 'updated_at': _iso(1)};
Map<String, dynamic> _item(int id, String title, int pos) => <String, dynamic>{
      'id': id, 'list_id': 1, 'title': title, 'notes': null, 'priority': 'none',
      'due_date': null, 'quantity': 1, 'position': pos, 'done': false,
      'recurrence': 'none', 'recurrence_interval': null,
      'created_at': _iso(2), 'updated_at': _iso(2)};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('add lands promptly even when a poll is in flight', (WidgetTester tester) async {
    final items = <Map<String, dynamic>>[_item(1, 'Milk', 0), _item(2, 'Eggs', 1)];
    var pollCount = 0;
    var nextId = 100;

    http.Response json(Object b, [int s = 200]) => http.Response(jsonEncode(b), s,
        headers: <String, String>{'content-type': 'application/json'});

    Future<http.Response> backend(http.Request r) async {
      final m = r.method, p = r.url.path;
      if (m == 'GET' && p == '/api/items') {
        pollCount++;
        // Slow the SECOND+ GETs (the 5s poll that races the create). The
        // first GET is the initial build fetch — keep it fast so the app
        // boots instantly, then the create races a poll that is in flight.
        if (pollCount >= 2) {
          await Future<void>.delayed(const Duration(milliseconds: 600));
        }
        return json(items);
      }
      if (m == 'POST' && p == '/api/items') {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final created = _item(nextId++, body['title'] as String, 0);
        items.insert(0, created);
        return json(created, 201);
      }
      if (m == 'GET' && p == '/api/lists') {
        return json(<Map<String, dynamic>>[_list(1, items.length, items.length)]);
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

    Finder row(String title) => find.descendant(
        of: find.byType(ItemRow), matching: find.text(title));

    // Start the app; initial load done, "Milk"+"Eggs" visible.
    expect(row('Milk'), findsOneWidget);

    // User adds a task. POST is fast (20ms). If a poll is STILL in flight at
    // this moment, the settled refresh must force through.
    await tester.enterText(find.byKey(const Key('quick-add-field')), 'Bread');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump(); // submit

    // Fast-forward. First poll (600ms) resolves mid-create. The create's own
    // refresh must NOT be skipped and must NOT wait for the next tick.
    await tester.pump(const Duration(milliseconds: 50)); // POST resolves
    await tester.pump(const Duration(milliseconds: 100)); // settle refresh runs
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    // THE assertion: Bread visible well before the 5s poll would come around.
    expect(row('Bread'), findsOneWidget,
        reason: 'row must appear promptly after the POST, even with a poll in flight');
  });
}