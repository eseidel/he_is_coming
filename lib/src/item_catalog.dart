import 'dart:io';

import 'package:collection/collection.dart';
import 'package:he_is_coming/src/item.dart';
import 'package:he_is_coming/src/item_effects.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

extension on YamlMap {
  T lookupOr<T extends Enum>(String key, List<T> values, T defaultValue) {
    final toFind = this[key] as String?;
    if (toFind == null) {
      return defaultValue;
    }
    final found = values.firstWhereOrNull((v) => v.name == toFind);
    if (found == null) {
      throw Exception('Unexpected $toFind in $this, expected in $values');
    }
    return found;
  }

  T lookup<T extends Enum>(String key, List<T> values) {
    final toFind = this[key] as String?;
    if (toFind == null) {
      throw Exception('$key is missing from $this');
    }
    final found = values.firstWhereOrNull((v) => v.name == toFind);
    if (found == null) {
      throw Exception('Unexpected $toFind in $this, expected in $values');
    }
    return found;
  }
}

class _ItemCatalogReader {
  static const List<String> _itemKeys = <String>[
    'name',
    'kind',
    'rarity',
    'material',
    'effect',
    'unlock', // ignored for now
    'unique',
    'attack',
    'health',
    'armor',
    'speed',
  ];

  static void validateKeys(YamlMap yaml, Set<String> expectedKeys) {
    final unexpected =
        yaml.keys.cast<String>().toSet().difference(expectedKeys);
    if (unexpected.isEmpty) {
      return;
    }
    for (final key in unexpected) {
      logger.err('Unexpected key: $key in $yaml allowed: $expectedKeys');
    }
    throw StateError('Unexpected keys in yaml');
  }

  static Item itemFromYaml(YamlMap yaml) {
    final name = yaml['name'] as String;
    final kind = yaml.lookupOr('kind', Kind.values, Kind.clothing);
    final rarity = yaml.lookup('rarity', Rarity.values);
    final material =
        yaml.lookupOr('material', Material.values, Material.leather);
    final attack = yaml['attack'] as int? ?? 0;
    final health = yaml['health'] as int? ?? 0;
    final armor = yaml['armor'] as int? ?? 0;
    final speed = yaml['speed'] as int? ?? 0;
    final effectText = yaml['effect'] as String?;
    final effects = effectsForItemNamed(name, effectText);
    validateKeys(yaml, _itemKeys.toSet());
    return Item(
      name,
      kind,
      rarity,
      material,
      attack: attack,
      health: health,
      armor: armor,
      speed: speed,
      effects: effects,
    );
  }

  static void _warnAboutMissingEffects(YamlList itemsYaml) {
    final itemYamlWithEffectText = itemsYaml
        .cast<YamlMap>()
        .where((yaml) => yaml['effect'] != null)
        .toSet();
    final itemsWithEffectText =
        itemYamlWithEffectText.map((yaml) => yaml['name'] as String).toSet();
    final itemsWithEffects = effectsByItemName.keys.toSet();
    final missingEffects = itemsWithEffectText.difference(itemsWithEffects);
    if (missingEffects.isNotEmpty) {
      logger.warn(
        '${missingEffects.length} items have effect text but no code:',
      );
      for (final item in missingEffects) {
        final yaml =
            itemYamlWithEffectText.firstWhere((yaml) => yaml['name'] == item);
        logger.info('${yaml['effect']}, for $item');
      }
      logger.info(''); // Add a newline.
    }
    final unusedEffects = itemsWithEffects.difference(itemsWithEffectText);
    if (unusedEffects.isNotEmpty) {
      logger.warn('Unused effects for: $unusedEffects');
    }
  }

  static List<Item> read(String path) {
    final itemsYaml = loadYaml(File(path).readAsStringSync()) as YamlList;
    _warnAboutMissingEffects(itemsYaml);
    return itemsYaml
        .cast<YamlMap>()
        .map<Item>(itemFromYaml)
        .sortedBy<String>((i) => i.name);
  }
}

/// Class to hold all known items.
class ItemCatalog {
  /// Create an ItemCatalog
  ItemCatalog(this.items);

  /// Create an ItemCatalog from a yaml file.
  factory ItemCatalog.fromFile(String path) {
    final items = _ItemCatalogReader.read(path);
    logger.info('Loaded ${items.length} from $path');
    return ItemCatalog(items);
  }

  /// The items in this catalog.
  final List<Item> items;

  /// Lookup an Item by name.
  Item operator [](String name) => items.firstWhere((i) => i.name == name);
}

final _defaultItemsPath = p.join('data', 'items.yaml');

/// Our global item catalog instance.
final itemCatalog = ItemCatalog.fromFile(_defaultItemsPath);
