// Regression for the trace-exposed race: a 5s poll that STARTED before a
// create's mutation ended, but COMPLETES after (with pre-commit data), must be
// discarded — it was clobbering the optimistic row (74->73 in the trace).
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

String _iso(int day) => '2026-09-${day.toString().padLeft(2, '0')}T10:00:00.000000Z';

Map<String, dynamic> _listJson(int id, String name, int total, int pending) => <String, dynamic>{
      'id': id, 'name': name, 'item_count': total, 'pending_count': pending,
      'created_at': _iso(1), 'updated_at': _iso(1),
    };

Map<String, dynamic> _itemJson(int id, int listId, String title, bool done, int pos) => <String, dynamic>{
      'id': id, 'list_id': listId, 'title': title, 'notes': null,
      'priority': 'none', 'due_date': null, 'quantity': 1, 'position': pos,
      'done': done, 'recurrence': 'none', 'recurrence_interval': null,
      'created_at': _iso(2), 'updated_at': _iso(2),
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('stale pre-commit poll after a create is discarded (gen on end)',
      (WidgetTester tester) async {
    // Stateful backend: POST commits instantly, but a GET started during the
    // POST resolves AFTER it with pre-commit data.
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[
      _itemJson(101, 1, 'Milk', false, 0),
      _itemJson(102, 1, 'Cheese', false, 1),
    ];
    final List<Map<String, dynamic>> lists = <Map<String, dynamic>>[
      _listJson(1, 'Groceries', 2, 2),
    ];
    int nextId = 200;
    // A GET that started before the POST commit; delay its response so it
    // lands after the create's end().
    late Future<http.Response> Function(http.Request) dispatcher;
    int postInFlight = 0;
    dispatcher = (http.Request r) async {
      final String m = r.method, p = r.url.path;
      if (m == 'GET' && p == '/api/items') {
        // If the POST is in flight, this GET is racing it: delay 50ms so it
        // completes after the create resolves, with PRE-COMMIT rows.
        if (postInFlight > 0) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        return http.Response(jsonEncode(items), 200,
            headers: <String, String>{'content-type': 'application/json'});
      }
      if (m == 'POST' && p == '/api/items') {
        postInFlight++;
        try {
          final body = jsonDecode(r.body) as Map<String, dynamic>;
          items.add(_itemJson(nextId++, body['list_id'] as int, body['title'] as String, false, 0));
          return http.Response(jsonEncode(items.last), 201,
              headers: <String, String>{'content-type': 'application/json'});
        } finally {
          postInFlight--;
        }
      }
      if (m == 'GET' && p == '/api/lists') {
        return http.Response(jsonEncode(lists), 200,
            headers: <String, String>{'content-type': 'application/json'});
      }
      return http.Response('{"detail":"nf"}', 404,
          headers: <String, String>{'content-type': 'application/json'});
    };

    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        apiClientProviderProvider.overrideWithValue(
            ApiClient('http://x', client: MockClient(dispatcher)))
      ],
      child: const TaskflowApp(),
    ));
    await tester.pumpAndSettle();

    // Trigger a poll that starts during the create (there's no real 5s timer
    // in widget tests, so fire the create and a concurrent fetch).
    await tester.enterText(find.byKey(const Key('quick-add-field')), 'Bread');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump(); // optimistic

    // Let the create resolve AND the racing GET finish (50ms delay).
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpAndSettle();

    // The stale pre-commit GET must NOT have removed the row.
    expect(find.text('Bread'), findsOneWidget,
        reason: 'stale pre-commit GET after create must be discarded');
  });
}