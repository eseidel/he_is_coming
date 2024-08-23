import 'dart:math';

import 'package:collection/collection.dart';
import 'package:he_is_coming/src/catalog.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/item.dart';
import 'package:he_is_coming/src/item_effects.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:yaml/yaml.dart';

Item? _itemFromYaml(YamlMap yaml, LookupEffect lookupEffect) {
  final name = yaml['name'] as String;
  final kind = yaml.get('kind', Kind.values);
  final rarity = yaml.expect('rarity', Rarity.values);
  final material = yaml.get('material', Material.values);
  final attack = yaml['attack'] as int? ?? 0;
  final health = yaml['health'] as int? ?? 0;
  final armor = yaml['armor'] as int? ?? 0;
  final speed = yaml['speed'] as int? ?? 0;
  final unlock = yaml['unlock'] as String?;
  final unique = yaml['unique'] as bool? ?? false;
  final effectText = yaml['effect'] as String?;
  final parts = yaml['parts'] as List?;
  final effect = lookupEffect(name: name, effectText: effectText);
  return Item(
    name,
    kind: kind,
    rarity,
    material: material,
    attack: attack,
    health: health,
    armor: armor,
    speed: speed,
    effect: effect,
    isUnique: unique,
    unlock: unlock,
    parts: parts?.cast<String>(),
  );
}

/// Class to hold all known items.
class ItemCatalog extends Catalog<Item> {
  /// Create an ItemCatalog
  ItemCatalog(super.items);

  /// Create an ItemCatalog from a yaml file.
  factory ItemCatalog.fromFile(String path) {
    final items = CatalogReader.read(
      path,
      _itemFromYaml,
      orderedKeys.toSet(),
      itemEffects,
    );
    logger.info('Loaded ${items.length} from $path');
    return ItemCatalog(items);
  }

  /// All the known keys in the item yaml, in sorted order.
  static const List<String> orderedKeys = <String>[
    'name',
    'unique',
    'kind',
    'rarity',
    'material',
    'unlock', // ignored for now
    'parts', // ignored for now
    'attack',
    'health',
    'armor',
    'speed',
    'effect',
  ];

  /// All the weapons in the catalog.
  List<Item> get weapons => items.where((i) => i.kind == Kind.weapon).toList();

  /// All the non-weapon items in the catalog.
  List<Item> get nonWeapons =>
      items.where((i) => i.kind != Kind.weapon).toList();

  /// Get a random weapon from the catalog.
  Item randomWeapon(Random random) => weapons[random.nextInt(weapons.length)];

  /// Get a random non-weapon item from the catalog.
  Item randomNonWeapon(Random random) =>
      nonWeapons[random.nextInt(nonWeapons.length)];

  /// Lookup an Item by name.
  @override
  Item operator [](String name) {
    final item = items.firstWhereOrNull((i) => i.name == name);
    if (item == null) {
      throw ArgumentError('Unknown item: $name');
    }
    return item;
  }
}
