import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class ClockTheme {
  static const shell = Color(0xff141412);
  static const panel = Color(0xff22221f);
  static const raised = Color(0xff302f2a);
  static const ink = Color(0xfff6f1e5);
  static const muted = Color(0xffc0bcaf);
  static const rule = Color(0xff878378);
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
  static const paper = Color(0xfff8f5ee);
  static const paperPanel = Color(0xfffffdf7);
  static const paperInk = Color(0xff24231e);
  static const paperMuted = Color(0xff555249);
  static const paperRule = Color(0xff79746a);
  static const paperDivider = Color(0xffc9c3b6);
  static const copper = Color(0xff833b16);
  static const darkBlue = Color(0xff165272);
  static const redInk = Color(0xff992e23);
  static const navy = Color(0xff102946);
  static const sans = 'sans-serif';
  static const mono = 'monospace';
  static const serif = 'serif';
  static const corner = BorderRadius.all(Radius.circular(4));
  static const shape = RoundedRectangleBorder(borderRadius: corner);

  static SystemUiOverlayStyle systemBars(Brightness brightness) =>
      (brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
          );

  static AppBar settingsBar(
    BuildContext context,
    String title, {
    PreferredSizeWidget? bottom,
  }) => AppBar(
    toolbarHeight: math.max(
      kToolbarHeight,
      MediaQuery.textScalerOf(context).scale(22) * 2.5,
    ),
    title: Text(title, maxLines: 2, softWrap: true),
    bottom: bottom,
  );

  static ThemeData data(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = dark
        ? const ColorScheme.dark(
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
          )
        : const ColorScheme.light(
            primary: copper,
            onPrimary: white,
            secondary: darkBlue,
            surface: paperPanel,
            onSurface: paperInk,
            onSurfaceVariant: paperMuted,
            surfaceContainerHighest: paper,
            outline: paperRule,
            outlineVariant: paperDivider,
            error: redInk,
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
            ? BorderSide(color: scheme.secondary, width: 3)
            : null,
      ),
    );
    return ThemeData(
      colorScheme: scheme,
      fontFamily: sans,
      scaffoldBackgroundColor: dark ? shell : paper,
      splashFactory: NoSplash.splashFactory,
      focusColor: scheme.secondary.withValues(alpha: .28),
      dividerColor: scheme.outlineVariant,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? shell : paper,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: systemBars(brightness),
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: buttons.copyWith(
          foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? BorderSide(color: scheme.secondary, width: 3)
                : BorderSide(color: scheme.outline),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: buttons),
      textButtonTheme: TextButtonThemeData(style: buttons),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(borderRadius: corner),
        focusedBorder: OutlineInputBorder(
          borderRadius: corner,
          borderSide: BorderSide(color: scheme.secondary, width: 2),
        ),
      ),
    );
  }
}

/// Dial and sound waves, shared with the Android launcher icon.
class ClockMark extends StatelessWidget {
  const ClockMark({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 36,
    height: 32,
    child: CustomPaint(
      painter: _MarkPainter(Theme.of(context).colorScheme.primary),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 28, size.height / 25);
    final line = Paint()
      ..color = color
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
  bool shouldRepaint(_MarkPainter oldDelegate) => oldDelegate.color != color;
}
