import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:he_is_coming/he_is_coming.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:ui/src/compendium.dart';
import 'package:ui/src/extensions.dart';
import 'package:ui/src/style.dart';

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
        .map((enemy) => Battle.resolve(first: player, second: enemy))
        .toList();

    if (state.level == Level.end) {
      // End only has one boss which you can never defeat, so instead
      // show the number of turns it took and how much dmg you did.
      if (results.length != 1) {
        throw StateError('Expected exactly one result for the end boss.');
      }
      final result = results.single;
      final turns = result.turns;
      final damage = -result.secondDelta.hp;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreatureName(creature: result.second),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              text: 'Damage Done: ',
              children: <TextSpan>[
                TextSpan(
                  text: '$damage',
                  style: const TextStyle(color: Palette.attack),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              text: 'Turn Counter: ',
              children: <TextSpan>[
                TextSpan(
                  text: '$turns',
                  style: const TextStyle(color: Palette.speed),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: results.map((result) {
        final change = result.firstDelta;
        final survived = result.first.isAlive;
        final diedIcon = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            Symbols.skull,
            color: Palette.attack,
            size: Style.inlineStatIconSize.border,
          ),
        );
        return Row(
          children: [
            CreatureName(creature: result.second),
            const Spacer(),
            if (survived) ..._battleDelta(change),
            if (!survived) diedIcon,
          ],
        );
      }).toList(),
    );
  }
}

/// Text Field for setting the build state from a string.
class CodeField extends StatefulWidget {
  /// CodeField constructor
  const CodeField({
    required this.data,
    required this.state,
    required this.changeState,
    super.key,
  });

  /// Data
  final Data data;

  /// BuildState
  final BuildState state;

  /// Callback to change the build state
  final void Function(BuildState) changeState;

  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
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

  @override
  void didUpdateWidget(CodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateFromState(widget.state);
    }
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

  @override
  Widget build(BuildContext context) {
    return Form(
      autovalidateMode: AutovalidateMode.always,
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
            final state = BuildStateCodec.tryDecode(value, widget.data);
            if (state == null) {
              return;
            }
            _updateFromState(state);
            widget.changeState(state);
          },
        ),
      ),
    );
  }
}

/// Helper for managing the battle state changes.  Lets callers speak in terms
/// of changes to single items, and turns those into a full state change.
/// Takes a callback to apply the state change.
class BattleStateController {
  /// Creates a new BattleStateController
  BattleStateController({
    required this.data,
    required this.state,
    required this.changeState,
  });

  /// Data
  final Data data;

  /// BuildState
  final BuildState state;

  /// Callback to apply the state change
  final void Function(BuildState) changeState;

  /// Level from the build state
  Level get level => state.level;

  /// Inventory from the build state
  Inventory get inventory => state.inventory;

  /// Set the inventory
  void setInventory(Inventory inventory) {
    changeState(BuildState(level: level, inventory: inventory));
  }

  /// Set the items
  void setItems(List<Item> items) {
    setInventory(
      inventory.copyWith(level: level, items: items, setBonuses: data.sets),
    );
  }

  /// Set the level
  void setLevel(Level level) {
    changeState(BuildState(level: level, inventory: inventory));
  }

  /// Re-roll the inventory
  void reroll() {
    setInventory(Inventory.random(level, Random(), data));
  }

  /// Add an item to the inventory
  void addItem(Item item) {
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
    setItems(newItems);
  }

  /// Remove an item from the inventory
  void removeItemAtIndex(int index) {
    setItems(inventory.items.toList()..removeAt(index));
  }
}

/// Displays a control to switch between levels.
class LevelSwitcher extends StatelessWidget {
  /// LevelSwitcher constructor
  const LevelSwitcher({
    required this.level,
    required this.setLevel,
    super.key,
  });

  /// Level
  final Level level;

  /// Callback to set the level
  final void Function(Level) setLevel;

  @override
  Widget build(BuildContext context) {
    return NesIterableOptions<Level>(
      values: Level.values,
      onChange: setLevel,
      optionBuilder: (context, level) => Text(
        level.name,
        style: const TextStyle(color: Palette.white),
      ),
      value: level,
    );
  }
}

