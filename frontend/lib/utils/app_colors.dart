import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Secondary
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFFA29BFE);
  static const Color primaryDark = Color(0xFF4834D4);

  // Status & Priority
  static const Color alert = Color(0xFFFF6B6B);
  static const Color alertLight = Color(0xFFFFEAEA);
  
  static const Color warning = Color(0xFFFDCB6E);
  static const Color warningLight = Color(0xFFFFF7E6);

  static const Color success = Color(0xFF00B894);
  static const Color successLight = Color(0xFFE6FAF5);

  static const Color info = Color(0xFF0984E3);
  static const Color infoLight = Color(0xFFEBF5FC);

  // Categories
  static const Color water = Color(0xFF00CEC9);
  static const Color road = Color(0xFFE17055);
  static const Color garbage = Color(0xFF2ED573);
  static const Color electricity = Color(0xFFFFA502);
  static const Color health = Color(0xFFFF4757);
  static const Color safety = Color(0xFF5352ED);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF8F9FD);
  static const Color surface = Colors.white;
  static const Color surfaceSecondary = Color(0xFFF1F3F9);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textMuted = Color(0xFFB2BEC3);
  static const Color border = Color(0xFFE2E8F0);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF8E44AD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient alertGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF4757)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00B894), Color(0xFF00CEC9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlow = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Box Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
}
