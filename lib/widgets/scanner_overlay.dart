import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({
    super.key,
    required this.scanWindowSize,
    required this.isScanning,
  });

  final Size scanWindowSize;
  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blueprint Grid Pattern Background Overlay
        const Positioned.fill(
          child: CustomPaint(
            painter: _BlueprintGridPainter(),
          ),
        ),

        // Darkened cutout overlay around the scan window
        Positioned.fill(
          child: CustomPaint(
            painter: _ScannerCutoutPainter(scanWindowSize: scanWindowSize),
          ),
        ),

        // Glowing White Corner Brackets & Laser Line centered in the screen
        Center(
          child: SizedBox(
            width: scanWindowSize.width,
            height: scanWindowSize.height,
            child: Stack(
              children: [
                // Glowing Corner Brackets Painter (White rounded corners matching Screen 2)
                CustomPaint(
                  size: scanWindowSize,
                  painter: _CornerBracketsPainter(),
                ),

                // Animated Laser Scanner Line
                if (isScanning)
                  Positioned.fill(
                    child: LaserAnimation(scanWindowHeight: scanWindowSize.height),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated White/Cyan Laser Scanning Line
class LaserAnimation extends StatefulWidget {
  const LaserAnimation({super.key, required this.scanWindowHeight});

  final double scanWindowHeight;

  @override
  State<LaserAnimation> createState() => _LaserAnimationState();
}

class _LaserAnimationState extends State<LaserAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final topOffset = _controller.value * (widget.scanWindowHeight - 24);
        return Positioned(
          top: topOffset,
          left: 8,
          right: 8,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0x80FFFFFF),
                  Colors.white,
                  Color(0xFFE0F2FE),
                  Colors.white,
                  Color(0x80FFFFFF),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  blurRadius: 14,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Cutout Painter for dark background around scanner window
class _ScannerCutoutPainter extends CustomPainter {
  _ScannerCutoutPainter({required this.scanWindowSize});

  final Size scanWindowSize;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final center = Offset(size.width / 2, size.height / 2);
    final scanRect = Rect.fromCenter(
      center: center,
      width: scanWindowSize.width,
      height: scanWindowSize.height,
    );
    final scanPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(24)));

    final cutoutPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      scanPath,
    );

    final paint = Paint()
      ..color = const Color(0xFF090D16).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    canvas.drawPath(cutoutPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerCutoutPainter oldDelegate) {
    return oldDelegate.scanWindowSize != scanWindowSize;
  }
}

/// Glowing Corner Brackets Painter (Screen 2 White Corner Brackets)
class _CornerBracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 36.0;
    const strokeWidth = 4.0;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    void drawCorner(double x, double y, double dx, double dy) {
      final path = Path()
        ..moveTo(x + dx * cornerLength, y)
        ..lineTo(x, y)
        ..lineTo(x, y + dy * cornerLength);

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }

    // Top-Left
    drawCorner(0, 0, 1, 1);
    // Top-Right
    drawCorner(size.width, 0, -1, 1);
    // Bottom-Left
    drawCorner(0, size.height, 1, -1);
    // Bottom-Right
    drawCorner(size.width, size.height, -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Blueprint Grid Pattern Painter
class _BlueprintGridPainter extends CustomPainter {
  const _BlueprintGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const spacing = 32.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
