// UI/UX flow tests: drive the real widget tree through user journeys against
// a stateful fake backend (mutation-aware MockClient), verifying what a user
// sees after each action. Complements the browser E2E — these run headless on
// the Dart VM (no GPU), which is the reliable way to test UI on this box.
//
// Flows: create task -> appears; server-side search; pending filter +
// optimistic toggle-drop; list view via drawer; arrow move -> PATCH + reorder.

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
      'id': id,
      'name': name,
      'item_count': total,
      'pending_count': pending,
      'created_at': _iso(1),
      'updated_at': _iso(1),
    };

Map<String, dynamic> _itemJson({
  required int id,
  required int listId,
  required String title,
  required bool done,
  int position = 0,
  String priority = 'none',
}) =>
    <String, dynamic>{
      'id': id,
      'list_id': listId,
      'title': title,
      'notes': null,
      'priority': priority,
      'due_date': null,
      'quantity': 1,
      'position': position,
      'done': done,
      'recurrence': 'none',
      'recurrence_interval': null,
      'created_at': _iso(2),
      'updated_at': _iso(2),
    };

/// Stateful fake of the Taskflow backend: mutation-aware, serves the exact
/// envelopes the client parses (lists/items GETs, bare-item POST, PATCH
/// envelopes with spawned/swapped).
class FakeBackend {
  FakeBackend() {
    reset();
  }

  final List<http.Request> requests = <http.Request>[];
  late List<Map<String, dynamic>> lists;
  late List<Map<String, dynamic>> items;
  int _nextItemId = 200;

  /// When true, DELETE /api/items/* answers 500 (tests error visibility).
  bool failItemDeletes = false;

  void reset() {
    requests.clear();
    lists = <Map<String, dynamic>>[
      _listJson(1, 'Groceries', 3, 2),
      _listJson(2, 'Work', 1, 1),
    ];
    items = <Map<String, dynamic>>[
      _itemJson(id: 101, listId: 1, title: 'Milk', done: false, position: 0, priority: 'medium'),
      _itemJson(id: 102, listId: 1, title: 'Cheese', done: false, position: 1),
      _itemJson(id: 103, listId: 1, title: 'Eggs', done: true, position: 2),
      _itemJson(id: 104, listId: 2, title: 'Report', done: false, position: 0),
    ];
  }

