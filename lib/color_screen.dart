import 'package:flutter/material.dart';

import 'clock_face.dart';
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
