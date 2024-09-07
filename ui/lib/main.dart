import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:he_is_coming/he_is_coming.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:ui/src/battle.dart';
import 'package:ui/src/compendium.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runScoped(() => runApp(const MyApp()), values: {loggerRef});
}

/// MyApp widget
class MyApp extends StatelessWidget {
  /// MyApp constructor
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'He is Coming',
      theme: flutterNesTheme(brightness: Brightness.dark),
      home: const HomePage(),
    );
  }
}

/// MyHomePage widget
class HomePage extends StatefulWidget {
  /// MyHomePage constructor
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _SteamLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        launchUrl(
          Uri.parse(
            'https://store.steampowered.com/app/2824490/He_is_coming/',
          ),
        );
      },
      child: Center(
        child: Image.asset(
          'assets/steam_logo.png',
          width: 24,
          height: 24,
        ),
      ),
    );
  }
}

class _MyHomePageState extends State<HomePage> {
  bool isLoading = true;
  late final Data data;

  @override
  void initState() {
    super.initState();
    isLoading = true;
    loadData().then((value) {
      setState(() {
        data = value.withoutEntriesMissingEffects();
        // TODO(eseidel): Remove defaultPlayerWeapon.
        Creature.defaultPlayerWeapon = data.items['Wooden Stick'];
        isLoading = false;
      });
    });
  }

  Future<Data> loadData() async {
    Future<String> load(String name) {
      return rootBundle.loadString('packages/he_is_coming/data/$name.yaml');
    }

    return Data.fromStrings(
      creatures: load('creatures'),
      edges: load('edges'),
      items: load('items'),
      oils: load('blade_oils'),
      challenges: load('challenges'),
      triggers: load('triggers'),
      sets: load('sets'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('He is Coming'),
          leading: _SteamLink(),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Compendium'),
              Tab(text: 'Battle'),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: <Widget>[
                  CompendiumPage(data),
                  BattlePage(data: data),
                ],
              ),
      ),
    );
  }
}
