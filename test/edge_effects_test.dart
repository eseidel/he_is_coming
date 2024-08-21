import 'package:he_is_coming/src/battle.dart';
import 'package:he_is_coming/src/creature.dart';
import 'package:he_is_coming/src/data.dart';
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
  runWithLogger(_MockLogger(), () {
    data = Data.load();
  });

  test('Bleeding Edge', () {
    final edge = data.edges['Bleeding Edge'];
    final player = createPlayer(edge: edge);
    final enemy = makeEnemy('Wolf', health: 6, attack: 1);
    final result = doBattle(first: player, second: enemy);
    // Bleeding edge gains 1 health on hit so we regain all the health we lose.
    expect(result.first.hp, 10);
    expect(result.winner, result.first);
  });

  test('Blunt Edge', () {
    final edge = data.edges['Blunt Edge'];
    final player = createPlayer(edge: edge);
    // Wolf is faster than us so it will hit first.
    final enemy = makeEnemy('Wolf', health: 6, attack: 1, speed: 1);
    final result = doBattle(first: player, second: enemy);
    // Blunt edge gains 1 armor on hit so we negate all damage except the first.
    expect(result.first.hp, 9);
    expect(result.winner, result.first);
  });
}
