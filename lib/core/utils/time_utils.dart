import 'package:intl/intl.dart';

/// Utility class untuk penanganan waktu WIB (Waktu Indonesia Barat).
///
/// Semua waktu di aplikasi ini menggunakan WIB (UTC+7)
/// agar sesuai dengan zona waktu pengguna di Indonesia bagian barat.
class TimeUtils {
  TimeUtils._();

  /// Offset WIB dari UTC (7 jam)
  static const Duration wibOffset = Duration(hours: 7);

  /// Mendapatkan waktu sekarang dalam WIB.
  static DateTime getWibTime() {
    return DateTime.now().toUtc().add(wibOffset);
  }

  /// Format waktu ke "HH:mm WIB".
  /// Contoh: "08:30 WIB"
  static String formatWibTime(DateTime? dt) {
    final wibTime = dt ?? getWibTime();
    final formatter = DateFormat('HH:mm');
    return '${formatter.format(wibTime)} WIB';
  }

  /// Format tanggal dan waktu ke "dd MMMM yyyy, HH:mm WIB".
  /// Contoh: "11 Juni 2026, 08:30 WIB"
  static String formatWibDateTime(DateTime? dt) {
    final wibTime = dt ?? getWibTime();
    final formatter = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');
    return '${formatter.format(wibTime)} WIB';
  }

  /// Format waktu singkat untuk overlay UI.
  /// Contoh: "08:30"
  static String formatWibTimeShort(DateTime? dt) {
    final wibTime = dt ?? getWibTime();
    final formatter = DateFormat('HH:mm');
    return formatter.format(wibTime);
  }

  /// Format tanggal singkat.
  /// Contoh: "11 Jun 2026"
  static String formatWibDateShort(DateTime? dt) {
    final wibTime = dt ?? getWibTime();
    final formatter = DateFormat('dd MMM yyyy', 'id_ID');
    return formatter.format(wibTime);
  }
}
