import 'package:material_ui/material_ui.dart';
import '../constants/app_colors.dart';

enum PillVariant { success, pending, danger, info, purple }

class StatusPill extends StatelessWidget {
  final String text;
  final PillVariant variant;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.text,
    this.variant = PillVariant.info,
    this.icon,
  });

  factory StatusPill.fromStatus(String status) {
    final lower = status.toLowerCase();
    if (lower == 'approved' ||
        lower == 'accepted' ||
        lower == 'completed' ||
        lower == 'active' ||
        lower == 'verified') {
      return StatusPill(text: status, variant: PillVariant.success);
    } else if (lower == 'pending' ||
        lower == 'open' ||
        lower == 'waiting for driver' ||
        lower == 'in review') {
      return StatusPill(text: status, variant: PillVariant.pending);
    } else if (lower == 'rejected' ||
        lower == 'cancelled' ||
        lower == 'suspended' ||
        lower == 'high priority' ||
        lower == 'disputed') {
      return StatusPill(text: status, variant: PillVariant.danger);
    } else {
      return StatusPill(text: status, variant: PillVariant.purple);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    Color border;

    switch (variant) {
      case PillVariant.success:
        bg = AppColors.statusSuccessBg;
        textColor = AppColors.statusSuccessText;
        border = AppColors.statusSuccessBorder;
        break;
      case PillVariant.pending:
        bg = AppColors.statusPendingBg;
        textColor = AppColors.statusPendingText;
        border = AppColors.statusPendingBorder;
        break;
      case PillVariant.danger:
        bg = AppColors.statusDangerBg;
        textColor = AppColors.statusDangerText;
        border = AppColors.statusDangerBorder;
        break;
      case PillVariant.info:
      case PillVariant.purple:
        bg = AppColors.statusInfoBg;
        textColor = AppColors.statusInfoText;
        border = AppColors.statusInfoBorder;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
