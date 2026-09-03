// Reproduce the Android quick-add "takes seconds" report:
// - long list (so the user is scrolled down)
// - quick-add a task
// - is the new row instantly in the *visible* viewport, or off-screen
//   until a refresh?
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

class LongBackend {
  final List<http.Request> requests = <http.Request>[];
  final List<Map<String, dynamic>> items = <Map<String, dynamic>>[
    _itemJson(101, 1, 'Task 00 (bottom)', false, 0),
    _itemJson(102, 1, 'Task 01', false, 1),
    _itemJson(103, 1, 'Task 02', false, 2),
    _itemJson(104, 1, 'Task 03', false, 3),
    _itemJson(105, 1, 'Task 04', false, 4),
    _itemJson(106, 1, 'Task 05', false, 5),
    _itemJson(107, 1, 'Task 06', false, 6),
    _itemJson(108, 1, 'Task 07', false, 7),
    _itemJson(109, 1, 'Task 08', false, 8),
    _itemJson(110, 1, 'Task 09', false, 9),
    _itemJson(111, 1, 'Task 10', false, 10),
    _itemJson(112, 1, 'Task 11', false, 11),
    _itemJson(113, 1, 'Task 12', false, 12),
    _itemJson(114, 1, 'Task 13', false, 13),
    _itemJson(115, 1, 'Task 14', false, 14),
    _itemJson(116, 1, 'Task 15', false, 15),
    _itemJson(117, 1, 'Task 16', false, 16),
    _itemJson(118, 1, 'Task 17', false, 17),
    _itemJson(119, 1, 'Task 18', false, 18),
    _itemJson(120, 1, 'Task 19 (top)', false, 19),
  ];
  final List<Map<String, dynamic>> lists = <Map<String, dynamic>>[
    _listJson(1, 'Groceries', 20, 20),
  ];
  int nextId = 200;
  int waitMs = 0; // simulate server latency

  http.Response _json(Object body, [int s = 200]) => http.Response(jsonEncode(body), s,
      headers: <String, String>{'content-type': 'application/json'});

  Future<http.Response> handle(http.Request r) async {
    requests.add(r);
    if (waitMs > 0) await Future<void>.delayed(Duration(milliseconds: waitMs));
    final String m = r.method, p = r.url.path;
    if (m == 'GET' && p == '/api/lists') return _json(lists);
    if (m == 'GET' && p == '/api/items') {
      final q = r.url.queryParameters;
      Iterable<Map<String, dynamic>> out = List<Map<String, dynamic>>.from(items);
      if (q.containsKey('list_id')) out = out.where((i) => i['list_id'] == int.parse(q['list_id']!));
      out = out.toList()..sort((a, b) => ((a['position'] as num) - (b['position'] as num)).compareTo(0));
      return _json(out.toList());
    }
    if (m == 'POST' && p == '/api/items') {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      for (final other in items) {
        if (other['list_id'] == body['list_id'] && other['done'] == false) {
          other['position'] = (other['position'] as num) + 1;
        }
      }
      items.add(_itemJson(nextId++, body['list_id'] as int, body['title'] as String, false, 0));
      return _json(items.last, 201);
    }
    return _json(<String, Object>{'detail': 'nf'}, 404);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scrolled list: quick-add row is instantly in the visible viewport',
      (WidgetTester tester) async {
    final backend = LongBackend()..waitMs = 300; // realistic server latency
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

    // Go to the Groceries list view (reorderable, scrolled).
    await tester.tap(find.byKey(const Key('drawer-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text('Groceries')).first);
    await tester.pumpAndSettle();

    // Force the item list scrolled down one screen (jump to a real offset).
    final Finder itemScrollable = find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.byType(Scrollable),
    );
    tester.state<ScrollableState>(itemScrollable.first).position.jumpTo(1500);
    await tester.pumpAndSettle();
    // Confirm we're genuinely scrolled: the top row (position 0 = "Task 00")
    // is off-screen/not built.
    expect(find.text('Task 00 (bottom)'), findsNothing,
        reason: 'top row gone when scrolled');
    tester.state<ScrollableState>(itemScrollable.first).position.jumpTo(800);
    await tester.pumpAndSettle();
    final double beforeY = tester.getTopLeft(find.textContaining('Task 12').first).dy;
    debugPrint('before add: Task 12 dy=$beforeY');

    // Quick-add in the scrolled state.
    await tester.enterText(find.byKey(const Key('quick-add-field')), 'NEW ITEM');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump(); // one frame after submit (optimistic)
    await tester.pump(const Duration(milliseconds: 50));
    // NOTE: the server POST takes 300ms — anything "visible" now is optimistic.
    expect(find.text('NEW ITEM'), findsOneWidget,
        reason: 'optimistic row must be in the widget tree immediately');
    final double newY = tester.getTopLeft(find.text('NEW ITEM')).dy;
    final bool inViewport = newY >= 0 && newY <= 844;
    debugPrint('optimistic row top-left dy after submit frame: $newY; inViewport=$inViewport');
    expect(inViewport, isTrue,
        reason: 'the JUST-ADDED item must be visible where the user can see it, even when scrolled');
    // Allow the simulated 300ms server latency + reconcile timers to finish
    // so no Timer is left pending at test teardown.
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  });
}