import 'package:he_is_coming/src/battle.dart';
import 'package:he_is_coming/src/creature.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/logger.dart';

/// Simulate one game with a player.
void runSim() {
  data = Data.load();

  final items = [
    'Granite Hammer',
    'Elderwood Necklace',
    'Iron Transfusion',
    'Iron Transfusion',
    'Iron Transfusion',
    'Plated Helmet',
    'Iron Transfusion',
  ].map((name) => data.items[name]).toList();
  final edge = data.edges['Bleeding Edge'];
  final oils = [
    data.oils['Attack Oil'],
    data.oils['Armor Oil'],
    data.oils['Speed Oil'],
  ];
  final player = createPlayer(items: items, edge: edge, oils: oils);
  final enemy = data.creatures['Woodland Abomination'];

  // final player = createPlayer(items: [data.items['Stone Steak']]);
  // final enemy = data.creatures['Spider Level 1'];

  final result = Battle.resolve(first: player, second: enemy, verbose: true);
  final winner = result.winner;
  final damageTaken = winner.baseStats.maxHp - winner.hp;
  logger.info('${result.winner.name} wins in ${result.turns} turns with '
      '$damageTaken damage taken.');
}
