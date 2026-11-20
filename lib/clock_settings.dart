import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_language.dart';
import 'clock_theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'face_styles.dart';
export 'face_styles.dart';

enum ClockFormat { device, h12, h24 }

enum ClockPart {
  digits,
  hourDigits,
  minuteDigits,
  dialMarkings,
  hourHand,
  minuteHand,
  secondHand,
}

String hexColor(Color color) =>
    rgb(color).toRadixString(16).padLeft(6, '0').toUpperCase();

final namedColors = Map<Color, String>.unmodifiable({
  ClockTheme.digits: 'ivory',
  ClockTheme.panel: 'charcoal',
  ClockTheme.white: 'white',
  ClockTheme.black: 'black',
  ClockTheme.accent: 'apricot',
  ClockTheme.yellow: 'yellow',
  ClockTheme.sky: 'skyBlue',
  ClockTheme.navy: 'navy',
  ClockTheme.mint: 'mint',
});

String colorName(Color color, AppLocalizations strings) {
  final key = namedColors[color];
  return key == null ? '#${hexColor(color)}' : strings.colorName(key);
}

@immutable
class SpeechLanguage {
  const SpeechLanguage(this.tag, this.label);
  static const device = SpeechLanguage('', '');
  String displayName(AppLocalizations strings) =>
      tag.isEmpty ? strings.deviceLanguage : label;
  final String tag;
  final String label;
}

@immutable
class ClockSettings {
  const ClockSettings({
    this.variant = FaceVariant.digital,
    this.digital = const DigitStyle(),
    this.stacked = const DigitStyle(),
    this.dial = const DialStyle(),
    this.format = ClockFormat.device,
    this.speakOnTap = true,
    this.language = SpeechLanguage.device,
    this.speechRate = 100,
  });

  final FaceVariant variant;
  final DigitStyle digital, stacked;
  final DialStyle dial;
  final ClockFormat format;
  final bool speakOnTap;
  final SpeechLanguage language;
  final int speechRate;

  DigitStyle get text => variant == FaceVariant.stacked ? stacked : digital;
  Color get face => variant == FaceVariant.analog ? dial.face : text.face;
  bool get seconds => switch (variant) {
    FaceVariant.digital => digital.seconds,
    FaceVariant.stacked => false,
    FaceVariant.analog => dial.seconds,
  };

  factory ClockSettings.fromMap(Map<Object?, Object?> map) {
    final tag = map['speech.language'];
    final label = map['speech.label'];
    return ClockSettings(
      variant: map.enumValue(
        'variant',
        FaceVariant.values,
        FaceVariant.digital,
      ),
      digital: DigitStyle.decode(map, ''),
      stacked: DigitStyle.decode(map, 'stack.'),
      dial: DialStyle.decode(map),
      format: map.enumValue('format', ClockFormat.values, ClockFormat.device),
      speakOnTap: map['speech.enabled'] != false,
      language: tag is String && tag.isNotEmpty
          ? SpeechLanguage(
              tag,
              label is String && label.isNotEmpty ? label : tag,
            )
          : SpeechLanguage.device,
      speechRate: map.intValue('speech.rate', 50, 200, 100),
    );
  }

  Map<String, Object> toMap() => {
    'variant': variant.name,
    ...digital.encode(''),
    ...stacked.encode('stack.'),
    ...dial.encode(),
    'format': format.name,
    'speech.enabled': speakOnTap,
    'speech.language': language.tag,
    'speech.rate': speechRate,
  };

  ClockSettings withText(DigitStyle style) => variant == FaceVariant.stacked
      ? copyWith(stacked: style)
      : copyWith(digital: style);

  ClockSettings copyWith({
    FaceVariant? variant,
    DigitStyle? digital,
    DigitStyle? stacked,
    DialStyle? dial,
    ClockFormat? format,
    bool? speakOnTap,
    SpeechLanguage? language,
    int? speechRate,
  }) => ClockSettings(
    variant: variant ?? this.variant,
    digital: digital ?? this.digital,
    stacked: stacked ?? this.stacked,
    dial: dial ?? this.dial,
    format: format ?? this.format,
    speakOnTap: speakOnTap ?? this.speakOnTap,
    language: language ?? this.language,
    speechRate: speechRate ?? this.speechRate,
  );

  ({ClockPart part, double ratio}) get lowestContrast {
    final background = face.computeLuminance();
    final colors = switch (variant) {
      FaceVariant.digital => {ClockPart.digits: digital.digits},
      FaceVariant.stacked => {
        ClockPart.hourDigits: stacked.digits,
        ClockPart.minuteDigits: stacked.minuteColor,
      },
      FaceVariant.analog => {
        ClockPart.dialMarkings: dial.marks,
        ClockPart.hourHand: dial.hour.color,
        ClockPart.minuteHand: dial.minute.color,
        if (dial.seconds) ClockPart.secondHand: dial.second.color,
      },
    };
    return colors.entries
        .map((entry) {
          final foreground = entry.value.computeLuminance();
          final ratio =
              (math.max(foreground, background) + .05) /
              (math.min(foreground, background) + .05);
          return (part: entry.key, ratio: ratio);
        })
        .reduce((a, b) => a.ratio <= b.ratio ? a : b);
  }

  double get contrast => lowestContrast.ratio;
}

class ClockPlatform {
  const ClockPlatform();
  static const _channel = MethodChannel('com.byfb.hear_clock/clock');
  Future<({AppLanguage language, bool device24})> displayPreferences() async {
    final values = (await _channel.invokeMapMethod<String, Object>(
      'displayPreferences',
    ))!;
    return (
      language: AppLanguage.fromTag(values['language'] as String),
      device24: values['device24'] as bool,
    );
  }

  void onTimeFormatChanged(ValueChanged<bool>? callback) {
    _channel.setMethodCallHandler(
      callback == null
          ? null
          : (call) async {
              if (call.method == 'timeFormatChanged') {
                callback(call.arguments as bool);
              }
            },
    );
  }

  Future<void> setAppLanguage(AppLanguage language) =>
      _channel.invokeMethod<void>('setAppLanguage', language.tag);

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
