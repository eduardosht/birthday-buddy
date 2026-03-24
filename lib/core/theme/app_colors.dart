import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette — warm rose/blush
  static const Color primary = Color(0xFFE8637A);
  static const Color primaryLight = Color(0xFFFAD4DA);
  static const Color primaryDark = Color(0xFFC0445B);

  // Accent — soft gold
  static const Color accent = Color(0xFFF0B429);
  static const Color accentLight = Color(0xFFFFF0C4);

  // Backgrounds
  static const Color background = Color(0xFFF8F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2F0ED);

  // Text
  static const Color textDark = Color(0xFF1C1C1E);
  static const Color textMedium = Color(0xFF4A4A4A);
  static const Color textLight = Color(0xFF9A9A9A);

  // Status
  static const Color alertRed = Color(0xFFD94F4F);
  static const Color alertOrange = Color(0xFFE07B39);
  static const Color todayGold = Color(0xFFF0B429);
  static const Color successGreen = Color(0xFF3DAA6E);

  // Borders
  static const Color outline = Color(0xFFE5E3DF);
  static const Color outlineFocus = Color(0xFFE8637A);

  // Group color palette — muted, refined tones
  static const List<Color> groupColors = [
    Color(0xFFE8637A), // rose
    Color(0xFF5B8FD4), // calm blue
    Color(0xFF59B88C), // sage green
    Color(0xFFF0B429), // warm gold
    Color(0xFF9B72CF), // soft purple
    Color(0xFFE07B39), // terracotta
  ];

  // WhatsApp green
  static const Color whatsapp = Color(0xFF25D366);
}
