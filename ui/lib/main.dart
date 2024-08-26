import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:he_is_coming/he_is_coming.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:ui/scrolling_grid.dart';
import 'package:ui/style.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
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

extension on ItemRarity {
  Color get color {
    switch (this) {
      case ItemRarity.common:
        return Palette.common;
      case ItemRarity.rare:
        return Palette.rare;
      case ItemRarity.heroic:
        return Palette.heroic;
      case ItemRarity.golden:
        return Palette.golden;
      case ItemRarity.cauldron:
        return Palette.cauldron;
    }
  }
}

extension on Item {
  Color get color {
    if (kind == ItemKind.weapon) {
      return Palette.weapon;
    }
    if (material == ItemMaterial.stone) {
      return Palette.stone;
    }
    if (material == ItemMaterial.sanguine) {
      return Palette.sanguine;
    }
    return Colors.orange;
  }

  Color get borderColor {
    if (kind == ItemKind.weapon) {
      return Palette.weapon;
    }
    return Palette.white;
  }

  IconData get icon {
    return Icons.help;
  }

  Widget get rarityIcon {
    return Icon(
      Icons.circle,
      color: rarity.color,
      size: 12,
    );
  }

  List<String> get tags {
    return [
      if (isUnique) 'Unique',
      if (kind == ItemKind.food) 'Food',
      if (kind == ItemKind.jewelry) 'Jewelry',
      if (material == ItemMaterial.stone) 'Stone',
      if (material == ItemMaterial.sanguine) 'Sanguine',
      if (material == ItemMaterial.wood) 'Wood',
    ];
  }
}

class StatIcon extends StatelessWidget {
  const StatIcon({
    required this.statType,
    super.key,
  });

  static const Size borderSize = Size(24, 24);
  static const Size iconSize = Size(14, 14);
  final StatType statType;

  Color get color {
    switch (statType) {
      case StatType.attack:
        return Palette.attack;
      case StatType.health:
        return Palette.health;
      case StatType.armor:
        return Palette.armor;
      case StatType.speed:
        return Palette.speed;
    }
  }

  Widget get icon {
    switch (statType) {
      case StatType.attack:
        return NesIcon(
          iconData: NesIcons.sword,
          primaryColor: Palette.attack,
          secondaryColor: Palette.black,
          size: iconSize,
        );
      case StatType.health:
        return Icon(
          Icons.favorite,
          color: Palette.health,
          size: iconSize.height,
        );
      case StatType.armor:
        return NesIcon(
          iconData: NesIcons.shield,
          primaryColor: Palette.armor,
          accentColor: Palette.black,
          size: iconSize,
        );
      case StatType.speed:
        return Icon(
          Icons.directions_run,
          color: Palette.speed,
          size: iconSize.height,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: NesContainerRoundedBorderPainter(
        label: null,
        pixelSize: 2,
        textStyle: Style.stats,
        backgroundColor: Palette.black,
        borderColor: color,
      ),
      child: SizedBox(
        width: borderSize.width,
        height: borderSize.height,
        child: Center(child: icon),
      ),
    );
  }
}

class StatLine extends StatelessWidget {
  const StatLine({
    required this.stats,
    required this.statType,
    super.key,
  });

  final Stats stats;
  final StatType statType;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StatIcon(statType: statType),
        const SizedBox(width: 4),
        Text(stats[statType].toString(), style: Style.stats),
      ],
    );
  }
}

/// Stats when displayed horizontally.
class StatsRow extends StatelessWidget {
  /// StatsRow constructor
  const StatsRow({
    required this.stats,
    super.key,
  });

  /// Stats to display
  final Stats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: StatType.values.map((statType) {
        if (stats[statType] == 0) {
          return const SizedBox();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: StatLine(stats: stats, statType: statType),
        );
      }).toList(),
    );
  }
}

/// Tags when displayed horizontally.
class TagsRow extends StatelessWidget {
  /// TagsRow constructor
  const TagsRow({
    required this.tags,
    super.key,
  });

  /// Tags to display
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final tag in tags)
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Palette.white,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(tag, style: Style.tags),
            ),
          ),
      ],
    );
  }
}

/// OutlinedBox widget
class OutlinedBox extends StatelessWidget {
  /// OutlinedBox constructor
  const OutlinedBox({
    required this.child,
    required this.borderColor,
    super.key,
  });

  /// Child widget
  final Widget child;

  /// Border color
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 64,
        height: 64,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 3),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// ItemBox widget
class ItemBox extends StatelessWidget {
  /// ItemBox constructor
  const ItemBox({
    required this.item,
    super.key,
  });

  /// Item to display
  final Item item;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        OutlinedBox(
          borderColor: item.borderColor,
          child: Icon(item.icon, color: item.color),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: item.rarityIcon,
        ),
      ],
    );
  }
}

/// ColoredEffectText widget
class ColoredEffectText extends StatelessWidget {
  /// ColoredEffectText constructor
  const ColoredEffectText({
    required this.text,
    super.key,
  });

  /// Text to display
  final String text;

