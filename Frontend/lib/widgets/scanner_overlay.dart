import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({
    Key? key,
    this.scanWindowSize = const Size(260, 260),
    this.isScanning = true,
  }) : super(key: key);

  final Size scanWindowSize;
  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: scanWindowSize,
        painter: _ScannerOverlayPainter(),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double cornerLength = 40.0;
    final double strokeWidth = 5.0;
    final double radius = 20.0;

    final Paint paint = Paint()
      ..color = const Color(0xFF3BA8FF)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint glowPaint = Paint()
      ..color = const Color(0xFF3BA8FF).withOpacity(0.5)
      ..strokeWidth = strokeWidth * 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    void drawCorner(Path path) {
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }

    // Top Left
    Path topLeft = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, radius)
      ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius))
      ..lineTo(cornerLength, 0);
    drawCorner(topLeft);

    // Top Right
    Path topRight = Path()
      ..moveTo(width - cornerLength, 0)
      ..lineTo(width - radius, 0)
      ..arcToPoint(Offset(width, radius), radius: Radius.circular(radius))
      ..lineTo(width, cornerLength);
    drawCorner(topRight);

    // Bottom Left
    Path bottomLeft = Path()
      ..moveTo(0, height - cornerLength)
      ..lineTo(0, height - radius)
      ..arcToPoint(Offset(radius, height), radius: Radius.circular(radius), clockwise: false)
      ..lineTo(cornerLength, height);
    drawCorner(bottomLeft);

    // Bottom Right
    Path bottomRight = Path()
      ..moveTo(width - cornerLength, height)
      ..lineTo(width - radius, height)
      ..arcToPoint(Offset(width, height - radius), radius: Radius.circular(radius), clockwise: false)
      ..lineTo(width, height - cornerLength);
    drawCorner(bottomRight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
