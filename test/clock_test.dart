import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_clock/clock_face.dart';
import 'package:hear_clock/clock_settings.dart';
import 'package:hear_clock/main.dart';

class _Platform extends ClockPlatform {
  ClockSettings saved = const ClockSettings();
  final readings = <ClockFormat>[];
  var failSpeech = false;
  var pins = 0;

  @override
  Future<ClockSettings> load() async => saved;
  @override
  Future<void> save(ClockSettings settings) async => saved = settings;
  @override
  Future<void> speak(ClockFormat format) async {
    if (failSpeech) {
      throw PlatformException(
        code: 'speech',
        message: 'Check your text-to-speech voice.',
      );
    }
    readings.add(format);
  }

  @override
  Future<bool> pinWidget() async {
    pins++;
    return false;
  }
}

Future<void> _tap(WidgetTester tester, String label) async {
  final target = find.text(label);
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .last,
    );
  }
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  test('noon, midnight and the device hour cycle', () {
    final midnight = DateTime(2026, 1, 1, 0, 3);
    final noon = DateTime(2026, 1, 1, 12, 0);
    expect(clockReading(midnight, ClockFormat.h12, device24: true), (
      digits: '12:03',
      period: 'AM',
    ));
    expect(clockReading(noon, ClockFormat.h12, device24: false), (
      digits: '12:00',
      period: 'PM',
    ));
    expect(clockReading(midnight, ClockFormat.h24, device24: false), (
      digits: '00:03',
      period: '',
    ));
    expect(clockReading(noon, ClockFormat.device, device24: true), (
      digits: '12:00',
      period: '',
    ));
    expect(clockReading(noon, ClockFormat.device, device24: false), (
      digits: '12:00',
      period: 'PM',
    ));
  });

  test(
    'settings preserve black, custom RGB and valid fields in a partial record',
    () {
      final settings = ClockSettings.fromMap({
        'digits': 0,
        'face': 0x12ab34,
        'font': 'serif',
        'size': 'removed-value',
        'format': 'h24',
        'bold': true,
      });
      expect(settings.toMap(), {
        'digits': 0,
        'face': 0x12ab34,
        'font': 'serif',
        'size': 'large',
        'format': 'h24',
        'bold': true,
      });
      expect(ClockSettings.fromMap(settings.toMap()).toMap(), settings.toMap());
      expect(const ClockSettings().contrast, greaterThan(7));
    },
  );

  testWidgets(
    'clock exposes one speaking action with a label and sufficient target size',
    (tester) async {
      final platform = _Platform();
      await tester.pumpWidget(HearClockApp(platform: platform));
      await tester.pumpAndSettle();
      final clock = find.bySemanticsLabel(RegExp(r'^Local time, '));
      expect(clock, findsOneWidget);
      expect(platform.readings, isEmpty);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await tester.tap(clock);
      await tester.pumpAndSettle();
      expect(platform.readings, [ClockFormat.device]);
      platform.failSpeech = true;
      await tester.tap(clock);
      await tester.pumpAndSettle();
      expect(find.text('Check your text-to-speech voice.'), findsOneWidget);
    },
  );

  testWidgets(
    'launcher instructions remain reachable when pinning is unavailable',
    (tester) async {
      final platform = _Platform();
      await tester.pumpWidget(HearClockApp(platform: platform));
      await tester.pumpAndSettle();
      await _tap(tester, 'Add widget');
      expect(platform.pins, 1);
      expect(find.textContaining('Open Widgets'), findsOneWidget);
      await _tap(tester, 'Done');
      expect(find.text('Hear the time'), findsOneWidget);
    },
  );
}
