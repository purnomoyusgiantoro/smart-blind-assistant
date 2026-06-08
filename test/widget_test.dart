import 'package:flutter_test/flutter_test.dart';
import 'package:smartassistant/app.dart';

void main() {
  testWidgets('SightAssist app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SightAssistApp());

    // Verify that the app title is displayed.
    expect(find.text('SightAssist'), findsOneWidget);
  });
}
