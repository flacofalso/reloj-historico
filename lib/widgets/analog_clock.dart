import 'dart:math';
import 'package:flutter/material.dart';

class AnalogClockWidget extends StatelessWidget {
  final DateTime time;
  final double size;

  const AnalogClockWidget({
    super.key,
    required this.time,
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: AnalogClockPainter(time),
      ),
    );
  }
}

class AnalogClockPainter extends CustomPainter {
  final DateTime time;

  AnalogClockPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    final facePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, facePaint);

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, borderPaint);

    _drawTickMarks(canvas, center, radius);

    final secondAngle = (time.second * 6.0) * (pi / 180) - pi / 2;
    final minuteAngle = ((time.minute + time.second / 60) * 6.0) * (pi / 180) - pi / 2;
    final hourAngle = ((time.hour % 12 + time.minute / 60) * 30.0) * (pi / 180) - pi / 2;

    _drawHand(canvas, center, hourAngle, radius * 0.4, 8, Colors.amber);
    _drawHand(canvas, center, minuteAngle, radius * 0.6, 6, Colors.white);
    _drawHand(canvas, center, secondAngle, radius * 0.7, 3, Colors.red);

    final centerDotPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 10, centerDotPaint);
  }

  void _drawTickMarks(Canvas canvas, Offset center, double radius) {
    for (int i = 0; i < 60; i++) {
      final angle = (i * 6.0) * (pi / 180);
      final isMajorTick = i % 5 == 0;

      final tickPaint = Paint()
        ..color = isMajorTick ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.6)
        ..strokeWidth = isMajorTick ? 3 : 2;

      final startRadius = radius - (isMajorTick ? 20 : 12);
      final endRadius = radius - 5;

      final startX = center.dx + startRadius * cos(angle);
      final startY = center.dy + startRadius * sin(angle);
      final endX = center.dx + endRadius * cos(angle);
      final endY = center.dy + endRadius * sin(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), tickPaint);
    }
  }

  void _drawHand(Canvas canvas, Offset center, double angle, double length, double width, Color color) {
    final handPaint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    final handX = center.dx + length * cos(angle);
    final handY = center.dy + length * sin(angle);

    canvas.drawLine(center, Offset(handX, handY), handPaint);
  }

  @override
  bool shouldRepaint(AnalogClockPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}