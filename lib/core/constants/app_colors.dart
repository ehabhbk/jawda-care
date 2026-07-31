import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF006B9E);
  static const Color primaryLight = Color(0xFF4A9BC7);
  static const Color primaryDark = Color(0xFF00456A);

  static const Color secondary = Color(0xFF2ECC71);
  static const Color secondaryLight = Color(0xFF82E0AA);

  static const Color accent = Color(0xFFE74C3C);
  static const Color accentLight = Color(0xFFF1948A);

  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFF8C471);

  static Brightness _brightness = Brightness.light;

  static set brightness(Brightness value) => _brightness = value;

  static bool get _isDark => _brightness == Brightness.dark;

  static Color get background =>
      _isDark ? const Color(0xFF12121A) : const Color(0xFFF5F8FA);
  static Color get surface => _isDark ? const Color(0xFF1E1E2E) : Colors.white;
  static Color get surfaceDark => const Color(0xFF1A1A2E);

  static Color get textPrimary =>
      _isDark ? const Color(0xFFE8EAF2) : const Color(0xFF2C3E50);
  static Color get textSecondary =>
      _isDark ? const Color(0xFFA3A8BD) : const Color(0xFF7F8C8D);
  static const Color textLight = Colors.white;

  static Color get border =>
      _isDark ? const Color(0xFF333348) : const Color(0xFFE0E6ED);
  static Color get divider =>
      _isDark ? const Color(0xFF26263A) : const Color(0xFFF0F0F0);

  static const Color success = Color(0xFF27AE60);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  static const Color ambulanceRed = Color(0xFFE74C3C);
  static const Color icuGreen = Color(0xFF2ECC71);
  static const Color pendingOrange = Color(0xFFF39C12);
}
