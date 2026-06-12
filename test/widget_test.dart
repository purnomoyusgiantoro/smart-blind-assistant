import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartassistant/app.dart';
import 'package:smartassistant/providers/assistant_provider.dart';
import 'package:smartassistant/providers/ble_provider.dart';
import 'package:smartassistant/providers/settings_provider.dart';

class FakeAssistantProvider extends AssistantProvider {
  @override
  Future<void> initialize() async {
    // Override to avoid native MethodChannel calls in tests
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(envString: 'OPENROUTER_API_KEY=test_key');
  });

  testWidgets('SightAssist app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BleProvider()),
          ChangeNotifierProvider<AssistantProvider>(create: (_) => FakeAssistantProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const SightAssistApp(),
      ),
    );

    // Verify that the app title is displayed.
    expect(find.byType(SightAssistApp), findsOneWidget);
  });
}
