import 'package:flutter/widgets.dart';

import 'l10n/generated/app_localizations.dart';

enum AppLanguage {
  system('', null, ''),
  english('en', Locale('en'), 'English'),
  simplified('zh-Hans', Locale('zh'), '简体中文'),
  traditional(
    'zh-Hant',
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    '繁體中文',
  );

  const AppLanguage(this.tag, this.locale, this.nativeName);
  final String tag, nativeName;
  final Locale? locale;

  String label(AppLocalizations strings) =>
      this == system ? strings.systemLanguage : nativeName;

  static AppLanguage fromTag(String? tag) {
    if (tag == null || tag.isEmpty) return system;
    final parts = tag.toLowerCase().split('-');
    if (parts.first == 'en') return english;
    if (parts.first != 'zh') return system;
    if (parts.contains('hant')) return traditional;
    if (parts.contains('hans')) return simplified;
    return parts.any(const {'tw', 'hk', 'mo'}.contains)
        ? traditional
        : simplified;
  }
}

Locale resolveAppLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  for (final locale in preferred ?? const <Locale>[]) {
    final match = AppLanguage.fromTag(locale.toLanguageTag()).locale;
    if (match != null && supported.contains(match)) return match;
  }
  return const Locale('en');
}

class AppLanguageScope extends InheritedWidget {
  const AppLanguageScope({
    super.key,
    required this.selected,
    required this.change,
    required super.child,
  });

  final AppLanguage selected;
  final Future<void> Function(AppLanguage) change;

  static AppLanguageScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLanguageScope>()!;

  @override
  bool updateShouldNotify(AppLanguageScope oldWidget) =>
      selected != oldWidget.selected;
}
