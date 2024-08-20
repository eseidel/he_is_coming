import 'package:he_is_coming/src/item_catalog.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  runWithLogger(_MockLogger(), initItemCatalog);

  test('ItemCatalog smoke test', () {
    final item = itemCatalog['Wooden Stick'];
    expect(item.stats.attack, 1);
  });
}
