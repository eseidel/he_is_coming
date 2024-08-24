import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  final data = runWithLogger(_MockLogger(), Data.load);

  test('ItemCatalog smoke test', () {
    final item = data.items['Wooden Stick'];
    expect(item.stats.attack, 1);
  });
}
