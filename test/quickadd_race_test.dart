// Regression: the Android "row appears then vanishes" race.
// A slow POST (300ms) with an item GET landing mid-POST must not drop the
// optimistic row — the pending-create funnel re-merges it on every write.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taskflow_app/app.dart';
import 'package:taskflow_app/data/services/api_client.dart';
import 'package:taskflow_app/presentation/features/home/widgets/item_row.dart';
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

class RaceBackend {
  final List<Map<String, dynamic>> items = <Map<String, dynamic>>[
    _itemJson(101, 1, 'Milk', false, 0),
    _itemJson(102, 1, 'Cheese', false, 1),
    _itemJson(103, 1, 'Eggs', true, 2),
  ];
  final List<Map<String, dynamic>> lists = <Map<String, dynamic>>[
    _listJson(1, 'Groceries', 3, 2),
  ];
  int nextId = 200;
  int postDelayMs = 300;

  http.Response _json(Object b, [int s = 200]) => http.Response(jsonEncode(b), s,
      headers: <String, String>{'content-type': 'application/json'});

  Future<http.Response> handle(http.Request r) async {
    final String m = r.method, p = r.url.path;
    if (m == 'GET' && p == '/api/lists') return _json(lists);
    if (m == 'GET' && p == '/api/items') {
      // A mid-POST fetch: returns the pre-commit world (no new row yet).
      final Iterable<Map<String, dynamic>> out = List<Map<String, dynamic>>.from(items);
      return _json(out.toList());
    }
    if (m == 'POST' && p == '/api/items') {
      await Future<void>.delayed(Duration(milliseconds: postDelayMs));
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      for (final other in items) {
        if (other['list_id'] == body['list_id'] && other['done'] == false) {
          other['position'] = (other['position'] as num) + 1;
        }
      }
      final created = _itemJson(nextId++, body['list_id'] as int, body['title'] as String, false, 0);
      items.insert(0, created);
      return _json(created, 201);
    }
    return _json(<String, Object>{'detail': 'nf'}, 404);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('optimistic row survives a mid-POST item fetch (Android race)', (WidgetTester tester) async {
    final backend = RaceBackend();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        apiClientProviderProvider.overrideWithValue(
            ApiClient('http://x', client: MockClient(backend.handle)))
      ],
      child: const TaskflowApp(),
    ));
    await tester.pumpAndSettle();

    // Add a task; the POST takes 300ms (Android-like).
    await tester.enterText(find.byKey(const Key('quick-add-field')), 'Bread');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump(); // optimistic insert frame
    await tester.pump(const Duration(milliseconds: 30));
    // Scope to the item row (the composer still holds the text until commit).
    Finder rowBread() => find.descendant(
        of: find.byType(ItemRow), matching: find.text('Bread'));
    expect(rowBread(), findsOneWidget, reason: 'optimistic row visible immediately');

    // Fire a fetch mid-POST (t=150ms) — pre-commit data arrives.
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    // THE ASSERTION: even after a stale pre-commit fetch landed, the row must
    // still be there (the pending merge re-adds it).
    expect(rowBread(), findsOneWidget,
        reason: 'row must NOT vanish while the POST is in flight');

    // Let the POST commit; the row becomes the server row.
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(rowBread(), findsOneWidget, reason: 'row present after commit');
  });
}