import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_language.dart';
import 'clock_face.dart';
import 'clock_settings.dart';
import 'clock_theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'settings_screen.dart';

void main() => runApp(const HearClockApp());

class HearClockApp extends StatefulWidget {
  const HearClockApp({super.key, this.platform = const ClockPlatform()});
  final ClockPlatform platform;

  @override
  State<HearClockApp> createState() => _HearClockAppState();
}

class _HearClockAppState extends State<HearClockApp>
    with WidgetsBindingObserver {
  var _language = AppLanguage.system;
  bool? _device24;
  var _read = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.platform.onTimeFormatChanged((value) {
      if (mounted && _device24 != value) setState(() => _device24 = value);
    });
    _reloadPreferences();
  }

  Future<void> _reloadPreferences() async {
    final read = ++_read;
    try {
      final value = await widget.platform.displayPreferences();
      if (mounted &&
          read == _read &&
          (value.language != _language || value.device24 != _device24)) {
        setState(() {
          _language = value.language;
          _device24 = value.device24;
        });
      }
    } on PlatformException {
      // Android's locale is already available to Flutter during startup.
    }
  }

  Future<void> _changeLanguage(AppLanguage language) async {
    ++_read;
    await widget.platform.setAppLanguage(language);
    if (mounted) {
      ++_read;
      setState(() => _language = language);
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) => _reloadPreferences();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reloadPreferences();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.platform.onTimeFormatChanged(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Hear Clock',
    locale: _language.locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    localeListResolutionCallback: resolveAppLocale,
    debugShowCheckedModeBanner: false,
    theme: ClockTheme.data(Brightness.light),
    darkTheme: ClockTheme.data(Brightness.dark),
    themeMode: ThemeMode.system,
    builder: (context, child) => AppLanguageScope(
      selected: _language,
      change: _changeLanguage,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: _device24),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: ClockTheme.systemBars(Theme.of(context).brightness),
          child: Semantics(localeForSubtree: _language.locale, child: child),
        ),
      ),
    ),
    home: _Home(platform: widget.platform),
  );
}

class _Home extends StatefulWidget {
  const _Home({required this.platform});
  final ClockPlatform platform;
  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  final _settings = ValueNotifier<ClockSettings?>(null);
  late ClockSettings _lastSaved;
  Future<void> _saving = Future<void>.value();
  var _loadFailed = false;
  var _pinning = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final value = await widget.platform.load();
      if (mounted) {
        _lastSaved = value;
        _settings.value = value;
      }
    } on PlatformException {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  void _changeSettings(ClockSettings value) {
    _settings.value = value;
    _saving = _saving.then((_) => _saveIfCurrent(value));
  }

  Future<void> _saveIfCurrent(ClockSettings value) async {
    // Each write contains all settings. A newer selection covers queued edits.
    if (!mounted || _settings.value != value) return;
    try {
      await widget.platform.save(value);
      _lastSaved = value;
    } on PlatformException {
      if (!mounted || _settings.value != value) return;
      _settings.value = _lastSaved;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saveError)),
      );
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ValueListenableBuilder(
          valueListenable: _settings,
          builder: (context, settings, _) => SettingsScreen(
            settings: settings!,
            platform: widget.platform,
            onChanged: _changeSettings,
          ),
        ),
      ),
    );
  }

  Future<void> _addWidget() async {
    if (_pinning) return;
    setState(() => _pinning = true);
    var requested = false;
    try {
      requested = await widget.platform.pinWidget();
    } on PlatformException {
      // Some launchers only support adding widgets from their widget picker.
    } finally {
      if (mounted) setState(() => _pinning = false);
    }
    if (requested || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: ClockTheme.shape,
        title: Text(AppLocalizations.of(context).addWidgetTitle),
        content: Text(AppLocalizations.of(context).placeWidget),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).done),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder(valueListenable: _settings, builder: _buildHome);

  Widget _buildHome(BuildContext context, ClockSettings? settings, Widget? _) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: LayoutBuilder(
              builder: (context, bounds) {
                final gutter = bounds.maxWidth > 600 ? 36.0 : 20.0;
                final compact = bounds.maxHeight < 480;
                final colors = Theme.of(context).colorScheme;
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    compact ? 8 : 24,
                    gutter,
                    24,
                  ),
                  children: [
                    Semantics(
                      header: true,
                      child: const Row(
                        children: [
                          ClockMark(),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Hear Clock',
                              style: TextStyle(
                                fontSize: 29,
                                height: 1.15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 24),
                    if (settings != null) ...[
                      ClockFace(settings: settings, platform: widget.platform),
                      SizedBox(height: compact ? 16 : 28),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                        leading: Icon(Icons.tune, color: colors.primary),
                        title: Text(
                          strings.settings,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          strings.faceDescription(settings.variant.name),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _openSettings,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                        leading: Icon(
                          Icons.widgets_outlined,
                          color: colors.primary,
                        ),
                        title: Text(
                          strings.addWidget,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(strings.resizeWidget),
                        trailing: const Icon(Icons.add),
                        onTap: _pinning ? null : _addWidget,
                      ),
                      const Divider(height: 1),
                    ] else if (_loadFailed) ...[
                      Text(strings.loadError),
                      TextButton(onPressed: _load, child: Text(strings.retry)),
                    ] else
                      Center(
                        child: CircularProgressIndicator(
                          semanticsLabel: strings.loadingClock,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
