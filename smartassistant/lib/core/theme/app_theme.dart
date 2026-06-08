import 'package:flutter/material.dart';

/// Theme aplikasi SightAssist.
///
/// Menggunakan dark theme dengan kontras tinggi untuk aksesibilitas.
/// Warna utama: cyan/teal — mudah dilihat di layar gelap oleh
/// pendamping tunanetra.
class AppTheme {
  AppTheme._();

  // ─── Warna Utama ───────────────────────────────────────────
  static const Color primaryColor = Color(0xFF00BCD4);    // Cyan
  static const Color secondaryColor = Color(0xFF26A69A);  // Teal
  static const Color accentColor = Color(0xFF4DD0E1);     // Light Cyan
  static const Color errorColor = Color(0xFFEF5350);      // Red 400
  static const Color successColor = Color(0xFF66BB6A);    // Green 400
  static const Color warningColor = Color(0xFFFFA726);    // Orange 400

  // ─── Background ────────────────────────────────────────────
  static const Color scaffoldBg = Color(0xFF0D1117);      // GitHub Dark
  static const Color cardBg = Color(0xFF161B22);           // Sedikit lebih terang
  static const Color surfaceBg = Color(0xFF21262D);        // Surface

  // ─── Teks ──────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF484F58);

  // ─── Theme Data ────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: cardBg,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        onError: Colors.white,
      ),

      // Scaffold
      scaffoldBackgroundColor: scaffoldBg,

      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: surfaceBg, width: 1),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 4,
      ),

      // Text
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textSecondary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
        labelLarge: TextStyle(
          color: textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: surfaceBg,
        thickness: 1,
      ),

      // ListTile
      listTileTheme: ListTileThemeData(
        tileColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.3);
          }
          return surfaceBg;
        }),
      ),
    );
  }
}
