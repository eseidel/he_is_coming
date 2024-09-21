import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:json_diff/json_diff.dart';
import 'package:scoped_deps/scoped_deps.dart';

extension on ItemRarity {
  int get multiplier {
    if (this == ItemRarity.golden) return 2;
    if (this == ItemRarity.diamond) return 4;
    throw UnimplementedError();
  }

  String get prefix {
    if (this == ItemRarity.golden) return 'Golden';
    if (this == ItemRarity.diamond) return 'Diamond';
    throw UnimplementedError();
  }
}

Item inferItem(Item item, ItemRarity rarity) {
  final multiplier = rarity.multiplier;
  final prefix = rarity.prefix;
  String doubleNumbers(String text) {
    return text.splitMapJoin(
      RegExp(r'\d+'),
      onMatch: (m) => '${int.parse(m.group(0)!) * multiplier}',
      onNonMatch: (n) => n,
    );
  }

  final effect = item.effect != null
      ? Effect.textOnly(doubleNumbers(item.effect!.text))
      : null;
  final inferred = item.copyWith(
    name: '$prefix ${item.name}',
    rarity: ItemRarity.golden,
    effect: effect,
    inferred: true,
    stats: item.stats * multiplier,
    // Food loses its food tag when it becomes golden.
    tags: item.tags..remove(ItemTag.food),
    id: 0, // TODO(eseidel): assign a unique id?
    // Should this have parts of item x multiplier?
  );
  return inferred;
}

DiffNode diff({required Item actual, required Item inferred}) {
  final unstableKeys = <String>{'id', 'inferred', 'version'};
  String encodeStableJson(Item item) {
    final json = item.toJson();
    for (final key in unstableKeys) {
      json.remove(key);
    }
    return jsonEncode(json);
  }

  final actualString = encodeStableJson(actual);
  final expectedString = encodeStableJson(inferred);
  final differ = JsonDiffer(actualString, expectedString);
  return differ.diff();
}

void warnMissing({
  required ItemRarity rarity,
  required Iterable<Item> inferred,
  required Iterable<Item> actual,
}) {
  final prefix = rarity.prefix;
  final inferredNames = inferred.map((i) => i.name).toSet();
  final actualNames = actual.map((i) => i.name).toSet();
  final missing = inferredNames.difference(actualNames);
  final unexpected = actualNames.difference(inferredNames);
  if (missing.isEmpty) {
    logger.info('All $prefix items found.');
  } else {
    logger.warn('${missing.length} $prefix items missing:');
    for (final item in missing) {
      logger.info('  $item');
    }
  }
  if (unexpected.isNotEmpty) {
    logger.warn('${unexpected.length} unexpected $prefix items found:');
    for (final item in unexpected) {
      logger.info('  $item');
    }
  }
}

Iterable<Item> itemsToAdd({
  required Data data,
  required List<Item> inferredItems,
  required List<Item> actualItems,
}) sync* {
  for (final inferred in inferredItems) {
    final actual = actualItems.firstWhereOrNull((i) => i.name == inferred.name);
    if (actual == null) {
      yield inferred;
      continue;
    }
    // Otherwise check that the golden item matches the inferred item.
    final result = diff(actual: actual, inferred: inferred);
    if (!result.hasNothing) {
      logger.warn('${actual.name} does not match expected: $result');
    }
  }
}

void doMain(List<String> arguments) {
  final data = Data.load();
  final items = data.items.items;
  var nextId = items.map((item) => item.id).reduce(max) + 1;
  final combinable = items
      .where(
        (item) =>
            item.rarity == ItemRarity.common &&
            !item.isWeapon &&
            !item.isUnique &&
            !item.inferred, // Don't infer golden items from inferred items.
      )
      .toList();
  final golden =
      items.where((item) => item.rarity == ItemRarity.golden).toList();
  final diamond =
      items.where((item) => item.rarity == ItemRarity.diamond).toList();
  final inferredGolden =
      combinable.map((i) => inferItem(i, ItemRarity.golden)).toList();
  final inferredDiamond =
      combinable.map((i) => inferItem(i, ItemRarity.diamond)).toList();

  // Warn about items that are missing or unexpected.
  warnMissing(
    rarity: ItemRarity.golden,
    inferred: inferredGolden,
    actual: golden,
  );
  warnMissing(
    rarity: ItemRarity.diamond,
    inferred: inferredDiamond,
    actual: diamond,
  );

  // Compare the inferred items with the golden items.
  // Add any missing golden items to the data.
  final toAdd = [
    ...itemsToAdd(
      data: data,
      inferredItems: inferredGolden,
      actualItems: golden,
    ),
    ...itemsToAdd(
      data: data,
      inferredItems: inferredDiamond,
      actualItems: diamond,
    ),
  ];
  for (final item in toAdd) {
    logger.info('Adding $item');
    data.items.items.add(item.copyWith(id: nextId++));
  }

  data.save();
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
