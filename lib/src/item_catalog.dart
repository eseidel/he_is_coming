import 'package:he_is_coming/src/catalog.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/item.dart';
import 'package:he_is_coming/src/item_effects.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

Item? _itemFromYaml(YamlMap yaml, LookupEffect lookupEffect) {
  final name = yaml['name'] as String;
  final kind = yaml.lookupOr('kind', Kind.values, Kind.notSpecified);
  final rarity = yaml.lookup('rarity', Rarity.values);
  final material =
      yaml.lookupOr('material', Material.values, Material.notSpecified);
  final attack = yaml['attack'] as int? ?? 0;
  final health = yaml['health'] as int? ?? 0;
  final armor = yaml['armor'] as int? ?? 0;
  final speed = yaml['speed'] as int? ?? 0;
  final effectText = yaml['effect'] as String?;
  final effects = lookupEffect(name);
  if (effectText != null && effects == null) {
    return null;
  }
  return Item(
    name,
    kind: kind,
    rarity,
    material: material,
    attack: attack,
    health: health,
    armor: armor,
    speed: speed,
    effects: effects,
  );
}

/// Class to hold all known items.
class ItemCatalog {
  /// Create an ItemCatalog
  ItemCatalog(this.items);

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
    'attack',
    'health',
    'armor',
    'speed',
    'effect',
  ];

  /// The items in this catalog.
  final List<Item> items;

  /// Lookup an Item by name.
  Item operator [](String name) => items.firstWhere((i) => i.name == name);
}

/// Our global item catalog instance.
late final ItemCatalog itemCatalog;

final _defaultItemsPath = p.join('data', 'items.yaml');

/// Initialize the global item catalog.
void initItemCatalog([String? path]) {
  itemCatalog = ItemCatalog.fromFile(path ?? _defaultItemsPath);
}
