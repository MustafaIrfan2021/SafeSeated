import 'package:material_ui/material_ui.dart';

/// App color palette matching the SafeSeated refined design system:
/// Women-focused purple/lavender theme with clean cards, rounded buttons,
/// and clear semantic status pills.
class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF5B49C8);
  static const Color primaryDark = Color(0xFF40338F);
  static const Color primaryLight = Color(0xFF8172E8);
  static const Color primaryMuted = Color(0xFFF0EDFF);
  static const Color accentLavender = Color(0xFFF0EDFF);

  // Background and Surfaces
  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Colors.white;
  static const Color surfaceSubtle = Color(0xFFFAF9FF);

  // Text colors
  static const Color textPrimary = Color(0xFF201D35);
  static const Color textSecondary = Color(0xFF77758D);
  static const Color textMuted = Color(0xFF9B95AE);

  // Borders and Dividers
  static const Color border = Color(0xFFE9E7F1);
  static const Color divider = Color(0xFFE9E7F1);

  // Status: Success (Approved / Accepted / Completed)
  static const Color statusSuccessBg = Color(0xFFE6F7EF);
  static const Color statusSuccessText = Color(0xFF16845D);
  static const Color statusSuccessBorder = Color(0xFFBFE6D3);

  // Status: Warning / Pending
  static const Color statusPendingBg = Color(0xFFFFF7E6);
  static const Color statusPendingText = Color(0xFFA66B13);
  static const Color statusPendingBorder = Color(0xFFF2DDAF);

  // Status: Danger / Rejected / Cancelled / SOS
  static const Color statusDangerBg = Color(0xFFFDE8E8);
  static const Color statusDangerText = Color(0xFFC4475B);
  static const Color statusDangerBorder = Color(0xFFF3C8CF);
  static const Color sosRed = Color(0xFFC4475B);

  // Status: Info / Purple Pill
  static const Color statusInfoBg = Color(0xFFEDE7F6);
  static const Color statusInfoText = Color(0xFF5B49C8);
  static const Color statusInfoBorder = Color(0xFFD8D1FF);

  // Rating gold
  static const Color starGold = Color(0xFFF5A623);
}
