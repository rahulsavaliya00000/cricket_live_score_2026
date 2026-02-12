import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary - Cricket Green
  static const Color primaryGreen = Color(0xFF00A86B);
  static const Color primaryDark = Color(0xFF007A4D);
  static const Color primaryLight = Color(0xFF33C98B);

  // Accent
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentGold = Color(0xFFFFD700);

  // Live match
  static const Color liveRed = Color(0xFFE53935);
  static const Color livePulse = Color(0xFFFF1744);
  static const Color winGreen = Color(0xFF4CAF50);
  static const Color loseRed = Color(0xFFE53935);
  static const Color drawGray = Color(0xFF9E9E9E);

  // Light theme
  static const Color lightBg = Color(0xFFF5F7FA);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightDivider = Color(0xFFE5E7EB);

  // Dark theme
  static const Color darkBg = Color(0xFF0D1117);
  static const Color darkCard = Color(0xFF161B22);
  static const Color darkCardElevated = Color(0xFF1C2333);
  static const Color darkText = Color(0xFFF0F6FC);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkDivider = Color(0xFF30363D);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, Color(0xFF00C853)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1A1F35), Color(0xFF0F1629)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient liveGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFFF5722)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
