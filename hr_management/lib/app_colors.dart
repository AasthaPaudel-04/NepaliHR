import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1B4FD8);
  static const primaryDeep = Color(0xFF0F2F8A);
  static const accent = Color(0xFF00D1B2);
  static const background = Color(0xFFF0F4FF);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF0D1B3E);
  static const textSecondary = Color(0xFF6B7A9E);
  static const border = Color(0xFFE4EAF8);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  static const headerGradient = LinearGradient(
    colors: [primary, primaryDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}