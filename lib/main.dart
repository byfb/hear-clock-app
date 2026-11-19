import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'clock_face.dart';
import 'clock_settings.dart';
import 'clock_theme.dart';
import 'settings_screen.dart';

void main() => runApp(const HearClockApp());

class HearClockApp extends StatelessWidget {
  const HearClockApp({super.key, this.platform = const ClockPlatform()});
  final ClockPlatform platform;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Hear Clock',
    debugShowCheckedModeBanner: false,
    theme: ClockTheme.data(Brightness.light),
    darkTheme: ClockTheme.data(Brightness.dark),
    themeMode: ThemeMode.system,
    builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: ClockTheme.systemBars(Theme.of(context).brightness),
      child: child!,
    ),
    home: _Home(platform: platform),
  );
}

class _Home extends StatefulWidget {
  const _Home({required this.platform});
  final ClockPlatform platform;
  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  ClockSettings? _settings;
  var _loadFailed = false;
  var _pinning = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final value = await widget.platform.load();
      if (mounted) setState(() => _settings = value);
    } on PlatformException {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsScreen(
          initial: _settings!,
          platform: widget.platform,
          onSave: (value) async {
            await widget.platform.save(value);
            if (mounted) setState(() => _settings = value);
          },
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
        title: const Text('Add the widget'),
        content: const Text(
          'Touch and hold an empty spot on your home screen. Open Widgets, then drag Hear Clock onto the screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
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
                        title: const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text('${settings.variant.label} clock'),
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
                        title: const Text(
                          'Add widget',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Touch and hold the widget to resize it.',
                        ),
                        trailing: const Icon(Icons.add),
                        onTap: _pinning ? null : _addWidget,
                      ),
                      const Divider(height: 1),
                    ] else if (_loadFailed) ...[
                      const Text('Couldn’t load clock settings.'),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Try again'),
                      ),
                    ] else
                      const Center(
                        child: CircularProgressIndicator(
                          semanticsLabel: 'Loading clock',
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