  @override
  Widget build(BuildContext context) {
    // Color a few special words:
    final specialWords = <String, Color>{
      'health': Palette.health,
      'attack': Palette.attack,
      'armor': Palette.armor,
      'speed': Palette.speed,
    };

    final words = text.split(' ');
    return RichText(
      text: TextSpan(
        style: Style.effect,
        children: [
          for (final word in words)
            TextSpan(
              text: '$word ',
              style: TextStyle(
                color: specialWords[word] ?? Palette.white,
              ),
            ),
        ],
      ),
    );
  }
}

/// ItemView widget
class ItemView extends StatelessWidget {
  /// ItemView constructor
  const ItemView({
    required this.item,
    super.key,
  });

  /// Item to display
  final Item item;

  @override
  Widget build(BuildContext context) {
    final name = item.name;
    final effect = item.effect;
    final stats = item.stats;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ItemBox(item: item),
          Expanded(
            child: Column(
              children: [
                Text(name, style: Theme.of(context).textTheme.labelLarge),
                if (effect != null)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: ColoredEffectText(text: effect.text),
                  ),
                if (!stats.isEmpty) StatsRow(stats: stats),
                TagsRow(tags: item.tags),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Display a Creature
class CreatureView extends StatelessWidget {
  /// CreatureView constructor
  const CreatureView({
    required this.creature,
    super.key,
  });

  /// Creature to display
  final Creature creature;

  @override
  Widget build(BuildContext context) {
    final name = creature.name;
    final effect = creature.effect;
    final stats = creature.baseStats;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // TODO(eseidel): Creatures use a different box than items.
          const OutlinedBox(
            borderColor: Palette.creature,
            child: Icon(Icons.bug_report, color: Palette.creature),
          ),
          Expanded(
            child: Column(
              children: [
                Text(name, style: Theme.of(context).textTheme.labelLarge),
                if (effect != null)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: ColoredEffectText(text: effect.text),
                  ),
                if (!stats.isEmpty) StatsRow(stats: stats),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Display an Edge
class EdgeView extends StatelessWidget {
  /// EdgeView constructor
  const EdgeView({
    required this.edge,
    super.key,
  });

  /// Edge to display
  final Edge edge;

  @override
  Widget build(BuildContext context) {
    final name = edge.name;
    final effect = edge.effect;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          OutlinedBox(
            borderColor: Palette.white, // Edges always use white.
            child: Icon(Icons.bug_report, color: Palette.white),
          ),
          Expanded(
            child: Column(
              children: [
                Text(name, style: Theme.of(context).textTheme.labelLarge),
                if (effect != null)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: ColoredEffectText(text: effect.text),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Display an Oil
class OilView extends StatelessWidget {
  /// OilView constructor
  const OilView({
    required this.oil,
    super.key,
  });

  /// Oil to display
  final Oil oil;

  @override
  Widget build(BuildContext context) {
    final name = oil.name;
    final stats = oil.stats;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Oils don't have an outline I don't think?
          // They just have an oil droplet in the color of the stat they modify.
          OutlinedBox(
            borderColor: Palette.white,
            child: Icon(Icons.bug_report, color: Palette.white),
          ),
          Expanded(
            child: Column(
              children: [
                Text(name, style: Theme.of(context).textTheme.labelLarge),
                if (!stats.isEmpty) StatsRow(stats: stats),
              ],
            ),
          ),
        ],
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
                  FilteredItemsView(
                    items: data.items.items,
                  ),
                  ScrollingGrid(
                    maxCrossAxisExtent: 240,
                    itemCount: data.creatures.creatures.length,
                    itemBuilder: (context, index) {
                      return CreatureView(
                        creature: data.creatures.creatures[index],
                      );
                    },
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

/// FilteredItemsView widget
class FilteredItemsView extends StatefulWidget {
  /// FilteredItemsView constructor
  const FilteredItemsView({
    required this.items,
    super.key,
  });

  /// Items to display
  final List<Item> items;

  @override
  State<FilteredItemsView> createState() => _FilteredItemsViewState();
}

extension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

class _FilteredItemsViewState extends State<FilteredItemsView> {
  static final List<String> possible = [
    'Weapon',
    'Food',
    'Jewelry',
    'Stone',
    'Sanguine',
    'Wood',
    'Bomb',
    'Unique',
    'Common',
    'Rare',
    'Heroic',
    'Golden',
    'Cauldron',
  ];
  final Set<String> enabled = possible.toSet();

  Set<String> tagsForItem(Item item) {
    return {
      if (item.kind != null) item.kind!.name.capitalize(),
      if (item.material != null) item.material!.name.capitalize(),
      if (item.isUnique) 'Unique',
      item.rarity.name.capitalize(),
    };
  }

  List<Item> get items {
    return widget.items.where((item) {
      return tagsForItem(item).intersection(enabled).isNotEmpty;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 5,
          children: possible.map((String tag) {
            return FilterChip(
              label: Text(tag),
              selected: enabled.contains(tag),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    enabled.add(tag);
                  } else {
                    enabled.remove(tag);
                  }
                });
              },
            );
          }).toList(),
        ),
        Expanded(
          child: ScrollingGrid(
            maxCrossAxisExtent: 240,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return ItemView(item: items[index]);
            },
          ),
        ),
      ],
    );
  }
}
