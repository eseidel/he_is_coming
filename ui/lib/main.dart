import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:he_is_coming/he_is_coming.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:ui/src/compendium.dart';
import 'package:ui/src/scrolling_grid.dart';
import 'package:ui/src/style.dart';
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

/// CompendiumPage widget
class CompendiumPage extends StatefulWidget {
  /// CompendiumPage constructor
  const CompendiumPage(this.data, {super.key});

  /// Data
  final Data data;

  @override
  State<CompendiumPage> createState() => _CompendiumPageState();
}

class _CompendiumPageState extends State<CompendiumPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  static const tabNames = <Widget>[
    Tab(text: 'Items'),
    Tab(text: 'Creatures'),
    Tab(text: 'Edges'),
    Tab(text: 'Oils'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabNames.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Data get data => widget.data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TabBar.secondary(controller: _tabController, tabs: tabNames),
        Expanded(
          child: TabBarView(
            controller: _tabController,
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
      ],
    );
  }
}

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
  late Inventory _endConfig;
  List<BattleResult> results = [];
  Level level = Level.one;
  final random = Random();

  @override
  void initState() {
    super.initState();
    _reroll();
  }

  void _reroll() {
    setState(() {
      _endConfig = Inventory.random(Level.end, random, widget.data);
      _updateResults();
    });
  }

  List<Creature> get enemies {
    return widget.data.creatures.creatures
        .where((c) => c.level == level)
        .toList();
  }

  Inventory get inventory {
    return Inventory(
      level: level,
      items: _endConfig.items.sublist(0, Inventory.itemSlotCount(level)),
      edge: _endConfig.edge,
      oils: _endConfig.oils,
    );
  }

  void _updateResults() {
    // For each enemy, run the battle and gather the results.
    final player = playerWithInventory(level, inventory);
    results = enemies
        .map(
          (enemy) => Battle.resolve(first: player, second: enemy),
        )
        .toList();
  }

  void _setLevel(Level level) {
    setState(() {
      this.level = level;
      _updateResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    String signed(int value) => value >= 0 ? '+$value' : '$value';

    Widget battleDelta(CreatureDelta delta) {
      const size = Style.inlineStatIconSize;
      return SizedBox(
        width: 150,
        child: Row(
          children: <Widget>[
            if (delta.hp != 0) ...[
              Text(signed(delta.hp)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: StatIcon(statType: StatType.health, size: size),
              ),
            ],
            if (delta.gold != 0) ...[
              Text(signed(delta.gold)),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: GoldIcon(size: size),
              ),
            ],
          ],
        ),
      );
    }

    Row resultLine(BattleResult result) {
      final change = result.firstDelta;
      final survived = result.first.isAlive;
      final survivedText = survived ? '✅' : '❌';
      return Row(
        children: [
          Text(survivedText),
          battleDelta(change),
          Text(result.second.name),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle'),
      ),
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    NesIterableOptions(
                      values: Level.values,
                      onChange: _setLevel,
                      value: level,
                    ),
                    ElevatedButton(
                      onPressed: _reroll,
                      child: const Icon(Icons.casino),
                    ),
                    const Text('Player'),
                    ...inventory.items.map((item) => Text(item.name)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: results.map(resultLine).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
