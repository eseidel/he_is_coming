import 'package:he_is_coming/src/battle.dart';
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

  test('Attack Oil', () {
    final oil = data.oils['Attack Oil'];
    final player = createPlayer(oils: [oil]);
    // One from the oil and one from the Wooden Stick.
    expect(player.baseStats.attack, 2);
  });

  test('Armor Oil', () {
    final oil = data.oils['Armor Oil'];
    final player = createPlayer(oils: [oil]);
    expect(player.baseStats.armor, 1);
  });

  test('Speed Oil', () {
    final oil = data.oils['Speed Oil'];
    final player = createPlayer(oils: [oil]);
    expect(player.baseStats.speed, 1);
  });
}
