// DELETE must survive the server's commit lag: the backend commits AFTER
// sending the response, so the delete's OWN settle refresh (sent right after
// the 204) can read pre-commit state that still contains the deleted item.
// Without a guard the deleted row resurrects on screen.
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DELETE: row does not resurrect from a pre-commit settle refresh',
      (WidgetTester tester) async {
    final srv = await pumpApp(tester);
    srv.commitLag = const Duration(milliseconds: 60); // server commits late
    await openList(tester, 'Groceries');
    expect(find.text('Eggs'), findsOneWidget);

    // Delete Eggs. The 204 returns instantly; the delete's settle refresh GET
    // arrives within the commit lag → server still has Eggs → response does.
    await deleteItemRow(tester, 'Eggs');
    await tester.pump(const Duration(milliseconds: 120)); // commit lands
    await tester.pumpAndSettle();

    // The pre-commit refresh must NOT have resurrected Eggs.
    expect(find.text('Eggs'), findsNothing,
        reason: 'deleted item must stay gone even if a settle refresh read '
            'pre-commit state');
  });
}
