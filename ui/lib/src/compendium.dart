import 'package:flutter/material.dart';
import 'package:he_is_coming/he_is_coming.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:ui/src/scrolling_grid.dart';
import 'package:ui/src/style.dart';

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

extension on StatType {
  Color get color {
    switch (this) {
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
}

/// StatIcon widget
class StatIcon extends StatelessWidget {
  /// StatIcon constructor
  const StatIcon({
    required this.statType,
    super.key,
  });

  static const Size _borderSize = Size(36, 36);
  static const Size _iconSize = Size(24, 24);

  /// Stat type
  final StatType statType;

  Widget get _icon {
    switch (statType) {
      case StatType.attack:
        return NesIcon(
          iconData: NesIcons.sword,
          primaryColor: Palette.attack,
          secondaryColor: Palette.black,
          size: _iconSize,
        );
      case StatType.health:
        return Icon(
          Icons.favorite,
          color: Palette.health,
          size: _iconSize.height,
        );
      case StatType.armor:
        return NesIcon(
          iconData: NesIcons.shield,
          primaryColor: Palette.armor,
          accentColor: Palette.black,
          size: _iconSize,
        );
      case StatType.speed:
        return Icon(
          Icons.directions_run,
          color: Palette.speed,
          size: _iconSize.height,
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
        borderColor: statType.color,
      ),
      child: SizedBox(
        width: _borderSize.width,
        height: _borderSize.height,
        child: Center(child: _icon),
      ),
    );
  }
}

/// StatLine widget
class StatLine extends StatelessWidget {
  /// StatLine constructor
  const StatLine({
    required this.stats,
    required this.statType,
    this.hideValue = false,
    super.key,
  });

  /// Stats to display
  final Stats stats;

  /// Stat type
  final StatType statType;

  /// Whether to hide the value (show ??? instead)
  final bool hideValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StatIcon(statType: statType),
        const SizedBox(width: 8),
        Text(
          hideValue ? '???' : stats[statType].toString(),
          style: Style.stats.copyWith(color: statType.color),
        ),
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
    this.hide = const {},
  });

  /// Stats to display
  final Stats stats;

  /// Stats to hide (show ??? instead)
  final Set<StatType> hide;

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
          child: StatLine(
            stats: stats,
            statType: statType,
            hideValue: hide.contains(statType),
          ),
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
      textAlign: TextAlign.center,
      text: TextSpan(
        style: Style.effect.copyWith(height: 1.5),
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
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                ItemBox(item: item),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.labelLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            if (effect != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ColoredEffectText(text: effect.text),
              ),
            if (!stats.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: StatsRow(stats: stats),
              ),
            TagsRow(tags: item.tags),
          ],
        ),
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

  Set<StatType> get _hideStats {
    if (creature.name == 'Woodland Abomination') {
      return {StatType.health};
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final name = creature.name;
    final effect = creature.effect;
    final stats = creature.baseStats;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // TODO(eseidel): Creatures use a different box than items.
              const OutlinedBox(
                borderColor: Palette.creature,
                child: Icon(Icons.bug_report, color: Palette.creature),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.labelLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          if (effect != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ColoredEffectText(text: effect.text),
            ),
          if (!stats.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: StatsRow(stats: stats, hide: _hideStats),
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
      child: Column(
        children: [
          OutlinedBox(
            borderColor: Palette.white, // Edges always use white.
            child: Icon(Icons.bug_report, color: Palette.white),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(name, style: Theme.of(context).textTheme.labelLarge),
          ),
          if (effect != null)
            Padding(
              padding: const EdgeInsets.all(4),
              child: ColoredEffectText(text: effect.text),
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

  Color get _color {
    if (oil.name == 'Attack Oil') {
      return Palette.attack;
    }
    if (oil.name == 'Speed Oil') {
      return Palette.speed;
    }
    if (oil.name == 'Armor Oil') {
      return Palette.armor;
    }
    return Palette.white;
  }

  @override
  Widget build(BuildContext context) {
    final name = oil.name;
    final stats = oil.stats;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          OutlinedBox(
            // Oils shouldn't have an outline.
            borderColor: Palette.white,
            child: Icon(Icons.water_drop, color: _color),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(name, style: Theme.of(context).textTheme.labelLarge),
          ),
          if (!stats.isEmpty) StatsRow(stats: stats),
        ],
      ),
    );
  }
}

/// Shows a scrolling grid of items with a filter.
class FilteredItems extends StatelessWidget {
  /// FilteredItems constructor
  const FilteredItems({
    required this.items,
    super.key,
  });

  static final List<String> _possible = [
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

  Set<String> _tagsForItem(Item item) {
    return {
      if (item.kind != null) item.kind!.name.capitalize(),
      if (item.material != null) item.material!.name.capitalize(),
      if (item.isUnique) 'Unique',
      item.rarity.name.capitalize(),
    };
  }

  /// Items to display
  final List<Item> items;

  @override
  Widget build(BuildContext context) {
    return FilteringHeader(
      filters: _possible,
      items: items,
      tagsForItem: _tagsForItem,
      builder: (context, items) => ScrollingGrid(
        maxCrossAxisExtent: 240,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ItemView(item: items[index]);
        },
      ),
    );
  }
}

/// Shows a scrolling grid of creatures with a filter.
class FilteredCreatures extends StatelessWidget {
  /// FilteredCreatures constructor
  const FilteredCreatures({
    required this.creatures,
    super.key,
  });

  static final List<String> _possible = [
    'Level 1',
    'Level 2',
    'Level 3',
    'End',
  ];

  Set<String> _tagsForCreature(Creature creature) {
    return {
      'Level ${creature.level}',
      if (creature.level == 4) 'End',
    };
  }

  /// Creatures to display
  final List<Creature> creatures;

  @override
  Widget build(BuildContext context) {
    return FilteringHeader(
      filters: _possible,
      items: creatures,
      tagsForItem: _tagsForCreature,
      builder: (context, items) => ScrollingGrid(
        maxCrossAxisExtent: 240,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return CreatureView(creature: items[index]);
        },
      ),
    );
  }
}

/// FilteredItemsView widget
class FilteringHeader<T> extends StatefulWidget {
  /// FilteredItemsView constructor
  const FilteringHeader({
    required this.items,
    required this.filters,
    required this.tagsForItem,
    required this.builder,
    super.key,
  });

  /// Items to display
  final List<T> items;

  /// Filters being offered
  final List<String> filters;

  /// Get the tags for an item
  final Set<String> Function(T) tagsForItem;

  /// Build the child widget displaying the items
  final Widget Function(BuildContext, List<T>) builder;

  @override
  State<FilteringHeader<T>> createState() => _FilteringHeaderState();
}

extension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

class _FilteringHeaderState<T> extends State<FilteringHeader<T>> {
  late final Set<String> enabled;

  @override
  void initState() {
    super.initState();
    enabled = widget.filters.toSet();
  }

  List<T> get items {
    return widget.items.where((item) {
      return widget.tagsForItem(item).intersection(enabled).isNotEmpty;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
          title: const Text('Filter'),
          children: [
            Wrap(
              spacing: 5,
              children: widget.filters.map((String tag) {
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
          ],
        ),
        Expanded(child: widget.builder(context, items)),
      ],
    );
  }
}