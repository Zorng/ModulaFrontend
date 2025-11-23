import 'package:flutter/material.dart';

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.0,
    this.dashWidth = 4.0,
    this.dashSpace = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)));

    final dashPath = _createDashedPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final path = Path();
    final dashCount = (source.computeMetrics().first.length / (dashWidth + dashSpace)).floor();
    final metric = source.computeMetrics().first;

    for (int i = 0; i < dashCount; ++i) {
      path.addPath(metric.extractPath(i * (dashWidth + dashSpace), (i * (dashWidth + dashSpace)) + dashWidth), Offset.zero);
    }
    return path;
  }
}