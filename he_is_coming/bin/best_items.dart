import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:he_is_coming/he_is_coming.dart';

extension<T> on List<T> {
  T pickOne(Random random) => this[random.nextInt(length)];
}

class RunResult {
  RunResult({
    required this.turns,
    required this.damage,
    required this.inventory,
  });

  factory RunResult.fromJson(Map<String, dynamic> json, Data data) {
    final inventory = Inventory.fromJson(
      json['config'] as Map<String, dynamic>,
      Level.end, // Hard coding for now.
      data,
    );
    return RunResult(
      turns: json['turns'] as int,
      damage: json['damage'] as int,
      inventory: inventory,
    );
  }

  RunResult.empty()
      : turns = 0,
        damage = 0,
        inventory = Inventory.empty();

  final int turns;
  final int damage;
  final Inventory inventory;

  Map<String, dynamic> toJson() {
    return {
      'turns': turns,
      'damage': damage,
      'config': inventory.toJson(),
    };
  }
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

class BestItemFinder {
  BestItemFinder(this.data, {this.itemLimits = const {}});

  final Data data;
  final Map<String, int> itemLimits;

  final level = Level.end;
  final random = Random();
  final populationSize = 1000;
  final survivalRate = 0.1;
  final mutationRate = 0.005;

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
      // Should probably pick unique parents?
      final parent1 = parents.pickOne(random);
      final parent2 = parents.pickOne(random);

      final edge = random.nextBool() ? parent1.edge : parent2.edge;
      final oils = random.nextBool() ? parent1.oils : parent2.oils;
      final items = <Item>[];
      assert(
        parent1.items.length == parent2.items.length,
        'Parents must have same number of items.',
      );
      for (var j = 0; j < parent1.items.length; j++) {
        final item = random.nextBool() ? parent1.items[j] : parent2.items[j];
        items.add(item);
      }
      try {
        // Constructor can throw if items break rules (e.g. duplicate unique).
        children.add(
          Inventory(
            level: level,
            items: items,
            edge: edge,
            oils: oils,
            data: data,
          ),
        );
      } on ItemException {
        continue;
      }
    }
    return children;
  }

  Inventory _mutate(
    Inventory inventory,
    Random random,
    double mutationRate,
  ) {
    bool shouldMutate() => random.nextDouble() < mutationRate;

    final mutated = inventory.items.toList();
    for (var i = 0; i < mutated.length; i++) {
      if (!shouldMutate()) {
        continue;
      }
      if (i == 0) {
        mutated[i] = data.items.randomWeapon(random);
      } else {
        mutated[i] = data.items.randomNonWeapon(random);
      }
    }
    final edge = shouldMutate()
        ? data.edges.randomIncludingNull(random)
        : inventory.edge;
    // Oil stats can disrupt certain item effects/combos so use random too.
    final oils = shouldMutate() ? data.oils.randomOils(random) : inventory.oils;
    try {
      // Constructor can throw if items break rules (e.g. duplicate unique).
      return Inventory(
        level: level,
        items: mutated,
        edge: edge,
        oils: oils,
        data: data,
      );
    } on ItemException {
      return inventory;
    }
  }

  List<Inventory> _enforceItemLimits(List<Inventory> population) {
    return population.where((c) {
      for (final entry in itemLimits.entries) {
        // This should move into Inventory.enforceItemLimits for Honeycomb.
        // https://discord.com/channels/1041414829606449283/1209488302269534209/1285467752936640552
        final count = c.items.fold(0, (acc, i) => acc + i.partCount(entry.key));
        if (count > entry.value) {
          return false;
        }
      }
      final craftedCount = c.items.where((i) => i.isCrafted).length;
      // Weapon can't be crafted and last item can't be either, since requires
      // combining two items.
      final craftedLimit = Inventory.itemSlotCount(level) - 2;
      if (craftedCount > craftedLimit) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Inventory> run(List<Inventory> initial, int rounds) {
    late List<RunResult> bestResults;
    final survivorsCount = (populationSize * survivalRate).ceil();
    var pop = initial.toList();
    final enemy = data.creatures['Woodland Abomination'];
    RunResult? bestResult;

    RunResult doBattle(Inventory inventory) {
      final player =
          playerFromState(BuildState(level: level, inventory: inventory));

      final BattleResult result;
      try {
        result = Battle.resolve(first: player, second: enemy);
      } on Exception catch (e, stackTrace) {
        logger
          ..err('Failed to resolve battle: $e')
          ..info('$stackTrace')
          ..info('Inventory: $inventory');
        exit(1);
      }
      return RunResult(
        turns: result.turns,
        damage: -result.secondDelta.hp,
        inventory: inventory,
      );
    }

    for (var i = 0; i < rounds; i++) {
      // Fill in any missing population with random.
      final fillSize = max(populationSize - pop.length, 0);
      pop.addAll(_seedPopulation(random, fillSize, data));
      // Remove any population who exceed item limits.
      pop = _enforceItemLimits(pop);

      final sorted = pop.map(doBattle).toList()..sortBy<num>((r) => -r.damage);
      // Select the top survivorRate of the population.
      bestResults = sorted.sublist(0, survivorsCount);
      bestResult = bestResults.firstOrNull;
      final survivors = bestResults.map((r) => r.inventory).toList();
      pop = [
        // Best comes back every round.
        if (bestResult != null) bestResult.inventory,
        // Keep the best survivors.
        ...survivors.take(2),
        // Crossover the survivors.
        ..._crossover(survivors, random),
        // And apply mutations.
      ].map((c) => _mutate(c, random, mutationRate)).toList();

      logger.info('Round $i');
      for (final result in bestResults.take(3)) {
        logResult(result);
      }
    }
    return pop;
  }

  void logResult(RunResult result) {
    logger.info('${result.damage} damage ${result.turns} turns:');
    logBuildState(BuildState(inventory: result.inventory, level: level), data);
  }
}

void doMain(List<String> arguments) {
  final data = Data.load().withoutMissingEffects().withoutInferredItems();

  const filePath = 'results.json';
  final saved = Population.fromFile(filePath, data);
  logger.info('Loaded ${saved.configs.length} saved configs.');

  final pop = saved.configs.toList();
  final finder = BestItemFinder(
    data,
    itemLimits: {
      // Game currently only allows you to find one Honeycomb per run.
      'Honeycomb': 1,
    },
  );
  const rounds = 1000;
  final newPop = finder.run(pop, rounds);

  Population(newPop).save(filePath);
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
