import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

void main() => runApp(const OdynApp());

class OdynApp extends StatefulWidget {
  const OdynApp({super.key});
  @override
  State<OdynApp> createState() => _OdynAppState();
}

class _OdynAppState extends State<OdynApp> {
  Locale? selectedLocale;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    onGenerateTitle: (context) => AppLocalizations.of(context).title,
    locale: selectedLocale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: Builder(builder: (context) => OdynHome(
      locale: selectedLocale,
      onLocaleChanged: (value) => setState(() => selectedLocale = value),
    )),
  );
}

class OdynHome extends StatefulWidget {
  const OdynHome({super.key, required this.locale, required this.onLocaleChanged});
  final Locale? locale;
  final ValueChanged<Locale?> onLocaleChanged;
  @override
  State<OdynHome> createState() => _OdynHomeState();
}

class _OdynHomeState extends State<OdynHome> {
  int selectedTab = 0;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final labels = [t.image, t.video, t.models, t.settings];
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: selectedTab == 3
        ? ListView(children: [
            ListTile(title: Text(t.language)),
            DropdownButton<Locale?>(
              value: widget.locale,
              items: [
                DropdownMenuItem<Locale?>(value: null, child: Text(t.systemLanguage)),
                ...AppLocalizations.supportedLocales.map((locale) =>
                  DropdownMenuItem<Locale?>(value: locale, child: Text(locale.languageCode.toUpperCase()))),
              ],
              onChanged: widget.onLocaleChanged,
            ),
          ])
        : Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(labels[selectedTab], style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Text(t.notReady, textAlign: TextAlign.center),
          ])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) => setState(() => selectedTab = index),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.image_outlined), label: t.image),
          NavigationDestination(icon: const Icon(Icons.movie_outlined), label: t.video),
          NavigationDestination(icon: const Icon(Icons.folder_outlined), label: t.models),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: t.settings),
        ],
      ),
    );
  }
}
