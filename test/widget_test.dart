// Widget smoke test: the shell renders against a mocked API and toggling a
// task issues the PATCH through the real providers (DESIGN.md §6 — smoke:
// shell renders, toggle calls PATCH — via ProviderScope overrides).
//
// The ApiClient provider is the only override: the ApiClient is pointed at a
// MockClient serving canned JSON in the exact backend envelopes (DESIGN.md
// §2.2), so the real controllers/lists/items fetch paths are exercised.

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

Map<String, dynamic> _listJson(int id, String name, int total, int pending) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'item_count': total,
    'pending_count': pending,
    'created_at': _iso(1),
    'updated_at': _iso(1),
  };
}

Map<String, dynamic> _itemJson({
  required int id,
  required int listId,
  required String title,
  required bool done,
  int position = 0,
  String priority = 'none',
  String? notes,
  String? dueDate,
  num quantity = 1,
}) {
  return <String, dynamic>{
    'id': id,
    'list_id': listId,
    'title': title,
    'notes': notes,
    'priority': priority,
    'due_date': dueDate,
    'quantity': quantity,
    'position': position,
    'done': done,
    'recurrence': 'none',
    'recurrence_interval': null,
    'created_at': _iso(2),
    'updated_at': _iso(2),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> requests;
  late http.Response Function(http.Request request) dispatcher;

  ApiClient buildApiClient() {
    return ApiClient(
      'http://127.0.0.1:8000',
      client: MockClient((http.Request request) async {
        requests.add(request);
        return dispatcher(request);
      }),
    );
  }

  setUp(() {
    requests = <http.Request>[];
    dispatcher = (http.Request request) {
      final String path = request.url.path;
      final String method = request.method;
      if (method == 'GET' && path == '/api/lists') {
        return http.Response(
          jsonEncode(<Object>[
            _listJson(1, 'Groceries', 2, 1),
            _listJson(2, 'Work', 0, 0),
          ]),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }
      if (method == 'GET' && path == '/api/items') {
        return http.Response(
          jsonEncode(<Object>[
            _itemJson(
              id: 101,
              listId: 1,
              title: 'Milk',
              done: false,
              priority: 'medium',
              position: 0,
            ),
            _itemJson(
              id: 102,
              listId: 1,
              title: 'Eggs',
              done: true,
              position: 1,
            ),
          ]),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }
      if (method == 'PATCH' && path == '/api/items/101') {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'item': _itemJson(
              id: 101,
              listId: 1,
              title: 'Milk',
              done: true,
              priority: 'medium',
              position: 0,
            ),
            'spawned': null,
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }
      return http.Response('{"detail": "Not Found"}', 404,
          headers: <String, String>{'content-type': 'application/json'});
    };
  });

  Future<ProviderScope> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ApiClient client = buildApiClient();
    final ProviderScope scope = ProviderScope(
      overrides: [
        // ADAPT(ApiClientProvider): generated instance for
        // `@riverpod class ApiClientProvider` is `apiClientProviderProvider`.
        apiClientProviderProvider.overrideWithValue(client),
      ],
      child: const TaskflowApp(),
    );
    await tester.pumpWidget(scope);
    return scope;
  }

  testWidgets('shell renders All tasks with items from the mocked API',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    // App bar brand + header + rows from the fixture.
    expect(find.text('Taskflow'), findsWidgets);
    expect(find.text('All tasks'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Eggs'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(2));

    // Sidebar entry behind the drawer and the quick-add composer are present.
    expect(find.byKey(const Key('quick-add-field')), findsOneWidget);
    expect(find.byKey(const Key('quick-add-submit')), findsOneWidget);
  });

  testWidgets('toggling a task issues a PATCH', (WidgetTester tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    final Iterable<http.Request> patches = requests.where(
      (http.Request r) =>
          r.method == 'PATCH' && r.url.path == '/api/items/101',
    );
    expect(patches, isNotEmpty);
    expect(
      patches.first.body,
      contains('"done"'),
    );
  });
}
