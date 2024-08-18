import 'dart:io';

import 'package:collection/collection.dart';
import 'package:he_is_coming_sim/src/item.dart';
import 'package:he_is_coming_sim/src/logger.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

// Dart doesn't have if-expressions, so made a helper function.
void _if(bool condition, void Function() fn) {
  if (condition) {
    fn();
  }
}

final _effectsByItemName = <String, Effects>{
  'Stone Steak': Effects(
    onBattle: (c) => _if(c.isHealthFull, () => c.gainArmor(4)),
  ),
  'Redwood Cloak': Effects(onBattle: (c) => c.restoreHealth(1)),
  'Emergency Shield': Effects(
    onBattle: (c) => _if(c.my.speed < c.enemy.speed, () => c.gainArmor(4)),
  ),
  'Granite Gauntlet': Effects(onBattle: (c) => c.gainArmor(5)),
  'Ruby Earings': Effects(
    onTurn: (c) => _if(c.isEveryOtherTurn, () => c.dealDamage(1)),
  ),
  'Firecracker Belt':
      Effects(onExposed: (c) => [1, 1, 1].forEach(c.dealDamage)),
  'Redwood Helmet': Effects(onExposed: (c) => c.restoreHealth(3)),
  'Explosive Surprise': Effects(onExposed: (c) => c.dealDamage(5)),
  'Cracked Bouldershield': Effects(onExposed: (c) => c.gainArmor(5)),
  'Vampiric Wine': Effects(onWounded: (c) => c.restoreHealth(4)),
  'Mortal Edge': Effects(
    onWounded: (c) => c
      ..gainAttack(5)
      ..takeDamage(2),
  ),
  'Lifeblood Burst': Effects(onWounded: (c) => c.dealDamage(c.my.maxHp ~/ 2)),
  'Chain Mail': Effects(onWounded: (c) => c.gainArmor(3)),
  'Stoneslab Sword': Effects(onHit: (c) => c.gainArmor(2)),
  'Heart Drinker': Effects(onHit: (c) => c.restoreHealth(1)),
  'Gold Ring': Effects(onBattle: (c) => c.gainGold(1)),
  'Ruby Ring': Effects(
    onBattle: (c) => c
      ..gainAttack(1)
      ..takeDamage(2),
  ),
  'Ruby Crown': Effects(
    onBattle: (c) => _if(c.my.attack >= 6, () => c.gainAttack(2)),
  ),
  'Melting Iceblade': Effects(onHit: (c) => c.loseAttack(-1)),
  'Double-edged Sword': Effects(onHit: (c) => c.takeDamage(1)),
  'Sapphire Crown': Effects(
    onBattle: (c) => _if(c.my.armor >= 15, () => c.gainArmor(10)),
  ),
  'Citrine Ring': Effects(
    onBattle: (c) => _if(c.my.speed > 0, () => c.dealDamage(c.my.speed)),
  ),
  'Marble Mirror': Effects(onBattle: (c) => c.gainArmor(c.enemy.armor)),
  'Leather Boots': Effects(
    onBattle: (c) => _if(c.my.speed > c.enemy.speed, () => c.gainAttack(2)),
  ),
};

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
    Effects? effects;
    if (effectText != null) {
      effects = _effectsByItemName[name];
      if (effects == null) {
        logger.warn('missing: $effectText');
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
      effects: effects,
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
