import 'package:flutter/material.dart';

class SparklineGraph extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double lineWidth;

  const SparklineGraph({
    super.key,
    required this.data,
    this.color = const Color(0xFF00D09E), // Default teal
    this.lineWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      painter: _SparklinePainter(
        data: data,
        color: color,
        lineWidth: lineWidth,
      ),
      size: Size.infinite,
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double lineWidth;

  _SparklinePainter({
    required this.data,
    required this.color,
    required this.lineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double min = data.reduce((a, b) => a < b ? a : b);
    final double max = data.reduce((a, b) => a > b ? a : b);
    final double range = max - min;
    
    // Normalize range if all values are the same
    final double actualRange = range == 0 ? 1 : range;

    final path = Path();
    final double stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final double normalizedY = (data[i] - min) / actualRange;
      // Invert Y because canvas Y goes down
      final double y = size.height - (normalizedY * size.height);
      final double x = i * stepX;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
           oldDelegate.color != color ||
           oldDelegate.lineWidth != lineWidth;
  }
}
