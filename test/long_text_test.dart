import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartassistant/features/scan/widgets/device_list_tile.dart';
import 'package:smartassistant/models/ble_device.dart';
import 'package:smartassistant/providers/ble_provider.dart';

void main() {
  testWidgets('DeviceListTile with extremely long text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BleProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                DeviceListTile(
                  device: BleDevice(
                    name: 'ESP32 SightAssist Module Extra Long Text That Will Definitely Wrap Multiple Lines And Potentially Cause Layout Errors If Not Handled Properly But Let Us See If It Crashes',
                    id: '11:22:33:44:55:66',
                    rssi: -50,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byType(DeviceListTile), findsOneWidget);
  });
}
