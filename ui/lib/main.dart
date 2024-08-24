import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:he_is_coming/he_is_coming.dart';

void main() {
  runApp(const MyApp());
}

/// Color palette
class Palette {
  /// White, used for all UI and text.
  static final Color white = Colors.brown[100]!;

  /// Text color.
  static final Color text = Palette.white;

  /// Weapon Items color.
  static const Color weapon = Palette.attack;

  /// Sanguine Items color.
  static final Color sanguine = Colors.red[900]!;

  /// Food Items color.
  static final Color food = Colors.green[800]!;

  /// Stone Items color.
  static final Color stone = Colors.grey[800]!;

  /// Heroic Rarity color.
  static const Color heroic = Colors.teal;

  /// Rare Rarity color.
  static const Color rare = Colors.blue;

  /// Common Rarity color.
  static const Color common = Colors.green;

  /// Golden Rarity color.
  static const Color golden = Colors.yellow;

  /// Cauldron Rarity color.
  static const Color cauldron = Colors.orange;

  /// Health stat color.
  static const Color health = Colors.green;

  /// Attack stat color.
  static const Color attack = Colors.red;

  /// Armor stat color.
  static const Color armor = Colors.grey;

  /// Speed stat color.
  static const Color speed = Colors.yellow;
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
        useMaterial3: true,
        textTheme: GoogleFonts.pressStart2pTextTheme().apply(
          bodyColor: Palette.text,
          displayColor: Palette.text,
        ),
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
        child: Text(text),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final tag in tags)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Palette.white,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  tag,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .apply(color: Colors.black, fontWeightDelta: 2),
                ),
              ),
            ),
          ),
      ],
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
        Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: 64,
            height: 64,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: item.borderColor, width: 3),
              ),
              child: Icon(item.icon, color: item.color),
            ),
          ),
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

/// ItemView widget
class ItemView extends StatelessWidget {
  /// ItemView constructor
  const ItemView({
    required this.item,
    super.key,
  });

  /// Item to display
  final Item item;

  Widget _colorEffectText(String text) {
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

  @override
  Widget build(BuildContext context) {
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
                Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (item.effect != null) _colorEffectText(item.effect!.text),
                if (!item.stats.isEmpty) StatsRow(stats: item.stats),
                const SizedBox(height: 8),
                TagsRow(tags: item.tags),
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
    final creatures =
        rootBundle.loadString('packages/he_is_coming/data/creatures.yaml');
    final items =
        rootBundle.loadString('packages/he_is_coming/data/items.yaml');
    final edges =
        rootBundle.loadString('packages/he_is_coming/data/edges.yaml');
    final oils =
        rootBundle.loadString('packages/he_is_coming/data/blade_oils.yaml');
    return Data.fromStrings(
      creatures: creatures,
      items: items,
      edges: edges,
      oils: oils,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('He is Coming'),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : ItemGrid(items: data.items.items),
      ),
    );
  }
}

/// ItemGrid widget
class ItemGrid extends StatelessWidget {
  /// ItemGrid constructor
  const ItemGrid({required this.items, super.key});

  /// Items to display
  final List<Item> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Card(
        elevation: 8,
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: _CustomGridDelegate(dimension: 240),
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            return ItemView(item: items[index]);
          },
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
      fullRowPeriod:
          3, // Number of rows per block (one of which is the full row).
      dimension: squareDimension,
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
    required this.dimension,
    required this.fullRowPeriod,
  })  : assert(crossAxisCount > 0, 'crossAxisCount must be greater than zero'),
        assert(fullRowPeriod > 1, 'fullRowPeriod must be greater than one'),
        loopLength = crossAxisCount * (fullRowPeriod - 1) + 1,
        loopHeight = fullRowPeriod * dimension;

  final int crossAxisCount;
  final double dimension;
  final int fullRowPeriod;

  // Computed values.
  final int loopLength;
  final double loopHeight;

  @override
  double computeMaxScrollOffset(int childCount) {
    // This returns the scroll offset of the end side of the childCount'th
    // child. In the case of this example, this method is not used, since the
    // grid is infinite. However, if one set an itemCount on the GridView above,
    // this function would be used to determine how far to allow the user to
    // scroll.
    if (childCount == 0 || dimension == 0) {
      return 0;
    }
    return (childCount ~/ loopLength) * loopHeight +
        ((childCount % loopLength) ~/ crossAxisCount) * dimension;
  }

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    // This returns the position of the index'th tile.
    //
    // The SliverGridGeometry object returned from this method has four
    // properties. For a grid that scrolls down, as in this example, the four
    // properties are equivalent to x,y,width,height. However, since the
    // GridView is direction agnostic, the names used for SliverGridGeometry are
    // also direction-agnostic.
    //
    // Try changing the scrollDirection and reverse properties on the GridView
    // to see how this algorithm works in any direction (and why, therefore, the
    // names are direction-agnostic).
    final loop = index ~/ loopLength;
    final loopIndex = index % loopLength;
    if (loopIndex == loopLength - 1) {
      // Full width case.
      return SliverGridGeometry(
        scrollOffset: (loop + 1) * loopHeight - dimension, // "y"
        crossAxisOffset: 0, // "x"
        mainAxisExtent: dimension, // "height"
        crossAxisExtent: crossAxisCount * dimension, // "width"
      );
    }
    // Square case.
    final rowIndex = loopIndex ~/ crossAxisCount;
    final columnIndex = loopIndex % crossAxisCount;
    return SliverGridGeometry(
      scrollOffset: (loop * loopHeight) + (rowIndex * dimension), // "y"
      crossAxisOffset: columnIndex * dimension, // "x"
      mainAxisExtent: dimension, // "height"
      crossAxisExtent: dimension, // "width"
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
    final rows = scrollOffset ~/ dimension;
    final loops = rows ~/ fullRowPeriod;
    final extra = rows % fullRowPeriod;
    return loops * loopLength + extra * crossAxisCount;
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    // (See commentary above.)
    final rows = scrollOffset ~/ dimension;
    final loops = rows ~/ fullRowPeriod;
    final extra = rows % fullRowPeriod;
    final count = loops * loopLength + extra * crossAxisCount;
    if (extra == fullRowPeriod - 1) {
      return count;
    }
    return count + crossAxisCount - 1;
  }
}
