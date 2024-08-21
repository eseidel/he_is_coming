import 'package:he_is_coming/src/battle.dart';
import 'package:he_is_coming/src/creature.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/logger.dart';

/// Simulate one game with a player.
void runSim() {
  data = Data.load();

  final player = createPlayer(withItems: [data.items['Stone Steak']]);
  final wolf = data.creatures['Spider Level 1'];

  final result = Battle.resolve(first: player, second: wolf);
  logger.info('${result.winner.name} wins!');
}
