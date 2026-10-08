import 'package:flutter_test/flutter_test.dart';
import 'package:aviator_game/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const AviatorApp());
    expect(find.text('Aviator'), findsOneWidget);
  });
}
