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

void endFight({
  required Data data,
  required List<String> items,
  required String? edge,
  required List<String> oils,
  required int turns,
  required int damage,
  bool verbose = false,
}) {
  final player = data.player(items: items, edge: edge, oils: oils);
  final enemy = data.creatures['Woodland Abomination'];
  final result = doBattle(first: player, second: enemy, verbose: verbose);
  expect(result.turns, turns);
  expect(result.second.lostHp, damage);
}

void main() {
  final data = runWithLogger(_MockLogger(), Data.load);

  test('Infinite battle', () {
    final healOnHit = onHit((c) => c.restoreHealth(1));
    final item = Item.test(effect: healOnHit);
    final player = data.player(customItems: [item]);
    final enemy = makeEnemy(attack: 1, health: 5, effect: healOnHit);
    final result = doBattle(first: player, second: enemy);
    // Stuck battles result in player wins.
    expect(result.first.hp, 10);
    expect(result.second.hp, 0);
  });

  test('Gemstone Scepter build', () {
    // https://discord.com/channels/1041414829606449283/1209488593219756063/1283570085268688989
    final items = [
      'Gemstone Scepter',
      'Horned Helmet',
      'Golden Sapphire Earring',
      'Boots of the Hero',
      'Golden Leather Glove',
      'Golden Emerald Earring',
      'Emerald Earring',
      'Pinecone Plate',
      'Sapphire Ring',
    ];
    const edge = 'Bleeding Edge';
    final oils = [
      'Attack Oil',
      'Armor Oil',
    ];
    endFight(
      data: data,
      items: items,
      edge: edge,
      oils: oils,
      turns: 12, // should be 13
      damage: 53, // should be 54
    );
  });

  test('Blackbriar Blade build', () {
    // https://discord.com/channels/1041414829606449283/1209488593219756063/1282945788846149685
    final items = [
      'Blackbriar Blade',
      'Tree Sap',
      'Sanguine Rose',
      'Crimson Cloak',
      'Razorvine Talisman',
      'Briar Rose',
      'Iron Rose',
      'Pinecone Plate',
      'Vampiric Wine',
    ];
    const edge = 'Cutting Edge';
    final oils = [
      'Attack Oil',
    ];
    endFight(
      data: data,
      items: items,
      edge: edge,
      oils: oils,
      turns: 12, // should be 15
      damage: 352, // should be 519
    );
  });

  test('Three cloak', () {
    // https://discord.com/channels/1041414829606449283/1209488593219756063/1286786296840323074
    final items = [
      'Granite Hammer',
      'Crimson Cloak',
      'Crimson Cloak',
      'Crimson Cloak',
      'Iron Transfusion',
      'Shield Talisman',
      'Iron Rose',
      'Pinecone Plate', // Unclear if this is correct?
      'Tree Sap',
    ];
    const edge = 'Blunt Edge';
    final oils = [
      'Attack Oil',
      'Armor Oil',
      'Speed Oil',
    ];
    endFight(
      data: data,
      items: items,
      edge: edge,
      oils: oils,
      turns: 19, // should be 50
      damage: 417, // should be 2642
    );
  });
}
