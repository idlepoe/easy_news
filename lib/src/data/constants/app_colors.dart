import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF3182F6);
  static const Color secondary = Color(0xFF1564D6);

  // Background Colors
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFF2F4F6);
  static const Color white = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF191F28);
  static const Color textSecondary = Color(0xFF8B95A1);
  static const Color textTertiary = Color(0xFFB0B8C1);

  // Border Colors
  static const Color divider = Color(0xFFE5E8EB);
  static const Color border = Color(0xFFD1D6DB);

  // Status Colors
  static const Color success = Color(0xFF00C851);
  static const Color warning = Color(0xFFFFBB33);
  static const Color error = Color(0xFFFF4444);
  static const Color info = Color(0xFF33B5E5);

  // Entity Colors
  static const Color entityPerson = Color(0xFF3182F6);
  static const Color entityOrganization = Color(0xFF00C851);
  static const Color entityLocation = Color(0xFFFFBB33);
  static const Color entityCompany = Color(0xFF9C27B0);
  static const Color entityCountry = Color(0xFFFF4444);

  // Opacity Colors
  static const Color overlay = Color(0x80000000);
  static const Color disabled = Color(0xFFE5E8EB);
}

// Legacy constants for backward compatibility
const tossBlue = AppColors.primary;
const tossBlueDark = AppColors.secondary;
