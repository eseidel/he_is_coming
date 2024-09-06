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
      setBonuses: widget.data.sets,
    );
  }

  void _setItem(int index, Item? item) {
    setState(() {
      if (item == null) {
        _endConfig.items.removeAt(index);
      } else {
        _endConfig.items[index] = item;
      }
      _updateResults();
    });
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

    List<Widget> battleDelta(CreatureDelta delta) {
      const size = Style.inlineStatIconSize;
      return <Widget>[
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
      ];
    }

    Row resultLine(BattleResult result) {
      final change = result.firstDelta;
      final survived = result.first.isAlive;
      const diedText = Text('💀');
      return Row(
        children: [
          Text(result.second.name),
          const Spacer(),
          if (survived) ...battleDelta(change),
          if (!survived) diedText,
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle'),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            width: 300,
            child: NesIterableOptions(
              values: Level.values,
              onChange: _setLevel,
              optionBuilder: (context, level) => Text(
                level.name,
                style: TextStyle(color: Palette.white),
              ),
              value: level,
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: [
                    PlayerBattleView(
                      inventory: inventory,
                      level: level,
                      data: widget.data,
                      setItem: _setItem,
                    ),
                    ElevatedButton.icon(
                      onPressed: _reroll,
                      icon: const Icon(Icons.casino),
                      label: const Text('Reroll'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
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

/// Displays the inventory for the battle view.
class PlayerBattleView extends StatefulWidget {
  /// PlayerBattleView constructor
  const PlayerBattleView({
    required this.inventory,
    required this.level,
    required this.data,
    required this.setItem,
    super.key,
  });

  /// Inventory
  final Inventory inventory;

  /// Level
  final Level level;

  /// Data
  final Data data;

  /// Callback to set an item in a specific slot.
  final void Function(int index, Item? item) setItem;

  @override
  State<PlayerBattleView> createState() => _PlayerBattleViewState();
}

class _PlayerBattleViewState extends State<PlayerBattleView> {
  final controller = SearchController();
  final List<Item> weaponsSearchHistory = [];
  final List<Item> nonWeaponsSearchHistory = [];

  Widget itemSlot(int index) {
    final isWeapon = index == 0;
    final maybeItem = (index < widget.inventory.items.length)
        ? widget.inventory.items[index]
        : null;
    final possibleItems =
        isWeapon ? widget.data.items.weapons : widget.data.items.nonWeapons;
    final searchHistory =
        isWeapon ? weaponsSearchHistory : nonWeaponsSearchHistory;
    return ItemSlot(
      item: maybeItem,
      possibleItems: possibleItems,
      searchHistory: searchHistory,
      changeItem: (item) {
        if (item != null) {
          searchHistory.insert(0, item);
          if (searchHistory.length > 5) {
            searchHistory.removeLast();
          }
        }
        widget.setItem(index, item);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Should this make a Player first?
    final stats = widget.inventory.statsWithItems(playerIntrinsicStats);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 100,
          child: Column(
            children: StatType.values.map((statType) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: StatLine(
                  stats: stats,
                  statType: statType,
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: Column(
            children: <Widget>[
              itemSlot(0),
              Text(widget.inventory.edge?.name ?? 'No Edge'),
              for (int i = 1; i < Inventory.itemSlotCount(widget.level); i++)
                itemSlot(i),
            ],
          ),
        ),
      ],
    );
  }
}

/// Displays an item slot with a search anchor.
class ItemSlot extends StatefulWidget {
  /// ItemSlot constructor
  const ItemSlot({
    required this.item,
    required this.possibleItems,
    required this.changeItem,
    super.key,
    this.searchHistory = const [],
  });

  /// Item to display
  final Item? item;

  /// List of all available items for this slot.
  final List<Item> possibleItems;

  /// List of items that have been searched for.
  final List<Item> searchHistory;

  /// Callback to change the item.
  final void Function(Item? item) changeItem;

  @override
  State<ItemSlot> createState() => _ItemSlotState();
}

class _ItemSlotState extends State<ItemSlot> {
  final SearchController controller = SearchController();

  Iterable<Widget> getHistoryList(SearchController controller) {
    return widget.searchHistory.map(
      (Item item) => ListTile(
        leading: const Icon(Icons.history),
        title: Text(item.name),
        trailing: IconButton(
          icon: const Icon(Icons.call_missed),
          onPressed: () {
            controller
              ..text = item.name
              ..selection =
                  TextSelection.collapsed(offset: controller.text.length);
          },
        ),
      ),
    );
  }

  Iterable<Widget> getSuggestions(SearchController controller) {
    final input = controller.value.text;
    return widget.possibleItems
        .where(
          (Item item) => item.name.toLowerCase().contains(input.toLowerCase()),
        )
        .map(
          (Item item) => ListTile(
            leading: CircleAvatar(backgroundColor: item.color),
            title: Text(item.name),
            trailing: IconButton(
              icon: const Icon(Icons.call_missed),
              onPressed: () {
                controller
                  ..text = item.name
                  ..selection =
                      TextSelection.collapsed(offset: controller.text.length);
              },
            ),
            onTap: () {
              controller.closeView(item.name);
              widget.changeItem(item);
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final searchButton = SearchAnchor(
      searchController: controller,
      builder: (BuildContext context, SearchController controller) {
        return IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            controller.openView();
          },
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        if (controller.text.isEmpty) {
          if (widget.searchHistory.isNotEmpty) {
            return getHistoryList(controller);
          }
          return <Widget>[const Center(child: Text('No search history.'))];
        }
        return getSuggestions(controller);
      },
    );
    return Row(
      children: <Widget>[
        if (widget.item != null) ...[
          Text(widget.item!.name),
          const SizedBox(width: 4),
        ],
        const Spacer(),
        searchButton,
      ],
    );
  }
}
