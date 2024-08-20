import 'dart:math';

import 'package:collection/collection.dart';
import 'package:he_is_coming/src/battle.dart';
import 'package:he_is_coming/src/creature.dart';
import 'package:he_is_coming/src/creature_catalog.dart';
import 'package:he_is_coming/src/item.dart';
import 'package:he_is_coming/src/item_catalog.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:scoped_deps/scoped_deps.dart';

List<Item> _pickItems(Random random, int count) {
  final items = <Item>[];
  var hasWeapon = false;
  while (items.length < count) {
    final item = itemCatalog.items[random.nextInt(itemCatalog.items.length)];
    if (item.kind == Kind.weapon) {
      if (hasWeapon) continue;
      hasWeapon = true;
    }
    if (item.isUnique && items.any((i) => i.name == item.name)) continue;
    items.add(item);
  }
  return items;
}

void _runBattle(Random random, BattleStats stats) {
  // Pick a random set of items.
  final player = createPlayer(withItems: _pickItems(random, 7));

  // Battle against the abomination.
  final abomination = creatureCatalog['Woodland Abomination'];
  final result = Battle.resolve(first: player, second: abomination);
  if (result.first.isAlive) {
    logger.warn('Player won!?');
  }
  stats.recordItems(player.items, result, abomination);
}

class BattleStats {
  final itemValues = <String, List<int>>{};
  int bestValue = 0;
  List<Item> bestItems = [];

  Map<String, double> get averages {
    final averages = <String, double>{};
    for (final entry in itemValues.entries) {
      final sum = entry.value.reduce((a, b) => a + b);
      averages[entry.key] = sum / entry.value.length;
    }
    return averages;
  }

  void recordItems(List<Item> items, BattleResult result, Creature enemy) {
    // Record the number of turns those items survived for.
    // Can either look at # of turns survived or total damage dealt.
    // final value = result.turns;
    final value = enemy.baseStats.maxHp - result.second.hp;
    if (value > bestValue) {
      bestValue = value;
      bestItems = items;
    }

    for (final item in items) {
      itemValues.putIfAbsent(item.name, () => []).add(value);
    }
  }
}

void doMain(List<String> arguments) {
  initItemCatalog();
  initCreatureCatalog();

  final random = Random();
  final stats = BattleStats();

  for (var i = 0; i < 10000; i++) {
    _runBattle(random, stats);
  }

  // Figure out the items which survived the longest on average.
  final itemAverages = stats.averages.entries.toList()
    ..sortBy<num>((e) => e.value);

  for (final entry in itemAverages) {
    logger.info('${entry.key}: ${entry.value.toStringAsFixed(1)}');
  }

  logger
    ..info('---')
    ..info('Best item set:');
  for (final item in stats.bestItems) {
    logger.info(item.name);
  }
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
