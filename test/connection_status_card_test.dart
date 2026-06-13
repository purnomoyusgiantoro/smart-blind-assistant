import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartassistant/features/home/widgets/connection_status_card.dart';
import 'package:smartassistant/providers/ble_provider.dart';

void main() {
  testWidgets('ConnectionStatusCard renders without crash', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BleProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ConnectionStatusCard(),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byType(ConnectionStatusCard), findsOneWidget);
  });
}
