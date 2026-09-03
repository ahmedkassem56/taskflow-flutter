// UX audit probes: objective checks for issues a visual review would catch.
// - narrow + large-text layout sweep (RenderFlex overflows throw in tests)
// - destructive-action error visibility (user must never get silent failure)
// - WCAG contrast math for text/icon color pairs used in the UI
// - responsive structure: rail vs drawer at breakpoint

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taskflow_app/app.dart';
import 'package:taskflow_app/data/services/api_client.dart';
import 'package:taskflow_app/presentation/providers/api_client.dart';
import 'package:taskflow_app/theme.dart';

import 'ui_flows_test.dart' show FakeBackend;

// ---------------------------------------------------------------------------
// WCAG contrast helpers
// ---------------------------------------------------------------------------

double _lum(Color c) {
  double f(double v) {
    v = v / 255;
    return v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * f(c.r * 255) + 0.7152 * f(c.g * 255) + 0.0722 * f(c.b * 255);
}

double contrast(Color a, Color b) {
  final double l1 = _lum(a), l2 = _lum(b);
  final double hi = math.max(l1, l2), lo = math.min(l1, l2);
  return (hi + 0.05) / (lo + 0.05);
}

// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeBackend backend;
  ApiClient buildApiClient() => ApiClient(
        'http://127.0.0.1:8000',
        client: MockClient((http.Request request) async => backend.handle(request)),
      );

  Future<void> pumpAt(WidgetTester tester, Size size, {double textScale = 1.0}) async {
    backend = FakeBackend();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProviderProvider.overrideWithValue(buildApiClient())],
        child: const TaskflowApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  // -------------------------------------------------------------------------
  // 1. Layout sweep: no RenderFlex overflow on small phones or large text
  // -------------------------------------------------------------------------

  testWidgets('mobile 360x740: list renders without overflow', (WidgetTester tester) async {
    await pumpAt(tester, const Size(360, 740));
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Eggs'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'overflow on mobile All-tasks list');
  });

  testWidgets('mobile 360x740: edit sheet fits without overflow', (WidgetTester tester) async {
    await pumpAt(tester, const Size(360, 740));
    // Row tap opens the full edit sheet (fields + delete/action row).
    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('item-title-field')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('item-save-button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'overflow in edit sheet');
  });

  testWidgets('mobile 360x740: list-view rows with move arrows fit', (WidgetTester tester) async {
    await pumpAt(tester, const Size(360, 740));
    await tester.tap(find.byKey(const Key('drawer-button')));
    await tester.pumpAndSettle();
    final Finder drawerList = find.descendant(of: find.byType(Drawer), matching: find.text('Groceries'));
    await tester.tap(drawerList.first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Move down'), findsWidgets);
    expect(tester.takeException(), isNull, reason: 'overflow with arrow column on mobile');
  });

  testWidgets('large text scale 1.3 on 360dp: no overflow in list or sheet',
      (WidgetTester tester) async {
    await pumpAt(tester, const Size(360, 740), textScale: 1.3);
    expect(tester.takeException(), isNull, reason: 'overflow at textScale 1.3 (list)');
    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('item-save-button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'overflow at textScale 1.3 (sheet)');
  });

  // -------------------------------------------------------------------------
  // 2. Error visibility on destructive actions (silent failure = UX bug)
  // -------------------------------------------------------------------------

  testWidgets('DELETE item failure surfaces a user-visible SnackBar', (WidgetTester tester) async {
    backend = FakeBackend()..failItemDeletes = true;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProviderProvider.overrideWithValue(buildApiClient())],
        child: const TaskflowApp(),
      ),
    );
    await tester.pumpAndSettle();
    // Row tap opens edit sheet; Delete -> confirm dialog -> DELETE fails (500).
    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Expect the user to be told the delete failed — not silent.
    expect(find.byType(SnackBar), findsOneWidget,
        reason: 'delete failure must not be silent — user needs feedback');
  });

  // -------------------------------------------------------------------------
  // 3. Responsive structure at the breakpoint
  // -------------------------------------------------------------------------

  testWidgets('wide 1280: rail shown, drawer button hidden', (WidgetTester tester) async {
    await pumpAt(tester, const Size(1280, 800));
    expect(find.text('All tasks'), findsWidgets); // sidebar row present
    expect(find.byKey(const Key('drawer-button')), findsNothing);
    expect(find.byType(Drawer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // -------------------------------------------------------------------------
  // 4. WCAG contrast audit of the theme token pairs
  // -------------------------------------------------------------------------

  test('theme color contrast audit (WCAG AA 4.5:1)', () {
    final ColorScheme light = buildLightColorScheme();
    final ColorScheme dark = buildDarkColorScheme();
    // _MetaChip label color = lerp(color -> onSurface, 0.38) when colored.
    Color chipLabel(Color color, ColorScheme scheme) =>
        Color.lerp(color, scheme.onSurface, 0.38)!;
    final List<(String, Color, Color)> pairs = <(String, Color, Color)>[
      ('light primary btn (white on indigo)', light.onPrimary, light.primary),
      ('light surface text', light.onSurface, light.surface),
      ('light secondary text', light.onSurfaceVariant, light.surface),
      ('light error text', light.onError, light.error),
      ('dark primary btn', dark.onPrimary, dark.primary),
      ('dark surface text', dark.onSurface, dark.surface),
      ('dark secondary text', dark.onSurfaceVariant, dark.surface),
      ('dark error text', dark.onError, dark.error),
      // Chip labels (lerped toward onSurface in both themes).
      ('light chip surface text', light.onSurfaceVariant, light.surfaceContainerHighest),
      ('light high-prio chip label', chipLabel(kPriorityHigh, light), light.surfaceContainerHighest),
      ('light medium-prio chip label', chipLabel(kPriorityMedium, light), light.surfaceContainerHighest),
      ('light low-prio chip label', chipLabel(kPriorityLow, light), light.surfaceContainerHighest),
      ('light due-today label (primary)', chipLabel(light.primary, light), light.surfaceContainerHighest),
      ('light overdue label (error)', chipLabel(light.error, light), light.surfaceContainerHighest),
      ('dark high-prio chip label', chipLabel(kPriorityHigh, dark), dark.surfaceContainerHighest),
      ('dark medium-prio chip label', chipLabel(kPriorityMedium, dark), dark.surfaceContainerHighest),
      ('dark low-prio chip label', chipLabel(kPriorityLow, dark), dark.surfaceContainerHighest),
    ];
    for (final (String name, Color fg, Color bg) in pairs) {
      final double ratio = contrast(fg, bg);
      // ignore: avoid_print
      print('  $name: ${ratio.toStringAsFixed(2)}:1');
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: '$name is $ratio:1 — below WCAG AA 4.5:1 for normal text');
    }
    // Decorative dots only need the graphics bar (3:1).
    for (final Color dot in <Color>[
      kPriorityHigh,
      kPriorityMedium,
      kPriorityLow,
      light.primary,
      light.error,
    ]) {
      expect(contrast(dot, light.surfaceContainerHighest), greaterThanOrEqualTo(3.0),
          reason: 'chip dot $dot below 3:1 on light chip background');
    }
  });
}
