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

/// AddItem widget
class AddItem extends StatefulWidget {
  /// AddItem constructor
  const AddItem({
    required this.data,
    required this.addItem,
    this.enabled = true,
    super.key,
  });

  /// Data
  final Data data;

  /// AddItem callback
  final void Function(Item item) addItem;

  /// Enabled
  final bool enabled;

  @override
  State<AddItem> createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  final SearchController controller = SearchController();
  final List<Item> searchHistory = [];

  Iterable<Widget> getHistoryList(SearchController controller) {
    return searchHistory.map(
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
    return widget.data.items.items
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
              searchHistory.insert(0, item);
              if (searchHistory.length > 5) {
                searchHistory.removeLast();
              }
              widget.addItem(item);
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final anchor = SearchAnchor(
      searchController: controller,
      builder: (BuildContext context, SearchController controller) {
        return ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Item'),
          onPressed: () {
            // This is optional, SearchAnchor also does openView for us.
            controller.openView();
          },
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        if (controller.text.isEmpty) {
          if (searchHistory.isNotEmpty) {
            return getHistoryList(controller);
          }
          return <Widget>[const Center(child: Text('No search history.'))];
        }
        return getSuggestions(controller);
      },
    );
    if (widget.enabled) {
      return anchor;
    }
    return Opacity(opacity: 0.5, child: IgnorePointer(child: anchor));
  }
}

class _BattlePageState extends State<BattlePage> {
  // Saves "offscreen" items, even those not displayed at the current level.
  // This lets you change the level back and forth and still see the same items.
  // These "offscreen" items are intentionally removed when an item is cleared
  // to avoid having them suddenly appear in the inventory.
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
    final maxItem =
        min(_endConfig.items.length, Inventory.itemSlotCount(level));
    return Inventory(
      level: level,
      items: _endConfig.items.sublist(0, maxItem),
      edge: _endConfig.edge,
      oils: _endConfig.oils,
      setBonuses: widget.data.sets,
    );
  }

  void _addItem(Item item) {
    setState(() {
      _endConfig.items.add(item);
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
                      clearItem: (index) {
                        setState(() {
                          final items = inventory.items.toList()
                            ..removeAt(index);
                          // This intentionally removes any "offscreen" items.
                          _endConfig = inventory.copyWith(
                            items: items,
                            level: level,
                            setBonuses: widget.data.sets,
                          );
                          _updateResults();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    AddItem(
                      data: widget.data,
                      addItem: _addItem,
                      enabled: inventory.items.length <
                          Inventory.itemSlotCount(level),
                    ),
                    ElevatedButton.icon(
                      onPressed: _reroll,
                      icon: const Icon(Icons.casino),
                      label: const Text('Reroll'),
                    ),
                    Text(inventory.toUrlString(widget.data)),
                    const SizedBox(height: 16),
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
    this.clearItem,
    super.key,
  });

  /// Inventory
  final Inventory inventory;

  /// Level
  final Level level;

  final void Function(int)? clearItem;

  @override
  State<PlayerBattleView> createState() => _PlayerBattleViewState();
}

class _PlayerBattleViewState extends State<PlayerBattleView> {
  final controller = SearchController();
  final List<Item> weaponsSearchHistory = [];
  final List<Item> nonWeaponsSearchHistory = [];

  Widget itemSlot(int index) {
    final maybeItem = (index < widget.inventory.items.length)
        ? widget.inventory.items[index]
        : null;
    final slot = ItemSlot(item: maybeItem);
    if (widget.clearItem == null || maybeItem == null) {
      return slot;
    }
    return Row(
      children: <Widget>[
        slot,
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            widget.clearItem!(index);
          },
        ),
      ],
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

/// Displays an item slot
class ItemSlot extends StatelessWidget {
  /// ItemSlot constructor
  const ItemSlot({
    required this.item,
    super.key,
  });

  /// Item to display
  final Item? item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (item != null) ...[
          Text(item!.name),
          const SizedBox(width: 4),
        ],
      ],
    );
  }
}
