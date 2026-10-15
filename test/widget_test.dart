import 'package:flutter_test/flutter_test.dart';
import 'package:practice8/main.dart';

void main() {
  testWidgets('GreenhouseApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GreenhouseApp());
    expect(find.text('Моніторинг розумної теплиці'), findsOneWidget);
  });
}
