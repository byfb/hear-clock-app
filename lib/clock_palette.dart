import 'package:flutter/material.dart';

import 'clock_settings.dart';
import 'clock_theme.dart';

enum ClockPalette {
  original('Original colors', ClockTheme.digits, ClockTheme.panel),
  whiteOnBlack('White on black', ClockTheme.white, ClockTheme.black),
  blackOnWhite('Black on white', ClockTheme.black, ClockTheme.white),
  yellowOnBlack('Yellow on black', ClockTheme.yellow, ClockTheme.black);

  const ClockPalette(this.label, this.ink, this.background);
  final String label;
  final Color ink, background;

  Color get _stackMinutes => this == original ? ClockTheme.sky : ink;
  Color get _markings => this == original ? ClockTheme.muted : ink;
  Color get _minuteHand => this == original ? ClockTheme.accent : ink;
  Color get _secondHand => this == original ? ClockTheme.sky : ink;

  ClockSettings apply(ClockSettings settings) {
    if (settings.variant != FaceVariant.analog) {
      return settings.withText(
        settings.text.copyWith(
          digits: ink,
          face: background,
          minuteColor: settings.variant == FaceVariant.stacked
              ? _stackMinutes
              : null,
        ),
      );
    }
    final dial = settings.dial;
    return settings.copyWith(
      dial: dial.copyWith(
        face: background,
        marks: _markings,
        hour: dial.hour.copyWith(color: ink),
        minute: dial.minute.copyWith(color: _minuteHand),
        second: dial.second.copyWith(color: _secondHand),
      ),
    );
  }

  bool matches(ClockSettings s) =>
      s.face == background &&
      switch (s.variant) {
        FaceVariant.digital => s.digital.digits == ink,
        FaceVariant.stacked =>
          s.stacked.digits == ink && s.stacked.minuteColor == _stackMinutes,
        FaceVariant.analog =>
          s.dial.marks == _markings &&
              s.dial.hour.color == ink &&
              s.dial.minute.color == _minuteHand &&
              s.dial.second.color == _secondHand,
      };

  static ClockPalette? current(ClockSettings settings) =>
      values.where((palette) => palette.matches(settings)).firstOrNull;
}
