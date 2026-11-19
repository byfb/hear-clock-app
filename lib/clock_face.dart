import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'clock_settings.dart';
import 'clock_theme.dart';

typedef ClockReading = ({String digits, String period});

ClockReading clockReading(
  DateTime time,
  ClockFormat format, {
  required bool device24,
}) {
  final use24 =
      format == ClockFormat.h24 || (format == ClockFormat.device && device24);
  final hour = use24
      ? time.hour.toString().padLeft(2, '0')
      : ((time.hour + 11) % 12 + 1).toString();
  return (
    digits: '$hour:${time.minute.toString().padLeft(2, '0')}',
    period: use24
        ? ''
        : time.hour < 12
        ? 'AM'
        : 'PM',
  );
}

class ClockFace extends StatefulWidget {
  const ClockFace({
    super.key,
    required this.settings,
    required this.platform,
    this.compact = false,
  });
  final ClockSettings settings;
  final ClockPlatform platform;
  final bool compact;

  @override
  State<ClockFace> createState() => _ClockFaceState();
}

class _ClockFaceState extends State<ClockFace> with WidgetsBindingObserver {
  late DateTime _now;
  Timer? _timer;
  var _focused = false;
  var _speaking = false;
  var _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tick();
  }

  void _tick() {
    _timer?.cancel();
    _now = DateTime.now();
    final next =
        Duration(minutes: 1) -
        Duration(
          seconds: _now.second,
          milliseconds: _now.millisecond,
          microseconds: _now.microsecond,
        );
    _timer = Timer(next, () => setState(_tick));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(_tick);
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _speak() async {
    final request = ++_request;
    setState(() => _speaking = true);
    try {
      await widget.platform.speak(widget.settings.format);
    } on PlatformException catch (error) {
      if (mounted && request == _request) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                error.message ??
                    'Check your Android text-to-speech voice and try again.',
              ),
            ),
          );
      }
    } finally {
      if (mounted && request == _request) setState(() => _speaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final time = clockReading(
      _now,
      settings.format,
      device24: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final label = [
      time.digits,
      if (time.period.isNotEmpty) time.period,
    ].join(' ');
    return Semantics(
      label: 'Local time, $label',
      button: true,
      onTap: _speak,
      onTapHint: 'Hear the time',
      excludeSemantics: true,
      child: Material(
        color: settings.face,
        shape: RoundedRectangleBorder(
          borderRadius: ClockTheme.corner,
          side: BorderSide(
            color: _focused ? ClockTheme.focus : ClockTheme.rule,
            width: _focused ? 3 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _speak,
          excludeFromSemantics: true,
          onFocusChange: (focused) => setState(() => _focused = focused),
          child: LayoutBuilder(
            builder: (context, bounds) {
              final compact = widget.compact;
              final height = compact
                  ? 108.0
                  : math.min(
                      MediaQuery.sizeOf(context).height / 3,
                      (bounds.maxWidth * .54).clamp(146.0, 278.0),
                    );
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: height,
                    child: FractionallySizedBox(
                      widthFactor: settings.size.fraction,
                      heightFactor: settings.size.fraction,
                      child: FittedBox(
                        child: Text.rich(
                          TextSpan(
                            text: time.digits,
                            children: [
                              if (time.period.isNotEmpty)
                                TextSpan(
                                  text: ' ${time.period}',
                                  style: const TextStyle(fontSize: 35),
                                ),
                            ],
                          ),
                          textDirection: TextDirection.ltr,
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            color: settings.digits,
                            fontFamily: settings.font.family,
                            fontWeight: settings.bold
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            fontSize: 100,
                            height: 1.08,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!compact) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                      child: SizedBox(
                        height: 16,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _MinuteScale(_now.minute, settings.digits),
                        ),
                      ),
                    ),
                    Ink(
                      color: ClockTheme.accent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.volume_up_outlined,
                              color: ClockTheme.onAccent,
                              size: 26,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                _speaking ? 'Reading time…' : 'Hear the time',
                                style: const TextStyle(
                                  color: ClockTheme.onAccent,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The taller mark is the current minute. Every fifth mark is a longer division.
class _MinuteScale extends CustomPainter {
  const _MinuteScale(this.minute, this.ink);
  final int minute;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()..strokeWidth = 1;
    for (var i = 0; i < 60; i++) {
      final x = 2 + (size.width - 4) * i / 59;
      final active = i == minute;
      final major = i % 5 == 0;
      final height = active
          ? size.height
          : major
          ? 10.0
          : 5.0;
      line
        ..color = active ? ink : ink.withValues(alpha: major ? .54 : .28)
        ..strokeWidth = active ? 3 : 1;
      canvas.drawLine(
        Offset(x, size.height - height),
        Offset(x, size.height),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_MinuteScale old) =>
      old.minute != minute || old.ink != ink;
}
