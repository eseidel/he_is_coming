import 'dart:io';
import 'dart:math';

import 'package:he_is_coming/src/catalog.dart';
import 'package:he_is_coming/src/creature.dart';
import 'package:he_is_coming/src/creature_effects.dart';
import 'package:he_is_coming/src/edge_effects.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/item.dart';
import 'package:he_is_coming/src/item_effects.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

export 'package:he_is_coming/src/creature.dart';
export 'package:he_is_coming/src/item.dart';

class _Paths {
  _Paths(this.dir);

  final String dir;

  String get creatures => p.join(dir, 'creatures.yaml');
  String get items => p.join(dir, 'items.yaml');
  String get edges => p.join(dir, 'edges.yaml');
  String get oils => p.join(dir, 'blade_oils.yaml');
}

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
  factory Data.load([String path = 'lib/data']) {
    final paths = _Paths(path);
    T load<T>(String path, T Function(YamlList) fromYaml) {
      final yaml = loadYaml(File(path).readAsStringSync()) as YamlList;
      return fromYaml(yaml);
    }

    return Data(
      creatures: load(paths.creatures, CreatureCatalog.fromYaml),
      items: load(paths.items, ItemCatalog.fromYaml),
      edges: load(paths.edges, EdgeCatalog.fromYaml),
      oils: load(paths.oils, OilCatalog.fromYaml),
    );
  }

  /// Create a new data object from strings.
  static Future<Data> fromStrings({
    required Future<String> creatures,
    required Future<String> items,
    required Future<String> edges,
    required Future<String> oils,
  }) async {
    T load<T>(String content, T Function(YamlList) fromYaml) {
      final yaml = loadYaml(content) as YamlList;
      return fromYaml(yaml);
    }

    return Data(
      creatures: load(await creatures, CreatureCatalog.fromYaml),
      items: load(await items, ItemCatalog.fromYaml),
      edges: load(await edges, EdgeCatalog.fromYaml),
      oils: load(await oils, OilCatalog.fromYaml),
    );
  }

  /// Save the data to the yaml files.
  void save([String path = 'lib/data']) {
    final paths = _Paths(path);
    creatures.save(paths.creatures);
    items.save(paths.items);
    edges.save(paths.edges);
    oils.save(paths.oils);
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

/// Class to hold all known creatures.
class CreatureCatalog extends Catalog<Creature> {
  /// Create an CreatureCatalog
  CreatureCatalog(super.creatures);

  /// Create an CreatureCatalog from a yaml file.
  factory CreatureCatalog.fromYaml(YamlList yaml) {
    final creatures = CatalogReader.parseYaml(
      yaml,
      Creature.fromYaml,
      Creature.orderedKeys.toSet(),
      creatureEffects,
    );
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
  factory EdgeCatalog.fromYaml(YamlList yaml) {
    final edges = CatalogReader.parseYaml(
      yaml,
      Edge.fromYaml,
      orderedKeys.toSet(),
      edgeEffects,
    );
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
  factory ItemCatalog.fromYaml(YamlList yaml) {
    final items = CatalogReader.parseYaml(
      yaml,
      Item.fromYaml,
      Item.orderedKeys.toSet(),
      itemEffects,
    );
    return ItemCatalog(items);
  }

  /// All the weapons in the catalog.
  List<Item> get weapons =>
      items.where((i) => i.kind == ItemKind.weapon).toList();

  /// All the non-weapon items in the catalog.
  List<Item> get nonWeapons =>
      items.where((i) => i.kind != ItemKind.weapon).toList();

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
  factory OilCatalog.fromYaml(YamlList yaml) {
    final oils = CatalogReader.parseYaml(
      yaml,
      Oil.fromYaml,
      Oil.orderedKeys.toSet(),
      EffectCatalog({}), // No oils have effects in the game yet.
    );
    return OilCatalog(oils);
  }

  /// The oils in this catalog.
  List<Oil> get oils => items;
}
