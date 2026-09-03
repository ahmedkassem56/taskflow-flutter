// THE trace-proven bug (img_5e61ad277923): the added item's row appears
// instantly (create INSERT), but a 5s poll whose SQLite read snapshot
// predates the create's commit returns a list WITHOUT the new item, and
// applying it makes the row VANISH until the next poll (4.4s later).
//
// Guard under test: after a create, any fetch response that lacks the
// just-created id is a pre-commit snapshot → DISCARD (keep showing the row).
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
Map<String, dynamic> _item(int id, String title, int pos) => <String, dynamic>{
      'id': id, 'list_id': 1, 'title': title, 'notes': null, 'priority': 'none',
      'due_date': null, 'quantity': 1, 'position': pos, 'done': false,
      'recurrence': 'none', 'recurrence_interval': null,
      'created_at': _iso(2), 'updated_at': _iso(2)};
Map<String, dynamic> _list(int id, int total, int pending) => <String, dynamic>{
      'id': id, 'name': 'Groceries', 'item_count': total, 'pending_count': pending,
      'created_at': _iso(1), 'updated_at': _iso(1)};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('row does NOT vanish when a pre-commit poll snapshot lands after a create',
      (WidgetTester tester) async {
    // Server state: 2 items. The mock lets a poll return a STALE list (missing
    // the just-created item) ONCE, exactly like a read snapshot taken before
    // the create's commit.
    final items = <Map<String, dynamic>>[_item(1, 'Milk', 0), _item(2, 'Eggs', 1)];
    var returnStaleOnce = false; // set true right after a create, cleared after
    var nextId = 100;

    http.Response json(Object b, [int s = 200]) => http.Response(jsonEncode(b), s,
        headers: <String, String>{'content-type': 'application/json'});

    Future<http.Response> backend(http.Request r) async {
      final m = r.method, p = r.url.path;
      if (m == 'GET' && p == '/api/items') {
        if (returnStaleOnce) {
          returnStaleOnce = false;
          return json(<Map<String, dynamic>>[
            for (final i in items)
              if (i['id'] != 100) i // stale snapshot: no "Bread"
          ]);
        }
        return json(items);
      }
      if (m == 'POST' && p == '/api/items') {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final created = _item(nextId++, body['title'] as String, 0);
        items.insert(0, created);
        returnStaleOnce = true; // the NEXT poll will be a pre-commit snapshot
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
    expect(row('Milk'), findsOneWidget);

    // Add a task (POST returns instantly, row appears from the response).
    await tester.enterText(find.byKey(const Key('quick-add-field')), 'Bread');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump(const Duration(milliseconds: 20)); // POST resolves
    await tester.pump();
    expect(row('Bread'), findsOneWidget,
        reason: 'row appears instantly from the POST response');

    // Now a poll lands with the PRE-COMMIT snapshot (no Bread) — the exact
    // 10884ms "fetch OK 82" moment from the device trace. It MUST be
    // discarded; Bread must STAY visible.
    await tester.pump(const Duration(milliseconds: 600)); // let poll run
    await tester.pump();
    expect(row('Bread'), findsOneWidget,
        reason: 'pre-commit snapshot poll must NOT remove the just-created row');

    // The NEXT poll has the real data; the guard clears and the row stays.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(row('Bread'), findsOneWidget,
        reason: 'row persists once the server snapshot includes it');
  });
}