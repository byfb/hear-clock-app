import 'package:flutter/material.dart';

import 'clock_theme.dart';

enum FaceVariant { digital, stacked, analog }

enum DigitFont {
  mono(ClockTheme.mono),
  sans(ClockTheme.sans),
  serif(ClockTheme.serif);

  const DigitFont(this.family);
  final String family;
}

enum DigitSize {
  small(.56),
  medium(.74),
  large(.91);

  const DigitSize(this.fraction);
  final double fraction;
}

enum ClockHand { hour, minute, second }

enum HandWeight {
  slim(.05),
  regular(.09),
  bold(.14);

  const HandWeight(this.width);
  final double width;
}

enum DialLabels { numbers, quarters, ticks }

int rgb(Color color) => color.toARGB32() & 0xffffff;

extension ClockValues on Map<Object?, Object?> {
  Color colorValue(String key, Color fallback) {
    final value = this[key];
    return value is int && value >= 0 && value <= 0xffffff
        ? Color(0xff000000 | value)
        : fallback;
  }

  T enumValue<T extends Enum>(String key, List<T> values, T fallback) =>
      values.where((value) => value.name == this[key]).firstOrNull ?? fallback;

  int intValue(String key, int min, int max, int fallback) {
    final value = this[key];
    return value is int && value >= min && value <= max ? value : fallback;
  }
}

@immutable
class DigitStyle {
  const DigitStyle({
    this.digits = ClockTheme.digits,
    this.face = ClockTheme.panel,
    this.minuteColor = ClockTheme.sky,
    this.font = DigitFont.mono,
    this.size = DigitSize.large,
    this.bold = false,
    this.padHour = false,
    this.seconds = false,
  });

  final Color digits, face, minuteColor;
  final DigitFont font;
  final DigitSize size;
  final bool bold, padHour, seconds;

  factory DigitStyle.decode(
    Map<Object?, Object?> values,
    String prefix,
  ) => DigitStyle(
    digits: values.colorValue('${prefix}digits', ClockTheme.digits),
    face: values.colorValue('${prefix}face', ClockTheme.panel),
    minuteColor: values.colorValue('${prefix}minutes', ClockTheme.sky),
    font: values.enumValue('${prefix}font', DigitFont.values, DigitFont.mono),
    size: values.enumValue('${prefix}size', DigitSize.values, DigitSize.large),
    bold: values['${prefix}bold'] == true,
    padHour: values['${prefix}padHour'] == true,
    seconds: prefix.isEmpty && values['seconds'] == true,
  );

  Map<String, Object> encode(String prefix) => {
    '${prefix}digits': rgb(digits),
    '${prefix}face': rgb(face),
    '${prefix}font': font.name,
    '${prefix}size': size.name,
    '${prefix}bold': bold,
    '${prefix}padHour': padHour,
    if (prefix.isEmpty)
      'seconds': seconds
    else
      '${prefix}minutes': rgb(minuteColor),
  };

  DigitStyle copyWith({
    Color? digits,
    Color? face,
    Color? minuteColor,
    DigitFont? font,
    DigitSize? size,
    bool? bold,
    bool? padHour,
    bool? seconds,
  }) => DigitStyle(
    digits: digits ?? this.digits,
    face: face ?? this.face,
    minuteColor: minuteColor ?? this.minuteColor,
    font: font ?? this.font,
    size: size ?? this.size,
    bold: bold ?? this.bold,
    padHour: padHour ?? this.padHour,
    seconds: seconds ?? this.seconds,
  );
}

@immutable
class HandStyle {
  const HandStyle(this.color, this.length, this.weight);
  final Color color;
  final int length;
  final HandWeight weight;

  HandStyle copyWith({Color? color, int? length, HandWeight? weight}) =>
      HandStyle(
        color ?? this.color,
        length ?? this.length,
        weight ?? this.weight,
      );

  HandStyle decode(Map<Object?, Object?> values, String name) => HandStyle(
    values.colorValue('$name.color', color),
    values.intValue('$name.length', 35, 95, length),
    values.enumValue('$name.weight', HandWeight.values, weight),
  );
  Map<String, Object> encode(String name) => {
    '$name.color': rgb(color),
    '$name.length': length,
    '$name.weight': weight.name,
  };
}

@immutable
class DialStyle {
  const DialStyle({
    this.face = ClockTheme.panel,
    this.marks = ClockTheme.muted,
    this.labels = DialLabels.quarters,
    this.seconds = false,
    this.hour = const HandStyle(ClockTheme.digits, 55, HandWeight.bold),
    this.minute = const HandStyle(ClockTheme.accent, 80, HandWeight.regular),
    this.second = const HandStyle(ClockTheme.sky, 90, HandWeight.slim),
  });
  final Color face, marks;
  final DialLabels labels;
  final bool seconds;
  final HandStyle hour, minute, second;

  HandStyle hand(ClockHand key) => switch (key) {
    ClockHand.hour => hour,
    ClockHand.minute => minute,
    ClockHand.second => second,
  };
  DialStyle withHand(ClockHand key, HandStyle hand) => switch (key) {
    ClockHand.hour => copyWith(hour: hand),
    ClockHand.minute => copyWith(minute: hand),
    ClockHand.second => copyWith(second: hand),
  };

  factory DialStyle.decode(Map<Object?, Object?> values) {
    const defaults = DialStyle();
    return DialStyle(
      face: values.colorValue('dial.face', defaults.face),
      marks: values.colorValue('dial.marks', defaults.marks),
      labels: values.enumValue(
        'dial.labels',
        DialLabels.values,
        defaults.labels,
      ),
      seconds: values['dial.seconds'] == true,
      hour: defaults.hour.decode(values, 'hour'),
      minute: defaults.minute.decode(values, 'minute'),
      second: defaults.second.decode(values, 'second'),
    );
  }

  Map<String, Object> encode() => {
    'dial.face': rgb(face),
    'dial.marks': rgb(marks),
    'dial.labels': labels.name,
    'dial.seconds': seconds,
    for (final key in ClockHand.values) ...hand(key).encode(key.name),
  };

  DialStyle copyWith({
    Color? face,
    Color? marks,
    DialLabels? labels,
    bool? seconds,
    HandStyle? hour,
    HandStyle? minute,
    HandStyle? second,
  }) => DialStyle(
    face: face ?? this.face,
    marks: marks ?? this.marks,
    labels: labels ?? this.labels,
    seconds: seconds ?? this.seconds,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    second: second ?? this.second,
  );
}
