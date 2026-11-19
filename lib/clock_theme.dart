import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class ClockTheme {
  static const shell = Color(0xff141412);
  static const panel = Color(0xff22221f);
  static const raised = Color(0xff302f2a);
  static const ink = Color(0xfff6f1e5);
  static const muted = Color(0xffc0bcaf);
  static const rule = Color(0xff5e5b51);
  static const divider = Color(0xff403f38);
  static const accent = Color(0xffffa66b);
  static const onAccent = Color(0xff24170d);
  static const focus = Color(0xffa6dcff);
  static const error = Color(0xffffb4a5);
  static const digits = Color(0xfffff4db);
  static const white = Color(0xffffffff);
  static const black = Color(0xff000000);
  static const yellow = Color(0xffffdd59);
  static const sky = Color(0xffa4dcff);
  static const mint = Color(0xffa9edc2);
  static const navy = Color(0xff102946);
  static const sans = 'sans-serif';
  static const mono = 'monospace';
  static const serif = 'serif';
  static const corner = BorderRadius.all(Radius.circular(4));
  static const shape = RoundedRectangleBorder(borderRadius: corner);

  static AppBar settingsBar(BuildContext context, String title) => AppBar(
    toolbarHeight: math.max(
      kToolbarHeight,
      MediaQuery.textScalerOf(context).scale(22) * 2.5,
    ),
    title: Text(title, maxLines: 2, softWrap: true),
  );

  static ThemeData get data {
    const scheme = ColorScheme.dark(
      primary: accent,
      onPrimary: onAccent,
      secondary: focus,
      surface: shell,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceContainerHighest: raised,
      outline: rule,
      outlineVariant: divider,
      error: error,
    );
    final buttons = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 50)),
      shape: const WidgetStatePropertyAll(shape),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      side: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? const BorderSide(color: focus, width: 3)
            : null,
      ),
    );
    return ThemeData(
      colorScheme: scheme,
      fontFamily: sans,
      scaffoldBackgroundColor: shell,
      splashFactory: NoSplash.splashFactory,
      focusColor: focus.withValues(alpha: .32),
      dividerColor: divider,
      appBarTheme: const AppBarTheme(
        backgroundColor: shell,
        foregroundColor: ink,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: buttons.copyWith(
          foregroundColor: const WidgetStatePropertyAll(ink),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? const BorderSide(color: focus, width: 3)
                : const BorderSide(color: rule),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: buttons),
      textButtonTheme: TextButtonThemeData(style: buttons),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: corner),
        focusedBorder: OutlineInputBorder(
          borderRadius: corner,
          borderSide: BorderSide(color: focus, width: 2),
        ),
      ),
    );
  }
}

/// Dial and sound waves, shared with the Android launcher icon.
class ClockMark extends StatelessWidget {
  const ClockMark({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 36,
    height: 32,
    child: CustomPaint(painter: _MarkPainter()),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 28, size.height / 25);
    final line = Paint()
      ..color = ClockTheme.accent
      ..strokeWidth = 1.9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawArc(
      const Rect.fromLTWH(1.5, 3, 18, 18),
      math.pi * .29,
      math.pi * 1.42,
      false,
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(10.5, 7)
        ..lineTo(10.5, 12)
        ..lineTo(14, 14),
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(18.5, 8)
        ..quadraticBezierTo(22, 12, 18.5, 16)
        ..moveTo(22.2, 5)
        ..quadraticBezierTo(28, 12, 22.2, 19),
      line,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}
