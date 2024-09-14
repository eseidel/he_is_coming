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
  final itemCatalog = data.items;

  test('maxHp from items', () {
    final player = data.player(items: ['Redwood Roast']);
    // Redwood Roast gives 5 maxHp, so the player should have 15 maxHp.
    expect(player.hp, 15);
    expect(player.baseStats.maxHp, 15);
  });

  test('Stone Steak', () {
    final player = data.player(items: ['Stone Steak']);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);
    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Stone Steak gives 4 armor, so the player should win with 9 health.
    expect(result.first.hp, 9);
    expect(result.first.baseStats.armor, 0);
    expect(result.winner, result.first);
  });

  test('Redwood Cloak', () {
    final player = data.player(items: ['Redwood Cloak']);
    expect(player.hp, 12);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Lose 5 hp from the wolf, since cloak doesn't trigger.
    expect(result.first.hp, 7);

    // Fight the same battle again, should heal on start this time.
    final result2 = doBattle(first: result.first, second: enemy);
    // Lose only 4 hp from the wolf, since cloak triggers.
    expect(result2.first.hp, 3);
  });

  test('Golden Redwood Cloak', () {
    const item = 'Golden Redwood Cloak';
    final player = data.player(items: [item]);
    expect(player.hp, 14);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Lose 5 hp from the wolf, since cloak doesn't trigger.
    expect(result.first.hp, 9);

    // Fight the same battle again, should heal on start this time.
    final result2 = doBattle(first: result.first, second: enemy);
    // Lose 5 more from wolf, but heal 2 from cloak.
    expect(result2.first.hp, 6);
  });

  test('Emergency Shield', () {
    const item = 'Emergency Shield';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.speed, 0);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy(attack: 1, health: 6, speed: 2);
    final result = doBattle(first: player, second: enemy);
    // Wolf is faster, so does 6 dmg to us, but we get 4 armor from the shield.
    expect(result.first.hp, 8);
    expect(result.first.baseStats.armor, 0);

    final player2 = data.player(speed: 2, items: [item]);
    expect(player2.hp, 10);
    expect(player2.baseStats.speed, 2);
    expect(player2.baseStats.armor, 0);

    final result2 = doBattle(first: player2, second: enemy);
    // Wolf is same speed, so only does 5 dmg to us.
    // Emergency Shield won't give armor, since player has >= enemy speed.
    expect(result2.first.hp, 5);
    expect(result2.first.baseStats.armor, 0);
  });

  test('Golden Emergency Shield', () {
    const item = 'Golden Emergency Shield';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.speed, 0);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy(attack: 1, health: 6, speed: 2);
    final result = doBattle(first: player, second: enemy);
    // Wolf is faster, so does 6 dmg to us, but we get 8 armor from the shield.
    expect(result.first.hp, 10);
    expect(result.first.baseStats.armor, 0);

    final player2 = data.player(speed: 2, items: [item]);
    expect(player2.hp, 10);
    expect(player2.baseStats.speed, 2);
    expect(player2.baseStats.armor, 0);

    final result2 = doBattle(first: player2, second: enemy);
    // Wolf is same speed, so only does 5 dmg to us.
    // Emergency Shield won't give armor, since player has >= enemy speed.
    expect(result2.first.hp, 5);
    expect(result2.first.baseStats.armor, 0);
  });

  test('Ruby Earning', () {
    const item = 'Ruby Earring';
    final player = data.player(items: [item]);
    expect(player.hp, 10);

    final enemy = makeEnemy(attack: 1, health: 6);
    // Normally kill it in 6 turns (take 5 dmg), but the ruby earnings trigger
    // every other turn (including the first) for 1 dmg, meaning we
    // kill it in 4 turns (take 3 dmg).
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 7);
  });

  test('Firecracker Belt', () {
    const item = 'Firecracker Belt';
    final player = data.player(armor: 1, items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 1);

    // Normally we would kill the wolf in 6 turns (take 5 dmg), but the armor
    // reduces one damage, and then the firecracker belt triggers after the
    // armor is broken, dealing 3 dmg to the wolf, killing it in 3 turns.
    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 9);
  });

  test('Golden Firecracker Belt', () {
    const item = 'Golden Firecracker Belt';
    final player = data.player(armor: 1, items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 1);

    // Normally we would kill the wolf in 10 turns (take 9 dmg), but the armor
    // reduces one damage, and then the firecracker belt triggers after the
    // armor is broken, dealing 6 dmg to the wolf, killing it in 4 turns
    final enemy = makeEnemy(attack: 1, health: 10);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 8);
  });

  test('Redwood Helmet', () {
    // Gives 1 armor.
    const item = 'Redwood Helmet';
    final player = data.player(items: [item], hp: 5);
    expect(player.hp, 5);
    expect(player.baseStats.armor, 1);

    final enemy = makeEnemy(attack: 1, health: 6);
    // We would kill the wolf in 6 turns (take 4 dmg, 1 absorbed by armor), but
    // the helmet triggers after the armor is broken, healing 3 hp.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 4);

    final player2 = data.player(items: [item]);
    expect(player2.hp, 10);
    expect(player2.baseStats.armor, 1);

    // But if we fight with full health, the helmet triggers at exposed
    // and does nothing because we're already at full health.
    final result2 = doBattle(first: player2, second: enemy);
    expect(result2.first.hp, 6);
  });

  test('Golden Redwood Helmet', () {
    const item = 'Golden Redwood Helmet';
    final player = data.player(items: [item], hp: 5);
    expect(player.hp, 5);
    expect(player.baseStats.armor, 2);

    final enemy = makeEnemy(attack: 1, health: 12);
    // We would kill the wolf in 12 turns (take 9 dmg, 2 absorbed by armor), but
    // the golden helmet triggers after the armor is broken, healing 6 hp.
    // 6 would over-heal, so we only get 5 hp.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 1);

    final player2 = data.player(items: [item]);
    expect(player2.hp, 10);
    expect(player2.baseStats.armor, 2);

    // But if we fight with full health, the helmet triggers at exposed
    // and does nothing because we're already at full health.
    final result2 = doBattle(first: player2, second: enemy);
    expect(result2.first.hp, 1);
  });

  test('Explosive Surprise', () {
    const item = 'Explosive Surprise';
    final player = data.player(armor: 1, items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 1);

    final enemy = makeEnemy(attack: 1, health: 6);
    // We would kill the wolf in 6 turns (take 5 dmg), but the explosive
    // surprise triggers at exposed, dealing 5 dmg to the wolf, killing it
    // in 2 turns.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 10);
  });

  test('Cracked Bouldershield', () {
    const item = 'Cracked Bouldershield';
    final player = data.player(armor: 1, items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 1);

    final enemy = makeEnemy(attack: 1, health: 6);
    // We would kill the wolf in 6 turns (take 5 dmg), but the bouldershield
    // triggers at exposed, giving 5 armor, so we take no damage.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 10);
    // We still have our base armor, but any armor during battle is gone.
    expect(player.baseStats.armor, 1);
  });

  test('Vampiric Wine', () {
    const item = 'Vampiric Wine';
    final player = data.player(items: [item], hp: 9);
    expect(player.hp, 9);

    final enemy = makeEnemy(attack: 1, health: 6);
    // Normally take 5 dmg but the wine triggers
    // when we're at 50% health, healing 4 hp.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 8);
  });

  test('Golden Vampiric Wine', () {
    const item = 'Golden Vampiric Wine';
    final player = data.player(items: [item], hp: 9);
    expect(player.hp, 9);

    final enemy = makeEnemy(attack: 1, health: 6);
    // Normally take 5 dmg but the wine triggers
    // when we're at 50% health, healing 8 hp.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 9);
  });

  test('Wounded when already below 50%', () {
    const item = 'Vampiric Wine';
    final player = data.player(items: [item], hp: 4);
    expect(player.hp, 4);

    // Wounded does not trigger when we're already below 50% health.
    // You have to be at-or-above 50% when taking damage for it to trigger.
    // https://discord.com/channels/1041414829606449283/1209488302269534209/1274771566231552151
    final enemy = makeEnemy(attack: 1, health: 6);
    // Normally take 5 dmg but the wine triggers
    // when we're below 50% health, healing 4 hp.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 0);
  });

  test('Mortal Edge', () {
    const item = 'Mortal Edge';
    final player = data.player(items: [item], hp: 6);
    expect(player.hp, 6);
    expect(player.baseStats.attack, 2);

    final enemy = makeEnemy(attack: 1, health: 6);
    // Normally take 5 dmg but the mortal edge triggers
    // when we're below 50% health, increasing attack by 5 and taking 2 dmg.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 3);
    expect(result.first.baseStats.attack, 2);
  });

  test('Lifeblood Burst', () {
    const item = 'Lifeblood Burst';
    final player = data.player(items: [item], hp: 6);
    expect(player.hp, 6);

    final enemy = makeEnemy(attack: 1, health: 6);
    // Normally take 5 dmg but the lifeblood burst triggers
    // onWounded, dealing 5 dmg to the enemy.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 5);
    expect(result.second.hp, 0);
  });

  test('Chain Mail', () {
    const item = 'Chain Mail';
    final player = data.player(armor: 3, items: [item], hp: 6);
    expect(player.hp, 6);
    expect(player.baseStats.armor, 3);

    final enemy = makeEnemy(attack: 1, health: 6);
    // Normally take 5 dmg but the first 3 are absorbed by the armor
    // and then the chain mail triggers, giving 3 armor again, so take 1 dmg.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 5);
    expect(result.first.baseStats.armor, 3);
  });

  test('Stoneslab Sword', () {
    const item = 'Stoneslab Sword';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 2);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy(attack: 1, health: 6);
    // We attack first, and then the sword triggers, giving 2 armor, so we
    // never take damage.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 10);
    expect(result.first.baseStats.armor, 0);
  });

  test('Heart Drinker', () {
    const item = 'Heart Drinker';
    final player = data.player(items: [item]);
    expect(player.hp, 10);

    final enemy = makeEnemy(attack: 2, health: 6);
    // We attack first, and then the sword triggers, healing 1 hp, so we only
    // lose 2 hp since wolf hits us twice and we gain 3 from attacking.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 8);
  });

  test('Gold Ring', () {
    const item = 'Gold Ring';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.gold, 0);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 5);
    // Gain one gold at battle start and one gold at battle end.
    expect(result.first.gold, 2);
  });

  test('Ruby Ring', () {
    const item = 'Ruby Ring';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 1);

    // Ruby Ring gives 1 attack and takes 2 damage at the start of battle.
    // Which means we only take 2 dmg from wolf, but 2 from ring.
    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 6);
  });

  test('Golden Ruby Ring', () {
    const item = 'Golden Ruby Ring';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 1);

    // Ruby Ring gives 2 attack and takes 4 damage at the start of battle.
    // Which means we only take 1 dmg from wolf, but 4 from ring.
    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 5);
  });

  test('Ruby Crown', () {
    const item = 'Ruby Crown';
    final player = data.player(items: [item]);
    // Ruby crown gives +1 attack and -1 speed.
    expect(player.hp, 10);
    expect(player.baseStats.attack, 2);
    expect(player.baseStats.speed, -1);
    expect(player.inventory!.items.last.effect, isNull);
  });

  test('Melting Iceblade', () {
    const item = 'Melting Iceblade';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 7);

    // Melting Iceblade reduces attack by 1 on Hit, so first hit is 7
    // then 6, 5, 4, 3, 2, 1, 0.
    // 15 will take 3 hits, so we should take 2 dmg.
    final enemy = makeEnemy(attack: 1, health: 15);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 8);
    // Attack recovers after battle I think?
    expect(result.first.baseStats.attack, 7);
  });

  test('Melting Iceblade attack clamping', () {
    const item = 'Melting Iceblade';
    final player = data.player(maxHp: 100, items: [item]);
    expect(player.hp, 100);
    expect(player.baseStats.attack, 7);

    // Melting Iceblade reduces attack by 1 on Hit, so first hit is 7
    // then 6, 5, 4, 3, 2, 1, 0.
    // Melting Iceblade can only do 28 dmg when clamped to 0, so we will lose
    // to a 29 health enemy.
    final enemy = makeEnemy(attack: 1, health: 29);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 0);
    expect(result.first.baseStats.attack, 7);
  });

  test('Double-edged Sword', () {
    const item = 'Double-edged Sword';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 5);

    // Double-edged Sword deals 1 damage on hit, so we should take 3 dmg.
    // One from wolf and two from sword.
    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 7);
  });

  test('Sapphire Crown', () {
    const item = 'Sapphire Crown';
    final player = data.player(items: [item]);
    // Sapphire Crown gives -2 health and +5 armor.
    expect(player.baseStats.maxHp, 8);
    expect(player.baseStats.armor, 5);
    expect(player.inventory!.items.last.effect, isNull);
  });

  test('Citrine Ring', () {
    const item = 'Citrine Ring';
    final player = data.player(items: [item], speed: 2);
    expect(player.baseStats.speed, 2);

    // Citrine Ring deals damage equal to our speed at the start of battle.
    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 7);

    final player2 = data.player(items: [item], speed: -2);
    expect(player2.baseStats.speed, -2);

    // Speed can be negative, but won't deal negative damage.
    final result2 = doBattle(first: player2, second: enemy);
    // Wolf goes first so we take 6 hits rather than 5.
    expect(result2.first.hp, 4);
  });

  test('Marble Mirror', () {
    const item = 'Marble Mirror';
    final player = data.player(items: [item], attack: 1);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 2);
    expect(player.baseStats.armor, 0);

    // Marble Mirror gives armor equal to the enemy's armor at the start.
    final enemy = makeEnemy(attack: 1, health: 6, armor: 3);
    final result = doBattle(first: player, second: enemy);
    // We have 2 attack, wolf has 9 hp + armor, so we need 5 hits.
    // Wolf attacks 4 times, so we take 4 dmg, but mirror gives 3 armor.
    expect(result.first.hp, 9);
    expect(result.first.baseStats.armor, 0);

    final player2 = data.player(items: [item]);
    expect(player2.hp, 10);
    expect(player2.baseStats.attack, 1);
    expect(player2.baseStats.armor, 0);

    final enemy2 = makeEnemy(attack: 1, health: 6);
    final result2 = doBattle(first: player2, second: enemy2);
    // We have 1 attack, wolf has 6 hp, so we need 6 hits.
    // Wolf attacks 5 times, so we take 5 dmg, but mirror gives 0 armor.
    expect(result2.first.hp, 5);
    expect(player2.baseStats.armor, 0);
  });

  test('Leather Boots', () {
    const item = 'Leather Boots';
    final player = data.player(items: [item], speed: 2);
    expect(player.hp, 10);
    expect(player.baseStats.speed, 2);
    expect(player.baseStats.attack, 1);

    // Leather Boots gives 2 attack if we have more speed than the enemy.
    final enemy = makeEnemy(attack: 1, health: 6, speed: 1);
    final result = doBattle(first: player, second: enemy);
    // With leather boots we get +2 attack so we kill the wolf in 2 hits.
    expect(result.first.hp, 9);
    expect(result.first.baseStats.attack, 1);

    final player2 = data.player(items: [item], speed: 1);
    expect(player2.hp, 10);
    expect(player2.baseStats.speed, 1);
    expect(player2.baseStats.attack, 1);

    // With the same speed, we don't get the attack bonus.
    final result2 = doBattle(first: player2, second: enemy);
    expect(result2.first.hp, 5);
  });

  test('Plated Helmet', () {
    const item = 'Plated Helmet';
    final player = data.player(items: [item], hp: 5);
    expect(player.hp, 5);
    expect(player.baseStats.armor, 0);

    // Plated Helmet gives 2 armor if we're below 50% health.
    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // We take 1 dmg from the wolf the first hit, and then no more after that
    // due to the 2 armor we get each turn from the helmet.
    expect(result.first.hp, 4);
    expect(result.first.baseStats.armor, 0);

    final player2 = data.player(items: [item]);
    expect(player2.hp, 10);
    expect(player2.baseStats.armor, 0);

    // If we're not below 50% health, the helmet does nothing.
    final result2 = doBattle(first: player2, second: enemy);
    expect(result2.first.hp, 5);
    expect(result2.first.baseStats.armor, 0);
  });

  test('Ore Heart', () {
    const item = 'Ore Heart';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);

    // Ore Heart gives 2 armor for each stone item we have.
    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // We get 2 armor from the Ore Heart, so we take 3 dmg from the wolf.
    expect(result.first.hp, 7);
    expect(result.first.baseStats.armor, 0);

    final other = Item.test(material: ItemMaterial.stone);
    final player2 = data.player(customItems: [itemCatalog[item], other]);
    expect(player2.hp, 10);
    expect(player2.baseStats.armor, 0);

    // Ore Heart gives 2 armor for each stone item we have.
    final result2 = doBattle(first: player2, second: enemy);
    // We get 4 armor from the Ore Heart, so we take 1 dmg from the wolf.
    expect(result2.first.hp, 9);
  });

  test('Granite Hammer', () {
    const item = 'Granite Hammer';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 2);
    expect(player.baseStats.armor, 0);

    // Granite Hammer gives 2 attack and 1 armor on hit if we have armor.
    // If we don't have armor it does nothing.
    final enemy = makeEnemy(attack: 1, health: 10);
    final result = doBattle(first: player, second: enemy);
    // Takes 5 hits to kill the wolf, so we take 4 dmg.
    expect(result.first.hp, 6);
    expect(result.first.baseStats.attack, 2);
    expect(result.first.baseStats.armor, 0);

    final player2 = data.player(armor: 1, items: [item]);
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
    const item = 'Iron Transfusion';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Iron Transfusion gives 2 armor and loses 1 hp every turn.
    // We take 6 turns to kill the wolf, so we lose 6 hp.
    // The wolf never gets through our armor.
    expect(result.first.hp, 4);
    expect(result.first.baseStats.armor, 0);
  });

  test('Iron Transfusion can kill', () {
    final item = itemCatalog['Iron Transfusion'];
    final healOnHit = Item.test(effect: onHit((c) => c.restoreHealth(1)));
    final player = data.player(customItems: [item, item, healOnHit], hp: 1);
    expect(player.hp, 1);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // We die on the first turn from our own item, even though our healOnHit
    // item triggers, it's too late.
    expect(result.first.hp, 0);
    expect(result.first.baseStats.armor, 0);
  });

  test('Fortified Gauntlet', () {
    const item = 'Fortified Gauntlet';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // We never gain any armor from the gauntlet.
    expect(result.first.hp, 5);
    expect(result.first.baseStats.armor, 0);

    final player2 = data.player(armor: 1, items: [item]);
    expect(player2.hp, 10);
    expect(player2.baseStats.armor, 1);

    final result2 = doBattle(first: player2, second: enemy);
    // Fortified Gauntlet gives 1 armor if we have armor.
    // So we never take any damage from the wolf.
    expect(result2.first.hp, 10);
    expect(result2.first.baseStats.armor, 1);
  });

  test('Item order matters', () {
    final armor = Item.test(
      effect: onTurn((c) => c.gainArmor(1)),
    );
    final gauntlet = itemCatalog['Fortified Gauntlet'];
    final player = data.player(customItems: [armor, gauntlet]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy(attack: 2, health: 6);
    // The armor item gives 1 armor before the gauntlet, so the Gauntlet
    // triggers and gives 1 armor, so we take no damage from the wolf.
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 10);
    expect(result.first.baseStats.armor, 0);

    final player2 = data.player(customItems: [gauntlet, armor]);
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
    final healOnHit = Item.test(
      effect: onHit((c) => c.restoreHealth(1)),
    );
    final item = itemCatalog['Iron Rose'];
    // Order of the items should not matter in this case.
    final player = data.player(customItems: [item, healOnHit]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy(attack: 3, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Iron Rose gives 1 armor on (successful) heal, but the first hit we're
    // not damaged, so it does nothing.  Our remaining 5 hits heal 1 each time.
    // Wolf hits us 5 times, the first time for 3 dmg, then 1 for each.
    // TODO(eseidel): Should the last hit heal?
    // The last hit does not heal us (since battle immediately ends)?
    expect(result.first.hp, 3);
    expect(result.first.baseStats.armor, 0);

    // This time w/o the healOnHit item, the iron rose won't trigger.
    final player2 = data.player(customItems: [item], hp: 5);
    expect(player2.hp, 5);
    expect(player2.baseStats.armor, 0);

    final result2 = doBattle(first: player2, second: enemy);
    expect(result2.first.hp, 0);
    expect(result2.first.baseStats.armor, 0);
  });

  test('Featherweight Coat', () {
    const item = 'Featherweight Coat';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);
    expect(player.baseStats.speed, 0);

    final enemy = makeEnemy(attack: 1, health: 6, speed: 2);
    final result = doBattle(first: player, second: enemy);
    // Featherweight Coat gives 3 speed if we have armor, but we don't.
    // Wolf goes first so we take 6 dmg.
    expect(result.first.hp, 4);
    expect(result.first.baseStats.armor, 0);
    expect(result.first.baseStats.speed, 0);

    final player2 = data.player(armor: 1, items: [item]);
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
    const item = 'Redwood Roast';
    final player = data.player(items: [item]);
    expect(player.hp, 15);
    expect(player.baseStats.maxHp, 15);

    final player2 = data.player(items: [item, item]);
    expect(player2.hp, 20);
    expect(player2.baseStats.maxHp, 20);
  });

  test('Sticky Web', () {
    const item = 'Sticky Web';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.speed, 0);

    final enemy = makeEnemy(attack: 1, health: 6, speed: 2);
    final result = doBattle(first: player, second: enemy);
    // Wolf is faster, but the web triggers and so we go first.
    expect(result.first.hp, 5);
    expect(result.first.baseStats.speed, 0);

    final player2 = data.player(speed: 2, items: [item]);
    expect(player2.hp, 10);
    expect(player2.baseStats.speed, 2);

    final result2 = doBattle(first: player2, second: enemy);
    // We're the same speed, so the web does nothing.
    expect(result2.first.hp, 5);
    expect(result2.first.baseStats.speed, 2);
  });

  test('Impressive Physique', () {
    const item = 'Impressive Physique';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);

    // With no armor, nothing happens.
    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 5);
    expect(result.first.baseStats.armor, 0);

    final player2 = data.player(items: [item], armor: 1);
    expect(player2.hp, 10);
    expect(player2.baseStats.armor, 1);

    final result2 = doBattle(first: player2, second: enemy);
    // When our armor breaks, the wolf is stunned for 1 turn.
    // So we only take 4 dmg from the wolf - 1 from the armor.
    expect(result2.first.hp, 7);
    expect(result2.first.baseStats.armor, 1);
  });

  test('Steelbond Curse', () {
    // Steelbond Curse is not a weapon, so we keep our wooden stick.
    const item = 'Steelbond Curse';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);
    expect(player.baseStats.attack, 3);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Steelbond Curse gives 8 armor to the enemy, so it takes 14 dmg to kill
    // We hit for 3, so that's 5 hits, so we take 4 dmg.
    expect(result.first.hp, 6);
    expect(player.baseStats.armor, 0);
    expect(player.baseStats.attack, 3);
  });

  test('Bejeweled Blade', () {
    final item = itemCatalog['Bejeweled Blade'];
    final player = data.player(customItems: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 0);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Bejeweled Blade gives 2 attack for each jewelry item we have
    // if we don't have any jewelry we have 0 attack!
    expect(result.first.hp, 0);
    expect(player.baseStats.attack, 0);

    final jewelry = Item.test(kind: ItemKind.jewelry);
    final player2 = data.player(customItems: [item, jewelry]);
    expect(player2.hp, 10);
    // We've implemented Bejeweled Blade onBattle so this is still 0.
    expect(player2.baseStats.attack, 0);

    final result2 = doBattle(first: player2, second: enemy);
    // Bejeweled Blade gives 2 attack for each jewelry item we have.
    // So we kill the wolf in 3 attacks, so we take 2 dmg.
    expect(result2.first.hp, 8);
    expect(player2.baseStats.attack, 0);
  });

  test('Emerald Ring', () {
    const item = 'Emerald Ring';
    final player = data.player(items: [item], hp: 7);
    expect(player.hp, 7);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Emerald ring restores 2 hp on battle start, then wolf does 5 dmg.
    expect(result.first.hp, 4);
  });
  test('Golden Emerald Ring', () {
    const item = 'Golden Emerald Ring';
    final player = data.player(items: [item], hp: 5);
    expect(player.hp, 5);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Golden Emerald Ring restores 4 hp on battle start, then wolf does 5 dmg.
    expect(result.first.hp, 4);

    // Test with full health
    final player2 = data.player(items: [item]);
    expect(player2.hp, 10);

    final result2 = doBattle(first: player2, second: enemy);
    // Golden Emerald Ring restores 4 hp on battle start (but player is already
    // at max), then wolf does 5 dmg.
    expect(result2.first.hp, 5);
  });

  test('Ironskin Potion', () {
    const item = 'Ironskin Potion';
    final player = data.player(items: [item], hp: 6);
    expect(player.hp, 6);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Ironskin potion gives armor = lost hp (4) so we only take 1 dmg.
    expect(result.first.hp, 5);
    expect(result.first.baseStats.armor, 0);

    final player2 = data.player(items: [item], hp: 10);
    expect(player2.hp, 10);
    expect(player2.baseStats.armor, 0);
    final result2 = doBattle(first: player2, second: enemy);
    // Ironskin potion gives armor = lost hp (0) so we take 5 dmg.
    expect(result2.first.hp, 5);
    expect(result2.first.baseStats.armor, 0);
  });

  test('Double-plated Armor', () {
    const item = 'Double-plated Armor';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 2);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Double-plated armor makes us slower, so wolf hits us 6 times.
    // It absorbs the first 2 hits with armor and then adds 3 armor on exposed.
    expect(result.first.hp, 9);
    expect(result.first.baseStats.armor, 2);
  });

  test('Sapphire Earring', () {
    const item = 'Sapphire Earring';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Sapphire Earring gains 1 armor every other turn starting the first.
    // We would take 5 dmg from the wolf, but the earning negates 3 of that.
    expect(result.first.hp, 8);
    expect(result.first.baseStats.armor, 0);
  });

  test('Emerald Earring', () {
    const item = 'Emerald Earring';
    final player = data.player(items: [item]);
    expect(player.hp, 10);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Emerald Earring gains 1 hp every other turn starting the first.
    // We would take 5 dmg from the wolf, but the earning negates 2 of that
    // since the first heal happens while we're at full hp.
    expect(result.first.hp, 7);
  });

  test('Emerald Crown', () {
    const itemName = 'Emerald Crown';
    final player = data.player(items: [itemName]);
    // Emerald crown gives +8 hp and -1 attack.
    expect(player.baseStats.maxHp, 18);
    expect(player.baseStats.attack, 0);
    final item = player.inventory!.items.last;
    expect(item.name, itemName);
    expect(item.effect, isNull);
  });

  test('Sapphire Ring', () {
    const item = 'Sapphire Ring';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 0);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Sapphire Ring does nothing if enemy has no armor.
    expect(result.first.hp, 5);
    expect(result.first.baseStats.armor, 0);

    final enemy2 = makeEnemy(attack: 1, health: 6, armor: 1);
    final result2 = doBattle(first: player, second: enemy2);
    // Sapphire Ring steals up to 2 armor from the enemy.
    expect(result2.first.hp, 6);
    expect(result2.first.baseStats.armor, 0);
    expect(result2.second.baseStats.armor, 1);

    final enemy3 = makeEnemy(attack: 1, health: 6, armor: 2);
    final result3 = doBattle(first: player, second: enemy3);
    // Sapphire Ring steals up to 2 armor from the enemy.
    expect(result3.first.hp, 7);
    expect(result3.first.baseStats.armor, 0);
    expect(result3.second.baseStats.armor, 2);

    final enemy4 = makeEnemy(attack: 1, health: 6, armor: 3);
    final result4 = doBattle(first: player, second: enemy4);
    // Sapphire Ring steals up to 2 armor from the enemy.
    expect(result4.first.hp, 6);
    expect(result4.first.baseStats.armor, 0);
    expect(result4.second.baseStats.armor, 3);
  });

  test('Horned Helmet', () {
    const item = 'Horned Helmet';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 2);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Horned Helmet gives 2 armor and 2 thorns on battle start.
    // 2 armor negates 2 hits from wolf and 2 thorns deal 2 dmg to wolf.
    // Wolf only gets attack 3 times instead of 5 and 2 of those are blocked.
    expect(result.first.hp, 9);
    expect(result.first.baseStats.armor, 2);
  });

  test('Golden Horned Helmet', () {
    const item = 'Golden Horned Helmet';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 4);

    final enemy = makeEnemy(attack: 1, health: 10);
    final result = doBattle(first: player, second: enemy);
    // Golden Horned Helmet gives 4 armor and 4 thorns on battle start.
    // 4 armor negates 4 hits from wolf and 4 thorns deal 4 dmg to wolf.
    // Wolf only gets attack 5 times instead of 9 and 4 of those are blocked.
    expect(result.first.hp, 9);
    expect(result.first.baseStats.armor, 4);
  });

  test('Crimson Cloak', () {
    const item = 'Crimson Cloak';
    final player = data.player(items: [item]);
    expect(player.hp, 10);

    // Note this wolf is attacking with 2 rather than 1.
    final enemy = makeEnemy(attack: 2, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Crimson Cloak heals onTakeDamage, so for every 2 dmg we take, we heal 1.
    expect(result.first.hp, 5);

    final player2 = data.player(items: [item], hp: 5, armor: 10);
    expect(player2.hp, 5);
    final result2 = doBattle(first: player2, second: enemy);
    // Crimson Cloak triggers even if armor blocks the damage?
    expect(result2.first.hp, 10);
  });

  test('Tree Sap', () {
    final item = itemCatalog['Tree Sap'];
    final player = data.player(customItems: [item], hp: 8);
    expect(player.baseStats.maxHp, 15);
    expect(player.hp, 8);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Tree Sap heals 1 hp 5 times on wounded, negating all of the wolf's dmg.
    expect(result.first.hp, 8);

    final heals = Item.test(effect: onHeal((c) => c.gainArmor(1)));
    final player2 = data.player(customItems: [item, heals], hp: 8);
    expect(player2.baseStats.maxHp, 15);
    expect(player2.hp, 8);
    final result2 = doBattle(first: player2, second: enemy);
    // Tree Sap heals 1 hp 5 times on wounded, but the onHeal item triggers
    // and gives us 1 armor every time we heal, so we gain 5 armor.
    // Thus we get hit once for 1 dmg, then heal 5 times and gain 5 armor.
    expect(result2.first.hp, 12);
  });

  test('Petrifying Flask', () {
    const item = 'Petrifying Flask';
    final player = data.player(items: [item], hp: 6);
    expect(player.hp, 6);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Petrifying Flask gives 10 armor and self-stuns for 2 turns on wounded.
    expect(result.first.hp, 5);
    // turns is 0-indexed, turn 7 is the 8th turn.
    expect(result.turns, 7);
  });

  test('Ruby Gemstone', () {
    const item = 'Ruby Gemstone';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 1);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Ruby Gemstone triggers on-hit for 4 if we have exactly 1 attack.
    // Thus we kill the wolf in 2 hits, losing only 1 hp.
    expect(result.first.hp, 9);
    expect(result.first.baseStats.attack, 1);

    final player2 = data.player(attack: 1, items: [item]);
    expect(player2.hp, 10);
    expect(player2.baseStats.attack, 2);
    // If we have more than 1 attack, the Ruby Gemstone does nothing.
    final result2 = doBattle(first: player2, second: enemy);
    // We have 2 attack, so wolf dies in 3 hits, we take 2 dmg.
    expect(result2.first.hp, 8);
  });

  test('Bloody Steak', () {
    const item = 'Bloody Steak';
    final player = data.player(items: [item], hp: 6);
    expect(player.hp, 6);

    final enemy = makeEnemy(attack: 2, health: 6);
    final result = doBattle(first: player, second: enemy);
    // On wounded, gain 50% of maxHp as armor.  In our case, that's 5 hp.
    // We kill the wolf in 6 hits, so we take 10 dmg, 5 of which is blocked
    // by armor.
    expect(result.first.hp, 1);
  });

  test('Assault Greaves', () {
    const item = 'Assault Greaves';
    final player = data.player(items: [item]);
    expect(player.hp, 10);

    final enemy = makeEnemy(attack: 1, health: 6, speed: 2);
    final result = doBattle(first: player, second: enemy);
    // Assault Greaves deals 1 dmg every time we take dmg.
    // Meaning we kill the wolf in 3 turns rather than 5.
    expect(result.first.hp, 7);

    final player2 = data.player(
      armor: 1,
      items: [item],
    );
    expect(player2.hp, 10);
    expect(player2.baseStats.armor, 1);

    final result2 = doBattle(first: player2, second: enemy);
    // Assault Greaves triggers even when armor blocks the damage.
    expect(result2.first.hp, 8);
  });

  test('Thorn Ring', () {
    const item = 'Thorn Ring';
    final player = data.player(items: [item], armor: 1);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 1);

    final enemy = makeEnemy(attack: 1, health: 9);
    final result = doBattle(first: player, second: enemy);
    // Thorn Ring adds 6 thorns on battle start.
    // Wolf hits us twice for 1 dmg each.
    expect(result.first.hp, 9);
    expect(result.first.baseStats.armor, 1);
  });

  test('Bramble Buckler', () {
    const item = 'Bramble Buckler';
    final player = data.player(items: [item], armor: 1);
    expect(player.hp, 10);
    expect(player.baseStats.armor, 3);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Bramble Buckler gives 2 armor. onTurn we convert 1 armor to 2 thorns.
    // Wolf takes 4 dmg from thorns, 2 dmg from attacks.
    // Wolf attacks 2 times, first is blocked by armor, second hits for 1.
    expect(result.first.hp, 9);
    expect(result.first.baseStats.armor, 3);
  });

  test('Stormcloud Spear', () {
    const item = 'Stormcloud Spear';
    final player = data.player(items: [item]);
    expect(player.hp, 10);

    final enemy = makeEnemy(attack: 1, health: 26);
    final result = doBattle(first: player, second: enemy);

    // Stormcloud Spear stuns the enemy for 2 turns every 5 strikes
    // Player attacks 13 times.
    // Enemy should be stunned twice (on 5th and 10th strike) for 2 turns each.
    // Enemy should only attack 8 times (1, 2, 3, 4, 7, 8, 9, 13)
    expect(result.first.hp, 2);
    expect(result.second.hp, 0);
  });

  test(
    'Explosive Sword',
    () {
      const item = 'Explosive Sword';
      final player = data.player(items: [item]);
      expect(player.hp, 10);

      final enemy = makeEnemy(attack: 1, health: 20);
      final result = doBattle(first: player, second: enemy);

      // Explosive Sword deals 4 dmg, does 6 dmg and sets attack=0 on exposed.
      // We kill the wolf in 5 hits, taking 4 dmg.
      expect(result.first.hp, 6);

      final player2 = data.player(armor: 1, items: [item]);
      expect(player2.hp, 10);
      expect(player2.baseStats.armor, 1);

      final result2 = doBattle(first: player2, second: enemy);
      // Explosive Sword deals 4 dmg, does 6 dmg and sets attack=0 on exposed.
      // Wolf breaks our armor on the first hit, we lose all attack and die.
      expect(result2.first.hp, 0);
      expect(result2.second.hp, 10);
    },
    skip: true,
  );

  test('Pinecone Plate', () {
    const item = 'Pinecone Plate';
    final player = data.player(items: [item]);
    expect(player.hp, 10);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Pinecone Plate gives 1 thorns every turn if we started with full health.
    // Enemy dies after 3 dmg from our strikes and 3 from thorns.
    expect(result.first.hp, 7);

    final player2 = data.player(items: [item], hp: 9);
    expect(player2.hp, 9);

    final result2 = doBattle(first: player2, second: enemy);
    // Since we didn't start with full health, pinecone plate does nothing.
    // Enemy hits us 5 times before dying.
    expect(result2.first.hp, 4);
  });

  test('Gemstone Scepter ruby', () {
    final item = itemCatalog['Gemstone Scepter'];
    final ruby = Item.test(name: 'Ruby');
    final player = data.player(customItems: [item, ruby]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 2);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Gemstone Scepter does 1 extra dmg on hit for each ruby (3 total).
    // So we kill the enemy in 2 hits.
    expect(result.first.hp, 9);
    expect(result.first.baseStats.attack, 2);

    final player2 = data.player(customItems: [item, ruby, ruby]);
    expect(player2.hp, 10);
    expect(player2.baseStats.attack, 2);
    final enemy2 = makeEnemy(attack: 1, health: 10);
    final result2 = doBattle(first: player2, second: enemy2);
    // Gemstone Scepter does 1 extra dmg on hit for each ruby (4 total).
    // So we kill the enemy in 3 hits.
    expect(result2.first.hp, 8);
  });

  test('Gemstone Scepter sapphire', () {
    final item = itemCatalog['Gemstone Scepter'];
    final sapphire = Item.test(name: 'Sapphire');
    final player = data.player(customItems: [item, sapphire]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 2);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Gemstone Scepter gains 1 armor on hit for each sapphire.
    // So we kill the enemy in 3 hits.
    expect(result.first.hp, 10);
    expect(result.first.baseStats.attack, 2);

    final player2 = data.player(customItems: [item, sapphire, sapphire]);
    expect(player2.hp, 10);
    expect(player2.baseStats.attack, 2);
    final enemy2 = makeEnemy(attack: 3, health: 6);
    final result2 = doBattle(first: player2, second: enemy2);
    // Gemstone Scepter gains 1 armor on hit for each sapphire (2 total).
    // Blocks 2 dmg each attack, we only take 2 dmg.
    expect(result2.first.hp, 8);
  });

  test('Gemstone Scepter emerald', () {
    final item = itemCatalog['Gemstone Scepter'];
    final emerald = Item.test(name: 'Emerald');
    final player = data.player(customItems: [item, emerald]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 2);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Gemstone Scepter heals 1 hp on hit for each emerald.
    // So we kill the enemy in 3 hits.
    expect(result.first.hp, 10);
    expect(result.first.baseStats.attack, 2);

    final player2 = data.player(customItems: [item, emerald, emerald]);
    expect(player2.hp, 10);
    expect(player2.baseStats.attack, 2);
    final enemy2 = makeEnemy(attack: 3, health: 6);
    final result2 = doBattle(first: player2, second: enemy2);
    // Gemstone Scepter heals 1 hp on hit for each emerald (2 total).
    // We take 3 dmg from the wolf, but heal 2 hp.
    // TODO(eseidel): Trigger onHit effects on winning hit.
    expect(result2.first.hp, 7); // This should be 8 not 7.
  });

  test('Gemstone Scepter citrine', () {
    final item = itemCatalog['Gemstone Scepter'];
    final citrine = Item.test(name: 'Citrine');
    final player = data.player(customItems: [item, citrine]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 2);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Gemstone Scepter strikes an 1 extra time on first turn for each citrine.
    // So we kill the enemy in 2 turns.
    expect(result.first.hp, 9);
    expect(result.first.baseStats.attack, 2);

    final player2 = data.player(customItems: [item, citrine, citrine]);
    expect(player2.hp, 10);
    expect(player2.baseStats.attack, 2);
    final enemy2 = makeEnemy(attack: 1, health: 10);
    final result2 = doBattle(first: player2, second: enemy2);
    // Gemstone Scepter strikes an 1 extra time on first turn for each citrine.
    // So we kill the enemy in 3 turns.
    expect(result2.first.hp, 8);
  });

  test('Blacksmith Bond', () {
    const item = 'Blacksmith Bond';
    final player = data.player(items: [item]);
    expect(player.hp, 10);

    // Blacksmith's bond allows an extra exposed trigger, which does
    // nothing by itself.
    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    expect(result.first.hp, 5);

    final healOnExposed =
        Item.test(effect: onExposed((c) => c.restoreHealth(1)));
    final player2 = data.player(items: [item], customItems: [healOnExposed]);
    final result2 = doBattle(first: player2, second: enemy);
    // Does nothing without armor to trigger exposed.
    expect(result2.first.hp, 5);

    final player3 =
        data.player(armor: 1, items: [item], customItems: [healOnExposed]);
    final result3 = doBattle(first: player3, second: enemy);
    // Only triggers once since we only expose once.
    // 5 dmg from wolf - 1 armor = 4 dmg.
    expect(result3.first.hp, 6);

    final armorOnExposed = Item.test(effect: onExposed((c) => c.gainArmor(1)));
    final player4 = data.player(
      armor: 1,
      items: [item],
      customItems: [armorOnExposed, healOnExposed],
    );
    final result4 = doBattle(first: player4, second: enemy);
    // We gain 1 armor and 1 hp on exposed, then we gain hp again due to
    // Blacksmith Bond allowing a second exposed trigger.
    // 5 dmg from wolf - 1 armor - 1 hp (overheal) - 1 armor - 1 hp = 1 dmg.
    expect(result4.first.hp, 8);
  });

  test('Brittlebark Bow', () {
    const item = 'Brittlebark Bow';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 4);

    final enemy = makeEnemy(attack: 1, health: 20);
    final result = doBattle(first: player, second: enemy);
    // Brittlebark Bow loses 2 attack after 3 strikes.
    // First 3 strikes are 4 dmg each, then 2 dmg each after that.
    // Enemy dies in 7 hits we take 6 dmg.
    expect(result.first.hp, 4);
    // Attack changes are only during battle.
    expect(result.first.baseStats.attack, 4);
  });

  test('Swiftstrike Rapier', () {
    // If more speed than the enemy on the first turn strike 2x extra times.
    const item = 'Swiftstrike Rapier';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 2);

    final enemy = makeEnemy(attack: 1, health: 8);
    final result = doBattle(first: player, second: enemy);
    // No speed advantage, so we hit the wolf 4 times for 2 dmg each.
    expect(result.first.hp, 7);

    final player2 = data.player(speed: 2, items: [item]);
    expect(player2.hp, 10);
    expect(player2.baseStats.attack, 2);
    final result2 = doBattle(first: player2, second: enemy);
    // Speed advantage means we hit 2x extra times on first turn.
    // 2 turns to kill enemy, we take 1 dmg.
    expect(result2.first.hp, 9);
    expect(result2.first.baseStats.attack, 2);
  });

  test('Swiftstrike Gauntlet', () {
    const item = 'Swiftstrike Gauntlet';
    final player = data.player(items: [item], hp: 6);
    expect(player.hp, 6);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Dueling Gauntlet gives one extra attack for the next turn on wounded.
    // So we kill the enemy in 5 turns rather than 6, taking 4 dmg.
    expect(result.first.hp, 2);
  });
  test('Bonespine Whip', () {
    const item = 'Bonespine Whip';
    final player = data.player(items: [item]);
    expect(player.hp, 10);
    expect(player.baseStats.attack, 2);

    final enemy = makeEnemy(attack: 1, health: 20);
    final result = doBattle(first: player, second: enemy);
    // Bonespine Whip adds two extra strikes which do 1 dmg each.
    // Thus we do 4 dmg per turn, killing the enemy in 5 turns.
    expect(result.first.hp, 6);
  });

  test('Heart-shaped Acorn', () {
    const item = 'Heart-shaped Acorn';
    final player = data.player(items: [item], maxHp: 20, hp: 10);
    expect(player.hp, 10);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Heart-shaped Acorn heals to full if base armor is 0, then we take
    // 5 dmg from the enemy.
    expect(result.first.hp, 15);
  });

  test('Cherry Bomb', () {
    const item = 'Cherry Bomb';
    final player = data.player(items: [item]);
    expect(player.hp, 10);

    final enemy = makeEnemy(attack: 1, health: 6);
    final result = doBattle(first: player, second: enemy);
    // Cherry Bomb deals 2 dmg to the enemy on battle start
    // So we kill it in 4 turns rather than 6, taking 3 dmg.
    expect(result.first.hp, 7);
  });
}
