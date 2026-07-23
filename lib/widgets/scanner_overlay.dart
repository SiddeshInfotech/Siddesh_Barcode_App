import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

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

        // Floating Soft Particles Animation
        const Positioned.fill(
          child: _FloatingParticlesWidget(),
        ),

        // Darkened cutout overlay around the scan window
        Positioned.fill(
          child: CustomPaint(
            painter: _ScannerCutoutPainter(scanWindowSize: scanWindowSize),
          ),
        ),

        // Glowing Blue Corner Brackets & Laser Line centered in the screen
        Center(
          child: SizedBox(
            width: scanWindowSize.width,
            height: scanWindowSize.height,
            child: Stack(
              children: [
                // Glowing Corner Brackets Painter
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

/// Animated Laser Scanning Line
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
          left: 12,
          right: 12,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primary,
                  AppColors.secondary,
                  Colors.white,
                  AppColors.secondary,
                  AppColors.primary,
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  blurRadius: 6,
                  spreadRadius: 1,
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
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    canvas.drawPath(cutoutPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerCutoutPainter oldDelegate) {
    return oldDelegate.scanWindowSize != scanWindowSize;
  }
}

/// Glowing Corner Brackets Painter
class _CornerBracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 34.0;
    const strokeWidth = 4.5;

    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

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
      ..color = AppColors.primary.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const spacing = 36.0;

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

/// Floating Soft Particles Animation
class _FloatingParticlesWidget extends StatefulWidget {
  const _FloatingParticlesWidget();

  @override
  State<_FloatingParticlesWidget> createState() => _FloatingParticlesWidgetState();
}

class _FloatingParticlesWidgetState extends State<_FloatingParticlesWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  final math.Random _random = math.Random(42);
  late final List<Offset> _particleOffsets = List.generate(
    12,
    (_) => Offset(_random.nextDouble(), _random.nextDouble()),
  );

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
        return CustomPaint(
          painter: _ParticlesPainter(
            progress: _controller.value,
            offsets: _particleOffsets,
          ),
        );
      },
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({required this.progress, required this.offsets});

  final double progress;
  final List<Offset> offsets;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < offsets.length; i++) {
      final base = offsets[i];
      final dy = (base.dy - (progress * 0.3) + 1.0) % 1.0;
      final dx = (base.dx + math.sin(progress * math.pi * 2 + i) * 0.05) % 1.0;

      final opacity = (math.sin(progress * math.pi * 2 + i) * 0.3 + 0.5).clamp(0.1, 0.7);
      paint.color = AppColors.secondary.withValues(alpha: opacity);

      final radius = 2.0 + (i % 3);
      canvas.drawCircle(Offset(dx * size.width, dy * size.height), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
