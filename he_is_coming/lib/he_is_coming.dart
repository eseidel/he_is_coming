import 'package:he_is_coming/src/battle.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/logger.dart';

export 'package:he_is_coming/src/creature_config.dart';
export 'package:he_is_coming/src/data.dart';
export 'package:he_is_coming/src/logger.dart';
export 'package:scoped_deps/scoped_deps.dart';

/// Simulate one game with a player.
void runSim() {
  final data = Data.load();
  Creature.defaultPlayerWeapon = data.items['Wooden Stick'];

  // final items = [
  //   'Heart Drinker',
  //   'Horned Helmet',
  //   'Iron Rose',
  //   'Crimson Cloak',
  //   'Impressive Physique',
  //   'Iron Transfusion',
  //   'Tree Sap',
  //   'Sapphire Earing',
  //   'Emerald Earing',
  // ];
  // const edge = 'Jagged Edge';
  // final oils = [
  //   'Speed Oil',
  // ];

  final items = [
    'Granite Hammer',
    'Elderwood Necklace',
    'Iron Transfusion',
    'Iron Transfusion',
    'Iron Transfusion',
    'Plated Helmet',
    'Iron Transfusion',
  ];
  const edge = 'Bleeding Edge';
  final oils = [
    'Attack Oil',
    'Armor Oil',
    'Speed Oil',
  ];
  final player = createPlayer(
    items: items.map((name) => data.items[name]).toList(),
    edge: data.edges[edge],
    oils: oils.map((name) => data.oils[name]).toList(),
  );
  final enemy = data.creatures['Woodland Abomination'];

  // final player = createPlayer(items: [data.items['Stone Steak']]);
  // final enemy = data.creatures['Spider Level 1'];

  final result = Battle.resolve(first: player, second: enemy, verbose: true);
  final winner = result.winner;
  final damageTaken = winner.baseStats.maxHp - winner.hp;
  logger.info('${result.winner.name} wins in ${result.turns} turns with '
      '$damageTaken damage taken.');
}
