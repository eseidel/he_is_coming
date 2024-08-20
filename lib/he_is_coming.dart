import 'package:he_is_coming/src/battle.dart';
import 'package:he_is_coming/src/creature.dart';
import 'package:he_is_coming/src/creature_catalog.dart';
import 'package:he_is_coming/src/item_catalog.dart';
import 'package:he_is_coming/src/logger.dart';

/// Simulate one game with a player.
void runSim() {
  initItemCatalog();
  initCreatureCatalog();

  final player = createPlayer(withItems: [itemCatalog['Stone Steak']]);
  final wolf = creatureCatalog['Wolf Level 1'];

  final result = Battle.resolve(first: player, second: wolf);
  logger.info('${result.winner.name} wins!');
}
