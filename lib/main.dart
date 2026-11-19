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
    theme: ClockTheme.data,
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
                final shortLandscape =
                    bounds.maxHeight < 480 &&
                    bounds.maxWidth > bounds.maxHeight;
                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 14),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runSpacing: 6,
                          spacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClockMark(),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Hear Clock',
                                    style: TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
                              onPressed: settings == null
                                  ? null
                                  : _openSettings,
                              icon: const Icon(Icons.tune, size: 20),
                              label: const Text('Settings'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        SizedBox(
                          height: shortLandscape
                              ? 12
                              : (bounds.maxHeight * .065).clamp(24.0, 54.0),
                        ),
                        if (settings != null) ...[
                          if (!shortLandscape) ...[
                            Semantics(
                              header: true,
                              child: const Text(
                                'Local time',
                                style: TextStyle(
                                  fontSize: 34,
                                  height: 1.18,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                          ClockFace(
                            settings: settings,
                            platform: widget.platform,
                          ),
                          const SizedBox(height: 36),
                          const Divider(height: 1),
                          const SizedBox(height: 22),
                          Semantics(
                            header: true,
                            child: const Text(
                              'Home screen widget',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Touch and hold the widget to resize it.',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.45,
                              color: ClockTheme.muted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: OutlinedButton.icon(
                              onPressed: _pinning ? null : _addWidget,
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text('Add widget'),
                            ),
                          ),
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
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
