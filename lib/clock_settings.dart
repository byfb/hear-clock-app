import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'clock_theme.dart';

enum DigitFont {
  mono('Mono', ClockTheme.mono),
  sans('Sans serif', ClockTheme.sans),
  serif('Serif', ClockTheme.serif);

  const DigitFont(this.label, this.family);
  final String label;
  final String family;
}

enum DigitSize {
  small('Small', .56),
  medium('Medium', .74),
  large('Large', .91);

  const DigitSize(this.label, this.fraction);
  final String label;
  final double fraction;
}

enum ClockFormat {
  device('Device'),
  h12('12-hour'),
  h24('24-hour');

  const ClockFormat(this.label);
  final String label;
}

int rgb(Color color) => color.toARGB32() & 0xffffff;
String hexColor(Color color) =>
    rgb(color).toRadixString(16).padLeft(6, '0').toUpperCase();

final namedColors = Map<Color, String>.unmodifiable({
  ClockTheme.digits: 'Ivory',
  ClockTheme.panel: 'Charcoal',
  ClockTheme.white: 'White',
  ClockTheme.black: 'Black',
  ClockTheme.accent: 'Apricot',
  ClockTheme.yellow: 'Yellow',
  ClockTheme.sky: 'Sky blue',
  ClockTheme.navy: 'Navy',
  ClockTheme.mint: 'Mint',
});

String colorName(Color color) => namedColors[color] ?? '#${hexColor(color)}';

@immutable
class SpeechLanguage {
  const SpeechLanguage(this.tag, this.label);
  static const device = SpeechLanguage('', 'Device language');
  final String tag;
  final String label;
}

@immutable
class ClockSettings {
  const ClockSettings({
    this.digits = ClockTheme.digits,
    this.face = ClockTheme.panel,
    this.font = DigitFont.mono,
    this.size = DigitSize.large,
    this.bold = false,
    this.format = ClockFormat.device,
    this.language = SpeechLanguage.device,
    this.speechRate = 100,
  });

  final Color digits;
  final Color face;
  final DigitFont font;
  final DigitSize size;
  final bool bold;
  final ClockFormat format;
  final SpeechLanguage language;
  final int speechRate;

  factory ClockSettings.fromMap(Map<Object?, Object?> map) {
    const defaults = ClockSettings();
    Color color(String key, Color fallback) {
      final value = map[key];
      return value is int && value >= 0 && value <= 0xffffff
          ? Color(0xff000000 | value)
          : fallback;
    }

    T choice<T extends Enum>(String key, List<T> values, T fallback) =>
        values.where((v) => v.name == map[key]).firstOrNull ?? fallback;
    final tag = map['speech.language'];
    final label = map['speech.label'];
    final rate = map['speech.rate'];
    return ClockSettings(
      digits: color('digits', defaults.digits),
      face: color('face', defaults.face),
      font: choice('font', DigitFont.values, defaults.font),
      size: choice('size', DigitSize.values, defaults.size),
      bold: map['bold'] == true,
      format: choice('format', ClockFormat.values, defaults.format),
      language: tag is String && tag.isNotEmpty
          ? SpeechLanguage(
              tag,
              label is String && label.isNotEmpty ? label : tag,
            )
          : SpeechLanguage.device,
      speechRate: rate is int && rate >= 50 && rate <= 200 ? rate : 100,
    );
  }

  Map<String, Object> toMap() => {
    'digits': rgb(digits),
    'face': rgb(face),
    'font': font.name,
    'size': size.name,
    'bold': bold,
    'format': format.name,
    'speech.language': language.tag,
    'speech.rate': speechRate,
  };

  ClockSettings copyWith({
    Color? digits,
    Color? face,
    DigitFont? font,
    DigitSize? size,
    bool? bold,
    ClockFormat? format,
    SpeechLanguage? language,
    int? speechRate,
  }) => ClockSettings(
    digits: digits ?? this.digits,
    face: face ?? this.face,
    font: font ?? this.font,
    size: size ?? this.size,
    bold: bold ?? this.bold,
    format: format ?? this.format,
    language: language ?? this.language,
    speechRate: speechRate ?? this.speechRate,
  );

  double get contrast {
    final a = digits.computeLuminance();
    final b = face.computeLuminance();
    return (math.max(a, b) + .05) / (math.min(a, b) + .05);
  }
}

class ClockPlatform {
  const ClockPlatform();
  static const _channel = MethodChannel('com.byfb.hear_clock/clock');
  Future<ClockSettings> load() async => ClockSettings.fromMap(
    await _channel.invokeMapMethod<Object?, Object?>('load') ?? {},
  );
  Future<void> save(ClockSettings settings) =>
      _channel.invokeMethod('save', settings.toMap());
  Future<void> speak(ClockSettings settings) =>
      _channel.invokeMethod('speak', settings.toMap());
  Future<List<SpeechLanguage>> languages() async {
    final items = await _channel.invokeListMethod<Object?>('languages') ?? [];
    return [
      for (final item in items)
        if (item case {'tag': final String tag, 'label': final String label})
          SpeechLanguage(tag, label),
    ];
  }

  Future<bool> pinWidget() async =>
      await _channel.invokeMethod<bool>('pinWidget') ?? false;
}
