import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:he_is_coming/src/battle.dart';
import 'package:he_is_coming/src/creature.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/item.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:scoped_deps/scoped_deps.dart';

List<Item> _pickItems(Random random, int count, ItemCatalog itemCatalog) {
  final items = <Item>[
    itemCatalog.randomWeapon(random),
  ];
  while (items.length < count) {
    final item = itemCatalog.randomNonWeapon(random);
    if (item.isUnique && items.any((i) => i.name == item.name)) continue;
    items.add(item);
  }
  return items;
}

List<Player> _seedPopulation(
  Random random,
  int count,
  ItemCatalog itemCatalog,
) {
  final population = <Creature>[];
  for (var i = 0; i < count; i++) {
    population.add(
      createPlayer(withItems: _pickItems(random, 7, itemCatalog)),
    );
  }
  return population;
}

class CreatureConfig {
  CreatureConfig(this.items);

  factory CreatureConfig.fromJson(Map<String, dynamic> json) {
    final itemNames = (json['items'] as List).cast<String>();
    final items = itemNames.map<Item>((n) => data.items[n]).toList();
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
    if (parent1.items.length != parent2.items.length) {
      throw StateError(
        'Parents must have the same number of items: '
        '${parent1.items} vs ${parent2.items}',
      );
    }
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
  data = Data.load();

  final random = Random();
  const rounds = 1000;
  const populationSize = 1000;
  final survivorsCount = (populationSize * 0.1).ceil();
  const mutationRate = 0.01;
  const filePath = 'results.json';
  final saved = Population.fromFile(filePath);
  logger.info('Loaded ${saved.configs.length} saved configs.');

  List<Creature> pop;
  if (saved.configs.isNotEmpty) {
    pop = saved.configs.map(playerForConfig).toList();
  } else {
    pop = _seedPopulation(random, populationSize, data.items);
  }
  late List<RunResult> bestResults;

  for (var i = 0; i < rounds; i++) {
    final enemy = data.creatures['Woodland Abomination'];
    final results =
        pop.map((player) => _doBattle(player: player, enemy: enemy));
    // Select the top 10% of the population.
    final sorted = results.toList()..sortBy<num>((r) => -r.damage);
    bestResults = sorted.sublist(0, survivorsCount);
    final survivors = bestResults.map((r) => r.player).toList();
    // children can be shorter than survivors currently.
    pop = [
      ...survivors.take(2),
      ..._crossover(survivors, random),
    ];
    // Mutate some of the children.
    for (var j = 0; j < pop.length; j++) {
      if (random.nextDouble() < mutationRate) {
        final mutated = pop[j].items.toList();
        final index = random.nextInt(mutated.length);
        if (index == 0) {
          mutated[index] = data.items.randomWeapon(random);
        } else {
          mutated[index] = data.items.randomNonWeapon(random);
        }
        try {
          pop[j] = createPlayer(withItems: mutated);
        } on ItemException {
          continue;
        }
      }
    }

    pop.addAll(
      _seedPopulation(random, populationSize - pop.length, data.items),
    );
    logger.info('Round $i');
    for (final result in bestResults.take(3)) {
      logResult(result);
    }
  }
  Population.fromPlayers(pop).save(filePath);
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
