import 'package:he_is_coming_sim/src/battle.dart';
import 'package:he_is_coming_sim/src/creatures.dart';
import 'package:he_is_coming_sim/src/item.dart';
import 'package:he_is_coming_sim/src/item_catalog.dart';
import 'package:test/test.dart';

void main() {
  test('ItemCatalog smoke test', () {
    final item = itemCatalog['Wooden Stick'];
    expect(item.stats.attack, 1);
  });

  test('maxHp from items', () {
    final item = itemCatalog['Redwood Roast'];
    final player = createPlayer(withItems: [item]);
    // Redwood Roast gives 5 maxHp, so the player should have 15 maxHp.
    expect(player.hp, 15);
    expect(player.startingStats.maxHp, 15);
  });

  test('Stone Steak effect', () {
    final item = itemCatalog['Stone Steak'];
    final player = createPlayer(withItems: [item]);
    expect(player.hp, 10);
    expect(player.startingStats.armor, 0);
    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = Battle.resolve(first: player, second: enemy);
    // Stone Steak gives 4 armor, so the player should win with 9 health.
    expect(result.first.hp, 9);
    expect(result.first.startingStats.armor, 0);
    expect(result.winner, result.first);
  });

  test('Redwood Cloak effect', () {
    final item = itemCatalog['Redwood Cloak'];
    final player = createPlayer(withItems: [item]);
    expect(player.hp, 12);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = Battle.resolve(first: player, second: enemy);
    // Lose 5 hp from the wolf, since cloak doesn't trigger.
    expect(result.first.hp, 7);

    // Fight the same battle again, should heal on start this time.
    final result2 = Battle.resolve(first: result.first, second: enemy);
    // Lose only 4 hp from the wolf, since cloak triggers.
    expect(result2.first.hp, 3);
  });

  test('Emergency Shield effect', () {
    final item = itemCatalog['Emergency Shield'];
    final player = createPlayer(withItems: [item]);
    expect(player.hp, 10);
    expect(player.startingStats.speed, 0);
    expect(player.startingStats.armor, 0);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6, speed: 2);
    final result = Battle.resolve(first: player, second: enemy);
    // Wolf is faster, so does 6 dmg to us, but we get 4 armor from the shield.
    expect(result.first.hp, 8);
    expect(result.first.startingStats.armor, 0);

    final player2 =
        createPlayer(baseStats: const Stats(speed: 2), withItems: [item]);
    expect(player2.hp, 10);
    expect(player2.startingStats.speed, 2);
    expect(player2.startingStats.armor, 0);

    final result2 = Battle.resolve(first: player2, second: enemy);
    // Wolf is same speed, so only does 5 dmg to us.
    // Emergency Shield won't give armor, since player has >= enemy speed.
    expect(result2.first.hp, 5);
    expect(result2.first.startingStats.armor, 0);
  });

  test('Ruby Earnings effect', () {
    final item = itemCatalog['Ruby Earings'];
    final player = createPlayer(withItems: [item]);
    expect(player.hp, 10);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    // Normally kill it in 6 turns (take 5 dmg), but the ruby earnings trigger
    // every other turn (including the first) for 1 dmg, meaning we
    // kill it in 4 turns (take 3 dmg).
    final result = Battle.resolve(first: player, second: enemy);
    expect(result.first.hp, 7);
  });

  test('Firecracker Belt effect', () {
    final item = itemCatalog['Firecracker Belt'];
    final player =
        createPlayer(baseStats: const Stats(armor: 1), withItems: [item]);
    expect(player.hp, 10);
    expect(player.startingStats.armor, 1);

    // Normally we would kill the wolf in 6 turns (take 5 dmg), but the armor
    // reduces one damage, and then the firecracker belt triggers after the
    // armor is broken, dealing 3 dmg to the wolf, killing it in 3 turns.
    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = Battle.resolve(first: player, second: enemy);
    expect(result.first.hp, 9);
  });

  test('Redwood Helmet effect', () {
    // Gives 1 armor.
    final item = itemCatalog['Redwood Helmet'];
    final player = createPlayer(withItems: [item], hp: 5);
    expect(player.hp, 5);
    expect(player.startingStats.armor, 1);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    // We would kill the wolf in 6 turns (take 4 dmg, 1 absorbed by armor), but
    // the helmet triggers after the armor is broken, healing 3 hp.
    final result = Battle.resolve(first: player, second: enemy);
    expect(result.first.hp, 4);

    final player2 = createPlayer(withItems: [item]);
    expect(player2.hp, 10);
    expect(player2.startingStats.armor, 1);

    // But if we fight with full health, the helmet triggers at exposed
    // and does nothing because we're already at full health.
    final result2 = Battle.resolve(first: player2, second: enemy);
    expect(result2.first.hp, 6);
  });

  test('Explosive Surprise effect', () {
    final item = itemCatalog['Explosive Surprise'];
    final player =
        createPlayer(baseStats: const Stats(armor: 1), withItems: [item]);
    expect(player.hp, 10);
    expect(player.startingStats.armor, 1);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    // We would kill the wolf in 6 turns (take 5 dmg), but the explosive
    // surprise triggers at exposed, dealing 5 dmg to the wolf, killing it
    // in 2 turns.
    final result = Battle.resolve(first: player, second: enemy);
    expect(result.first.hp, 10);
  });

  test('Cracked Bouldershield', () {
    final item = itemCatalog['Cracked Bouldershield'];
    final player =
        createPlayer(baseStats: const Stats(armor: 1), withItems: [item]);
    expect(player.hp, 10);
    expect(player.startingStats.armor, 1);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    // We would kill the wolf in 6 turns (take 5 dmg), but the bouldershield
    // triggers at exposed, giving 5 armor, so we take no damage.
    final result = Battle.resolve(first: player, second: enemy);
    expect(result.first.hp, 10);
    // We still have our base armor, but any armor during battle is gone.
    expect(player.startingStats.armor, 1);
  });

  test('Vampiric Wine effect', () {
    final item = itemCatalog['Vampiric Wine'];
    final player = createPlayer(withItems: [item], hp: 9);
    expect(player.hp, 9);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    // Normally take 5 dmg but the wine triggers
    // when we're below 50% health, healing 4 hp.
    final result = Battle.resolve(first: player, second: enemy);
    expect(result.first.hp, 8);
  });
}
