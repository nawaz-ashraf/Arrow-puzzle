import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_puzzle/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ArrowPuzzleApp());
    expect(find.text('ARROW'), findsOneWidget);
    expect(find.text('ESCAPE'), findsOneWidget);
  });
}
