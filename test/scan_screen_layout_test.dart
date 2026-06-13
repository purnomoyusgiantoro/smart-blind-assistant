import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartassistant/providers/ble_provider.dart';
import 'package:smartassistant/features/scan/scan_screen.dart';

void main() {
  testWidgets('ScanScreen renders list without layout errors', (WidgetTester tester) async {
    final bleProvider = BleProvider();
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BleProvider>.value(value: bleProvider),
        ],
        child: const MaterialApp(
          home: ScanScreen(),
        ),
      ),
    );
    
    // Simulate finding devices
    // We can't easily inject devices into BleProvider without a setter, but wait, we can mock it or use reflection.
  });
}
