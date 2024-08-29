import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:he_is_coming/src/battle.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:scoped_deps/scoped_deps.dart';

extension<T> on List<T> {
  T pickOne(Random random) => this[random.nextInt(length)];
}

class RunResult {
  RunResult({required this.turns, required this.damage, required this.player});

  factory RunResult.fromJson(Map<String, dynamic> json, Data data) {
    final config = Inventory.fromJson(
      json['config'] as Map<String, dynamic>,
      Level.end, // Hard coding for now.
      data,
    );
    return RunResult(
      turns: json['turns'] as int,
      damage: json['damage'] as int,
      player: playerWithInventory(config),
    );
  }

  RunResult.empty()
      : turns = 0,
        damage = 0,
        player = Creature(
          name: 'Empty',
          intrinsic: const Stats(),
          inventory: Inventory.empty(),
          gold: 0,
          level: Level.one,
        );

  final int turns;
  final int damage;
  final Creature player;

  Map<String, dynamic> toJson() {
    return {
      'turns': turns,
      'damage': damage,
      'config': player.inventory!.toJson(),
    };
  }
}

RunResult _doBattle({required Creature player, required Creature enemy}) {
  final result = Battle.resolve(first: player, second: enemy);
  return RunResult(
    turns: result.turns,
    damage: result.secondDelta.hp,
    player: player,
  );
}

class Population {
  Population(this.configs);

  factory Population.fromFile(String path, Data data) {
    if (!File(path).existsSync()) {
      return Population([]);
    }
    final contents = File(path).readAsStringSync();
    final json = jsonDecode(contents);
    return Population.fromJson(json, Level.end, data);
  }

  factory Population.fromJson(dynamic json, Level level, Data data) {
    final results = (json as List)
        .map<Inventory>(
          (r) => Inventory.fromJson(r as Map<String, dynamic>, level, data),
        )
        .toList();
    return Population(results);
  }

  void save(String path) {
    final json = jsonEncode(configs.map((c) => c.toJson()).toList());
    File(path).writeAsStringSync(json);
  }

  final List<Inventory> configs;
}

void logConfig(Inventory config) {
  logger.info('Items:');
  for (final item in config.items) {
    logger.info('  ${item.name}');
  }
  if (config.edge != null) {
    logger.info('Edge: ${config.edge!.name}');
  }
  logger.info('Oils:');
  for (final oil in config.oils) {
    logger.info('  ${oil.name}');
  }
}

void logResult(RunResult result) {
  logger.info('${result.damage} damage ${result.turns} turns:');
  logConfig(result.player.inventory!);
}

class BestItemFinder {
  BestItemFinder(this.data);

  final Data data;

  final level = Level.end;
  final random = Random();
  final populationSize = 1000;
  final survivalRate = 0.1;
  final mutationRate = 0.01;

  List<Inventory> _seedPopulation(
    Random random,
    int count,
    Data data,
  ) {
    final population = <Inventory>[];
    for (var i = 0; i < count; i++) {
      population.add(Inventory.random(level, random, data));
    }
    return population;
  }

  List<Inventory> _crossover(
    List<Inventory> parents,
    Random random,
  ) {
    final children = <Inventory>[];
    for (var i = 0; i < parents.length; i++) {
      final parent1 = parents.pickOne(random);
      final parent2 = parents.pickOne(random);

      final edge = random.nextBool() ? parent1.edge : parent2.edge;
      final oils = random.nextBool() ? parent1.oils : parent2.oils;
      final items = <Item>[];
      if (parent1.items.length != parent2.items.length) {
        throw StateError(
          'Parents must have the same number of items: '
          '${parent1.items} vs ${parent2.items}',
        );
      }
      for (var j = 0; j < parent1.items.length; j++) {
        final item = random.nextBool() ? parent1.items[j] : parent2.items[j];
        items.add(item);
      }
      try {
        children
            .add(Inventory(level: level, items: items, edge: edge, oils: oils));
      } on ItemException {
        continue;
      }
    }
    return children;
  }

  Inventory _mutate(
    Inventory config,
    Random random,
    double mutationRate,
  ) {
    if (random.nextDouble() > mutationRate) {
      return config;
    }
    final mutated = config.items.toList();
    final index = random.nextInt(mutated.length);
    if (index == 0) {
      mutated[index] = data.items.randomWeapon(random);
    } else {
      mutated[index] = data.items.randomNonWeapon(random);
    }
    try {
      return Inventory(
        level: level,
        items: mutated,
        edge: config.edge,
        oils: config.oils,
      );
    } on ItemException {
      return config;
    }
  }

  List<Inventory> run(List<Inventory> initial, int rounds) {
    late List<RunResult> bestResults;
    final survivorsCount = (populationSize * survivalRate).ceil();
    var pop = initial.toList();

    for (var i = 0; i < rounds; i++) {
      final fillSize = min(populationSize - pop.length, 0);
      pop.addAll(_seedPopulation(random, fillSize, data));

      final enemy = data.creatures['Woodland Abomination'];
      final results = pop.map(
        (inventory) =>
            _doBattle(player: playerWithInventory(inventory), enemy: enemy),
      );
      // Select the top 10% of the population.
      final sorted = results.toList()..sortBy<num>((r) => -r.damage);
      bestResults = sorted.sublist(0, survivorsCount);
      final survivors = bestResults.map((r) => r.player.inventory!).toList();
      pop = [
        ...survivors.take(2),
        ..._crossover(survivors, random),
      ];
      // Mutate some of the children.
      pop = pop.map((c) => _mutate(c, random, mutationRate)).toList();

      logger.info('Round $i');
      for (final result in bestResults.take(3)) {
        logResult(result);
      }
    }
    return pop;
  }
}

void doMain(List<String> arguments) {
  final data = Data.load();
  Creature.defaultPlayerWeapon = data.items['Wooden Stick'];
  data
    ..removeEntriesMissingEffects()
    ..removeInferredItems();

  const filePath = 'results.json';
  final saved = Population.fromFile(filePath, data);
  logger.info('Loaded ${saved.configs.length} saved configs.');

  final pop = saved.configs.toList();
  final finder = BestItemFinder(data);
  const rounds = 1000;
  final newPop = finder.run(pop, rounds);

  Population(newPop).save(filePath);
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
