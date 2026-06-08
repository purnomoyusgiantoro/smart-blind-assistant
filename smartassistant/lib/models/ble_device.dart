/// Model data perangkat BLE yang ditemukan saat scanning.
class BleDevice {
  /// Nama perangkat (misalnya "SightAssist-ESP32")
  final String name;

  /// ID unik perangkat (MAC address)
  final String id;

  /// Kekuatan sinyal (semakin besar semakin dekat)
  final int rssi;

  /// Apakah sedang terhubung
  final bool isConnected;

  const BleDevice({
    required this.name,
    required this.id,
    this.rssi = 0,
    this.isConnected = false,
  });

  /// Membuat salinan dengan field yang diubah
  BleDevice copyWith({
    String? name,
    String? id,
    int? rssi,
    bool? isConnected,
  }) {
    return BleDevice(
      name: name ?? this.name,
      id: id ?? this.id,
      rssi: rssi ?? this.rssi,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  String toString() => 'BleDevice($name, $id, rssi: $rssi)';
}
