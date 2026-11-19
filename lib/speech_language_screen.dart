import 'package:flutter/material.dart';

import 'clock_settings.dart';
import 'clock_theme.dart';
import 'l10n/generated/app_localizations.dart';

class SpeechLanguageScreen extends StatefulWidget {
  const SpeechLanguageScreen({
    super.key,
    required this.platform,
    required this.selected,
  });
  final ClockPlatform platform;
  final SpeechLanguage selected;

  @override
  State<SpeechLanguageScreen> createState() => _SpeechLanguageScreenState();
}

class _SpeechLanguageScreenState extends State<SpeechLanguageScreen> {
  late Future<List<SpeechLanguage>> _languages = widget.platform.languages();
  String _query = '';
  AppLocalizations get strings => AppLocalizations.of(context);

  Widget _row(SpeechLanguage language) => ListTile(
    title: Text(language.displayName(strings)),
    selected: widget.selected.tag == language.tag,
    trailing: widget.selected.tag == language.tag
        ? const Icon(Icons.check)
        : null,
    onTap: () => Navigator.pop(context, language),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ClockTheme.settingsBar(context, strings.speechLanguage),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: FutureBuilder<List<SpeechLanguage>>(
            future: _languages,
            builder: (context, snapshot) {
              final languages = snapshot.data ?? [];
              final matches = languages
                  .where(
                    (l) =>
                        l.label.toLowerCase().contains(_query) ||
                        l.tag.toLowerCase().contains(_query),
                  )
                  .toList();
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  if (languages.length > 5)
                    TextField(
                      decoration: InputDecoration(
                        labelText: strings.findLanguage,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) =>
                          setState(() => _query = value.trim().toLowerCase()),
                    ),
                  _row(SpeechLanguage.device),
                  if (snapshot.connectionState != ConnectionState.done)
                    LinearProgressIndicator(
                      semanticsLabel: strings.loadingLanguages,
                    )
                  else if (snapshot.hasError || languages.isEmpty) ...[
                    Text(strings.checkVoices),
                    TextButton(
                      onPressed: () => setState(
                        () => _languages = widget.platform.languages(),
                      ),
                      child: Text(strings.retry),
                    ),
                  ] else if (matches.isEmpty)
                    Text(strings.noLanguages)
                  else
                    ...matches.map(_row),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
