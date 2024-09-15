import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:scoped_deps/scoped_deps.dart';

void doMain(List<String> arguments) {
  final data = Data.load();
  final foods = data.items.items.where((item) => item.isFood).toList();
  logger.info('${foods.length} food items found:');
  for (final food in foods) {
    logger.info('  ${food.name}');
  }

  final cauldronItems = data.items.items
      .where((item) => item.rarity == ItemRarity.cauldron)
      .toList();
  logger.info('${cauldronItems.length} cauldron items found:');
  for (final item in cauldronItems) {
    logger.info('  ${item.name}');
  }
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
