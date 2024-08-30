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
  List<Item> items = [];
  Edge? edge;
}

_Needed _lookupSet(String name, Data data) {
  final set = data.sets[name];
  final needed = _Needed();
  for (final part in set.parts) {
    final item = data.items.get(part);
    if (item != null) {
      needed.items.add(item);
      continue;
    }
    if (needed.edge != null) {
      throw Exception('Multiple edges in set $name');
    }
    needed.edge = data.edges[part];
  }
  return needed;
}

void main() {
  final data = runWithLogger(_MockLogger(), Data.load);
  Creature.defaultPlayerWeapon = data.items['Wooden Stick'];

  test('Redwood Crown', () {
    final needed = _lookupSet('Redwood Crown', data);
    final player = data.createPlayer(items: needed.items, edge: needed.edge);
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
}
