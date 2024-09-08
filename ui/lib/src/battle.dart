import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:he_is_coming/he_is_coming.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:ui/src/compendium.dart';
import 'package:ui/src/extensions.dart';
import 'package:ui/src/style.dart';

/// BattlePage widget
class BattlePage extends StatefulWidget {
  /// BattlePage constructor
  const BattlePage({required this.data, required this.state, super.key});

  /// Data
  final Data data;

  /// BuildState
  final BuildState state;

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

/// EnemyResults widget
class EnemyResults extends StatelessWidget {
  /// EnemyResults constructor
  const EnemyResults({
    required this.state,
    required this.data,
    super.key,
  });

  /// BuildState
  final BuildState state;

  /// Data
  final Data data;

  List<Creature> get _enemies {
    return data.creatures.creatures
        .where((c) => c.level == state.level)
        .toList();
  }

  String _signed(int value) => value >= 0 ? '+$value' : '$value';

  List<Widget> _battleDelta(CreatureDelta delta) {
    const size = Style.inlineStatIconSize;
    return <Widget>[
      if (delta.hp != 0) ...[
        Text(_signed(delta.hp)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: StatIcon(statType: StatType.health, size: size),
        ),
      ],
      if (delta.gold != 0) ...[
        Text(_signed(delta.gold)),
        const SizedBox(width: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: GoldIcon(size: size),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    // For each enemy, run the battle and gather the results.
    final player = playerWithInventory(state.level, state.inventory);
    final results = _enemies
        .map(
          (enemy) => Battle.resolve(first: player, second: enemy),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: results.map((result) {
        final change = result.firstDelta;
        final survived = result.first.isAlive;
        const diedText = Text('💀');
        return Row(
          children: [
            CreatureName(creature: result.second),
            const Spacer(),
            if (survived) ..._battleDelta(change),
            if (!survived) diedText,
          ],
        );
      }).toList(),
    );
  }
}

class _BattlePageState extends State<BattlePage> {
  final random = Random();

  late TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.selection =
            TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      }
    });
    _updateFromState(widget.state);
  }

  void _updateFromState(BuildState state) {
    setState(() {
      // Update the text field with the current build id.
      _controller.text = BuildStateCodec.encode(state, widget.data);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Level get level => widget.state.level;
  Inventory get inventory => widget.state.inventory;

  void setBuildState(BuildContext context, BuildState state) {
    _updateFromState(state);
    context.goNamed(
      'battle',
      pathParameters: {
        BuildStateCodec.parameterName:
            BuildStateCodec.encode(state, widget.data),
      },
    );
  }

  void setInventory(BuildContext context, Inventory inventory) {
    setBuildState(context, BuildState(level, inventory));
  }

  void setLevel(BuildContext context, Level level) {
    setBuildState(context, BuildState(level, inventory));
  }

  void _reroll() {
    setInventory(context, Inventory.random(level, random, widget.data));
  }

  void _addItem(Item item) {
    // If the item is a weapon, replace the first item.
    // If the inventory is full, replace the last item.
    final newItems = inventory.items.toList();
    if (item.isWeapon ||
        inventory.items.length >= Inventory.itemSlotCount(level)) {
      final index = item.isWeapon ? 0 : inventory.items.length - 1;
      newItems[index] = item;
    } else {
      // Otherwise add the item to the end.
      newItems.add(item);
    }
    setInventory(
      context,
      inventory.copyWith(
        items: newItems,
        level: level,
        setBonuses: widget.data.sets,
      ),
    );
  }

  void _removeItemAtIndex(int index) {
    final items = inventory.items.toList()..removeAt(index);
    setInventory(
      context,
      inventory.copyWith(
        level: level,
        items: items,
        setBonuses: widget.data.sets,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              onChange: (value) => setLevel(context, value),
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
                      clearItem: _removeItemAtIndex,
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
                    Form(
                      autovalidateMode: AutovalidateMode.always,
                      onChanged: () {
                        Form.of(primaryFocus!.context!).save();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Code',
                          ),
                          controller: _controller,
                          focusNode: _focusNode,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter a value';
                            }
                            try {
                              BuildStateCodec.decode(value, widget.data);
                            } catch (e) {
                              return e.toString();
                            }
                            return null;
                          },
                          onFieldSubmitted: (String value) async {
                            final build =
                                BuildStateCodec.tryDecode(value, widget.data);
                            if (build == null) {
                              return;
                            }
                            setBuildState(context, build);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: EnemyResults(state: widget.state, data: widget.data),
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
