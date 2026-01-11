import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DigitalClockWidget extends StatelessWidget {
  final DateTime time;

  const DigitalClockWidget({
    super.key,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');
    final timeString = timeFormat.format(time);

    return Text(
      timeString,
      style: const TextStyle(
        fontSize: 80,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 8,
        shadows: [
          Shadow(
            blurRadius: 10,
            color: Colors.black,
            offset: Offset(4, 4),
          ),
        ],
      ),
    );
  }
}