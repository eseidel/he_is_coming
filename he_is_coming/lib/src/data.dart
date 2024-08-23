import 'dart:math';

import 'package:he_is_coming/src/catalog.dart';
import 'package:he_is_coming/src/creature.dart';
import 'package:he_is_coming/src/creature_effects.dart';
import 'package:he_is_coming/src/edge_effects.dart';
import 'package:he_is_coming/src/item.dart';
import 'package:he_is_coming/src/item_effects.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:path/path.dart' as p;

final _creaturesPath = p.join('data', 'creatures.yaml');
final _defaultItemsPath = p.join('data', 'items.yaml');
final _edgesPath = p.join('data', 'edges.yaml');
final _oilsPath = p.join('data', 'blade_oils.yaml');

/// The data for the game.
class Data {
  /// Create a new data object.
  Data({
    required this.creatures,
    required this.items,
    required this.edges,
    required this.oils,
  });

  /// Load the data from the yaml files.
  factory Data.load() {
    final creatures = CreatureCatalog.fromFile(_creaturesPath);
    final items = ItemCatalog.fromFile(_defaultItemsPath);
    final edges = EdgeCatalog.fromFile(_edgesPath);
    final oils = OilCatalog.fromFile(_oilsPath);
    return Data(creatures: creatures, items: items, edges: edges, oils: oils);
  }

  /// Save the data to the yaml files.
  void save() {
    creatures.save(_creaturesPath);
    items.save(_defaultItemsPath);
    edges.save(_edgesPath);
    oils.save(_oilsPath);
  }

  /// The creatures in this catalog.
  final CreatureCatalog creatures;

  /// The items in this catalog.
  final ItemCatalog items;

  /// The edges in this catalog.
  final EdgeCatalog edges;

  /// The oils in this catalog.
  final OilCatalog oils;
}

/// Global data object.
late final Data data;

/// Class to hold all known creatures.
class CreatureCatalog extends Catalog<Creature> {
  /// Create an CreatureCatalog
  CreatureCatalog(super.creatures);

  /// Create an CreatureCatalog from a yaml file.
  factory CreatureCatalog.fromFile(String path) {
    final creatures = CatalogReader.read(
      path,
      Creature.fromYaml,
      Creature.orderedKeys.toSet(),
      creatureEffects,
    );
    logger.info('Loaded ${creatures.length} from $path');
    return CreatureCatalog(creatures);
  }

  /// The creatures in this catalog.
  List<Creature> get creatures => items;
}

/// Class to hold all known edges.
class EdgeCatalog extends Catalog<Edge> {
  /// Create an EdgeCatalog
  EdgeCatalog(super.edges);

  /// Create an EdgeCatalog from a yaml file.
  factory EdgeCatalog.fromFile(String path) {
    final edges = CatalogReader.read(
      path,
      Edge.fromYaml,
      orderedKeys.toSet(),
      edgeEffects,
    );
    logger.info('Loaded ${edges.length} from $path');
    return EdgeCatalog(edges);
  }

  /// All the known keys in the enemies yaml, in sorted order.
  static const List<String> orderedKeys = <String>[
    'name',
    'unlock', // ignored for now
    'effect',
  ];

  /// The edges in this catalog.
  List<Edge> get edges => items;
}

/// Class to hold all known items.
class ItemCatalog extends Catalog<Item> {
  /// Create an ItemCatalog
  ItemCatalog(super.items);

  /// Create an ItemCatalog from a yaml file.
  factory ItemCatalog.fromFile(String path) {
    final items = CatalogReader.read(
      path,
      Item.fromYaml,
      Item.orderedKeys.toSet(),
      itemEffects,
    );
    logger.info('Loaded ${items.length} from $path');
    return ItemCatalog(items);
  }

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
}

/// Class to hold all known Oils.
class OilCatalog extends Catalog<Oil> {
  /// Create an OilCatalog
  OilCatalog(super.oils);

  /// Create an EdgeCatalog from a yaml file.
  factory OilCatalog.fromFile(String path) {
    final oils = CatalogReader.read(
      path,
      Oil.fromYaml,
      Oil.orderedKeys.toSet(),
      {}, // No oils have effects in the game yet.
    );
    logger.info('Loaded ${oils.length} from $path');
    return OilCatalog(oils);
  }

  /// The oils in this catalog.
  List<Oil> get oils => items;
}
