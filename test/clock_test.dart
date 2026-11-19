import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_clock/clock_face.dart';
import 'package:hear_clock/clock_settings.dart';
import 'package:hear_clock/main.dart';

class _Platform extends ClockPlatform {
  ClockSettings saved = const ClockSettings();
  final readings = <ClockSettings>[];
  var failSpeech = false;
  var pins = 0;

  @override
  Future<ClockSettings> load() async => saved;
  @override
  Future<void> save(ClockSettings settings) async => saved = settings;
  @override
  Future<void> speak(ClockSettings settings) async {
    if (failSpeech) {
      throw PlatformException(
        code: 'speech',
        message: 'Check your text-to-speech voice.',
      );
    }
    readings.add(settings);
  }

  @override
  Future<List<SpeechLanguage>> languages() async => [
    const SpeechLanguage('fr-FR', 'French (France)'),
  ];

  @override
  Future<bool> pinWidget() async {
    pins++;
    return false;
  }
}

Future<void> _tap(
  WidgetTester tester,
  String label, {
  double scroll = 200,
}) async {
  final target = find.text(label);
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      scroll,
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
    final evening = DateTime(2026, 1, 1, 19, 4, 9);
    expect(
      clockReading(
        evening,
        ClockFormat.h12,
        device24: true,
        seconds: true,
        padHour: true,
      ),
      (digits: '07:04:09', period: 'PM'),
    );
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
        ...const ClockSettings().toMap(),
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

  test('each analog hand retains its own color, length and thickness', () {
    final values = {
      ...const ClockSettings().toMap(),
      'variant': 'analog',
      'dial.seconds': true,
      'dial.labels': 'numbers',
      'hour.color': 0x987654,
      'hour.length': 40,
      'hour.weight': 'regular',
      'minute.color': 0x10b57c,
      'minute.length': 95,
      'minute.weight': 'slim',
      'second.color': 0xfedcba,
      'second.length': 70,
      'second.weight': 'bold',
    };
    final settings = ClockSettings.fromMap(values);
    expect(settings.seconds, isTrue);
    expect(settings.dial.labels, DialLabels.numbers);
    expect(settings.dial.hour.length, 40);
    expect(settings.dial.minute.weight, HandWeight.slim);
    expect(rgb(settings.dial.second.color), 0xfedcba);
    expect(settings.toMap(), values);
    final invalid = ClockSettings.fromMap({
      ...values,
      'minute.length': 10,
      'second.color': -1,
    });
    expect(invalid.dial.minute.length, const DialStyle().minute.length);
    expect(invalid.dial.second.color, const DialStyle().second.color);
    expect(invalid.dial.hour.length, 40);
  });

  testWidgets('switching faces preserves each set of digits after saving', (
    tester,
  ) async {
    final platform = _Platform()
      ..saved = ClockSettings.fromMap({'digits': 0xf1c04a, 'font': 'serif'});
    await tester.pumpWidget(HearClockApp(platform: platform));
    await tester.pumpAndSettle();
    await _tap(tester, 'Settings');
    await _tap(tester, 'Show seconds');
    await _tap(tester, 'Stacked', scroll: -200);
    expect(find.text('Show seconds'), findsNothing);
    await _tap(tester, 'Minute digit color');
    await _tap(tester, 'Mint');
    await _tap(tester, 'Use color');
    await _tap(tester, 'Small');
    await _tap(tester, 'Leading zero in 12-hour time');
    await _tap(tester, 'Save settings');
    expect(platform.saved.variant, FaceVariant.stacked);
    expect(platform.saved.digital.font, DigitFont.serif);
    expect(platform.saved.digital.seconds, isTrue);
    expect(platform.saved.stacked.size, DigitSize.small);
    expect(colorName(platform.saved.stacked.minuteColor), 'Mint');
    expect(platform.saved.stacked.padHour, isTrue);
    expect(platform.saved.seconds, isFalse);
    await _tap(tester, 'Settings');
    await _tap(tester, 'Digital');
    await _tap(tester, 'Save settings');
    expect(platform.saved.seconds, isTrue);
    expect(rgb(platform.saved.digital.digits), 0xf1c04a);
    expect(colorName(platform.saved.stacked.minuteColor), 'Mint');
  });

  testWidgets('a customized second hand speaks from the analog face', (
    tester,
  ) async {
    final platform = _Platform();
    await tester.pumpWidget(HearClockApp(platform: platform));
    await tester.pumpAndSettle();
    await _tap(tester, 'Settings');
    await _tap(tester, 'Analog');
    await _tap(tester, 'All numbers');
    await _tap(tester, 'Show second hand');
    await _tap(tester, 'Second hand');
    await _tap(tester, 'Second hand color');
    await _tap(tester, 'Yellow');
    await _tap(tester, 'Use color');
    final length = find.byWidgetPredicate(
      (widget) => widget is Slider && widget.min == 35,
    );
    await tester.scrollUntilVisible(
      length,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    tester.widget<Slider>(length).onChanged!(65);
    await tester.pump();
    await _tap(tester, 'Bold');
    await _tap(tester, 'Save settings');
    expect(platform.saved.dial.labels, DialLabels.numbers);
    expect(platform.saved.dial.hour.length, 55);
    expect(platform.saved.dial.minute.weight, HandWeight.regular);
    expect(platform.saved.dial.second.length, 65);
    expect(platform.saved.dial.second.weight, HandWeight.bold);
    expect(colorName(platform.saved.dial.second.color), 'Yellow');
    final clock = find.bySemanticsLabel(RegExp(r'^Local time, \d+:\d\d:\d\d'));
    expect(clock, findsOneWidget);
    await tester.tap(clock);
    await tester.pumpAndSettle();
    expect(platform.readings.single.variant, FaceVariant.analog);
    expect(platform.readings.single.seconds, isTrue);
  });

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
      expect(platform.readings.single.format, ClockFormat.device);
      platform.failSpeech = true;
      await tester.tap(clock);
      await tester.pumpAndSettle();
      expect(find.text('Check your text-to-speech voice.'), findsOneWidget);
    },
  );

  testWidgets(
    'custom colors and typography save together and survive reopening the app',
    (tester) async {
      final platform = _Platform();
      await tester.pumpWidget(HearClockApp(platform: platform));
      await tester.pumpAndSettle();
      await _tap(tester, 'Settings');
      await _tap(tester, 'Digit color');
      await tester.enterText(find.byType(TextField), 'XYZ');
      await _tap(tester, 'Use color');
      expect(find.textContaining('Enter six hex digits'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '#f1c04a');
      await _tap(tester, 'Use color');
      await _tap(tester, 'Background color');
      await _tap(tester, 'Navy');
      await _tap(tester, 'Use color');
      await _tap(tester, 'Small');
      await _tap(tester, 'Serif');
      await _tap(tester, 'Bold digits');
      await tester.scrollUntilVisible(
        find.text('24-hour'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await _tap(tester, '24-hour');
      expect(platform.saved.toMap(), const ClockSettings().toMap());
      await _tap(tester, 'Save settings');
      final expected = {
        ...const ClockSettings().toMap(),
        'digits': 0xf1c04a,
        'face': 0x102946,
        'font': 'serif',
        'size': 'small',
        'bold': true,
        'format': 'h24',
      };
      expect(platform.saved.toMap(), expected);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(HearClockApp(platform: platform));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ClockFace>(find.byType(ClockFace)).settings.toMap(),
        expected,
      );
    },
  );

  testWidgets(
    'a voice preview uses the draft language and speed before saving',
    (tester) async {
      final platform = _Platform();
      await tester.pumpWidget(HearClockApp(platform: platform));
      await tester.pumpAndSettle();
      await _tap(tester, 'Settings');
      await _tap(tester, 'Speech language');
      await _tap(tester, 'French (France)');
      await tester.ensureVisible(find.byType(Slider));
      tester.widget<Slider>(find.byType(Slider)).onChanged!(75);
      await tester.pump();
      await _tap(tester, 'Test voice');
      expect(platform.readings.last.language.tag, 'fr-FR');
      expect(platform.readings.last.speechRate, 75);
      expect(platform.saved.language.tag, isEmpty);
      await _tap(tester, 'Save settings');
      expect(platform.saved.toMap()['speech.rate'], 75);
      expect(platform.saved.toMap()['speech.language'], 'fr-FR');
    },
  );

  testWidgets('large system text leaves settings usable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final platform = _Platform();
    await tester.pumpWidget(HearClockApp(platform: platform));
    await tester.pumpAndSettle();
    await _tap(tester, 'Settings');
    await _tap(tester, 'Background color');
    await _tap(tester, 'White');
    await _tap(tester, 'Use color');
    expect(find.textContaining('Low contrast'), findsOneWidget);
    await _tap(tester, 'Save settings');
    expect(rgb(platform.saved.face), 0xffffff);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the speech action fits a short landscape screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(HearClockApp(platform: _Platform()));
    await tester.pumpAndSettle();
    expect(find.text('Hear the time').hitTestable(), findsOneWidget);
  });

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
