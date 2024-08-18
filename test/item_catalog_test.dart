import 'package:he_is_coming_sim/src/battle.dart';
import 'package:he_is_coming_sim/src/creatures.dart';
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
}
