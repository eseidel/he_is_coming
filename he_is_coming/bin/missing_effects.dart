import 'package:he_is_coming/src/catalog.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:scoped_deps/scoped_deps.dart';

void logMissingEffects(Catalog catalog) {
  final items = catalog.items;
  final typeName = items.first.runtimeType;
  final missingEffects =
      items.where((item) => item.effect?.isEmpty ?? false).toList();
  if (missingEffects.isEmpty) {
    logger.info('All $typeName effects found.');
  } else {
    logger.warn(
      '${missingEffects.length} ${typeName}s with missing effects found:',
    );
    for (final item in missingEffects) {
      final effect = item.effect;
      logger.info('  $effect for ${item.name}');
    }
  }
}

void doMain(List<String> arguments) {
  // Just loading the data should print the effects warnings.
  final data = Data.load();
  logMissingEffects(data.items);
  logMissingEffects(data.creatures);
  logMissingEffects(data.oils);
  logMissingEffects(data.edges);
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
