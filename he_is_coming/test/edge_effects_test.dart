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
  Creature.defaultPlayerWeapon = data.items['Wooden Stick'];

  test('Bleeding Edge', () {
    final player = data.player(edge: 'Bleeding Edge');
    final enemy = makeEnemy(health: 6, attack: 1);
    final result = doBattle(first: player, second: enemy);
    // Bleeding edge gains 1 health on hit so we regain all the health we lose.
    expect(result.first.hp, 10);
  });

  test('Blunt Edge', () {
    final player = data.player(edge: 'Blunt Edge');
    // Wolf is faster than us so it will hit first.
    final enemy = makeEnemy(health: 6, attack: 1, speed: 1);
    final result = doBattle(first: player, second: enemy);
    // Blunt edge gains 1 armor on hit so we negate all damage except the first.
    expect(result.first.hp, 9);
  });

  test('Lightning Edge', () {
    final player = data.player(edge: 'Lightning Edge');
    final enemy = makeEnemy(health: 6, attack: 1);
    final result = doBattle(first: player, second: enemy);
    // Lightning edge stuns the enemy for 1 turn so we take 1 less damage.
    expect(result.first.hp, 6);
  });

  test('Thieving Edge', () {
    final player = data.player(edge: 'Thieving Edge', gold: 8);
    final enemy = makeEnemy(health: 6, attack: 1);
    final result = doBattle(first: player, second: enemy);
    // Thieving edge gains 1 gold on hit if we have less than 10 gold.
    // We gain up to 10 from the edge and then +1 for the wolf kill.
    expect(result.first.gold, 11);
  });

  test('Jagged Edge', () {
    final player = data.player(edge: 'Jagged Edge');
    final enemy = makeEnemy(health: 6, attack: 1);
    final result = doBattle(first: player, second: enemy);
    // Jagged edge gains 2 thorns on hit and takes 1 damage.
    // Wolf after 2 attacks so we take 2 wolf damage and 2 jagged edge damage.
    expect(result.first.hp, 6);
  });

  test('Cutting Edge', () {
    final player = data.player(edge: 'Cutting Edge');
    final enemy = makeEnemy(health: 6, attack: 1);
    final result = doBattle(first: player, second: enemy);
    // Cutting edge deals 1 damage on hit.
    // Effectively gives us +1 attack (not exactly) defeating the Wolf in 3 hits
    // thus only taking 2 damage.
    expect(result.first.hp, 8);
    // "dealDamage" does not trigger thorns, nor is it a strike, but would
    // trigger onTakeDamage, etc.  We could test for that.
  });

  test('Agile Edge', () {
    final player = data.player(edge: 'Agile Edge');
    final enemy = makeEnemy(health: 6, attack: 1);
    final result = doBattle(first: player, second: enemy);
    // Agile edge queues an extra strike for the first turn.
    expect(result.first.hp, 6);
  });

  test('Featherweight Edge', () {
    const edge = 'Featherweight Edge';
    final player = data.player(speed: 2, maxHp: 10, edge: edge);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 1);
    expect(player.baseStats.speed, 2);
    final enemy = makeEnemy(health: 12, attack: 1);
    final result = doBattle(first: player, second: enemy);
    // On the first and second turns we convert 1 speed to 1 attack.
    // So we hit for 1, 2, 3, 3, 3 and kill in 5 hits. We take 4 dmg.
    expect(result.first.hp, 6);
    expect(player.baseStats.attack, 1);
    expect(player.baseStats.speed, 2);
  });
}
