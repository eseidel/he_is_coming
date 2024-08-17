import 'package:he_is_coming_sim/src/battle.dart';
import 'package:he_is_coming_sim/src/creatures.dart';
import 'package:he_is_coming_sim/src/item_catalog.dart';
import 'package:he_is_coming_sim/src/logger.dart';

/// Simulate one game with a player.
void runSim() {
  final player = createPlayer(withItems: [itemCatalog['Stone Steak']]);
  final wolf = Enemies.wolfLevel1;

  final result = Battle.resolve(first: player, second: wolf);
  logger.info('${result.winner.name} wins!');
}
