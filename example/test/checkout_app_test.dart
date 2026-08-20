import 'package:ephemeral_bloc_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cancelling confirmation keeps the order awaiting confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(const CheckoutApp());

    expect(find.text('Awaiting confirmation'), findsOneWidget);
    expect(find.text('Confirmed'), findsNothing);

    await tester.tap(find.text('Confirm order'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm order?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm order?'), findsNothing);
    expect(find.text('Awaiting confirmation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accepting confirmation updates the rendered state', (
    tester,
  ) async {
    await tester.pumpWidget(const CheckoutApp());

    expect(find.text('Awaiting confirmation'), findsOneWidget);

    await tester.tap(find.text('Confirm order'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm order?'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm order?'), findsNothing);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Awaiting confirmation'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
