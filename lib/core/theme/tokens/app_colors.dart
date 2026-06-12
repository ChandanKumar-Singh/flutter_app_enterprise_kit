import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  // Brand
  static const primary       = Color(0xFF2563EB);
  static const primaryDark   = Color(0xFF1D4ED8);
  static const primaryLight  = Color(0xFF3B82F6);
  static const secondary     = Color(0xFF7C3AED);
  static const accent        = Color(0xFFF59E0B);

  // Semantic
  static const success  = Color(0xFF16A34A);
  static const warning  = Color(0xFFD97706);
  static const error    = Color(0xFFDC2626);
  static const info     = Color(0xFF0284C7);

  // Neutrals
  static const slate50  = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);

  // Surface
  static const white       = Color(0xFFFFFFFF);
  static const black       = Color(0xFF000000);
  static const transparent = Color(0x00000000);

  // Charts
  static const chart1 = Color(0xFF2563EB);
  static const chart2 = Color(0xFF7C3AED);
  static const chart3 = Color(0xFF16A34A);
  static const chart4 = Color(0xFFD97706);
  static const chart5 = Color(0xFFDC2626);
  static const chart6 = Color(0xFF0284C7);

  static List<Color> get chartPalette =>
      [chart1, chart2, chart3, chart4, chart5, chart6];
}
