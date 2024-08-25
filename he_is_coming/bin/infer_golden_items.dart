import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:json_diff/json_diff.dart';
import 'package:scoped_deps/scoped_deps.dart';

String doubleNumbers(String text) {
  return text.splitMapJoin(
    RegExp(r'\d+'),
    onMatch: (m) => '${int.parse(m.group(0)!) * 2}',
    onNonMatch: (n) => n,
  );
}

Item inferGoldenItem(Item item) {
  final effect = item.effect != null
      ? Effect(
          text: doubleNumbers(item.effect!.text),
          callbacks: const {},
        )
      : null;
  final goldenItem = Item(
    'Golden ${item.name}',
    ItemRarity.golden,
    material: item.material,
    isUnique: item.isUnique,
    kind: item.kind,
    effect: effect,
    inferred: true,
    stats: item.stats * 2,
    // Should this have parts of item x 2?
  );
  return goldenItem;
}

DiffNode diffWithGolden(Item item, Item golden) {
  final actualString = jsonEncode(item);
  final goldenJson = golden.toJson()..remove('inferred');
  final expectedString = jsonEncode(goldenJson);
  final differ = JsonDiffer(actualString, expectedString);
  return differ.diff();
}

void doMain(List<String> arguments) {
  final data = Data.load();
  final items = data.items.items;
  final combinable = items
      .where(
        (item) =>
            item.rarity == ItemRarity.common &&
            item.kind != ItemKind.weapon &&
            item.isUnique == false,
      )
      .toList();
  final golden =
      items.where((item) => item.rarity == ItemRarity.golden).toList();
  final inferredItems = combinable.map(inferGoldenItem).toList();

  // Warn about any golden items that are missing or unexpected.
  final goldenNames = golden.map((item) => item.name).toSet();
  final inferredNames = inferredItems.map((item) => item.name).toSet();
  final missing = inferredNames.difference(goldenNames);
  final unexpected = goldenNames.difference(inferredNames);
  if (missing.isEmpty) {
    logger.info('All golden items found.');
  } else {
    logger.warn('${missing.length} golden items missing:');
    for (final item in missing) {
      logger.info('  $item');
    }
  }
  if (unexpected.isNotEmpty) {
    logger.warn('${unexpected.length} unexpected golden items found:');
    for (final item in unexpected) {
      logger.info('  $item');
    }
  }

  // Compare the inferred items with the golden items.
  // Add any missing golden items to the data.
  for (final inferred in inferredItems) {
    final actual = golden.firstWhereOrNull((i) => i.name == inferred.name);
    if (actual == null) {
      logger.info('Adding: ${inferred.name}');
      data.items.items.add(inferred);
      continue;
    }
    // Otherwise check that the golden item matches the inferred item.
    final diff = diffWithGolden(actual, inferred);
    if (!diff.hasNothing) {
      logger.warn('${actual.name} does not match expected: $diff');
    }
  }

  data.save();
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}