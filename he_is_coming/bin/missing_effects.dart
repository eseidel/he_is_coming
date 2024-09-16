import 'package:he_is_coming/src/creature_effects.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/edge_effects.dart';
import 'package:he_is_coming/src/item_effects.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:he_is_coming/src/set_effects.dart';
import 'package:scoped_deps/scoped_deps.dart';

Set<String> findImplementedEffects() {
  final implementedEffectNames = <String>[
    ...creatureEffects.implemented,
    ...itemEffects.implemented,
    ...edgeEffects.implemented,
    ...setEffects.implemented,
  ];
  final implementedEffects = implementedEffectNames.toSet();
  if (implementedEffects.length != implementedEffectNames.length) {
    throw StateError('Duplicate effect names found.');
  }
  return implementedEffects;
}

void doMain(List<String> arguments) {
  final data = Data.load();
  final missingEffects = data
      .withoutInferredItems()
      .allItems
      .where((item) => !item.isImplemented)
      .toList();
  final sortedMissing = missingEffects.toList()
    ..sort((a, b) => a.effect!.text.compareTo(b.effect!.text));
  for (final item in sortedMissing) {
    logger.info('${item.effect!.text} for ${item.name}');
  }

  final allItemsMap = {
    for (final item in data.allItems) item.name: item,
  };
  final implementedEffects = findImplementedEffects();
  for (final name in implementedEffects) {
    final item = allItemsMap[name];
    if (item == null || item.effect == null || item.effect!.isEmpty) {
      logger.warn('Effect $name is implemented but not found in data');
    }
  }
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
