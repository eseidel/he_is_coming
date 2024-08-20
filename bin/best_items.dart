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

class RunResult {
  RunResult({required this.turns, required this.dmg, required this.items});

  RunResult.empty()
      : turns = 0,
        dmg = 0,
        items = [];

  final int turns;
  final int dmg;
  List<Item> items;
}

class BattleStats {
  final itemValues = <String, List<int>>{};
  RunResult bestTurns = RunResult.empty();
  RunResult bestDmg = RunResult.empty();

  Map<String, double> get averages {
    final averages = <String, double>{};
    for (final entry in itemValues.entries) {
      final sum = entry.value.reduce((a, b) => a + b);
      averages[entry.key] = sum / entry.value.length;
    }
    return averages;
  }

  void recordItems(List<Item> items, BattleResult result, Creature enemy) {
    // Record the best items we've seen for turns and damage.
    final turns = result.turns;
    final dmg = enemy.baseStats.maxHp - result.second.hp;
    if (result.turns > bestTurns.turns) {
      bestTurns = RunResult(turns: turns, dmg: dmg, items: items);
    }
    if (dmg > bestDmg.dmg) {
      bestDmg = RunResult(turns: turns, dmg: dmg, items: items);
    }

    // Can either look at # of turns survived or total damage dealt.
    final value = dmg;
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
    ..info(
      'Best survivor (${stats.bestTurns.turns} turns,'
      ' ${stats.bestTurns.dmg} damage):',
    );
  for (final item in stats.bestTurns.items) {
    logger.info(item.name);
  }
  logger
    ..info('---')
    ..info('Best damage (${stats.bestDmg.turns} turns,'
        ' ${stats.bestDmg.dmg} damage):');
  for (final item in stats.bestDmg.items) {
    logger.info(item.name);
  }
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
