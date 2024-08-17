import 'package:he_is_coming_sim/src/battle.dart';
import 'package:he_is_coming_sim/src/creatures.dart';
import 'package:he_is_coming_sim/src/item_catalog.dart';
import 'package:he_is_coming_sim/src/logger.dart';

/// Simulate one game with a player.
void runSim() {
  // This is mostly a placeholder for now.

  final player = createPlayer(withItems: [itemCatalog['Stone Steak']]);
  final wolf = Enemies.wolfLevel1;

  final battle = Battle();
  final result = battle.resolve(first: player, second: wolf);
  logger.info('${result.winner.name} wins!');

  // Create a new Game
  // Simulate it until the player dies?
  // Print the results.
}
