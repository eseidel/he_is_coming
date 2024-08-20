import 'package:he_is_coming/src/item.dart';
import 'package:test/test.dart';

void main() {
  test('Weapons require attack', () {
    expect(
      () => Item(
        'Test',
        kind: Kind.weapon,
        Rarity.common,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
