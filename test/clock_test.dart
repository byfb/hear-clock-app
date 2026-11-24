import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_clock/app_language.dart';
import 'package:hear_clock/clock_face.dart';
import 'package:hear_clock/clock_palette.dart';
import 'package:hear_clock/clock_settings.dart';
import 'package:hear_clock/l10n/generated/app_localizations.dart';
import 'package:hear_clock/main.dart';

class _Platform extends ClockPlatform {
  AppLanguage interfaceLanguage = AppLanguage.system;
  bool device24 = false;
  ValueChanged<bool>? onHourFormat;
  @override
  Future<({AppLanguage language, bool device24})> displayPreferences() async =>
      (language: interfaceLanguage, device24: device24);
  @override
  void onTimeFormatChanged(ValueChanged<bool>? callback) =>
      onHourFormat = callback;
  @override
  Future<void> setAppLanguage(AppLanguage language) async =>
      interfaceLanguage = language;
  ClockSettings saved = const ClockSettings();
  Future<void>? nextSave;
  final readings = <ClockSettings>[];
  var failSpeech = false;
  var pins = 0;

  @override
  Future<ClockSettings> load() async => saved;
  @override
  Future<void> save(ClockSettings settings) async {
    final pending = nextSave;
    nextSave = null;
    if (pending != null) await pending;
    saved = settings;
  }

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
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  test('Chinese script takes precedence over region and unsupported locales fall back', () {
    Locale resolve(List<Locale> locales) =>
        resolveAppLocale(locales, AppLocalizations.supportedLocales);
    final hant = AppLanguage.traditional.locale!;
    final hans = AppLanguage.simplified.locale!;
    for (final region in ['HK', 'TW', 'MO']) {
      expect(resolve([Locale('zh', region)]), hant);
    }
    expect(resolve([const Locale('fr'), const Locale('zh', 'SG')]), hans);
    expect(
      resolve([
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'TW',
        ),
      ]),
      hans,
    );
    expect(
      resolve([
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'CN',
        ),
      ]),
      hant,
    );
    expect(resolve([const Locale('de')]), const Locale('en'));
  });

  testWidgets(
    'regional Chinese follows the phone and localizes the clock action',
    (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('zh', 'HK')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final platform = _Platform()
        ..saved = ClockSettings.fromMap({'format': 'h12'});
      await tester.pumpWidget(HearClockApp(platform: platform));
      await tester.pumpAndSettle();
      var clock = find.bySemanticsLabel('聽時間');
      expect(clock, findsOneWidget);
      expect(
        tester.getSemantics(clock).value,
        matches(RegExp(r'^本地時間，(上午|下午)\d+:\d\d$')),
      );
      expect(find.text('加入小工具'), findsOneWidget);
      tester.platformDispatcher.localesTestValue = [const Locale('zh', 'CN')];
      await tester.pumpAndSettle();
      clock = find.bySemanticsLabel('听时间');
      expect(clock, findsOneWidget);
      expect(find.text('添加小组件'), findsOneWidget);
      await tester.tap(clock);
      await tester.pumpAndSettle();
      expect(platform.readings, hasLength(1));
      await _tap(tester, '添加小组件');
      expect(find.textContaining('长按桌面空白处'), findsOneWidget);
      await _tap(tester, '完成');
      tester.platformDispatcher.localesTestValue = [const Locale('de')];
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
    },
  );

  testWidgets(
    'changing the UI language keeps the phone hour cycle and live format changes',
    (tester) async {
      final platform = _Platform()..interfaceLanguage = AppLanguage.simplified;
      await tester.pumpWidget(HearClockApp(platform: platform));
      await tester.pumpAndSettle();
      final clock = find.bySemanticsLabel('听时间');
      expect(
        tester.getSemantics(clock).value,
        matches(RegExp(r'(上午|下午)\d+:\d\d$')),
      );
      platform.device24 = true;
      platform.onHourFormat!(true);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(clock).value,
        matches(RegExp(r'^当地时间，\d\d:\d\d$')),
      );
    },
  );

  testWidgets(
    'switching the interface language preserves the voice and clock face',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final platform = _Platform()
        ..saved = ClockSettings.fromMap({
          'speech.language': 'fr-FR',
          'speech.label': 'français (France)',
          'speech.rate': 75,
        });
      await tester.pumpWidget(HearClockApp(platform: platform));
      await tester.pumpAndSettle();
      await _tap(tester, 'Settings');
      await _tap(tester, 'Analog');
      await _tap(tester, 'App language', scroll: -200);
      await _tap(tester, '繁體中文');
      expect(platform.interfaceLanguage, AppLanguage.traditional);
      expect(find.text('時鐘設定'), findsOneWidget);
      await _tap(tester, '語音');
      expect(find.text('français (France)'), findsOneWidget);
      final slider = find.bySemanticsLabel('語速');
      await tester.ensureVisible(find.byType(Slider));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(slider).getSemanticsData().value, '百分之75');
      await _tap(tester, '試聽');
      expect(platform.readings.single.variant, FaceVariant.analog);
      expect(platform.readings.single.language.tag, 'fr-FR');
      expect(platform.readings.single.speechRate, 75);
      expect(platform.saved.variant, FaceVariant.analog);
      await _back(tester);
      expect(find.text('指針時鐘'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(HearClockApp(platform: platform));
      await tester.pumpAndSettle();
      expect(find.text('設定'), findsOneWidget);
      await _tap(tester, '設定');
      await _tap(tester, '介面語言');
      await _tap(tester, '跟隨系統語言');
      expect(find.text('Clock settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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

  test('color combinations change only the current face colors', () {
    final original = ClockSettings.fromMap({
      'font': 'serif',
      'hour.length': 45,
      'minute.weight': 'bold',
      'dial.seconds': true,
      'format': 'h24',
      'speech.rate': 150,
      'stack.digits': 0xfedcba,
    });
    for (final variant in FaceVariant.values) {
      final prior = original.copyWith(variant: variant);
      for (final palette in ClockPalette.values) {
        final changed = palette.apply(prior);
        expect(ClockPalette.current(changed), palette);
        expect(changed.contrast, greaterThan(7));
        expect(changed.format, ClockFormat.h24);
        expect(changed.speechRate, 150);
        expect(changed.digital.font, DigitFont.serif);
        expect(changed.dial.hour.length, 45);
        expect(changed.dial.minute.weight, HandWeight.bold);
        expect(changed.dial.seconds, isTrue);
        if (variant != FaceVariant.stacked) {
          expect(changed.stacked, same(prior.stacked));
        }
        if (variant != FaceVariant.digital) {
          expect(changed.digital, same(prior.digital));
        }
        if (variant != FaceVariant.analog) {
          expect(changed.dial, same(prior.dial));
        }
        expect(
          ClockPalette.current(ClockSettings.fromMap(changed.toMap())),
          palette,
        );
      }
    }
    final unreadable = ClockSettings.fromMap({
      'variant': 'analog',
      'dial.face': 0,
      'minute.color': 0,
      'second.color': 0,
    });
    expect(unreadable.lowestContrast, (part: ClockPart.minuteHand, ratio: 1.0));
    expect(ClockPalette.current(unreadable), isNull);
  });

  testWidgets('rapid edits persist silently across settings visits', (
    tester,
  ) async {
    final firstSave = Completer<void>();
    final platform = _Platform()..nextSave = firstSave.future;
    await tester.pumpWidget(HearClockApp(platform: platform));
    await tester.pumpAndSettle();
    await _tap(tester, 'Settings');
    expect(find.text('Save settings'), findsNothing);
    await _tap(tester, 'Analog');
    await _tap(tester, 'Voice');
    await _tap(tester, 'Include today’s date');
    await _back(tester);
    final clock = tester.widget<ClockFace>(find.byType(ClockFace));
    expect(clock.settings.variant, FaceVariant.analog);
    expect(clock.settings.includeDate, isTrue);
    await _tap(tester, 'Settings');
    await _tap(tester, 'Stacked');
    expect(platform.saved.variant, FaceVariant.digital);

    firstSave.complete();
    await tester.pumpAndSettle();
    expect(platform.saved.variant, FaceVariant.stacked);
    expect(platform.saved.includeDate, isTrue);
    expect(find.text('Clock settings'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(platform.readings, isEmpty);
  });

  testWidgets('a failed edit restores the saved choice and can be retried', (
    tester,
  ) async {
    final platform = _Platform();
    await tester.pumpWidget(HearClockApp(platform: platform));
    await tester.pumpAndSettle();
    await _tap(tester, 'Settings');
    await _tap(tester, 'Stacked');
    final failedSave = Completer<void>();
    platform.nextSave = failedSave.future;
    await _tap(tester, 'Analog');
    failedSave.completeError(PlatformException(code: 'settings'));
    await tester.pumpAndSettle();
    expect(
      find.text('Couldn’t save these settings. Try again.'),
      findsOneWidget,
    );
    expect(platform.saved.variant, FaceVariant.stacked);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Stacked'))
          .selected,
      isTrue,
    );
    await _tap(tester, 'Analog');
    expect(platform.saved.variant, FaceVariant.analog);
  });

  testWidgets('switching faces preserves each set of digits automatically', (
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
    expect(platform.saved.variant, FaceVariant.stacked);
    expect(platform.saved.digital.font, DigitFont.serif);
    expect(platform.saved.digital.seconds, isTrue);
    expect(platform.saved.stacked.size, DigitSize.small);
    expect(rgb(platform.saved.stacked.minuteColor), 0xa9edc2);
    expect(platform.saved.stacked.padHour, isTrue);
    expect(platform.saved.seconds, isFalse);
    await _back(tester);
    await _tap(tester, 'Settings');
    await _tap(tester, 'Digital');
    expect(platform.saved.seconds, isTrue);
    expect(rgb(platform.saved.digital.digits), 0xf1c04a);
    expect(rgb(platform.saved.stacked.minuteColor), 0xa9edc2);
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
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Second hand length'))
          .getSemanticsData()
          .hasAction(SemanticsAction.increase),
      isTrue,
    );
    tester.widget<Slider>(length).onChanged!(65);
    await tester.pump();
    await _tap(tester, 'Bold');
    expect(platform.saved.dial.labels, DialLabels.numbers);
    expect(platform.saved.dial.hour.length, 55);
    expect(platform.saved.dial.minute.weight, HandWeight.regular);
    expect(platform.saved.dial.second.length, 65);
    expect(platform.saved.dial.second.weight, HandWeight.bold);
    expect(rgb(platform.saved.dial.second.color), 0xffdd59);
    await _back(tester);
    final clock = find.bySemanticsLabel('Hear the time');
    expect(clock, findsOneWidget);
    expect(
      tester.getSemantics(clock).value,
      matches(RegExp(r'^Local time, \d+:\d\d:\d\d')),
    );
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
      final clock = find.bySemanticsLabel('Hear the time');
      expect(clock, findsOneWidget);
      expect(platform.readings, isEmpty);
      await tester.pump(const Duration(minutes: 1));
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
    'the clock is the first keyboard action and keeps its colors when Android changes theme',
    (tester) async {
      final platform = _Platform()
        ..saved = ClockSettings.fromMap({'face': 0x102946, 'digits': 0xffdd59});
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(HearClockApp(platform: platform));
      await tester.pumpAndSettle();
      final face = find.byType(ClockFace);
      expect(Theme.of(tester.element(face)).brightness, Brightness.light);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(platform.readings, hasLength(1));
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(Theme.of(tester.element(face)).brightness, Brightness.dark);
      expect(rgb(tester.widget<ClockFace>(face).settings.face), 0x102946);
      expect(platform.readings, hasLength(1));
    },
  );

  testWidgets(
    'custom colors and typography autosave and survive reopening the app',
    (tester) async {
      final platform = _Platform();
      await tester.pumpWidget(HearClockApp(platform: platform));
      await tester.pumpAndSettle();
      await _tap(tester, 'Settings');
      await _tap(tester, 'Digit color');
      await tester.enterText(find.byType(TextField), 'XYZ');
      await _tap(tester, 'Use color');
      expect(find.textContaining('Enter six hex digits'), findsOneWidget);
      expect(platform.saved.toMap(), const ClockSettings().toMap());
      await tester.enterText(find.byType(TextField), '#f1c04a');
      await _tap(tester, 'Use color');
      expect(rgb(platform.saved.digital.digits), 0xf1c04a);
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
    'muting clock taps keeps a readable time and remembers the voice',
    (tester) async {
      final platform = _Platform()
        ..saved = ClockSettings.fromMap({
          'speech.language': 'fr-FR',
          'speech.label': 'Français',
          'speech.rate': 75,
          'speech.includeDate': true,
        });
      expect(platform.saved.speakOnTap, isTrue);
      await tester.pumpWidget(HearClockApp(platform: platform));
      await tester.pumpAndSettle();
      await _tap(tester, 'Settings');
      await _tap(tester, 'Voice');
      await _tap(tester, 'Speak on tap');
      expect(find.text('Test voice'), findsNothing);
      expect(find.text('Include today’s date'), findsNothing);
      expect(platform.saved.toMap()['speech.enabled'], false);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(HearClockApp(platform: platform));
      await tester.pumpAndSettle();
      final clock = find.byType(ClockFace);
      final node = tester.getSemantics(clock);
      expect(node.value, startsWith('Local time, '));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      expect(find.text('Hear the time'), findsNothing);
      await tester.tap(clock);
      expect(platform.readings, isEmpty);
      await _tap(tester, 'Settings');
      await _tap(tester, 'Voice');
      await _tap(tester, 'Speak on tap');
      await _back(tester);
      await tester.tap(find.bySemanticsLabel('Hear the time and date'));
      expect(platform.readings.single.language.tag, 'fr-FR');
      expect(platform.readings.single.speechRate, 75);
      expect(platform.readings.single.includeDate, isTrue);
    },
  );

  testWidgets(
    'voice previews and saved clock taps use the chosen date, language and speed',
    (tester) async {
      final platform = _Platform();
      expect(ClockSettings.fromMap({}).includeDate, isFalse);
      await tester.pumpWidget(HearClockApp(platform: platform));
      await tester.pumpAndSettle();
      await _tap(tester, 'Settings');
      await _tap(tester, 'Voice');
      await _tap(tester, 'Include today’s date');
      await _tap(tester, 'Speech language');
      await _tap(tester, 'French (France)');
      await tester.ensureVisible(find.byType(Slider));
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Speech speed'))
            .getSemanticsData()
            .hasAction(SemanticsAction.decrease),
        isTrue,
      );
      tester.widget<Slider>(find.byType(Slider)).onChanged!(75);
      await tester.pump();
      await _tap(tester, 'Test voice');
      expect(platform.readings.last.language.tag, 'fr-FR');
      expect(platform.readings.last.speechRate, 75);
      expect(platform.readings.last.includeDate, isTrue);
      expect(platform.saved.toMap()['speech.rate'], 75);
      expect(platform.saved.toMap()['speech.language'], 'fr-FR');
      expect(platform.saved.toMap()['speech.includeDate'], isTrue);
      await _back(tester);
      final action = find.bySemanticsLabel('Hear the time and date');
      expect(tester.getSemantics(action).value, startsWith('Local time, '));
      await tester.tap(action);
      expect(platform.readings.last.includeDate, isTrue);
      await _tap(tester, 'Settings');
      await _tap(tester, 'Voice');
      await _tap(tester, 'Include today’s date');
      await _back(tester);
      await tester.tap(find.bySemanticsLabel('Hear the time'));
      expect(platform.readings.last.includeDate, isFalse);
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
    expect(rgb(platform.saved.face), 0xffffff);
    expect(tester.takeException(), isNull);
  });

  testWidgets('presets, voice and defaults autosave at 200 percent text size', (
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
    await _tap(tester, 'Color combinations');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await _tap(tester, 'Black on white');
    await _tap(tester, 'Voice');
    await _tap(tester, 'Speech language');
    await _tap(tester, 'French (France)');
    await _tap(tester, 'Test voice');
    expect(platform.readings.single.language.tag, 'fr-FR');
    expect(
      ClockPalette.current(platform.readings.single),
      ClockPalette.blackOnWhite,
    );
    expect(platform.saved.language.tag, 'fr-FR');
    expect(ClockPalette.current(platform.saved), ClockPalette.blackOnWhite);
    await _tap(tester, 'Appearance');
    await _tap(tester, 'Restore all defaults');
    expect(platform.saved.toMap(), const ClockSettings().toMap());
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
