import 'package:he_is_coming/he_is_coming.dart';

void _logMissingEffects(Inventory inventory) {
  void logMissing(List<CatalogItem> items) {
    final missingEffects = items.where((item) => !item.isImplemented).toList();
    for (final item in missingEffects) {
      final effect = item.effect;
      logger.warn('Missing $effect for ${item.name}');
    }
  }

  logMissing(inventory.items);
  logMissing(inventory.oils);
  if (inventory.edge != null) {
    logMissing([inventory.edge!]);
  }
  logMissing(inventory.sets);
}

BuildState defaultState(Data data) {
  // https://discord.com/channels/1041414829606449283/1209488593219756063/1283944376069787710
  final items = [
    'Haymaker',
    'Blacksmith Bond',
    'Cracked Whetstone',
    'Explosive Surprise',
    'Golden Leather Vest',
    'Leather Glove',
    'Leather Boots',
    'Golden Ruby Ring',
    'Cracked Bouldershield',
  ];
  const edge = 'Lightning Edge';
  final oils = [
    'Attack Oil',
    'Armor Oil',
    'Speed Oil',
  ];
  const level = Level.end;
  final inventory = Inventory.fromNames(
    items: items,
    edge: edge,
    oils: oils,
    level: level,
    data: data,
  );
  return BuildState(level: level, inventory: inventory);
}

/// Simulate one game with a player.
void runSim(Data data, BuildState state) {
  final player = playerFromState(state);
  final enemy = data.creatures['Woodland Abomination'];

  final result = Battle.resolve(first: player, second: enemy, verbose: true);
  _logMissingEffects(result.first.inventory!);
  final winner = result.winner;
  final damageTaken = winner.baseStats.maxHp - winner.hp;
  logger.info('${result.winner.name} wins in ${result.turns} turns with '
      '$damageTaken damage taken.');
  final encoded = BuildStateCodec.encode(state, data);
  logger.info('Build Id: $encoded');
}

int doMain(List<String> arguments) {
  final data = Data.load();
  final buildId = arguments.firstOrNull;
  final BuildState state;
  if (buildId != null) {
    final maybeState = BuildStateCodec.tryDecode(buildId, data);
    if (maybeState == null) {
      logger.err('Invalid build ID: $buildId');
      return 1;
    }
    state = maybeState;
  } else {
    state = defaultState(data);
  }
  runSim(data, state);
  return 0;
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
