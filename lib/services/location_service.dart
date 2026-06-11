import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../core/utils/logger.dart';

/// Service untuk mengelola akses lokasi GPS.
///
/// Digunakan oleh mode Navigasi untuk mengetahui posisi pengguna
/// secara akurat dan mengkonversi koordinat ke alamat yang bisa dibaca.
class LocationService {
  static const String _tag = 'LocationService';

  Position? _lastPosition;
  Placemark? _lastPlacemark;

  /// Posisi terakhir yang diketahui
  Position? get lastPosition => _lastPosition;

  /// Placemark terakhir (alamat)
  Placemark? get lastPlacemark => _lastPlacemark;

  /// Inisialisasi dan minta izin lokasi.
  ///
  /// Return true jika lokasi tersedia dan izin diberikan.
  Future<bool> initialize() async {
    try {
      // Cek apakah layanan lokasi aktif
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning(_tag, 'Layanan lokasi tidak aktif');
        return false;
      }

      // Cek dan minta izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warning(_tag, 'Izin lokasi ditolak');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.warning(_tag, 'Izin lokasi ditolak permanen');
        return false;
      }

      AppLogger.info(_tag, 'Lokasi siap digunakan');
      return true;
    } catch (e) {
      AppLogger.error(_tag, 'Gagal inisialisasi lokasi', e);
      return false;
    }
  }

  /// Ambil posisi GPS saat ini.
  ///
  /// Menggunakan akurasi tinggi untuk navigasi.
  /// Return null jika gagal.
  Future<Position?> getCurrentPosition() async {
    try {
      _lastPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      AppLogger.info(_tag,
          'Posisi: ${_lastPosition!.latitude}, ${_lastPosition!.longitude} '
          '(akurasi: ${_lastPosition!.accuracy.toStringAsFixed(1)}m)');
      return _lastPosition;
    } catch (e) {
      AppLogger.error(_tag, 'Gagal mendapatkan posisi', e);
      return null;
    }
  }

  /// Konversi koordinat ke alamat menggunakan reverse geocoding.
  ///
  /// Return Placemark dengan info: jalan, kelurahan, kecamatan, kota, dll.
  Future<Placemark?> getPlacemarkFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        _lastPlacemark = placemarks.first;
        AppLogger.info(_tag,
            'Alamat: ${_lastPlacemark!.street}, '
            '${_lastPlacemark!.subLocality}, '
            '${_lastPlacemark!.locality}, '
            '${_lastPlacemark!.subAdministrativeArea}');
        return _lastPlacemark;
      }

      AppLogger.warning(_tag, 'Tidak ada placemark ditemukan');
      return null;
    } catch (e) {
      AppLogger.error(_tag, 'Gagal reverse geocoding', e);
      return null;
    }
  }

  /// Dapatkan deskripsi lokasi lengkap untuk prompt AI.
  ///
  /// Menggabungkan informasi GPS + reverse geocoding menjadi
  /// string deskriptif yang bisa langsung dimasukkan ke prompt.
  ///
  /// Contoh output:
  /// "Lokasi saat ini: Jalan Sudirman, Setiabudi, Jakarta Selatan.
  ///  Koordinat: -6.2088, 106.8456 (akurasi: 5.2m)"
  Future<String> getLocationDescription() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) {
        return 'Lokasi tidak tersedia';
      }

      final placemark = await getPlacemarkFromPosition(position);

      final buffer = StringBuffer();
      buffer.write('Lokasi saat ini: ');

      if (placemark != null) {
        // Bangun alamat dari komponen yang tersedia
        final parts = <String>[];

        if (placemark.street != null && placemark.street!.isNotEmpty) {
          parts.add(placemark.street!);
        }
        if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
          parts.add(placemark.subLocality!);
        }
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          parts.add(placemark.locality!);
        }
        if (placemark.subAdministrativeArea != null &&
            placemark.subAdministrativeArea!.isNotEmpty) {
          parts.add(placemark.subAdministrativeArea!);
        }
        if (placemark.administrativeArea != null &&
            placemark.administrativeArea!.isNotEmpty) {
          parts.add(placemark.administrativeArea!);
        }

        if (parts.isNotEmpty) {
          buffer.write(parts.join(', '));
        } else {
          buffer.write('Alamat tidak diketahui');
        }
        buffer.write('. ');
      }

      buffer.write('Koordinat: '
          '${position.latitude.toStringAsFixed(6)}, '
          '${position.longitude.toStringAsFixed(6)} '
          '(akurasi: ${position.accuracy.toStringAsFixed(1)}m)');

      return buffer.toString();
    } catch (e) {
      AppLogger.error(_tag, 'Gagal mendapatkan deskripsi lokasi', e);
      return 'Lokasi tidak tersedia';
    }
  }

  /// Dapatkan deskripsi lokasi singkat untuk UI overlay.
  ///
  /// Contoh: "Jl. Sudirman, Jakarta Selatan"
  String getShortLocationLabel() {
    if (_lastPlacemark == null) return 'Menunggu lokasi...';

    final parts = <String>[];
    if (_lastPlacemark!.street != null && _lastPlacemark!.street!.isNotEmpty) {
      parts.add(_lastPlacemark!.street!);
    }
    if (_lastPlacemark!.locality != null && _lastPlacemark!.locality!.isNotEmpty) {
      parts.add(_lastPlacemark!.locality!);
    }
    if (_lastPlacemark!.subAdministrativeArea != null &&
        _lastPlacemark!.subAdministrativeArea!.isNotEmpty) {
      parts.add(_lastPlacemark!.subAdministrativeArea!);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Lokasi tidak diketahui';
  }

  /// Dispose service.
  void dispose() {
    // Geolocator tidak memerlukan dispose eksplisit
    AppLogger.info(_tag, 'LocationService disposed');
  }
}
