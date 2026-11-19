import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'clock_face.dart';
import 'clock_settings.dart';
import 'clock_theme.dart';
import 'color_screen.dart';
import 'speech_language_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.initial,
    required this.platform,
    required this.onSave,
  });
  final ClockSettings initial;
  final ClockPlatform platform;
  final Future<void> Function(ClockSettings) onSave;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ClockSettings _draft = widget.initial;
  var _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_draft);
      if (mounted) Navigator.pop(context);
    } on PlatformException {
      if (mounted) {
        setState(() {
          _error = 'Couldn’t save these settings. Try again.';
          _saving = false;
        });
      }
    }
  }

  ClockHand _hand = ClockHand.hour;

  Widget _color(
    String label,
    Color initial,
    ClockSettings Function(Color) change,
  ) => _ColorRow(
    label: label,
    color: initial,
    onTap: () async {
      final color = await Navigator.push<Color>(
        context,
        MaterialPageRoute(
          builder: (_) => ColorScreen(
            title: label,
            initial: initial,
            preview: change,
            platform: widget.platform,
          ),
        ),
      );
      if (mounted && color != null) setState(() => _draft = change(color));
    },
  );

  void _editDigits(DigitStyle style) =>
      setState(() => _draft = _draft.withText(style));

  List<Widget> _digitControls() {
    final style = _draft.text;
    final stacked = _draft.variant == FaceVariant.stacked;
    return [
      _color(
        stacked ? 'Hour digit color' : 'Digit color',
        style.digits,
        (c) => _draft.withText(style.copyWith(digits: c)),
      ),
      if (stacked)
        _color(
          'Minute digit color',
          style.minuteColor,
          (c) => _draft.withText(style.copyWith(minuteColor: c)),
        ),
      const Divider(height: 1),
      _color(
        'Background color',
        style.face,
        (c) => _draft.withText(style.copyWith(face: c)),
      ),
      const Divider(height: 1),
      _Choices<DigitSize>(
        label: 'Digit size',
        values: DigitSize.values,
        selected: style.size,
        name: (v) => v.label,
        onChange: (v) => _editDigits(style.copyWith(size: v)),
      ),
      _Choices<DigitFont>(
        label: 'Typeface',
        values: DigitFont.values,
        selected: style.font,
        name: (v) => v.label,
        onChange: (v) => _editDigits(style.copyWith(font: v)),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Bold digits'),
        value: style.bold,
        onChanged: (v) => _editDigits(style.copyWith(bold: v)),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Leading zero in 12-hour time'),
        value: style.padHour,
        onChanged: (v) => _editDigits(style.copyWith(padHour: v)),
      ),
      if (!stacked)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show seconds'),
          value: style.seconds,
          onChanged: (v) => _editDigits(style.copyWith(seconds: v)),
        ),
    ];
  }

  List<Widget> _dialControls() {
    final dial = _draft.dial;
    final selected = !dial.seconds && _hand == ClockHand.second
        ? ClockHand.hour
        : _hand;
    final hand = dial.hand(selected);
    final title = selected.label;
    void update(DialStyle next) =>
        setState(() => _draft = _draft.copyWith(dial: next));
    return [
      _color(
        'Background color',
        dial.face,
        (c) => _draft.copyWith(dial: dial.copyWith(face: c)),
      ),
      _color(
        'Marking color',
        dial.marks,
        (c) => _draft.copyWith(dial: dial.copyWith(marks: c)),
      ),
      _Choices<DialLabels>(
        label: 'Dial markings',
        values: DialLabels.values,
        selected: dial.labels,
        name: (v) => v.label,
        onChange: (v) => update(dial.copyWith(labels: v)),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Show second hand'),
        value: dial.seconds,
        onChanged: (v) => update(dial.copyWith(seconds: v)),
      ),
      const Divider(height: 1),
      _Choices<ClockHand>(
        label: 'Customize a hand',
        values: [
          ClockHand.hour,
          ClockHand.minute,
          if (dial.seconds) ClockHand.second,
        ],
        selected: selected,
        name: (v) => v.label,
        onChange: (v) => setState(() => _hand = v),
      ),
      _color(
        '$title color',
        hand.color,
        (c) => _draft.copyWith(
          dial: dial.withHand(selected, hand.copyWith(color: c)),
        ),
      ),
      Text(
        '$title length, ${hand.length}%',
        style: const TextStyle(fontSize: 18),
      ),
      Semantics(
        label: '$title length',
        child: Slider(
          min: 35,
          max: 95,
          divisions: 12,
          value: hand.length.toDouble(),
          semanticFormatterCallback: (v) => '${v.round()} percent',
          onChanged: (v) =>
              update(dial.withHand(selected, hand.copyWith(length: v.round()))),
        ),
      ),
      _Choices<HandWeight>(
        label: '$title thickness',
        values: HandWeight.values,
        selected: hand.weight,
        name: (v) => v.label,
        onChange: (v) =>
            update(dial.withHand(selected, hand.copyWith(weight: v))),
      ),
    ];
  }

  Future<void> _pickLanguage() async {
    final language = await Navigator.push<SpeechLanguage>(
      context,
      MaterialPageRoute(
        builder: (_) => SpeechLanguageScreen(
          platform: widget.platform,
          selected: _draft.language,
        ),
      ),
    );
    if (mounted && language != null) {
      setState(() => _draft = _draft.copyWith(language: language));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ClockTheme.settingsBar(context, 'Clock settings'),
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
                settings: _draft,
                platform: widget.platform,
              ),
              _Choices<FaceVariant>(
                label: 'Clock face',
                values: FaceVariant.values,
                selected: _draft.variant,
                name: (v) => v.label,
                onChange: (v) =>
                    setState(() => _draft = _draft.copyWith(variant: v)),
              ),
              const SizedBox(height: 12),
              if (_draft.contrast < 4.5)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Semantics(
                    liveRegion: true,
                    child: const Text(
                      'Low contrast. Pick one light color and one dark color for easier reading.',
                      style: TextStyle(color: ClockTheme.error, fontSize: 16),
                    ),
                  ),
                ),
              if (_draft.variant == FaceVariant.analog)
                ..._dialControls()
              else
                ..._digitControls(),
              const Divider(height: 1),
              _Choices<ClockFormat>(
                label: 'Time format',
                values: ClockFormat.values,
                selected: _draft.format,
                name: (v) => v.label,
                onChange: (v) =>
                    setState(() => _draft = _draft.copyWith(format: v)),
              ),
              const Divider(height: 24),
              ListTile(
                title: const Text('Speech language'),
                subtitle: Text(_draft.language.label),
                contentPadding: EdgeInsets.zero,
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickLanguage,
              ),
              Text(
                'Speech speed, ${_draft.speechRate}%',
                style: const TextStyle(fontSize: 18),
              ),
              Semantics(
                label: 'Speech speed',
                child: Slider(
                  min: 50,
                  max: 200,
                  divisions: 6,
                  value: _draft.speechRate.toDouble(),
                  semanticFormatterCallback: (v) => '${v.round()} percent',
                  onChanged: (v) => setState(
                    () => _draft = _draft.copyWith(speechRate: v.round()),
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  icon: const Icon(Icons.volume_up_outlined),
                  label: const Text('Test voice'),
                  onPressed: () async {
                    try {
                      await widget.platform.speak(_draft);
                    } on PlatformException catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.message ??
                                  'Check your Android text-to-speech voice.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () =>
                      setState(() => _draft = const ClockSettings()),
                  child: const Text('Restore defaults'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: _SaveBar(
      label: _saving ? 'Saving…' : 'Save settings',
      onTap: _saving ? null : _save,
      error: _error,
    ),
  );
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      leading: ColorSwatchMark(color),
      title: Text(label),
      subtitle: Text(colorName(color)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.label,
    required this.values,
    required this.selected,
    required this.name,
    required this.onChange,
  });
  final String label;
  final List<T> values;
  final T selected;
  final String Function(T) name;
  final ValueChanged<T> onChange;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final v in values)
              ChoiceChip(
                selected: selected == v,
                label: Text(name(v)),
                onSelected: (_) => onChange(v),
                selectedColor: ClockTheme.accent,
                backgroundColor: ClockTheme.panel,
                checkmarkColor: ClockTheme.onAccent,
                shape: ClockTheme.shape,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                labelStyle: TextStyle(
                  fontSize: 16,
                  color: selected == v ? ClockTheme.onAccent : ClockTheme.ink,
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.label, required this.onTap, this.error});
  final String label;
  final VoidCallback? onTap;
  final String? error;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    error!,
                    style: const TextStyle(color: ClockTheme.error),
                  ),
                ),
              FilledButton(onPressed: onTap, child: Text(label)),
            ],
          ),
        ),
      ),
    ),
  );
}