/// Widget for editing the player's inventory.
class PlayerEditor extends StatelessWidget {
  /// PlayerEditor constructor
  const PlayerEditor({
    required this.controller,
    super.key,
  });

  /// BattleStateController passed in by the parent.
  final BattleStateController controller;

  Data get _data => controller.data;
  BuildState get _state => controller.state;
  Inventory get _inventory => controller.inventory;
  Level get _level => controller.level;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PlayerBattleView(
          inventory: _inventory,
          level: _level,
          clearItem: controller.removeItemAtIndex,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AddItem(
              data: _data,
              addItem: controller.addItem,
            ),
            ElevatedButton.icon(
              onPressed: controller.reroll,
              icon: const Icon(Icons.casino),
              label: const Text('Reroll'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CodeField(
          data: _data,
          state: _state,
          changeState: controller.changeState,
        ),
      ],
    );
  }
}

/// BattlePage widget
class BattlePage extends StatelessWidget {
  /// BattlePage constructor
  const BattlePage({required this.data, required this.state, super.key});

  /// Data
  final Data data;

  /// BuildState
  final BuildState state;

  BattleStateController _stateController(BuildContext context) =>
      BattleStateController(
        state: state,
        data: data,
        changeState: (state) {
          final encoded = BuildStateCodec.encode(state, data);
          context.goNamed(
            'battle',
            pathParameters: {BuildStateCodec.parameterName: encoded},
          );
        },
      );

  /// Level from the build state
  Level get _level => state.level;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            SizedBox(
              width: 300,
              child: LevelSwitcher(
                level: _level,
                setLevel: _stateController(context).setLevel,
              ),
            ),
            Wrap(
              children: <Widget>[
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 500, minWidth: 400),
                  child: PlayerEditor(controller: _stateController(context)),
                ),
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 500, minWidth: 400),
                  child: EnemyResults(state: state, data: data),
                ),
              ],
            ),
          ],
        ),
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
    final rarityIcon = widget.item.rarityIcon;
    final name = ItemName(item: widget.item, controller: controller);
    if (widget.action == null) {
      return name;
    }
    return MouseRegion(
      onEnter: (_) => setState(() => opacity = 1),
      onExit: (_) => setState(() => opacity = 0),
      child: Row(
        children: <Widget>[
          rarityIcon,
          const SizedBox(width: 6),
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
                padding: const EdgeInsets.all(4),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ...inventory.oils.map((oil) {
                    return OilIconWithTooltip(oil: oil);
                  }),
                  if (edge != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: EdgeName(edge: edge),
                    ),
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

/// Wraps a widget with a gesture detector that shows a tooltip.
class CatalogTooltip extends StatelessWidget {
  /// CatalogTooltip constructor
  const CatalogTooltip({
    required this.maxWidth,
    required this.child,
    required this.tooltipChild,
    this.controller,
    super.key,
  });

  /// Maximum width of the tooltip
  final double maxWidth;

  /// Child widget
  final Widget child;

  /// Tooltip child widget
  final Widget tooltipChild;

  /// Tooltip controller
  final SuperTooltipController? controller;

  @override
  Widget build(BuildContext context) {
    return SuperTooltip(
      controller: controller,
      content: SizedBox(width: maxWidth, child: tooltipChild),
      child: child,
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
    return CatalogTooltip(
      maxWidth: 300,
      tooltipChild: ItemView(item: item),
      controller: controller,
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
    return CatalogTooltip(
      maxWidth: 400,
      tooltipChild: CreatureView(creature: creature),
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
    return CatalogTooltip(
      maxWidth: 300,
      tooltipChild: EdgeView(edge: edge),
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
    return CatalogTooltip(
      maxWidth: 200,
      tooltipChild: OilView(oil: oil),
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
    return CatalogTooltip(
      maxWidth: 300,
      tooltipChild: SetBonusView(setBonus: set),
      child: Text(set.name),
    );
  }
}
