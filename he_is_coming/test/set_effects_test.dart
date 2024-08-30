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

class _Needed {
  List<String> items = [];
  String? edge;
}

_Needed _lookupSet(String name, Data data) {
  final set = data.sets[name];
  final needed = _Needed();
  for (final part in set.parts) {
    final item = data.items.get(part);
    if (item != null) {
      needed.items.add(item.name);
      continue;
    }
    if (needed.edge != null) {
      throw Exception('Multiple edges in set $name');
    }
    needed.edge = part;
  }
  return needed;
}

void main() {
  final data = runWithLogger(_MockLogger(), Data.load);
  Creature.defaultPlayerWeapon = data.items['Wooden Stick'];

  Creature playerWithSet(String name) {
    final needed = _lookupSet(name, data);
    return data.player(
      items: needed.items,
      edge: needed.edge,
    );
  }

  test('Redwood Crown', () {
    final player = playerWithSet('Redwood Crown');
    expect(player.hp, 16); // 4 from rod, 2 from cloak
    expect(player.baseStats.armor, 1); // from Redwood Helmet
    expect(player.baseStats.attack, 2); // from Redwood Rod

    final enemy = makeEnemy(health: 16, attack: 2);
    final result = doBattle(first: player, second: enemy);
    // Wolf does 14 dmg over 7 hits, 1 is absorbed by armor.
    // Helmet restores 3 on exposed, player is only down 1 hp at that time.
    // Crown restores all health on wounded (after the 6th hit).
    expect(result.first.hp, 14);
  });

  // Sets work, even when the items are golden.
  test('Golden items', () {
    final items = [
      'Redwood Rod',
      'Redwood Cloak',
      'Golden Redwood Helmet',
    ];
    final player = data.player(items: items);
    expect(player.hp, 16); // 4 from rod, 2 from cloak
    expect(player.baseStats.armor, 2); // from Redwood Helmet
    expect(player.baseStats.attack, 2); // from Redwood Rod

    final enemy = makeEnemy(health: 16, attack: 2);
    final result = doBattle(first: player, second: enemy);
    // Wolf does 14 dmg over 7 hits, 2 is absorbed by armor.
    // Helmet restores 6 on exposed, player is at full health at that time.
    // Crown restores all health on wounded (after the 6th hit).
    expect(result.first.hp, 14);
  });

  test("Hero's Return", () {
    // Hero's return just gives +1 armor, +1 attack, +1 speed, no effects.
    final player = playerWithSet("Hero's Return");
    expect(player.hp, 10);
    expect(player.baseStats.armor, 4);
    expect(player.baseStats.attack, 4);
    expect(player.baseStats.speed, 3);
  });
}
