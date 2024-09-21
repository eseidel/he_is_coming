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
  final creatures = data.creatures;

  test('Spider Level 1 effect', () {
    final player = data.player();
    expect(player.hp, 10);
    final enemy = creatures['Spider Level 1'];
    final result = doBattle(first: player, second: enemy);
    // Spider is faster than us so should do 3 damage on battle start.
    // And then hit 2 more times (since it goes first).
    expect(result.first.hp, 5);
    expect(result.winner, result.first);

    final player2 = data.player(speed: 3);
    final result2 = doBattle(first: player2, second: enemy);
    // We are the same speed as the spider so it doesn't get the bonus damage
    // and only hits once (we kill it before it can hit a second time).
    expect(result2.first.hp, 9);
  });

  test('Bat Level 1', () {
    final player = data.player();
    final enemy = creatures['Bat Level 1'];
    final result = doBattle(first: player, second: enemy);
    // Bat is faster than us so should heal 1 on every other turn.
    // We hit first and take 6 hits to kill it.
    expect(result.first.hp, 4);
    expect(result.winner, result.first);
  });

  test('Hedgehog Level 1', () {
    final player = data.player();
    final enemy = creatures['Hedgehog Level 1'];
    final result = doBattle(first: player, second: enemy);
    // Hedgehog gains 3 thorns on battle start, dies in two hits (1 armor).
    expect(result.first.hp, 6);
  });

  test('Black Knight', () {
    final player = data.player();
    final enemy = creatures['Black Knight'];
    final result = doBattle(first: player, second: enemy);
    // Black Knight should gain our attack so do 2 per hit.
    // We have the same speed so we will hit first, but will die in 5 hits.
    expect(result.first.hp, 0);
    // We will have hit 5 times, never having broken its armor.
    expect(result.second.hp, 10);

    // I need to confirm this in-game, but...
    // Player onBattle happens before enemy onBattle (regardless of speed?)
    // so black knight should get our increased attack from onBattle effects.
    final player2 = data.player(
      maxHp: 20,
      customItems: [
        Item.test(
          effect: onBattle((c) => c.gainAttack(1)),
        ),
      ],
    );
    // We go first, we hit for 2 and black knight hits for 3.
    // Black knight has 10 hp and 5 armor so will die in 8 hits.
    // Black knight kills us in 7 hits.
    final result2 = doBattle(first: player2, second: enemy);
    expect(result2.first.hp, 0);
    expect(result2.second.hp, 1);
  });

  test('Ironstone Golem', () {
    final player = data.player(attack: 2, maxHp: 20);
    final enemy = creatures['Ironstone Golem'];
    final result = doBattle(first: player, second: enemy);
    // Ironstone hits for 4, killing us in 5 hits (at 20hp)
    // We hit for 3, killing it in 7 hits, but removing its armor in 5 hits when
    // it has only done 4 hits against us (16 hp), its last hits only do 1 dmg.
    expect(result.first.hp, 2);
    expect(result.winner, result.first);
  });

  test('Granite Griffin', () {
    final player = data.player(attack: 2, maxHp: 50);
    expect(player.hp, 50);
    expect(player.baseStats.attack, 3);
    final enemy = creatures['Granite Griffin'];
    final result = doBattle(first: player, second: enemy);
    // Granite Griffin gains 30 armor when wounded and stuns itself for 2 turns.
    // It hits for 5.  We hit for 3. It has 10 armor and 10 hp to start.
    // We should kill it in 7 hits, except it gets 30 armor when crossing 4 hp
    // and then after 2 more turns wakes and kills us in 10 total hits.
    expect(result.first.hp, 0);
    expect(result.second.hp, 5);
  });

  test('Razortusk Hog', () {
    final player = data.player(attack: 3, maxHp: 20);
    expect(player.hp, 20);
    expect(player.baseStats.attack, 4);
    expect(player.baseStats.speed, 0);
    final enemy = creatures['Razortusk Hog'];
    final result = doBattle(first: player, second: enemy);
    // Razortusk Hog gets an extra strike every turn if it had more speed
    // at the start of the battle.
    // It kills us in 5 hits, which is on its 3rd turn.
    expect(result.first.hp, 0);
    expect(result.second.hp, 12);

    // If we have the same speed, we go first, and it doesn't strike twice.
    final player2 = data.player(attack: 3, maxHp: 20, speed: 4);
    expect(player2.hp, 20);
    expect(player2.baseStats.attack, 4);
    expect(player2.baseStats.speed, 4);
    final result2 = doBattle(first: player2, second: enemy);
    expect(result2.first.hp, 4);
    expect(result2.second.hp, 0);
  });

  test('Gentle Giant', () {
    final player = data.player(attack: 3, maxHp: 29);
    expect(player.hp, 29);
    expect(player.baseStats.attack, 4);
    final enemy = creatures['Gentle Giant'];
    final result = doBattle(first: player, second: enemy);
    // Gentle Giant has 40hp, 0 armor, and 0 attack.
    // Gentle Giant gains 2 thorns when taking damage, 4 if wounded.
    // We kill the giant in 10 hits.  It has no thorns on the first hit
    // but we take 2 dmg for the next 4, plus 4 dmg for the next 5
    // for a total of 28
    // TODO(eseidel): Apply thorn dmg on the killing blow.
    expect(result.first.hp, 5);
  });

  test('Bloodmoon Werewolf', () {
    final player = data.player();
    expect(player.hp, 10);
    expect(player.baseStats.attack, 1);
    final enemy = creatures['Bloodmoon Werewolf'];
    expect(enemy.hp, 15);
    expect(enemy.baseStats.attack, 3);
    expect(enemy.baseStats.speed, 1);
    final result = doBattle(first: player, second: enemy);
    // Werewolf executes the player if they are at or below 50% hp on turn start
    // Goes first, attacks for 3, does 6 dmg and then executes on 3rd turn.
    expect(result.first.hp, 0);
    expect(result.second.hp, 13);
  });

  test('Brittlebark Beast', () {
    final dmgOnHit = Item.test(effect: onHit((c) => c.dealDamage(1)));
    final player = data.player(maxHp: 25, customItems: [dmgOnHit]);
    expect(player.hp, 25);
    final enemy = creatures['Brittlebark Beast'];
    expect(enemy.baseStats.maxHp, 50);
    expect(enemy.baseStats.speed, 2);
    expect(enemy.baseStats.attack, 3);
    final result = doBattle(first: player, second: enemy);
    // Brittlebark Beast takes 3 damage when taking damage.
    // We do an extra 1 dmg on hit, but it takes then 8 dmg from each strike.
    // It goes first, but we kill it in 7 hits.
    // We take 7 * 3 = 21 dmg.
    expect(result.first.hp, 4);
  });

  test('Wolf Level 1', () {
    // If we have < 5 hp, wolf gains 2 attack.
    final player = data.player(hp: 5);
    final enemy = creatures['Wolf Level 1'];
    expect(enemy.baseStats.attack, 1);
    expect(enemy.baseStats.speed, 1);
    expect(enemy.hp, 3);
    final result = doBattle(first: player, second: enemy);
    // Wolf hits first for 1, then we hit, then wolf starts hitting for 3.
    // Wolf kills us in 3 hits before we can kill it.
    expect(result.first.hp, 0);
    expect(result.second.hp, 1);

    // Wolf also gets the ad boost on the first turn if we are below 5.
    final player2 = data.player(hp: 4);
    // And thus kills us in 2 turns.
    final result2 = doBattle(first: player2, second: enemy);
    expect(result2.first.hp, 0);
    expect(result2.second.hp, 2);
  });

  test('Bear Level 1', () {
    // If we have armor, bear gains 3 attack.
    final player = data.player(hp: 5, armor: 1);
    final enemy = creatures['Bear Level 1'];
    expect(enemy.baseStats.attack, 1);
    expect(enemy.baseStats.armor, 2);
    expect(enemy.baseStats.speed, 0);
    expect(enemy.hp, 3);
    final result = doBattle(first: player, second: enemy);
    // Bear hits for 4 (due to armor), then 1 each remaining turn once
    // armor is broken.  Bear kills us in 3 turns, we only deal one dmg
    // due to its 2 armor.
    expect(result.first.hp, 0);
    expect(result.second.hp, 2);
  });
}
