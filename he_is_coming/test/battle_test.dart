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

  test('Infinite battle', () {
    final healOnHit = onHit((c) => c.restoreHealth(1));
    final item = Item.test(effect: healOnHit);
    final player = createPlayer(items: [item]);
    final enemy = makeEnemy(attack: 1, health: 5, effect: healOnHit);
    final result = doBattle(first: player, second: enemy);
    // Stuck battles result in player wins.
    expect(result.first.hp, 10);
    expect(result.second.hp, 0);
  });
}
