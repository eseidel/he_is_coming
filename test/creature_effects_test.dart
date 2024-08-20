import 'package:he_is_coming/src/battle.dart';
import 'package:he_is_coming/src/creature.dart';
import 'package:he_is_coming/src/creature_catalog.dart';
import 'package:he_is_coming/src/item.dart';
import 'package:he_is_coming/src/item_catalog.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

BattleResult doBattle({required Creature first, required Creature second}) {
  final logger = _MockLogger();
  return runWithLogger(
    logger,
    () => Battle.resolve(first: first, second: second),
  );
}

void main() {
  runWithLogger(_MockLogger(), () {
    initItemCatalog();
    initCreatureCatalog();
  });

  test('Spider Level 1 effect', () {
    final player = createPlayer();
    expect(player.hp, 10);
    final enemy = creatureCatalog['Spider Level 1'];
    final result = doBattle(first: player, second: enemy);
    // Spider is faster than us so should do 3 damage on battle start.
    // And then hit 3 more times (since it goes first).
    expect(result.first.hp, 4);
    expect(result.winner, result.first);

    final player2 = createPlayer(intrinsic: const Stats(speed: 3));
    final result2 = doBattle(first: player2, second: enemy);
    // We are the same speed as the spider so it doesn't get the bonus damage
    // and only hits twice (we kill it before it can hit a third time).
    expect(result2.first.hp, 8);
  });
}
