import 'dart:math';

import 'package:flutter/material.dart';
import 'package:he_is_coming/he_is_coming.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:ui/src/compendium.dart';
import 'package:ui/src/style.dart';

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
    super.key,
  });

  /// Data
  final Data data;

  /// AddItem callback
  final void Function(Item item) addItem;

  @override
  State<AddItem> createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  final SearchController controller = SearchController();
  final List<Item> searchHistory = [];

  void _addToSearchHistory(Item item) {
    if (searchHistory.contains(item)) {
      return;
    }
    setState(() {
      searchHistory.insert(0, item);
      if (searchHistory.length > 5) {
        searchHistory.removeLast();
      }
    });
  }

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
              _addToSearchHistory(item);
              widget.addItem(item);
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
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
      // If the item is a weapon, replace the first item.
      // If the inventory is full, replace the last item.
      if (item.isWeapon ||
          inventory.items.length >= Inventory.itemSlotCount(level)) {
        final index = item.isWeapon ? 0 : inventory.items.length - 1;
        _endConfig.items[index] = item;
      } else {
        // Otherwise add the item to the end.
        _endConfig = inventory.copyWith(
          items: inventory.items.toList()..add(item),
          level: level,
          setBonuses: widget.data.sets,
        );
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
          CreatureName(creature: result.second),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        AddItem(
                          data: widget.data,
                          addItem: _addItem,
                        ),
                        ElevatedButton.icon(
                          onPressed: _reroll,
                          icon: const Icon(Icons.casino),
                          label: const Text('Reroll'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(inventory.toUrlString(widget.data)),
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

/// Displays a item slot with an optional action.
class ItemSlot extends StatefulWidget {
  /// ItemSlot constructor
  const ItemSlot({
    required this.item,
    super.key,
    this.action,
  });

  /// Item to display
  final Item item;

  /// Action to display
  final Widget? action;

  @override
  State<ItemSlot> createState() => _ItemSlotState();
}

class _ItemSlotState extends State<ItemSlot> {
  double opacity = 0;
  // This shouldn't be necessary, but it seems that the AnimatedOpacity
  // interferes with the automatic SuperTooltipController management, so we
  // hold onto an explicit controller here.
  SuperTooltipController controller = SuperTooltipController();

  @override
  Widget build(BuildContext context) {
    final name = ItemName(item: widget.item, controller: controller);
    if (widget.action == null) {
      return name;
    }
    return MouseRegion(
      onEnter: (_) => setState(() => opacity = 1),
      onExit: (_) => setState(() => opacity = 0),
      child: Row(
        children: <Widget>[
          name,
          const Spacer(),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: opacity,
            child: widget.action,
          ),
          widget.action!,
        ],
      ),
    );
  }
}

/// Displays the inventory for the battle view.
class PlayerBattleView extends StatelessWidget {
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

  /// Callback to clear an item
  final void Function(int)? clearItem;

  Widget _itemSlot(int index) {
    return ItemSlot(
      item: inventory.items[index],
      action: (clearItem != null)
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => clearItem!(index),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Should this make a Player first?
    final stats = inventory.statsWithItems(playerIntrinsicStats);
    final edge = inventory.edge;
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
              _itemSlot(0),
              if (edge == null) const Text('No Edge') else EdgeName(edge: edge),
              if (inventory.oils.isNotEmpty)
                Row(
                  children: <Widget>[
                    ...inventory.oils.map((oil) {
                      return OilIconWithTooltip(oil: oil);
                    }),
                  ],
                ),
              ...inventory.items.skip(1).map((item) {
                return _itemSlot(inventory.items.indexOf(item));
              }),
              if (inventory.sets.isNotEmpty)
                ...inventory.sets.map((set) {
                  return SetBonusName(set: set);
                }),
            ],
          ),
        ),
      ],
    );
  }
}

/// Displays an item slot
class ItemName extends StatelessWidget {
  /// ItemName constructor
  const ItemName({
    required this.item,
    this.controller,
    super.key,
  });

  /// Item to display
  final Item item;

  /// Tooltip controller
  final SuperTooltipController? controller;

  @override
  Widget build(BuildContext context) {
    return SuperTooltip(
      controller: controller,
      showCloseButton: true,
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 300,
          minHeight: 200,
          maxWidth: 300,
          maxHeight: 300,
        ),
        child: ItemView(item: item),
      ),
      child: Text(item.name),
    );
  }
}

/// Displays an creature name and tooltip
class CreatureName extends StatelessWidget {
  /// CreatureName constructor
  const CreatureName({
    required this.creature,
    super.key,
  });

  /// Creature to display
  final Creature creature;

  @override
  Widget build(BuildContext context) {
    return SuperTooltip(
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 400,
          minHeight: 200,
          maxWidth: 400,
          maxHeight: 300,
        ),
        child: CreatureView(creature: creature),
      ),
      child: Text(creature.name),
    );
  }
}

/// Displays an edge name and tooltip
class EdgeName extends StatelessWidget {
  /// EdgeName constructor
  const EdgeName({
    required this.edge,
    super.key,
  });

  /// Creature to display
  final Edge edge;

  @override
  Widget build(BuildContext context) {
    return SuperTooltip(
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 300,
          minHeight: 200,
          maxWidth: 300,
          maxHeight: 300,
        ),
        child: EdgeView(edge: edge),
      ),
      child: Text(edge.name),
    );
  }
}

/// Displays an oil icon and tooltip
class OilIconWithTooltip extends StatelessWidget {
  /// OilIconWithTooltip constructor
  const OilIconWithTooltip({
    required this.oil,
    super.key,
  });

  /// Oil to display
  final Oil oil;

  @override
  Widget build(BuildContext context) {
    return SuperTooltip(
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 300,
          minHeight: 200,
          maxWidth: 300,
          maxHeight: 300,
        ),
        child: OilView(oil: oil),
      ),
      child: oil.icon,
    );
  }
}

/// Displays a set bonus name and tooltip
class SetBonusName extends StatelessWidget {
  /// SetBonusName constructor
  const SetBonusName({
    required this.set,
    super.key,
  });

  /// Set to display
  final SetBonus set;

  @override
  Widget build(BuildContext context) {
    return SuperTooltip(
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 300,
          minHeight: 200,
          maxWidth: 300,
          maxHeight: 300,
        ),
        child: SetBonusView(setBonus: set),
      ),
      child: Text(set.name),
    );
  }
}