  List<Map<String, dynamic>> _sorted() {
    final List<Map<String, dynamic>> copy = List<Map<String, dynamic>>.from(items);
    copy.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final int da = (a['done'] as bool) ? 1 : 0;
      final int db = (b['done'] as bool) ? 1 : 0;
      if (da != db) return da - db;
      return ((a['position'] as num) - (b['position'] as num)).compareTo(0);
    });
    return copy;
  }

  http.Response _json(Object body, [int status = 200]) => http.Response(
        jsonEncode(body),
        status,
        headers: <String, String>{'content-type': 'application/json'},
      );

  http.Response handle(http.Request request) {
    requests.add(request);
    final String method = request.method;
    final String path = request.url.path;
    final Map<String, String> q = request.url.queryParameters;

    if (method == 'GET' && path == '/api/lists') {
      return _json(lists);
    }
    if (method == 'POST' && path == '/api/lists') {
      final Map<String, dynamic> body = jsonDecode(request.body) as Map<String, dynamic>;
      final int id = lists.length + 10;
      final Map<String, dynamic> list = _listJson(id, body['name'] as String, 0, 0);
      lists.add(list);
      return _json(<String, Object>{'list': list}, 201);
    }
    if (method == 'DELETE' && path.startsWith('/api/lists/')) {
      lists.removeWhere((Map<String, dynamic> l) => l['id'] == int.parse(path.split('/')[3]));
      return http.Response('', 204);
    }
    if (method == 'GET' && path == '/api/items') {
      Iterable<Map<String, dynamic>> out = _sorted();
      final String? listId = q['list_id'];
      if (listId != null) {
        out = out.where((Map<String, dynamic> i) => i['list_id'] == int.parse(listId));
      }
      final String? status = q['status'];
      if (status == 'pending') {
        out = out.where((Map<String, dynamic> i) => i['done'] == false);
      } else if (status == 'done') {
        out = out.where((Map<String, dynamic> i) => i['done'] == true);
      }
      final String? search = q['q'];
      if (search != null && search.isNotEmpty) {
        out = out.where(
          (Map<String, dynamic> i) => (i['title'] as String).toLowerCase().contains(search.toLowerCase()),
        );
      }
      return _json(out.toList());
    }
    if (method == 'POST' && path == '/api/items') {
      final Map<String, dynamic> body = jsonDecode(request.body) as Map<String, dynamic>;
      final int listId = body['list_id'] as int;
      final int maxPos = items
          .where((Map<String, dynamic> i) => i['list_id'] == listId)
          .fold<int>(0, (int m, Map<String, dynamic> i) => ((i['position'] as num) + 1) > m ? (i['position'] as int) + 1 : m);
      final Map<String, dynamic> item = _itemJson(
        id: _nextItemId++,
        listId: listId,
        title: body['title'] as String,
        done: false,
        position: maxPos,
      );
      items.add(item);
      final Map<String, dynamic> list = lists.firstWhere((Map<String, dynamic> l) => l['id'] == listId);
      list['item_count'] = (list['item_count'] as int) + 1;
      list['pending_count'] = (list['pending_count'] as int) + 1;
      return _json(item, 201);
    }
    if (method == 'PATCH' && path.startsWith('/api/items/')) {
      final int id = int.parse(path.split('/')[3]);
      final Map<String, dynamic> body = jsonDecode(request.body) as Map<String, dynamic>;
      final Map<String, dynamic> item = items.firstWhere((Map<String, dynamic> i) => i['id'] == id);
      if (body.containsKey('done')) {
        final bool wasDone = item['done'] as bool;
        item['done'] = body['done'];
        final int listId = item['list_id'] as int;
        final Map<String, dynamic> list = lists.firstWhere((Map<String, dynamic> l) => l['id'] == listId);
        if (!wasDone && body['done'] == true) {
          list['pending_count'] = (list['pending_count'] as int) - 1;
        } else if (wasDone && body['done'] == false) {
          list['pending_count'] = (list['pending_count'] as int) + 1;
        }
        // done rows sort to the back of their list's position space
        if (body['done'] == true) {
          final int listId2 = item['list_id'] as int;
          final List<Map<String, dynamic>> pending =
              items.where((Map<String, dynamic> i) => i['list_id'] == listId2 && i['done'] == false).toList();
          item['position'] = pending.length;
        }
        return _json(<String, Object?>{'item': item, 'spawned': null});
      }
      if (body.containsKey('move')) {
        final String direction = body['move'] as String;
        final int listId = item['list_id'] as int;
        final List<Map<String, dynamic>> group = items
            .where((Map<String, dynamic> i) => i['list_id'] == listId && i['done'] == item['done'])
            .toList()
          ..sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
              ((a['position'] as num) - (b['position'] as num)).compareTo(0));
        final int idx = group.indexWhere((Map<String, dynamic> i) => i['id'] == id);
        final int target = direction == 'down' ? idx + 1 : idx - 1;
        if (target < 0 || target >= group.length) {
          return _json(<String, Object?>{'item': item, 'swapped': null});
        }
        final Map<String, dynamic> other = group[target];
        final num tmp = item['position'] as num;
        item['position'] = other['position'];
        other['position'] = tmp;
        return _json(<String, Object?>{'item': item, 'swapped': other});
      }
      return _json(<String, Object?>{'item': item, 'spawned': null});
    }
    if (method == 'DELETE' && path.startsWith('/api/items/')) {
      if (failItemDeletes) {
        return _json(<String, Object>{'detail': 'Simulated server failure'}, 500);
      }
      final int id = int.parse(path.split('/')[3]);
      final Map<String, dynamic> item = items.firstWhere((Map<String, dynamic> i) => i['id'] == id);
      items.removeWhere((Map<String, dynamic> i) => i['id'] == id);
      final Map<String, dynamic> list = lists.firstWhere((Map<String, dynamic> l) => l['id'] == item['list_id']);
      list['item_count'] = (list['item_count'] as int) - 1;
      if (item['done'] == false) list['pending_count'] = (list['pending_count'] as int) - 1;
      return http.Response('', 204);
    }
    return _json(<String, Object>{'detail': 'Not Found'}, 404);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeBackend backend;

  ApiClient buildApiClient() => ApiClient(
        'http://127.0.0.1:8000',
        client: MockClient((http.Request request) async => backend.handle(request)),
      );

  Future<ProviderScope> pumpApp(WidgetTester tester) async {
    backend = FakeBackend();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderScope scope = ProviderScope(
      overrides: [
        apiClientProviderProvider.overrideWithValue(buildApiClient()),
      ],
      child: const TaskflowApp(),
    );
    await tester.pumpWidget(scope);
    await tester.pumpAndSettle();
    return scope;
  }

  List<http.Request> reqs(String method, String pathPrefix) => backend.requests
      .where((http.Request r) => r.method == method && r.url.path.startsWith(pathPrefix))
      .toList();

  testWidgets('create task via FAB: sheet -> POST -> new row appears', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-task-fab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('item-title-field')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('item-title-field')), 'Buy bread');
    await tester.ensureVisible(find.byKey(const Key('item-save-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('item-save-button')));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    final List<http.Request> posts = reqs('POST', '/api/items');
    expect(posts, hasLength(1));
    expect(jsonDecode(posts.single.body), containsPair('title', 'Buy bread'));
    expect(find.text('Buy bread'), findsOneWidget);
  });

  testWidgets('search issues q param and filters rows server-side', (WidgetTester tester) async {
    await pumpApp(tester);
    expect(find.text('Eggs'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('filter-search')), 'Mil');
    await tester.pump(const Duration(milliseconds: 350)); // 300ms debounce
    await tester.pumpAndSettle();

    final Iterable<http.Request> gets = reqs('GET', '/api/items').where(
      (http.Request r) => r.url.queryParameters['q'] == 'Mil',
    );
    expect(gets, isNotEmpty);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Eggs'), findsNothing);
    expect(find.text('Report'), findsNothing);
  });

  testWidgets('Pending filter hides done; toggling drops row optimistically + PATCHes',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Pending'));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Cheese'), findsOneWidget);
    expect(find.text('Eggs'), findsNothing); // done item hidden by filter

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    final List<http.Request> patches = reqs('PATCH', '/api/items/101');
    expect(patches, hasLength(1));
    expect(jsonDecode(patches.single.body), containsPair('done', true));
    expect(find.text('Milk'), findsNothing); // dropped from pending view
    expect(find.text('Cheese'), findsOneWidget);
  });

  testWidgets('open list from drawer; move down issues move PATCH and reorders', (WidgetTester tester) async {
    await pumpApp(tester);

    // Open the drawer and pick Groceries (2 pending + 1 done).
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    final Finder drawerList = find.descendant(of: find.byType(Drawer), matching: find.text('Groceries'));
    await tester.tap(drawerList.first);
    await tester.pumpAndSettle();

    // Only Groceries items now.
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Cheese'), findsOneWidget);
    expect(find.text('Report'), findsNothing);

    // Move-down arrow on Milk's row.
    final Finder milkRow = find.ancestor(of: find.text('Milk'), matching: find.byType(ItemRow));
    final Finder downArrow = find.descendant(of: milkRow, matching: find.byTooltip('Move down'));
    expect(downArrow, findsOneWidget);

    final double milkY = tester.getTopLeft(find.text('Milk')).dy;
    final double cheeseY = tester.getTopLeft(find.text('Cheese')).dy;
    expect(milkY, lessThan(cheeseY)); // Milk above Cheese

    await tester.tap(downArrow);
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    final List<http.Request> patches = reqs('PATCH', '/api/items/101');
    expect(patches, hasLength(1));
    expect(jsonDecode(patches.single.body), containsPair('move', 'down'));

    final double milkY2 = tester.getTopLeft(find.text('Milk')).dy;
    final double cheeseY2 = tester.getTopLeft(find.text('Cheese')).dy;
    expect(cheeseY2, lessThan(milkY2)); // Cheese now above Milk
  });

  testWidgets('toggling a task in a list view moves it below pending siblings', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    final Finder drawerList = find.descendant(of: find.byType(Drawer), matching: find.text('Groceries'));
    await tester.tap(drawerList.first);
    await tester.pumpAndSettle();

    // Milk is pending and on top; toggle it done.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(reqs('PATCH', '/api/items/101'), hasLength(1));
    // Done rows sort below pending: Milk should now be beneath Cheese.
    final double milkY = tester.getTopLeft(find.text('Milk')).dy;
    final double cheeseY = tester.getTopLeft(find.text('Cheese')).dy;
    expect(cheeseY, lessThan(milkY));
    expect(find.byType(Checkbox), findsNWidgets(3)); // Cheese, Milk(done), Eggs(done)
  });
}
