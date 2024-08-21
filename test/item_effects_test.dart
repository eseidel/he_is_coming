import 'package:he_is_coming/src/battle.dart';
import 'package:he_is_coming/src/creature.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/item.dart';
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
  final itemCatalog = data.items;

  test('maxHp from items', () {
    final item = itemCatalog['Redwood Roast'];
    final player = createPlayer(items: [item]);
    // Redwood Roast gives 5 maxHp, so the player should have 15 maxHp.
    expect(player.hp, 15);
    expect(player.baseStats.maxHp, 15);
  });

  test('Stone Steak effect', () {
    final item = itemCatalog['Stone Steak'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);
    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Stone Steak gives 4 armor, so the player should win with 9 health.
    expect(result.first.hp, 9);
    expect(result.first.baseStats.armor, 0);
    expect(result.winner, result.first);
  });

  test('Redwood Cloak effect', () {
    final item = itemCatalog['Redwood Cloak'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 12);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Lose 5 hp from the wolf, since cloak doesn't trigger.
    expect(result.first.hp, 7);

    // Fight the same battle again, should heal on start this time.
    final result2 = doBattle(first: result.first, second: enemy);
    // Lose only 4 hp from the wolf, since cloak triggers.
    expect(result2.first.hp, 3);
  });

  test('Emergency Shield effect', () {
    final item = itemCatalog['Emergency Shield'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.speed, 0);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6, speed: 2);
    final result = doBattle(first: player, second: enemy);
    // Wolf is faster, so does 6 dmg to us, but we get 4 armor from the shield.
    expect(result.first.hp, 8);
    expect(result.first.baseStats.armor, 0);

    final player2 =
        createPlayer(intrinsic: const Stats(speed: 2), items: [item]);
    expect(player2.hp, 10);
    expect(player2.baseStats.speed, 2);
    expect(player2.baseStats.armor, 0);

    final result2 = doBattle(first: player2, second: enemy);
    // Wolf is same speed, so only does 5 dmg to us.
    // Emergency Shield won't give armor, since player has >= enemy speed.
    expect(result2.first.hp, 5);
    expect(result2.first.baseStats.armor, 0);
  });

  test('Ruby Earning effect', () {
    final item = itemCatalog['Ruby Earing'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    // Normally kill it in 6 turns (take 5 dmg), but the ruby earnings trigger
    // every other turn (including the first) for 1 dmg, meaning we
    // kill it in 4 turns (take 3 dmg).
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 7);
  });

  test('Firecracker Belt effect', () {
    final item = itemCatalog['Firecracker Belt'];
    final player =
        createPlayer(intrinsic: const Stats(armor: 1), items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 1);

    // Normally we would kill the wolf in 6 turns (take 5 dmg), but the armor
    // reduces one damage, and then the firecracker belt triggers after the
    // armor is broken, dealing 3 dmg to the wolf, killing it in 3 turns.
    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 9);
  });

  test('Redwood Helmet effect', () {
    // Gives 1 armor.
    final item = itemCatalog['Redwood Helmet'];
    final player = createPlayer(items: [item], hp: 5);
    expect(player.hp, 5);
    expect(player.baseStats.armor, 1);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    // We would kill the wolf in 6 turns (take 4 dmg, 1 absorbed by armor), but
    // the helmet triggers after the armor is broken, healing 3 hp.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 4);

    final player2 = createPlayer(items: [item]);
    expect(player2.hp, 10);
    expect(player2.baseStats.armor, 1);

    // But if we fight with full health, the helmet triggers at exposed
    // and does nothing because we're already at full health.
    final result2 = doBattle(first: player2, second: enemy);
    expect(result2.first.hp, 6);
  });

  test('Explosive Surprise effect', () {
    final item = itemCatalog['Explosive Surprise'];
    final player =
        createPlayer(intrinsic: const Stats(armor: 1), items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 1);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    // We would kill the wolf in 6 turns (take 5 dmg), but the explosive
    // surprise triggers at exposed, dealing 5 dmg to the wolf, killing it
    // in 2 turns.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 10);
  });

  test('Cracked Bouldershield', () {
    final item = itemCatalog['Cracked Bouldershield'];
    final player =
        createPlayer(intrinsic: const Stats(armor: 1), items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 1);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    // We would kill the wolf in 6 turns (take 5 dmg), but the bouldershield
    // triggers at exposed, giving 5 armor, so we take no damage.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 10);
    // We still have our base armor, but any armor during battle is gone.
    expect(player.baseStats.armor, 1);
  });

  test('Vampiric Wine effect', () {
    final item = itemCatalog['Vampiric Wine'];
    final player = createPlayer(items: [item], hp: 9);
    expect(player.hp, 9);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    // Normally take 5 dmg but the wine triggers
    // when we're below 50% health, healing 4 hp.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 8);
  });

  test('Wounded when already below 50%', () {
    final item = itemCatalog['Vampiric Wine'];
    final player = createPlayer(items: [item], hp: 4);
    expect(player.hp, 4);

    // Wounded does not trigger when we're already below 50% health.
    // You have to be at-or-above 50% when taking damage for it to trigger.
    // https://discord.com/channels/1041414829606449283/1209488302269534209/1274771566231552151
    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    // Normally take 5 dmg but the wine triggers
    // when we're below 50% health, healing 4 hp.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 0);
  });

  test('Mortal Edge effect', () {
    final item = itemCatalog['Mortal Edge'];
    final player = createPlayer(items: [item], hp: 5);
    expect(player.hp, 5);
    expect(player.baseStats.attack, 2);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    // Normally take 5 dmg but the mortal edge triggers
    // when we're below 50% health, increasing attack by 5 and taking 2 dmg.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 2);
    expect(result.first.baseStats.attack, 2);
  });

  test('Lifeblood Burst effect', () {
    final item = itemCatalog['Lifeblood Burst'];
    final player = createPlayer(items: [item], hp: 5);
    expect(player.hp, 5);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    // Normally take 5 dmg but the lifeblood burst triggers
    // onWounded, dealing 5 dmg to the enemy.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 4);
    expect(result.second.hp, 0);
  });

  test('Chain Mail', () {
    final item = itemCatalog['Chain Mail'];
    final player = createPlayer(
      intrinsic: const Stats(armor: 3),
      items: [item],
      hp: 5,
    );
    expect(player.hp, 5);
    expect(player.baseStats.armor, 3);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    // Normally take 5 dmg but the first 3 are absorbed by the armor
    // and then the chain mail triggers, giving 3 armor again, so take 1 dmg.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 4);
    expect(result.first.baseStats.armor, 3);
  });

  test('Stoneslab Sword', () {
    final item = itemCatalog['Stoneslab Sword'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 2);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    // We attack first, and then the sword triggers, giving 2 armor, so we
    // never take damage.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 10);
    expect(result.first.baseStats.armor, 0);
  });

  test('Heart Drinker', () {
    final item = itemCatalog['Heart Drinker'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);

    final enemy = makeEnemy('Wolf', attack: 2, health: 6);
    // We attack first, and then the sword triggers, healing 1 hp, so we only
    // lose 2 hp since wolf hits us twice and we gain 3 from attacking.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 8);
  });

  test('Enemies give gold', () {
    final player = createPlayer();
    expect(player.hp, 10);
    expect(player.gold, 0);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    expect(enemy.gold, 1);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 5);
    // Gain one gold at battle end.
    expect(result.first.gold, 1);
  });

  test('Gold Ring', () {
    final item = itemCatalog['Gold Ring'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.gold, 0);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 5);
    // Gain one gold at battle start and one gold at battle end.
    expect(result.first.gold, 2);
  });

  test('Ruby Ring', () {
    final item = itemCatalog['Ruby Ring'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 1);

    // Ruby Ring gives 1 attack and takes 2 damage at the start of battle.
    // Which means we only take 2 dmg from wolf, but 2 from ring.
    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 6);
  });

  test('Ruby Crown', () {
    final item = itemCatalog['Ruby Crown'];
    final player =
        createPlayer(intrinsic: const Stats(attack: 1), items: [item]);
    expect(player.hp, 10);
    // We have 1 attack from intrinsic and 1 from "Wooden Stick".
    expect(player.baseStats.attack, 2);

    // Ruby Crown gives 2 attack if we have 6 or more attack.
    final enemy = makeEnemy('Wolf', attack: 1, health: 14);
    final result = doBattle(first: player, second: enemy);
    // Wolf dies in 7 attacks, so we lose 6 hp.
    expect(result.first.hp, 4);

    final player2 = createPlayer(
      intrinsic: const Stats(attack: 5),
      items: [item],
    );
    expect(player2.hp, 10);
    expect(player2.baseStats.attack, 6);
    // Ruby Crown gives 2 attack if we have 6 or more attack.
    final result2 = doBattle(first: player2, second: enemy);
    // Wolf dies in 2 hits (8 each) so we lose 1 hp.
    expect(result2.first.hp, 9);
  });

  test('Melting Iceblade', () {
    final item = itemCatalog['Melting Iceblade'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 7);

    // Melting Iceblade reduces attack by 1 on Hit, so first hit is 7
    // then 6, 5, 4, 3, 2, 1, 0.
    // 15 will take 3 hits, so we should take 2 dmg.
    final enemy = makeEnemy('Wolf', attack: 1, health: 15);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 8);
    // Attack recovers after battle I think?
    expect(result.first.baseStats.attack, 7);
  });

  test('Melting Iceblade attack clamping', () {
    final item = itemCatalog['Melting Iceblade'];
    final player =
        createPlayer(intrinsic: const Stats(maxHp: 100), items: [item]);
    expect(player.hp, 100);
    expect(player.baseStats.attack, 7);

    // Melting Iceblade reduces attack by 1 on Hit, so first hit is 7
    // then 6, 5, 4, 3, 2, 1, 0.
    // Melting Iceblade can only do 28 dmg when clamped to 0, so we will lose
    // to a 29 health enemy.
    final enemy = makeEnemy('Wolf', attack: 1, health: 29);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 0);
    expect(result.first.baseStats.attack, 7);
  });

  test('Double-edged Sword', () {
    final item = itemCatalog['Double-edged Sword'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 5);

    // Double-edged Sword deals 1 damage on hit, so we should take 3 dmg.
    // One from wolf and two from sword.
    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 7);
  });

  test('Sapphire Crown', () {
    final item = itemCatalog['Sapphire Crown'];
    final player =
        createPlayer(intrinsic: const Stats(armor: 15), items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 15);

    // Sapphire Crown gives 10 armor if we have 15 or more armor.
    final enemy = makeEnemy('Wolf', attack: 5, health: 6);
    final result = doBattle(first: player, second: enemy);
    // We take 5 hits from wolf, which is 25 dmg, but we have 25 armor.
    expect(result.first.hp, 10);
    expect(result.first.baseStats.armor, 15);

    final player2 = createPlayer(
      intrinsic: const Stats(armor: 14),
      items: [item],
    );
    expect(player2.hp, 10);
    expect(player2.baseStats.armor, 14);

    // Sapphire Crown gives 10 armor if we have 15 or more armor.
    final result2 = doBattle(first: player2, second: enemy);
    // We take 5 hits from wolf, which is 25 dmg, but we have 14 armor.
    expect(result2.first.hp, 0);
    expect(result2.first.baseStats.armor, 14);
  });

  test('Citrine Ring', () {
    final item = itemCatalog['Citrine Ring'];
    final player =
        createPlayer(items: [item], intrinsic: const Stats(speed: 2));
    expect(player.baseStats.speed, 2);

    // Citrine Ring deals damage equal to our speed at the start of battle.
    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 7);

    final player2 =
        createPlayer(items: [item], intrinsic: const Stats(speed: -2));
    expect(player2.baseStats.speed, -2);

    // Speed can be negative, but won't deal negative damage.
    final result2 = doBattle(first: player2, second: enemy);
    // Wolf goes first so we take 6 hits rather than 5.
    expect(result2.first.hp, 4);
  });

  test('Marble Mirror', () {
    final item = itemCatalog['Marble Mirror'];
    final player =
        createPlayer(items: [item], intrinsic: const Stats(attack: 1));
    expect(player.hp, 10);
    expect(player.baseStats.attack, 2);
    expect(player.baseStats.armor, 0);

    // Marble Mirror gives armor equal to the enemy's armor at the start.
    final enemy = makeEnemy('Wolf', attack: 1, health: 6, armor: 3);
    final result = doBattle(first: player, second: enemy);
    // We have 2 attack, wolf has 9 hp + armor, so we need 5 hits.
    // Wolf attacks 4 times, so we take 4 dmg, but mirror gives 3 armor.
    expect(result.first.hp, 9);
    expect(result.first.baseStats.armor, 0);

    final player2 = createPlayer(items: [item]);
    expect(player2.hp, 10);
    expect(player2.baseStats.attack, 1);
    expect(player2.baseStats.armor, 0);

    final enemy2 = makeEnemy('Wolf', attack: 1, health: 6);
    final result2 = doBattle(first: player2, second: enemy2);
    // We have 1 attack, wolf has 6 hp, so we need 6 hits.
    // Wolf attacks 5 times, so we take 5 dmg, but mirror gives 0 armor.
    expect(result2.first.hp, 5);
    expect(player2.baseStats.armor, 0);
  });

  test('Leather Boots', () {
    final item = itemCatalog['Leather Boots'];
    final player =
        createPlayer(items: [item], intrinsic: const Stats(speed: 2));
    expect(player.hp, 10);
    expect(player.baseStats.speed, 2);
    expect(player.baseStats.attack, 1);

    // Leather Boots gives 2 attack if we have more speed than the enemy.
    final enemy = makeEnemy('Wolf', attack: 1, health: 6, speed: 1);
    final result = doBattle(first: player, second: enemy);
    // With leather boots we get +2 attack so we kill the wolf in 2 hits.
    expect(result.first.hp, 9);
    expect(result.first.baseStats.attack, 1);

    final player2 =
        createPlayer(items: [item], intrinsic: const Stats(speed: 1));
    expect(player2.hp, 10);
    expect(player2.baseStats.speed, 1);
    expect(player2.baseStats.attack, 1);

    // With the same speed, we don't get the attack bonus.
    final result2 = doBattle(first: player2, second: enemy);
    expect(result2.first.hp, 5);
  });

  test('Plated Helmet', () {
    final item = itemCatalog['Plated Helmet'];
    final player = createPlayer(items: [item], hp: 5);
    expect(player.hp, 5);
    expect(player.baseStats.armor, 0);

    // Plated Helmet gives 2 armor if we're below 50% health.
    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // We take 1 dmg from the wolf the first hit, and then no more after that
    // due to the 2 armor we get each turn from the helmet.
    expect(result.first.hp, 4);
    expect(result.first.baseStats.armor, 0);

    final player2 = createPlayer(items: [item]);
    expect(player2.hp, 10);
    expect(player2.baseStats.armor, 0);

    // If we're not below 50% health, the helmet does nothing.
    final result2 = doBattle(first: player2, second: enemy);
    expect(result2.first.hp, 5);
    expect(result2.first.baseStats.armor, 0);
  });

  test('Ore Heart', () {
    final item = itemCatalog['Ore Heart'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);

    // Ore Heart gives 2 armor for each stone item we have.
    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // We get 2 armor from the Ore Heart, so we take 3 dmg from the wolf.
    expect(result.first.hp, 7);
    expect(result.first.baseStats.armor, 0);

    final other = Item('other', Rarity.common, material: Material.stone);
    final player2 = createPlayer(items: [item, other]);
    expect(player2.hp, 10);
    expect(player2.baseStats.armor, 0);

    // Ore Heart gives 2 armor for each stone item we have.
    final result2 = doBattle(first: player2, second: enemy);
    // We get 4 armor from the Ore Heart, so we take 1 dmg from the wolf.
    expect(result2.first.hp, 9);
  });

  test('Granite Hammer', () {
    final item = itemCatalog['Granite Hammer'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 2);
    expect(player.baseStats.armor, 0);

    // Granite Hammer gives 2 attack and 1 armor on hit if we have armor.
    // If we don't have armor it does nothing.
    final enemy = makeEnemy('Wolf', attack: 1, health: 10);
    final result = doBattle(first: player, second: enemy);
    // Takes 5 hits to kill the wolf, so we take 4 dmg.
    expect(result.first.hp, 6);
    expect(result.first.baseStats.attack, 2);
    expect(result.first.baseStats.armor, 0);

    final player2 = createPlayer(
      intrinsic: const Stats(armor: 1),
      items: [item],
    );
    expect(player2.hp, 10);
    expect(player2.baseStats.attack, 2);
    expect(player2.baseStats.armor, 1);

    // Granite Hammer gives 2 attack and 1 armor on hit if we have armor.
    final result2 = doBattle(first: player2, second: enemy);
    // We deal 2 dmg on the first hit and lose 1 armor and gain 2 attack.
    // Then we deal 4 dmg on the second and 3rd hit, killing the wolf.
    expect(result2.first.hp, 8);
    expect(result2.first.baseStats.attack, 2);
    expect(result2.first.baseStats.armor, 1);
  });

  test('Iron Transfusion', () {
    final item = itemCatalog['Iron Transfusion'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Iron Transfusion gives 2 armor and loses 1 hp every turn.
    // We take 6 turns to kill the wolf, so we lose 6 hp.
    // The wolf never gets through our armor.
    expect(result.first.hp, 4);
    expect(result.first.baseStats.armor, 0);
  });

  test('Fortified Gauntlet', () {
    final item = itemCatalog['Fortified Gauntlet'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // We never gain any armor from the gauntlet.
    expect(result.first.hp, 5);
    expect(result.first.baseStats.armor, 0);

    final player2 = createPlayer(
      intrinsic: const Stats(armor: 1),
      items: [item],
    );
    expect(player2.hp, 10);
    expect(player2.baseStats.armor, 1);

    final result2 = doBattle(first: player2, second: enemy);
    // Fortified Gauntlet gives 1 armor if we have armor.
    // So we never take any damage from the wolf.
    expect(result2.first.hp, 10);
    expect(result2.first.baseStats.armor, 1);
  });

  test('Item order matters', () {
    final armor = Item(
      'armor',
      Rarity.common,
      effects: Effects(onTurn: (c) => c.gainArmor(1)),
    );
    final gauntlet = itemCatalog['Fortified Gauntlet'];
    final player = createPlayer(items: [armor, gauntlet]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy('Wolf', attack: 2, health: 6);
    // The armor item gives 1 armor before the gauntlet, so the Gauntlet
    // triggers and gives 1 armor, so we take no damage from the wolf.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 10);
    expect(result.first.baseStats.armor, 0);

    final player2 = createPlayer(items: [gauntlet, armor]);
    expect(player2.hp, 10);
    expect(player2.baseStats.armor, 0);

    // The gauntlet triggers first, but we have no armor to gain 1 armor from
    // so the wolf hits us 5 times for 2 dmg each, one of which is absorbed
    // by the armor item, so we take 5 dmg.
    final result2 = doBattle(first: player2, second: enemy);
    expect(result2.first.hp, 5);
    expect(result2.first.baseStats.armor, 0);
  });

  test('Iron Rose', () {
    final healOnHit = Item(
      'healOnHit',
      Rarity.common,
      effects: Effects(onHit: (c) => c.restoreHealth(1)),
    );
    final item = itemCatalog['Iron Rose'];
    // Order of the items should not matter in this case.
    final player = createPlayer(items: [item, healOnHit]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy('Wolf', attack: 3, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Iron Rose gives 1 armor on (successful) heal, but the first hit we're
    // not damaged, so it does nothing.  Our remaining 5 hits heal 1 each time.
    // Wolf hits us 5 times, the first time for 3 dmg, then 1 for each.
    expect(result.first.hp, 4);
    expect(result.first.baseStats.armor, 0);

    // This time w/o the healOnHit item, the iron rose won't trigger.
    final player2 = createPlayer(items: [item], hp: 5);
    expect(player2.hp, 5);
    expect(player2.baseStats.armor, 0);

    final result2 = doBattle(first: player2, second: enemy);
    expect(result2.first.hp, 0);
    expect(result2.first.baseStats.armor, 0);
  });

  test('Featherweight Coat', () {
    final item = itemCatalog['Featherweight Coat'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);
    expect(player.baseStats.speed, 0);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6, speed: 2);
    final result = doBattle(first: player, second: enemy);
    // Featherweight Coat gives 3 speed if we have armor, but we don't.
    // Wolf goes first so we take 6 dmg.
    expect(result.first.hp, 4);
    expect(result.first.baseStats.armor, 0);
    expect(result.first.baseStats.speed, 0);

    final player2 = createPlayer(
      intrinsic: const Stats(armor: 1),
      items: [item],
    );
    expect(player2.hp, 10);
    expect(player2.baseStats.armor, 1);
    expect(player2.baseStats.speed, 0);

    final result2 = doBattle(first: player2, second: enemy);
    // Featherweight Coat gives 3 speed if we have armor, so we go first.
    expect(result2.first.hp, 5);
    expect(result2.first.baseStats.armor, 1);
    expect(result2.first.baseStats.speed, 0);
  });

  test('Item effects are cumulative', () {
    final item = itemCatalog['Redwood Roast'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 15);
    expect(player.baseStats.maxHp, 15);

    final player2 = createPlayer(items: [item, item]);
    expect(player2.hp, 20);
    expect(player2.baseStats.maxHp, 20);
  });

  test('Sticky Web effect', () {
    final item = itemCatalog['Sticky Web'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.speed, 0);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6, speed: 2);
    final result = doBattle(first: player, second: enemy);
    // Wolf is faster, but the web triggers and so we go first.
    expect(result.first.hp, 5);
    expect(result.first.baseStats.speed, 0);

    final player2 = createPlayer(
      intrinsic: const Stats(speed: 2),
      items: [item],
    );
    expect(player2.hp, 10);
    expect(player2.baseStats.speed, 2);

    final result2 = doBattle(first: player2, second: enemy);
    // We're the same speed, so the web does nothing.
    expect(result2.first.hp, 5);
    expect(result2.first.baseStats.speed, 2);
  });

  test('Impressive Physique effect', () {
    final item = itemCatalog['Impressive Physique'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);

    // With no armor, nothing happens.
    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 5);
    expect(result.first.baseStats.armor, 0);

    final player2 =
        createPlayer(items: [item], intrinsic: const Stats(armor: 1));
    expect(player2.hp, 10);
    expect(player2.baseStats.armor, 1);

    final result2 = doBattle(first: player2, second: enemy);
    // When our armor breaks, the wolf is stunned for 1 turn.
    // So we only take 4 dmg from the wolf - 1 from the armor.
    expect(result2.first.hp, 7);
    expect(result2.first.baseStats.armor, 1);
  });

  test('Steelbond Curse effect', () {
    final item = itemCatalog['Steelbond Curse'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);
    expect(player.baseStats.attack, 2);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Steelbond Curse gives 8 armor to the enemy, so it takes 14 dmg to kill
    // and it hits for 2, so that's 7 hits, so we take 6 dmg.
    expect(result.first.hp, 4);
    expect(player.baseStats.armor, 0);
    expect(player.baseStats.attack, 2);
  });

  test('Bejeweled Blade effect', () {
    final item = itemCatalog['Bejeweled Blade'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 0);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Bejeweled Blade gives 2 attack for each jewelry item we have
    // if we don't have any jewelry we have 0 attack!
    expect(result.first.hp, 0);
    expect(player.baseStats.attack, 0);

    final jewelry = Item(
      'jewelry',
      kind: Kind.jewelry,
      Rarity.common,
    );
    final player2 = createPlayer(items: [item, jewelry]);
    expect(player2.hp, 10);
    // We've implemented Bejeweled Blade onBattle so this is still 0.
    expect(player2.baseStats.attack, 0);

    final result2 = doBattle(first: player2, second: enemy);
    // Bejeweled Blade gives 2 attack for each jewelry item we have.
    // So we kill the wolf in 3 attacks, so we take 2 dmg.
    expect(result2.first.hp, 8);
    expect(player2.baseStats.attack, 0);
  });

  test("Woodcutter's Axe effect", () {
    final selfHealing = makeEnemy(
      'Wolf',
      attack: 1,
      health: 6,
      effects: Effects(onTurn: (c) => c.restoreHealth(1)),
    );

    final item = itemCatalog["Woodcutter's Axe"];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 2);

    final result = doBattle(first: player, second: selfHealing);
    // Woodcutter's Axe reduces maxHp on hit, negating any healing abilities.
    expect(result.first.hp, 8);

    // If we fight w/o the axe, the wolf heals 1 hp every turn, taking
    // 5 turns to kill so we take 4 dmg.
    final player2 = createPlayer(intrinsic: const Stats(attack: 1));
    expect(player2.hp, 10);
    expect(player2.baseStats.attack, 2);
    final result2 = doBattle(first: player2, second: selfHealing);
    expect(result2.first.hp, 6);
  });

  test('Emerald Ring', () {
    final item = itemCatalog['Emerald Ring'];
    final player = createPlayer(items: [item], hp: 7);
    expect(player.hp, 7);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Emerald ring restores 2 hp on battle start, then wolf does 5 dmg.
    expect(result.first.hp, 4);
  });

  test('Ironskin Potion', () {
    final item = itemCatalog['Ironskin Potion'];
    final player = createPlayer(items: [item], hp: 6);
    expect(player.hp, 6);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Ironskin potion gives armor = lost hp (4) so we only take 1 dmg.
    expect(result.first.hp, 5);
    expect(result.first.baseStats.armor, 0);

    final player2 = createPlayer(items: [item], hp: 10);
    expect(player2.hp, 10);
    expect(player2.baseStats.armor, 0);
    final result2 = doBattle(first: player2, second: enemy);
    // Ironskin potion gives armor = lost hp (0) so we take 5 dmg.
    expect(result2.first.hp, 5);
    expect(result2.first.baseStats.armor, 0);
  });

  test('Double-plated Armor', () {
    final item = itemCatalog['Double-plated Armor'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 2);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Double-plated armor makes us slower, so wolf hits us 6 times.
    // It absorbs the first 2 hits with armor and then adds 3 armor on exposed.
    expect(result.first.hp, 9);
    expect(result.first.baseStats.armor, 2);
  });

  test('Sapphire Earing', () {
    final item = itemCatalog['Sapphire Earing'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Sapphire Earing gains 1 armor every other turn starting the first.
    // We would take 5 dmg from the wolf, but the earning negates 3 of that.
    expect(result.first.hp, 8);
    expect(result.first.baseStats.armor, 0);
  });

  test('Emerald Earing', () {
    final item = itemCatalog['Emerald Earing'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Emerald Earing gains 1 hp every other turn starting the first.
    // We would take 5 dmg from the wolf, but the earning negates 2 of that
    // since the first heal happens while we're at full hp.
    expect(result.first.hp, 7);
  });

  test('Emerald Crown', () {
    final item = itemCatalog['Emerald Crown'];
    final player = createPlayer(items: [item], hp: 7);
    expect(player.hp, 7);

    // Emerald Crown does nothing if we don't have 20 or more max hp.
    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 2);

    final player2 = createPlayer(
      items: [item],
      intrinsic: const Stats(maxHp: 20),
      hp: 7,
    );
    expect(player2.hp, 7);
    final result2 = doBattle(first: player2, second: enemy);
    // Emerald Crown heals to full on battle start if we have 20 or more max hp.
    expect(result2.first.hp, 15);

    final player3 = createPlayer(
      items: [item],
      intrinsic: const Stats(maxHp: 20),
      hp: 20,
    );
    expect(player3.hp, 20);
    final result3 = doBattle(first: player3, second: enemy);
    // Emerald Crown does nothing if we're already at full hp.
    expect(result3.first.hp, 15);
  });

  test('Sapphire Ring', () {
    final item = itemCatalog['Sapphire Ring'];
    final player = createPlayer(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy('Wolf', attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Sapphire Ring does nothing if enemy has no armor.
    expect(result.first.hp, 5);
    expect(result.first.baseStats.armor, 0);

    final enemy2 = makeEnemy('Wolf', attack: 1, health: 6, armor: 1);
    final result2 = doBattle(first: player, second: enemy2);
    // Sapphire Ring steals up to 2 armor from the enemy.
    expect(result2.first.hp, 6);
    expect(result2.first.baseStats.armor, 0);
    expect(result2.second.baseStats.armor, 1);

    final enemy3 = makeEnemy('Wolf', attack: 1, health: 6, armor: 2);
    final result3 = doBattle(first: player, second: enemy3);
    // Sapphire Ring steals up to 2 armor from the enemy.
    expect(result3.first.hp, 7);
    expect(result3.first.baseStats.armor, 0);
    expect(result3.second.baseStats.armor, 2);

    final enemy4 = makeEnemy('Wolf', attack: 1, health: 6, armor: 3);
    final result4 = doBattle(first: player, second: enemy4);
    // Sapphire Ring steals up to 2 armor from the enemy.
    expect(result4.first.hp, 6);
    expect(result4.first.baseStats.armor, 0);
    expect(result4.second.baseStats.armor, 3);
  });
}
