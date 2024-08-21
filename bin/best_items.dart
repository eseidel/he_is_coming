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

List<Player> _seedPopulation(Random random, int count) {
  final population = <Creature>[];
  for (var i = 0; i < count; i++) {
    population.add(createPlayer(withItems: _pickItems(random, 7)));
  }
  return population;
}

class RunResult {
  RunResult({required this.turns, required this.damage, required this.player});

  RunResult.empty()
      : turns = 0,
        damage = 0,
        player = Creature(name: 'Empty', intrinsic: const Stats(), gold: 0);

  final int turns;
  final int damage;
  final Creature player;
}

RunResult _doBattle({required Creature player, required Creature enemy}) {
  final result = Battle.resolve(first: player, second: enemy);
  return RunResult(
    turns: result.turns,
    damage: enemy.baseStats.maxHp - result.second.hp,
    player: player,
  );
}

List<Player> pop = [];

List<Player> _crossover(List<Player> parents, Random random) {
  final children = <Player>[];
  for (var i = 0; i < parents.length; i++) {
    final parent1 = parents[random.nextInt(parents.length)];
    final parent2 = parents[random.nextInt(parents.length)];
    final childItems = <Item>[];
    // Assume items are always the same length.
    for (var j = 0; j < parent1.items.length; j++) {
      final item = random.nextBool() ? parent1.items[j] : parent2.items[j];
      childItems.add(item);
    }
    try {
      children.add(createPlayer(withItems: childItems));
    } on ItemException {
      continue;
    }
  }
  return children;
}

void logResult(RunResult result) {
  logger.info('${result.damage} damage ${result.turns} turns:');
  for (final item in result.player.items) {
    logger.info('  ${item.name}');
  }
}

void doMain(List<String> arguments) {
  initItemCatalog();
  initCreatureCatalog();

  final random = Random();
  const rounds = 10;
  const populationSize = 1000;
  final survivorsCount = (populationSize * 0.1).ceil();
  var pop = _seedPopulation(random, populationSize);
  late List<RunResult> bestResults;

  for (var i = 0; i < rounds; i++) {
    final enemy = creatureCatalog['Woodland Abomination'];
    final results =
        pop.map((player) => _doBattle(player: player, enemy: enemy));
    // Select the top 10% of the population.
    final sorted = results.toList()..sortBy<num>((r) => -r.damage);
    bestResults = sorted.sublist(0, survivorsCount);
    final survivors = bestResults.map((r) => r.player).toList();
    // children can be shorter than survivors currently.
    final children = _crossover(survivors, random);
    final remaining = populationSize - survivors.length - children.length;
    pop = [
      ...survivors,
      ...children,
      ..._seedPopulation(random, remaining),
    ];
    logger.info('Round $i');
    logResult(bestResults.first);
  }
  // Print the bestResults in order of damage dealt.
  bestResults.sortBy<num>((r) => -r.damage);
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
