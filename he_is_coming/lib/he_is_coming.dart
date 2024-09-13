import 'package:he_is_coming/he_is_coming.dart';

export 'package:he_is_coming/src/battle.dart';
export 'package:he_is_coming/src/build_id.dart';
export 'package:he_is_coming/src/data.dart';
export 'package:he_is_coming/src/inventory.dart';
export 'package:he_is_coming/src/logger.dart';
export 'package:scoped_deps/scoped_deps.dart';

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

/// Simulate one game with a player.
void runSim() {
  final data = Data.load();
  Creature.defaultPlayerWeapon = data.items['Wooden Stick'];

  final items = [
    'Gemstone Scepter',
    'Horned Helmet',
    'Golden Sapphire Earring',
    'Boots of the Hero',
    'Golden Leather Glove',
    'Golden Emerald Earring',
    'Emerald Earring',
    'Pinecone Plate',
    'Sapphire Ring',
  ];
  const edge = 'Bleeding Edge';
  final oils = [
    'Attack Oil',
    'Armor Oil',
  ];
  final player = data.player(items: items, edge: edge, oils: oils);
  final enemy = data.creatures['Woodland Abomination'];

  final result = Battle.resolve(first: player, second: enemy, verbose: true);
  _logMissingEffects(result.first.inventory!);
  final winner = result.winner;
  final damageTaken = winner.baseStats.maxHp - winner.hp;
  logger.info('${result.winner.name} wins in ${result.turns} turns with '
      '$damageTaken damage taken.');
  final state = BuildState(level: player.level, inventory: player.inventory!);
  final encoded = BuildStateCodec.encode(state, data);
  logger.info('Build Id: $encoded');
  final decoded = BuildStateCodec.tryDecode(encoded, data);
  logger.info('Decoded: $decoded');
}
