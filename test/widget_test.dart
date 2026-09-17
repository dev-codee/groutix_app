import 'package:flutter_test/flutter_test.dart';
import 'package:groutix_app/main.dart';

void main() {
  testWidgets('GroutixApp basic load test', (WidgetTester tester) async {
    await tester.pumpWidget(const GroutixApp());
    expect(find.byType(GroutixApp), findsOneWidget);
  });
}
