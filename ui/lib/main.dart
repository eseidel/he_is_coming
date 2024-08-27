import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:he_is_coming/he_is_coming.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:ui/src/compendium.dart';
import 'package:ui/src/scrolling_grid.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runScoped(
    () {
      runApp(const MyApp());
    },
    values: {loggerRef},
  );
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

class _MyHomePageState extends State<HomePage> {
  bool isLoading = true;
  late final Data data;

  @override
  void initState() {
    super.initState();
    isLoading = true;
    loadData().then((value) {
      setState(() {
        data = value;
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
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('He is Coming'),
          leading: GestureDetector(
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
          ),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Items'),
              Tab(text: 'Creatures'),
              Tab(text: 'Edges'),
              Tab(text: 'Oils'),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: <Widget>[
                  FilteredItems(
                    items: data.items.items,
                  ),
                  FilteredCreatures(
                    creatures: data.creatures.creatures,
                  ),
                  ScrollingGrid(
                    maxCrossAxisExtent: 240,
                    itemCount: data.edges.edges.length,
                    itemBuilder: (context, index) {
                      return EdgeView(edge: data.edges.edges[index]);
                    },
                  ),
                  ScrollingGrid(
                    maxCrossAxisExtent: 240,
                    itemCount: data.oils.oils.length,
                    itemBuilder: (context, index) {
                      return OilView(oil: data.oils.oils[index]);
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

// Battle display
// Has player on left and enemy results on the right.
// Lists the stats and items of player.
// Has a list of enemy results (changes in stats) and success/fail.
// Has a re-roll button for items.
// And maybe some sort of picker for the enemy.

/// BattlePage widget
class BattlePage extends StatefulWidget {
  /// BattlePage constructor
  const BattlePage({required this.data, super.key});

  /// Data
  final Data data;

  @override
  State<BattlePage> createState() => _BattlePageState();
}

class _BattlePageState extends State<BattlePage> {
  late CreatureConfig player;

  @override
  void initState() {
    super.initState();
    player = CreatureConfig.random(Random(), widget.data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle'),
      ),
      body: const Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text('Player'),
                    // Player stats
                    // Player items
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text('Enemy'),
                    // Enemy stats
                    // Enemy items
                  ],
                ),
              ),
            ],
          ),
          // List of enemy results
          // Re-roll button
          // Enemy picker
        ],
      ),
    );
  }
}
