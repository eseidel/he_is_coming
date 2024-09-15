import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  final data = runWithLogger(_MockLogger(), Data.load);
  Creature.defaultPlayerWeapon = data.items['Wooden Stick'];

  test('Weapons require attack', () {
    expect(
      () => Item.test(isWeapon: true),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('Unique items can only be equipped once', () {
    final item = Item.test(isUnique: true);
    expect(
      () => data.player(customItems: [item, item]),
      throwsA(isA<ItemException>()),
    );
  });
}
