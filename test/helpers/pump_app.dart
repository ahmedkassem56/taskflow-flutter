// Shared widget-test pump helper: boots the real app against a SnapshotServer
// with the standard phone viewport and clean prefs. All tests use this so the
// harness + setup stay in ONE place (single source of truth).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taskflow_app/app.dart';
import 'package:taskflow_app/data/services/api_client.dart';
import 'package:taskflow_app/data/services/settings_store.dart';
import 'package:taskflow_app/presentation/providers/api_client.dart';

import 'snapshot_server.dart';

/// Boots TaskflowApp against [server] at a phone viewport (390x844).
Future<SnapshotServer> pumpApp(
  WidgetTester tester, {
  SnapshotServer? server,
  Size size = const Size(390, 844),
  Map<String, Object>? prefs,
}) async {
  final SnapshotServer srv = server ?? SnapshotServer();
  SharedPreferences.setMockInitialValues(prefs ?? <String, Object>{});
  // SettingsStore mirrors every write into a process-static map and reads it
  // back when prefs have no value — without a reset, a list selection made by
  // an earlier test in this process (selectList -> write 'taskflow.view')
  // silently restores that list in the next pumpApp.
  SettingsStore.resetForTest();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      apiClientProviderProvider.overrideWithValue(
          ApiClient('http://x', client: MockClient(srv.handle))),
    ],
    child: const TaskflowApp(),
  ));
  await tester.pumpAndSettle();
  return srv;
}

/// Navigates from All tasks into the list titled [name] via the drawer.
Future<void> openList(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('drawer-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

/// Opens the rename dialog for the current list view and submits [newName].
Future<void> renameCurrentList(WidgetTester tester, String newName) async {
  await tester.tap(find.byTooltip('List actions'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Rename'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, newName);
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

/// Taps an item row (opens the edit sheet) then deletes via confirm dialog.
Future<void> deleteItemRow(WidgetTester tester, String title) async {
  await tester.tap(find.text(title).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete').last);
  await tester.pumpAndSettle();
}

/// Quick-adds [title] through the composer field.
Future<void> quickAdd(WidgetTester tester, String title) async {
  await tester.enterText(find.byKey(const Key('quick-add-field')), title);
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await tester.pumpAndSettle();
}
