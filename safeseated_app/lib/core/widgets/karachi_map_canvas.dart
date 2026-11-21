import 'package:material_ui/material_ui.dart';
import '../constants/app_colors.dart';

class KarachiMapCanvas extends StatefulWidget {
  final String pickup;
  final String destination;
  final String eta;

  const KarachiMapCanvas({
    super.key,
    this.pickup = 'Gulshan-e-Iqbal',
    this.destination = 'SMIU, Shahrah-e-Faisal',
    this.eta = '6 mins',
  });

  @override
  State<KarachiMapCanvas> createState() => _KarachiMapCanvasState();
}

class _KarachiMapCanvasState extends State<KarachiMapCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Custom Painter for roads and route
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _MapPainter(progress: _controller.value),
                );
              },
            ),
            // Top Badge with live status
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.statusSuccessText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Driver arriving in ${widget.eta}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Karachi route labels
            Positioned(
              bottom: 8,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.navigation,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Route: ${widget.pickup} ➔ ${widget.destination}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final double progress;

  _MapPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundRoadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final routePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    // Draw secondary road grid
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.35),
      backgroundRoadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, 0),
      Offset(size.width * 0.3, size.height),
      backgroundRoadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.75, 0),
      Offset(size.width * 0.7, size.height),
      backgroundRoadPaint,
    );

    // Main route path from pickup to destination
    final path = Path();
    final p0 = Offset(size.width * 0.15, size.height * 0.75); // Pickup
    final p1 = Offset(size.width * 0.45, size.height * 0.65);
    final p2 = Offset(size.width * 0.55, size.height * 0.35);
    final p3 = Offset(size.width * 0.85, size.height * 0.25); // Destination

    path.moveTo(p0.dx, p0.dy);
    path.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);

    // Draw base route path
    canvas.drawPath(path, routePaint);

    // Draw Pickup pin (Green)
    final pickupPaint = Paint()..color = const Color(0xFF1E824C);
    canvas.drawCircle(p0, 7, pickupPaint);
    canvas.drawCircle(p0, 3, Paint()..color = Colors.white);

    // Draw Destination pin (Purple)
    final destPaint = Paint()..color = AppColors.primaryDark;
    canvas.drawCircle(p3, 7, destPaint);
    canvas.drawCircle(p3, 3, Paint()..color = Colors.white);

    // Interpolate animated car position along path
    // Approximate cubic bezier point
    final t = progress;
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;

    final carX =
        uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx;
    final carY =
        uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy;

    // Draw pulsating outer circle for car
    canvas.drawCircle(
      Offset(carX, carY),
      12 + 4 * (1 - (progress * 2 % 1)),
      Paint()..color = AppColors.primary.withValues(alpha: 0.25),
    );

    // Draw Car icon dot
    canvas.drawCircle(Offset(carX, carY), 8, dotPaint);
    canvas.drawCircle(Offset(carX, carY), 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
