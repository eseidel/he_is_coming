import 'package:collection/collection.dart';
import 'package:he_is_coming/src/item_catalog.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:scoped_deps/scoped_deps.dart';

// get all the first and last words in item names.
// Look for repeats.

void doMain(List<String> arguments) {
  initItemCatalog();

  final firstWords = <String, List<String>>{};
  final lastWords = <String, List<String>>{};

  for (final item in itemCatalog.items) {
    final words = item.name.split(' ');
    firstWords.putIfAbsent(words.first, () => []).add(item.name);
    lastWords.putIfAbsent(words.last, () => []).add(item.name);
  }

  final firstWordsSorted = firstWords.entries.toList()
    ..sortBy<num>((e) => -e.value.length);
  final lastWordsSorted = lastWords.entries.toList()
    ..sortBy<num>((e) => -e.value.length);

  for (final entry in firstWordsSorted) {
    if (entry.value.length < 2) continue;
    logger.info('${entry.key}: ${entry.value}');
  }

  logger.info('---');

  for (final entry in lastWordsSorted) {
    if (entry.value.length < 2) continue;
    logger.info('${entry.key}: ${entry.value}');
  }
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
