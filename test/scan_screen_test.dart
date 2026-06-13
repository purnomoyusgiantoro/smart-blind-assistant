import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartassistant/models/ble_device.dart';
import 'package:smartassistant/providers/ble_provider.dart';
import 'package:smartassistant/features/scan/scan_screen.dart';

// Create a subclass to allow injecting devices
class MockBleProvider extends BleProvider {
  @override
  List<BleDevice> get devices => [
    const BleDevice(name: 'ESP32', id: '11:22', rssi: -50),
    const BleDevice(name: 'SightAssist', id: '33:44', rssi: -70),
  ];
}

void main() {
  testWidgets('ScanScreen renders devices without crash', (WidgetTester tester) async {
    final bleProvider = MockBleProvider();
    
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
    
    expect(find.text('ESP32'), findsOneWidget);
  });
}
