import 'package:material_ui/material_ui.dart';
import '../constants/app_colors.dart';

class AvatarWidget extends StatelessWidget {
  final String name;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const AvatarWidget({
    super.key,
    required this.name,
    this.size = 40,
    this.backgroundColor,
    this.textColor,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.accentLavender,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: textColor ?? AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
