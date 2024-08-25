import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:he_is_coming/he_is_coming.dart';
import 'package:ui/style.dart';

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
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(),
        textTheme: Style.textTheme,
      ),
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
    Widget padded(String text) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(text, style: Style.stats),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (stats.attack > 0) padded('⚔️${stats.attack}'),
        if (stats.maxHp > 0) padded('❤️${stats.maxHp}'),
        if (stats.armor > 0) padded('🛡️${stats.armor}'),
        if (stats.speed > 0) padded('👟${stats.speed}'),
      ],
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

/// ScrollingGrid widget
class ScrollingGrid extends StatelessWidget {
  /// ScrollingGrid constructor
  const ScrollingGrid({
    required this.maxCrossAxisExtent,
    required this.itemCount,
    required this.itemBuilder,
    super.key,
  });

  /// Maximum cross axis extent
  final double maxCrossAxisExtent;

  /// Item count
  final int itemCount;

  /// Item builder
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Card(
        elevation: 8,
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: _CustomGridDelegate(
            dimension: maxCrossAxisExtent,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        ),
      ),
    );
  }
}

class _CustomGridDelegate extends SliverGridDelegate {
  _CustomGridDelegate({required this.dimension});

  // This is the desired height of each row (and width of each square). When
  // there is not enough room, we shrink this to the width of the scroll view.
  final double dimension;

  // The layout is two rows of squares, then one very wide cell, repeat.

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    // Determine how many squares we can fit per row.
    var count = constraints.crossAxisExtent ~/ dimension;
    if (count < 1) {
      count = 1; // Always fit at least one regardless.
    }
    final squareDimension = constraints.crossAxisExtent / count;
    return _CustomGridLayout(
      crossAxisCount: count,
      childSize: Size(squareDimension, squareDimension),
    );
  }

  @override
  bool shouldRelayout(_CustomGridDelegate oldDelegate) {
    return dimension != oldDelegate.dimension;
  }
}

class _CustomGridLayout extends SliverGridLayout {
  const _CustomGridLayout({
    required this.crossAxisCount,
    required this.childSize,
  }) : assert(crossAxisCount > 0, 'crossAxisCount must be greater than zero');

  final Size childSize;
  final int crossAxisCount;

  @override
  double computeMaxScrollOffset(int childCount) {
    // This returns the scroll offset of the end side of the childCount'th
    // child. Determines how far to allow the user to scroll.
    if (childCount == 0) {
      return 0;
    }
    return (childCount ~/ crossAxisCount) * childSize.height;
  }

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    // This returns the start of the index'th tile.
    //
    // The SliverGridGeometry object returned from this method has four
    // properties. For a grid that scrolls down, as in this example, the four
    // properties are equivalent to x,y,width,height. However, since the
    // GridView is direction agnostic, the names used for SliverGridGeometry are
    // also direction-agnostic.

    final rowIndex = index ~/ crossAxisCount;
    final columnIndex = index % crossAxisCount;
    return SliverGridGeometry(
      scrollOffset: rowIndex * childSize.height, // "y"
      crossAxisOffset: columnIndex * childSize.width, // "x"
      mainAxisExtent: childSize.height, // "height"
      crossAxisExtent: childSize.width, // "width"
    );
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    // This returns the first index that is visible for a given scrollOffset.
    //
    // The GridView only asks for the geometry of children that are visible
    // between the scroll offset passed to getMinChildIndexForScrollOffset and
    // the scroll offset passed to getMaxChildIndexForScrollOffset.
    //
    // It is the responsibility of the SliverGridLayout to ensure that
    // getGeometryForChildIndex is consistent with
    // getMinChildIndexForScrollOffset and getMaxChildIndexForScrollOffset.
    //
    // Not every child between the minimum child index and the maximum child
    // index need be visible (some may have scroll offsets that are outside the
    // view; this happens commonly when the grid view places tiles out of
    // order). However, doing this means the grid view is less efficient, as it
    // will do work for children that are not visible. It is preferred that the
    // children are returned in the order that they are laid out.
    final rows = scrollOffset ~/ childSize.height;
    return rows * crossAxisCount;
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    // (See commentary above.)
    final rows = scrollOffset ~/ childSize.height;
    return (rows + 1) * crossAxisCount - 1;
  }
}
