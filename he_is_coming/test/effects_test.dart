import 'package:he_is_coming/src/battle.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

BattleResult doBattle({
  required Creature first,
  required Creature second,
  bool verbose = false,
}) {
  final logger = verbose ? Logger() : _MockLogger();
  return runWithLogger(
    logger,
    () => Battle.resolve(first: first, second: second, verbose: verbose),
  );
}

void main() {
  final data = runWithLogger(_MockLogger(), Data.load);
  Creature.defaultPlayerWeapon = data.items['Wooden Stick'];

  test('Enemies give gold', () {
    final player = data.player();
    expect(player.hp, 10);
    expect(player.gold, 0);

    final enemy = makeEnemy(attack: 1, health: 6);
    expect(enemy.gold, 1);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 5);
    // Gain one gold at battle end.
    expect(result.first.gold, 1);
  });

  test('Check for Death after every trigger', () {
    final player = data.createPlayer(
      items: [Item.test(effect: onTakeDamage((c) => c.restoreHealth(1)))],
    );
    final enemy = makeEnemy(attack: 10, health: 6);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 0);
    expect(result.second.hp, 5);
  });
}
