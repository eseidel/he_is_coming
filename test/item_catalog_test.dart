import 'package:he_is_coming/src/item_catalog.dart';
import 'package:test/test.dart';

void main() {
  test('ItemCatalog smoke test', () {
    final item = itemCatalog['Wooden Stick'];
    expect(item.stats.attack, 1);
  });
}
