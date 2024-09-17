import 'package:collection/collection.dart';
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
    logger.info('  ${item.name} (${item.sortedParts?.join(' + ')})');
  }

  // Walk through each cauldron item and make sure it has valid parts.
  for (final item in cauldronItems) {
    final parts = item.parts ?? {};
    if (parts.isEmpty) {
      logger.warn('Cauldron item ${item.name} has no parts!');
    } else {
      for (final part in parts) {
        final partItem =
            data.items.items.firstWhereOrNull((item) => item.name == part);
        if (partItem == null) {
          logger.warn('Part $part of ${item.name} not found!');
        } else if (!partItem.isFood) {
          logger.warn('Part $part of ${item.name} is not a food item!');
        }
      }
    }
  }

  // Find all combinations of food items.
  // List ones which we don't have a cauldron item for.
  for (var i = 0; i < foods.length; i++) {
    for (var j = i + 1; j < foods.length; j++) {
      final food1 = foods[i];
      final food2 = foods[j];
      final parts = {food1.name, food2.name};
      final cauldronItem = cauldronItems.firstWhereOrNull(
        (item) => item.parts != null && item.parts!.containsAll(parts),
      );
      if (cauldronItem == null) {
        logger.info('Missing ${parts.join(' + ')}');
      }
    }
  }
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
