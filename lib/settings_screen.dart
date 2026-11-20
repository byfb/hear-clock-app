import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_language.dart';
import 'clock_face.dart';
import 'clock_palette.dart';
import 'clock_settings.dart';
import 'clock_theme.dart';
import 'color_screen.dart';
import 'speech_language_screen.dart';
import 'l10n/generated/app_localizations.dart';

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
  var _saveFailed = false;
  AppLocalizations get strings => AppLocalizations.of(context);

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await widget.onSave(_draft);
      if (mounted) Navigator.pop(context);
    } on PlatformException {
      if (mounted) {
        setState(() {
          _saveFailed = true;
          _saving = false;
        });
      }
    }
  }

  ClockHand _hand = ClockHand.hour;

  Widget _color(
    String Function(AppLocalizations) label,
    Color initial,
    ClockSettings Function(Color) change,
  ) => _ColorRow(
    label: label(strings),
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
        (s) => stacked ? s.hourDigitColor : s.digitColor,
        style.digits,
        (c) => _draft.withText(style.copyWith(digits: c)),
      ),
      if (stacked)
        _color(
          (s) => s.minuteDigitColor,
          style.minuteColor,
          (c) => _draft.withText(style.copyWith(minuteColor: c)),
        ),
      const Divider(height: 1),
      _color(
        (s) => s.backgroundColor,
        style.face,
        (c) => _draft.withText(style.copyWith(face: c)),
      ),
      const Divider(height: 1),
      _Choices<DigitSize>(
        label: strings.digitSize,
        values: DigitSize.values,
        selected: style.size,
        name: (v) => strings.digitSizeName(v.name),
        onChange: (v) => _editDigits(style.copyWith(size: v)),
      ),
      _Choices<DigitFont>(
        label: strings.typeface,
        values: DigitFont.values,
        selected: style.font,
        name: (v) => strings.typefaceName(v.name),
        onChange: (v) => _editDigits(style.copyWith(font: v)),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(strings.boldDigits),
        value: style.bold,
        onChanged: (v) => _editDigits(style.copyWith(bold: v)),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(strings.leadingZero),
        value: style.padHour,
        onChanged: (v) => _editDigits(style.copyWith(padHour: v)),
      ),
      if (!stacked)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.showSeconds),
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
    final title = strings.handName(selected.name);
    void update(DialStyle next) =>
        setState(() => _draft = _draft.copyWith(dial: next));
    return [
      _color(
        (s) => s.backgroundColor,
        dial.face,
        (c) => _draft.copyWith(dial: dial.copyWith(face: c)),
      ),
      _color(
        (s) => s.markingColor,
        dial.marks,
        (c) => _draft.copyWith(dial: dial.copyWith(marks: c)),
      ),
      _Choices<DialLabels>(
        label: strings.dialMarkings,
        values: DialLabels.values,
        selected: dial.labels,
        name: (v) => strings.markingsName(v.name),
        onChange: (v) => update(dial.copyWith(labels: v)),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(strings.showSecondHand),
        value: dial.seconds,
        onChanged: (v) => update(dial.copyWith(seconds: v)),
      ),
      const Divider(height: 1),
      _Choices<ClockHand>(
        label: strings.customizeHand,
        values: [
          ClockHand.hour,
          ClockHand.minute,
          if (dial.seconds) ClockHand.second,
        ],
        selected: selected,
        name: (v) => strings.handName(v.name),
        onChange: (v) => setState(() => _hand = v),
      ),
      _color(
        (s) => s.handColor(s.handName(selected.name)),
        hand.color,
        (c) => _draft.copyWith(
          dial: dial.withHand(selected, hand.copyWith(color: c)),
        ),
      ),
      _PercentageSlider(
        label: strings.handLength(title),
        value: hand.length,
        min: 35,
        max: 95,
        divisions: 12,
        onChanged: (v) =>
            update(dial.withHand(selected, hand.copyWith(length: v))),
      ),
      _Choices<HandWeight>(
        label: strings.handThickness(title),
        values: HandWeight.values,
        selected: hand.weight,
        name: (v) => strings.weightName(v.name),
        onChange: (v) =>
            update(dial.withHand(selected, hand.copyWith(weight: v))),
      ),
    ];
  }

  Future<void> _pickAppLanguage() async {
    final preference = AppLanguageScope.of(context);
    final choice = await showDialog<AppLanguage>(
      context: context,
      builder: (context) {
        final strings = AppLocalizations.of(context);
        return SimpleDialog(
          title: Text(strings.appLanguage),
          children: [
            for (final language in AppLanguage.values)
              ListTile(
                title: Semantics(
                  localeForSubtree: language.locale,
                  child: Text(language.label(strings)),
                ),
                selected: language == preference.selected,
                trailing: language == preference.selected
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, language),
              ),
          ],
        );
      },
    );
    if (!mounted || choice == null || choice == preference.selected) return;
    try {
      await preference.change(choice);
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(strings.languageError)));
      }
    }
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

  Future<void> _pickPalette() async {
    final selected = await Navigator.push<ClockPalette>(
      context,
      MaterialPageRoute(
        builder: (_) => ColorCombinationsScreen(settings: _draft),
      ),
    );
    if (mounted && selected != null) {
      setState(() => _draft = selected.apply(_draft));
    }
  }

  Widget _appearance() => ListView(
    key: const PageStorageKey('appearance'),
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    children: [
      ClockFace(compact: true, settings: _draft, platform: widget.platform),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.language),
        title: Text(strings.appLanguage),
        subtitle: Text(AppLanguageScope.of(context).selected.label(strings)),
        trailing: const Icon(Icons.chevron_right),
        onTap: _pickAppLanguage,
      ),
      _Choices<FaceVariant>(
        label: strings.clockFace,
        values: FaceVariant.values,
        selected: _draft.variant,
        name: (v) => strings.faceName(v.name),
        onChange: (v) => setState(() => _draft = _draft.copyWith(variant: v)),
      ),
      const SizedBox(height: 12),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.contrast),
        title: Text(strings.colorCombinations),
        subtitle: Text(switch (ClockPalette.current(_draft)) {
          final palette? => strings.paletteName(palette.name),
          null => strings.customColors,
        }),
        trailing: const Icon(Icons.chevron_right),
        onTap: _pickPalette,
      ),
      const Divider(height: 1),
      ContrastNote(_draft),
      if (_draft.variant == FaceVariant.analog)
        ..._dialControls()
      else
        ..._digitControls(),
      const Divider(height: 1),
      _Choices<ClockFormat>(
        label: strings.timeFormat,
        values: ClockFormat.values,
        selected: _draft.format,
        name: (v) => strings.formatName(v.name),
        onChange: (v) => setState(() => _draft = _draft.copyWith(format: v)),
      ),
      const Divider(height: 24),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(
          onPressed: () => setState(() => _draft = const ClockSettings()),
          child: Text(strings.restoreDefaults),
        ),
      ),
    ],
  );

  Future<void> _testVoice() async {
    try {
      await widget.platform.speak(_draft);
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? strings.speechError)),
      );
    }
  }

  Widget _voice() => ListView(
    key: const PageStorageKey('voice'),
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(strings.speakOnTap),
        value: _draft.speakOnTap,
        onChanged: (enabled) =>
            setState(() => _draft = _draft.copyWith(speakOnTap: enabled)),
      ),
      if (_draft.speakOnTap) ...[
        ListTile(
          title: Text(strings.speechLanguage),
          subtitle: Text(_draft.language.displayName(strings)),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          trailing: const Icon(Icons.chevron_right),
          onTap: _pickLanguage,
        ),
        const Divider(height: 1),
        const SizedBox(height: 24),
        _PercentageSlider(
          label: strings.speechSpeed,
          value: _draft.speechRate,
          min: 50,
          max: 200,
          divisions: 6,
          onChanged: (v) =>
              setState(() => _draft = _draft.copyWith(speechRate: v)),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.volume_up_outlined),
            label: Text(strings.testVoice),
            onPressed: _testVoice,
          ),
        ),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) {
    final tabHeight = (MediaQuery.textScalerOf(context).scale(16) * 1.6 + 14)
        .clamp(50.0, double.infinity);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: ClockTheme.settingsBar(
          context,
          strings.clockSettings,
          bottom: TabBar(
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
            tabs: [
              Tab(height: tabHeight, text: strings.appearance),
              Tab(height: tabHeight, text: strings.voice),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: TabBarView(children: [_appearance(), _voice()]),
            ),
          ),
        ),
        bottomNavigationBar: _SaveBar(
          label: _saving ? strings.saving : strings.saveSettings,
          onTap: _saving ? null : _save,
          error: _saveFailed ? strings.saveError : null,
        ),
      ),
    );
  }
}

class _PercentageSlider extends StatelessWidget {
  const _PercentageSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });
  final String label;
  final int value, min, max, divisions;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Text(
              AppLocalizations.of(context).sliderValue(label, value),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Slider(
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions,
            value: value.toDouble(),
            semanticFormatterCallback: (v) =>
                AppLocalizations.of(context).spokenPercent(v.round()),
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
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
      subtitle: Text(colorName(color, AppLocalizations.of(context))),
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
                selectedColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                shape: ClockTheme.shape,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                labelStyle: TextStyle(
                  fontSize: 16,
                  color: selected == v
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
