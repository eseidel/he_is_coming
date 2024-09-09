import 'package:he_is_coming/he_is_coming.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  final data = runWithLogger(_MockLogger(), Data.load);
  Creature.defaultPlayerWeapon = data.items['Wooden Stick'];

  test('BitsBuilder', () {
    final builder = BitsBuilder()
      ..add(0, 0)
      ..add(1, 1)
      ..add(2, 2)
      ..add(3, 3)
      ..add(4, 4)
      ..add(5, 5)
      ..add(6, 6)
      ..add(7, 7);

    final bytes = builder.takeBytes();
    final reader = BitsReader(bytes);
    expect(reader.read(0), 0);
    expect(reader.read(1), 1);
    expect(reader.read(2), 2);
    expect(reader.read(3), 3);
    expect(reader.read(4), 4);
    expect(reader.read(5), 5);
    expect(reader.read(6), 6);
    expect(reader.read(7), 7);
  });

  test('BuildStateCodec round trip', () {
    const level = Level.two;
    final inventory = Inventory(
      level: Level.two,
      items: [data.items['Wooden Stick'], data.items['Shield of the Hero']],
      edge: data.edges['Cutting Edge'],
      oils: [data.oils['Attack Oil']],
      setBonuses: data.sets,
    );
    final state = BuildState(level, inventory);
    final encoded = BuildStateCodec.encode(state, data);
    final decoded = BuildStateCodec.decode(encoded, data);
    expect(decoded.level, Level.two);
    expect(decoded.inventory.items, inventory.items);
    expect(decoded.inventory.edge, inventory.edge);
    expect(decoded.inventory.oils, inventory.oils);
  });

  test('Items test', () {
    final edge = data.edges['Blunt Edge'];
    final oils = [
      data.oils['Armor Oil'],
      data.oils['Attack Oil'],
      data.oils['Speed Oil'],
    ];
    final itemNames = [
      'Explosive Sword',
      'Lifeblood Burst',
      'Emerald Ring',
      'Emerald Crown',
      'Citrine Ring',
      'Assault Greaves',
    ];
    final items = itemNames.map((name) => data.items[name]).toList();
    final inventory = Inventory(
      level: Level.end,
      items: items,
      edge: edge,
      oils: oils,
      setBonuses: data.sets,
    );
    final state = BuildState(Level.end, inventory);
    final encoded = BuildStateCodec.encode(state, data);
    expect(encoded, 'd726cc80e0e06080');
    final decoded = BuildStateCodec.decode(encoded, data);
    expect(decoded.level, Level.end);
    expect(decoded.inventory.items, items);
    expect(decoded.inventory.edge, data.edges['Cutting Edge']);
    expect(decoded.inventory.oils, [data.oils['Attack Oil']]);
  });
}
