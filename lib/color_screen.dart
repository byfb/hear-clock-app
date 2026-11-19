import 'package:flutter/material.dart';

import 'clock_face.dart';
import 'clock_palette.dart';
import 'clock_settings.dart';
import 'clock_theme.dart';

class ColorSwatchMark extends StatelessWidget {
  const ColorSwatchMark(this.color, {super.key});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 26,
    height: 26,
    decoration: BoxDecoration(
      color: color,
      borderRadius: ClockTheme.corner,
      border: Border.all(color: Theme.of(context).colorScheme.outline),
    ),
  );
}

class ContrastNote extends StatelessWidget {
  const ContrastNote(this.settings, {super.key});
  final ClockSettings settings;

  @override
  Widget build(BuildContext context) {
    final pair = settings.lowestContrast;
    if (pair.ratio >= 4.5) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'Low contrast between the ${pair.part} and the background.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class ColorCombinationsScreen extends StatelessWidget {
  const ColorCombinationsScreen({super.key, required this.settings});
  final ClockSettings settings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ClockTheme.settingsBar(context, 'Color combinations'),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                for (final palette in ClockPalette.values) ...[
                  Semantics(
                    button: true,
                    selected: palette.matches(settings),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 10,
                      ),
                      leading: ExcludeSemantics(
                        child: Container(
                          width: 56,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.background,
                            border: Border.all(color: scheme.outline),
                            borderRadius: ClockTheme.corner,
                          ),
                          child: Text(
                            '12',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: palette.ink,
                              fontFamily: ClockTheme.mono,
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        palette.label,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: palette.matches(settings)
                          ? Icon(Icons.check, color: scheme.primary)
                          : null,
                      onTap: () => Navigator.pop(context, palette),
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ColorScreen extends StatefulWidget {
  const ColorScreen({
    super.key,
    required this.title,
    required this.initial,
    required this.preview,
    required this.platform,
  });
  final String title;
  final Color initial;
  final ClockSettings Function(Color) preview;
  final ClockPlatform platform;

  @override
  State<ColorScreen> createState() => _ColorScreenState();
}

class _ColorScreenState extends State<ColorScreen> {
  static final _hex = RegExp(r'^#?([0-9a-fA-F]{6})$');
  late Color _picked = widget.initial;
  late final _input = TextEditingController(text: hexColor(_picked));
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Color? _parse(String value) {
    final digits = _hex.firstMatch(value.trim())?.group(1);
    return digits == null
        ? null
        : Color(0xff000000 | int.parse(digits, radix: 16));
  }

  void _choose(Color color) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _picked = color;
      _input.text = hexColor(color);
      _error = null;
    });
  }

  void _apply() {
    final chosen = _parse(_input.text);
    if (chosen == null) {
      setState(() => _error = 'Enter six hex digits, such as FFD459.');
    } else {
      Navigator.pop(context, chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview(_picked);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ClockTheme.settingsBar(context, widget.title),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              children: [
                ClockFace(
                  compact: true,
                  settings: preview,
                  platform: widget.platform,
                ),
                ContrastNote(preview),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final color in namedColors.entries)
                      ChoiceChip(
                        avatar: ColorSwatchMark(color.key),
                        label: Text(color.value),
                        selected: color.key == _picked,
                        showCheckmark: true,
                        shape: ClockTheme.shape,
                        selectedColor: scheme.primary,
                        backgroundColor: scheme.surface,
                        checkmarkColor: scheme.onPrimary,
                        labelStyle: TextStyle(
                          fontSize: 16,
                          color: color.key == _picked
                              ? scheme.onPrimary
                              : scheme.onSurface,
                        ),
                        onSelected: (_) => _choose(color.key),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _input,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _apply(),
                  decoration: InputDecoration(
                    labelText: 'Custom hex color',
                    hintText: 'FFD459',
                    errorText: _error,
                  ),
                  onChanged: (value) {
                    final next = _parse(value);
                    setState(() {
                      if (next != null) _picked = next;
                      _error = null;
                    });
                  },
                ),
                const SizedBox(height: 18),
                FilledButton(onPressed: _apply, child: const Text('Use color')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
