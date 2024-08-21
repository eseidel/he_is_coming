import 'dart:convert';
import 'dart:io';
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

class CreatureConfig {
  CreatureConfig(this.items);

  factory CreatureConfig.fromJson(Map<String, dynamic> json) {
    final itemNames = (json['items'] as List).cast<String>();
    final items = itemNames.map<Item>((n) => itemCatalog[n]).toList();
    return CreatureConfig(items);
  }

  factory CreatureConfig.fromPlayer(Player player) {
    return CreatureConfig(player.items);
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((i) => i.name).toList(),
    };
  }

  final List<Item> items;
}

Player playerForConfig(CreatureConfig config) {
  return createPlayer(withItems: config.items);
}

class RunResult {
  RunResult({required this.turns, required this.damage, required this.player});

  factory RunResult.fromJson(Map<String, dynamic> json) {
    final config =
        CreatureConfig.fromJson(json['config'] as Map<String, dynamic>);
    return RunResult(
      turns: json['turns'] as int,
      damage: json['damage'] as int,
      player: playerForConfig(config),
    );
  }

  RunResult.empty()
      : turns = 0,
        damage = 0,
        player = Creature(name: 'Empty', intrinsic: const Stats(), gold: 0);

  final int turns;
  final int damage;
  final Creature player;

  Map<String, dynamic> toJson() {
    return {
      'turns': turns,
      'damage': damage,
      'config': CreatureConfig.fromPlayer(player).toJson(),
    };
  }
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

class Population {
  Population(this.configs);

  factory Population.fromFile(String path) {
    if (!File(path).existsSync()) {
      return Population([]);
    }
    final contents = File(path).readAsStringSync();
    final json = jsonDecode(contents);
    return Population.fromJson(json);
  }

  factory Population.fromJson(dynamic json) {
    final results = (json as List)
        .map<CreatureConfig>(
          (r) => CreatureConfig.fromJson(r as Map<String, dynamic>),
        )
        .toList();
    return Population(results);
  }

  factory Population.fromPlayers(List<Creature> players) {
    final results = players.map(CreatureConfig.fromPlayer).toList();
    return Population(results);
  }

  void save(String path) {
    final json = jsonEncode(configs.map((c) => c.toJson()).toList());
    File(path).writeAsStringSync(json);
  }

  final List<CreatureConfig> configs;
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
  const rounds = 100;
  const populationSize = 1000;
  final survivorsCount = (populationSize * 0.1).ceil();
  const filePath = 'results.json';
  final saved = Population.fromFile(filePath);

  List<Creature> pop;
  if (saved.configs.isNotEmpty) {
    pop = saved.configs.map(playerForConfig).toList();
  } else {
    pop = _seedPopulation(random, populationSize);
  }
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
  Population.fromPlayers(pop).save(filePath);
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
