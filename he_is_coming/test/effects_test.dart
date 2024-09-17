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

  test('Non-bosses give gold', () {
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

  test('Bosses do not give gold', () {
    final player = data.player();
    expect(player.hp, 10);
    expect(player.gold, 0);

    final enemy = makeEnemy(attack: 1, health: 6, isBoss: true);
    expect(enemy.gold, 0);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 5);
    // No gold from bosses.
    expect(result.first.gold, 0);
  });

  test('Edge triggers after weapon before other items', () {
    final orderedTriggers = <String>[];
    final player = data.player(
      customEdge: Edge.test(effect: onHit((c) => orderedTriggers.add('edge'))),
      customItems: [
        Item.test(
          isWeapon: true,
          attack: 1,
          effect: onHit((c) => orderedTriggers.add('weapon')),
        ),
        Item.test(
          effect: onHit((c) => orderedTriggers.add('item')),
        ),
      ],
    );
    final enemy = makeEnemy(attack: 10, health: 6);
    // Enemy dies in one hit.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 0);
    expect(result.second.hp, 5);
    expect(orderedTriggers, ['weapon', 'edge', 'item']);
  });

  test('Check for Death after every trigger', () {
    final player = data.player(
      customItems: [Item.test(effect: onTakeDamage((c) => c.restoreHealth(1)))],
    );
    final enemy = makeEnemy(attack: 10, health: 6);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 0);
    expect(result.second.hp, 5);
  });
}
