import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'face_styles.dart';
import 'clock_theme.dart';

class AnalogDial extends CustomPainter {
  const AnalogDial(this.time, this.style);
  final DateTime time;
  final DialStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .44;
    final mark = Paint()
      ..color = style.marks
      ..strokeCap = StrokeCap.round;
    Offset point(double turns, double length) {
      final angle = math.pi * 2 * turns;
      return center +
          Offset(math.sin(angle), -math.cos(angle)) * (radius * length);
    }

    for (var tick = 0; tick < 60; tick++) {
      final major = tick % 5 == 0;
      mark.strokeWidth = radius * (major ? .032 : .012);
      canvas.drawLine(
        point(tick / 60, major ? .89 : .95),
        point(tick / 60, 1),
        mark,
      );
    }
    for (var hour = 1; hour <= 12; hour++) {
      if (style.labels == DialLabels.ticks ||
          (style.labels == DialLabels.quarters && hour % 3 != 0)) {
        continue;
      }
      final label = TextPainter(
        text: TextSpan(
          text: '$hour',
          style: TextStyle(
            color: style.marks,
            fontFamily: ClockTheme.sans,
            fontWeight: FontWeight.w600,
            fontSize: radius * .23,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        point(hour / 12, .72) - Offset(label.width / 2, label.height / 2),
      );
      label.dispose();
    }

    void drawHand(HandStyle hand, double turns) {
      final length = hand.length / 100;
      final paint = Paint()
        ..color = hand.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = radius * length * hand.weight.width;
      canvas.drawLine(center, point(turns, length), paint);
    }

    drawHand(style.hour, ((time.hour % 12) * 60 + time.minute) / 720);
    drawHand(style.minute, time.minute / 60);
    if (style.seconds) drawHand(style.second, time.second / 60);
  }

  @override
  bool shouldRepaint(AnalogDial old) => old.time != time || old.style != style;
}
