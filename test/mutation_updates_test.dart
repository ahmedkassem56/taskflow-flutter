// Regression: renaming a list must update the header + sidebar immediately
// (no restart), and deleting an item must remove it promptly (no waiting for
// the next 5s poll).
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

class LiveBackend {
  List<Map<String, dynamic>> lists = <Map<String, dynamic>>[
    _list(1, 'Groceries', 2, 2)];
  List<Map<String, dynamic>> items = <Map<String, dynamic>>[
    _item(1, 'Milk', 0), _item(2, 'Eggs', 1)];

  http.Response _json(Object b, [int s = 200]) => http.Response(jsonEncode(b), s,
      headers: <String, String>{'content-type': 'application/json'});

  Future<http.Response> handle(http.Request r) async {
    final String m = r.method, p = r.url.path;
    if (m == 'GET' && p == '/api/lists') return _json(lists);
    if (m == 'GET' && p == '/api/items') return _json(items);
    if (m == 'PATCH' && p == '/api/lists/1') {
      final name = (jsonDecode(r.body) as Map<String, dynamic>)['name'] as String;
      lists = <Map<String, dynamic>>[_list(1, name, items.length, items.length)];
      return _json(lists.first);
    }
    if (m == 'DELETE' && p == '/api/items/2') {
      items = <Map<String, dynamic>>[items.first];
      lists = <Map<String, dynamic>>[_list(1, 'Groceries', 1, 1)];
      return http.Response('', 204);
    }
    return _json(<String, Object>{'detail': 'nf'}, 404);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LiveBackend> pump(WidgetTester tester) async {
    final backend = LiveBackend();
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
    return backend;
  }

  testWidgets('rename list updates header + sidebar immediately (no restart)',
      (WidgetTester tester) async {
    await pump(tester);

    // Boots to All tasks. Navigate into the Groceries list via sidebar.
    await tester.tap(find.byKey(const Key('drawer-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Groceries').last);
    await tester.pumpAndSettle();

    // Header shows Groceries; open its list-actions popup → Rename.
    expect(find.text('Groceries'), findsWidgets);
    await tester.tap(find.byTooltip('List actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Home');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Header + sidebar must now show 'Home' — NOT after restart.
    expect(find.text('Home'), findsWidgets,
        reason: 'renamed list must appear immediately, no restart needed');
    expect(find.text('Groceries'), findsNothing,
        reason: 'old name must be gone from header/sidebar');
  });

  testWidgets('delete item removes it promptly (not on next poll)',
      (WidgetTester tester) async {
    await pump(tester);

    // Tap the Eggs row → edit sheet → Delete → confirm.
    expect(find.text('Eggs'), findsOneWidget);
    await tester.tap(find.text('Eggs'));
    await tester.pumpAndSettle();
    // Edit sheet's Delete button.
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    // Confirm dialog ("Delete task?" → Delete).
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    // Eggs must be gone NOW, not after the next 5s poll.
    expect(find.text('Eggs'), findsNothing,
        reason: 'deleted item must disappear promptly');
  });
}
