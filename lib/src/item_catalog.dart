import 'dart:io';

import 'package:collection/collection.dart';
import 'package:he_is_coming_sim/src/item.dart';
import 'package:he_is_coming_sim/src/logger.dart';
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

final _effectByItemName = <String, Effect>{
  'Stone Steak': Effect(
    onBattle: (ctx) {
      if (ctx.isHealthFull) {
        ctx.adjustArmor(4);
      }
    },
  ),
  'Redwood Cloak': Effect(
    onBattle: (ctx) {
      if (!ctx.isHealthFull) {
        ctx.restoreHealth(1);
      }
    },
  ),
  'Emergency Shield': Effect(
    onBattle: (ctx) {
      if (ctx.my.speed < ctx.enemy.speed) {
        ctx.adjustArmor(4);
      }
    },
  ),
  'Granite Gauntlet': Effect(
    onBattle: (ctx) {
      ctx.adjustArmor(5);
    },
  ),
};

class _ItemCatalogReader {
  static const List<String> _itemKeys = <String>[
    'name',
    'kind',
    'rarity',
    'material',
    'effect', // ignored for now
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
    Effect? effect;
    if (effectText != null) {
      effect = _effectByItemName[name];
      // TODO(eseidel): Currently only warning about commons.
      if (effect == null && rarity == Rarity.common) {
        logger.warn('$name missing: $effectText');
      }
    }
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
      effect: effect,
    );
  }

  static List<Item> read(String path) {
    final itemsYaml = loadYaml(File(path).readAsStringSync()) as YamlList;
    // TODO(eseidel): Validate no extra item effects?
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
