// THE rename bug, trace-proven on web AND Android (img_4ad3d6bed15f):
//   14904ms rename OK server -> "Renamedddd again"
//   14904ms rename LOCAL-APPLIED  (header shows new name ✓)
//   14922ms rename refresh -> 2 lists   ← settle refresh returns OLD name
//   14927ms header shows "Renamedddd"    ← REVERTED by a pre-commit snapshot
//
// The refresh GET raced the PATCH commit: SQLite served a read snapshot taken
// before the rename committed. Fix: after a rename, discard any refresh whose
// response shows the OLD name for that list until one carries the new name.
import 'dart:async';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rename survives its own settle refresh returning a pre-commit snapshot',
      (WidgetTester tester) async {
    var serverName = 'Groceries';
    // After the rename PATCH, make the NEXT lists GET return the OLD name
    // (a SQLite snapshot taken before the commit became visible), held until
    // the gate opens so ordering is exact.
    var serveStaleAfterRename = false;
    final Completer<void> staleGate = Completer<void>();
    final items = <Map<String, dynamic>>[
      _item(1, 'Milk', 0), _item(2, 'Eggs', 1)];

    http.Response json(Object b, [int s = 200]) => http.Response(jsonEncode(b), s,
        headers: <String, String>{'content-type': 'application/json'});

    Future<http.Response> backend(http.Request r) async {
      final String m = r.method, p = r.url.path;
      if (m == 'GET' && p == '/api/lists') {
        if (serveStaleAfterRename) {
          serveStaleAfterRename = false;
          await staleGate.future;
          // Return the PRE-rename name — snapshot predates the commit.
          return json(<Map<String, dynamic>>[
            _list(1, 'Groceries', items.length, items.length),
            _list(2, 'Other', 0, 0)]);
        }
        return json(<Map<String, dynamic>>[
          _list(1, serverName, items.length, items.length),
          _list(2, 'Other', 0, 0)]);
      }
      if (m == 'GET' && p == '/api/items') return json(items);
      if (m == 'PATCH' && p == '/api/lists/1') {
        serverName =
            (jsonDecode(r.body) as Map<String, dynamic>)['name'] as String;
        serveStaleAfterRename = true; // next lists GET is a stale snapshot
        return json(_list(1, serverName, items.length, items.length));
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

    // Navigate into Groceries (list 1).
    await tester.tap(find.byKey(const Key('drawer-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Groceries').last);
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsWidgets);

    // Rename Groceries -> Home via the header popup.
    await tester.tap(find.byTooltip('List actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Home');
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(find.text('Home'), findsWidgets,
        reason: 'rename applied immediately (local apply)');

    // Now the settle refresh's stale snapshot lands — it shows the OLD name
    // 'Groceries'. It MUST be discarded; 'Home' stays.
    staleGate.complete();
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Home'), findsWidgets,
        reason: 'settle-refresh pre-commit snapshot must NOT revert the rename');
    expect(find.text('Groceries'), findsNothing,
        reason: 'old name must not return after the stale snapshot lands');
  });
}
