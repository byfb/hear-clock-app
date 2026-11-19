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
