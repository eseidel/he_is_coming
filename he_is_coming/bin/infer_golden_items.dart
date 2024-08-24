import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/logger.dart';
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
    health: item.stats.maxHp,
    attack: item.stats.attack,
    armor: item.stats.armor,
    speed: item.stats.speed,
    // Should this have parts of item x 2?
  );
  return goldenItem;
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
  final inferred = combinable.map(inferGoldenItem).toList();
  // Compare the inferred items with the golden items.
  // Add any missing golden items to the data.
  final goldenNames = golden.map((item) => item.name).toSet();
  final inferredNames = inferred.map((item) => item.name).toSet();
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
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
