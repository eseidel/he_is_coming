import 'package:he_is_coming_sim/src/item.dart';
import 'package:test/test.dart';

void main() {
  test('Weapons require attack', () {
    expect(
      () => Item(
        'Test',
        Kind.weapon,
        Rarity.common,
        Material.wood,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
