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
  final data = runWithLogger(_MockLogger(), Data.load);

  test('Attack Oil', () {
    const oil = 'Attack Oil';
    final player = data.player(oils: [oil]);
    // One from the oil and one from the Wooden Stick.
    expect(player.baseStats.attack, 2);
  });

  test('Armor Oil', () {
    const oil = 'Armor Oil';
    final player = data.player(oils: [oil]);
    expect(player.baseStats.armor, 1);
  });

  test('Speed Oil', () {
    const oil = 'Speed Oil';
    final player = data.player(oils: [oil]);
    expect(player.baseStats.speed, 1);
  });
}
