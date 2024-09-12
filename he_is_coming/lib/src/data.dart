import 'dart:io';
import 'dart:math';

import 'package:he_is_coming/src/catalog.dart';
import 'package:he_is_coming/src/creature.dart';
import 'package:he_is_coming/src/creature_effects.dart';
import 'package:he_is_coming/src/edge_effects.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/inventory.dart';
import 'package:he_is_coming/src/item.dart';
import 'package:he_is_coming/src/item_effects.dart';
import 'package:he_is_coming/src/set_effects.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

export 'package:he_is_coming/src/catalog.dart';
export 'package:he_is_coming/src/creature.dart';
export 'package:he_is_coming/src/inventory.dart';
export 'package:he_is_coming/src/item.dart';

class _Paths {
  _Paths(this.dir);

  final String dir;

  String get creatures => p.join(dir, 'creatures.yaml');
  String get items => p.join(dir, 'items.yaml');
  String get edges => p.join(dir, 'edges.yaml');
  String get oils => p.join(dir, 'blade_oils.yaml');
  String get sets => p.join(dir, 'sets.yaml');
  String get triggers => p.join(dir, 'triggers.yaml');
  String get challenges => p.join(dir, 'challenges.yaml');
}

/// The data for the game.
class Data {
  /// Create a new data object.
  Data({
    required this.creatures,
    required this.items,
    required this.edges,
    required this.oils,
    required this.sets,
    required this.triggers,
    required this.challenges,
  });

  /// Load the data from the yaml files.
  factory Data.load([String path = 'lib/data']) {
    final paths = _Paths(path);
    T load<T>(String path, T Function(YamlList) fromYaml) {
      final yaml =
          loadYaml(File(path).readAsStringSync()) as YamlList? ?? YamlList();
      return fromYaml(yaml);
    }

    return Data(
      creatures: load(paths.creatures, CreatureCatalog.fromYaml),
      items: load(paths.items, ItemCatalog.fromYaml),
      edges: load(paths.edges, EdgeCatalog.fromYaml),
      oils: load(paths.oils, OilCatalog.fromYaml),
      sets: load(paths.sets, SetBonusCatalog.fromYaml),
      triggers: load(paths.triggers, TriggerCatalog.fromYaml),
      challenges: load(paths.challenges, ChallengeCatalog.fromYaml),
    );
  }

  /// Create a new data object from strings.
  static Future<Data> fromStrings({
    required Future<String> creatures,
    required Future<String> items,
    required Future<String> edges,
    required Future<String> oils,
    required Future<String> sets,
    required Future<String> triggers,
    required Future<String> challenges,
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
      sets: load(await sets, SetBonusCatalog.fromYaml),
      triggers: load(await triggers, TriggerCatalog.fromYaml),
      challenges: load(await challenges, ChallengeCatalog.fromYaml),
    );
  }

  /// Save the data to the yaml files.
  void save([String path = 'lib/data']) {
    final paths = _Paths(path);
    creatures.save(paths.creatures);
    items.save(paths.items);
    edges.save(paths.edges);
    oils.save(paths.oils);
    sets.save(paths.sets);
    triggers.save(paths.triggers);
    challenges.save(paths.challenges);
  }

  /// Remove any items that are missing effects.
  Data withoutEntriesMissingEffects() {
    Catalog<T> onlyImplemented<T extends CatalogItem>(Catalog<T> catalog) {
      return catalog.copyWith(
        items: catalog.items.where((item) => item.isImplemented).toList(),
      ) as Catalog<T>;
    }

    return Data(
      creatures: onlyImplemented(creatures) as CreatureCatalog,
      items: onlyImplemented(items) as ItemCatalog,
      edges: onlyImplemented(edges) as EdgeCatalog,
      oils: onlyImplemented(oils) as OilCatalog,
      sets: onlyImplemented(sets) as SetBonusCatalog,
      triggers: onlyImplemented(triggers) as TriggerCatalog,
      challenges: onlyImplemented(challenges) as ChallengeCatalog,
    );
  }

  /// Remove any items that are inferred.
  Data withoutInferredItems() {
    Catalog<T> removeInferred<T extends CatalogItem>(Catalog<T> catalog) {
      return catalog.copyWith(
        items: catalog.items.where((item) => !item.inferred).toList(),
      ) as Catalog<T>;
    }

    return Data(
      creatures: removeInferred(creatures) as CreatureCatalog,
      items: removeInferred(items) as ItemCatalog,
      edges: removeInferred(edges) as EdgeCatalog,
      oils: removeInferred(oils) as OilCatalog,
      sets: removeInferred(sets) as SetBonusCatalog,
      triggers: removeInferred(triggers) as TriggerCatalog,
      challenges: removeInferred(challenges) as ChallengeCatalog,
    );
  }

  /// All known items.
  List<CatalogItem> get allItems => [
        ...creatures.items,
        ...items.items,
        ...edges.items,
        ...oils.items,
        ...sets.items,
        ...triggers.items,
        ...challenges.items,
      ];

  /// All known creatures.
  final CreatureCatalog creatures;

  /// All known items.
  final ItemCatalog items;

  /// All known edges.
  final EdgeCatalog edges;

  /// All known oils.
  final OilCatalog oils;

  /// All known set bonuses.
  final SetBonusCatalog sets;

  /// All known triggers.
  final TriggerCatalog triggers;

  /// All known challenges.
  final ChallengeCatalog challenges;
}

/// Class to hold all known creatures.
class CreatureCatalog extends Catalog<Creature> {
  /// Create an CreatureCatalog
  CreatureCatalog(super.creatures, {required super.idBits});

  /// Create an CreatureCatalog from a yaml file.
  factory CreatureCatalog.fromYaml(YamlList yaml) {
    final creatures = CatalogReader.parseYaml(
      yaml,
      Creature.fromYaml,
      Creature.orderedKeys.toSet(),
      creatureEffects,
    );
    return CreatureCatalog(creatures, idBits: null);
  }

  @override
  CreatureCatalog copyWith({List<Creature>? items}) {
    return CreatureCatalog(items ?? creatures, idBits: idBits);
  }

  /// The creatures in this catalog.
  List<Creature> get creatures => items;
}

/// Class to hold all known edges.
class EdgeCatalog extends Catalog<Edge> {
  /// Create an EdgeCatalog
  EdgeCatalog._(super.edges, {required super.idBits});

  /// Create an EdgeCatalog from a list of edges.
  EdgeCatalog.fromItems(super.items) : super(idBits: null);

  /// Create an EdgeCatalog from a yaml file.
  factory EdgeCatalog.fromYaml(YamlList yaml) {
    final edges = CatalogReader.parseYaml(
      yaml,
      Edge.fromYaml,
      Edge.orderedKeys.toSet(),
      edgeEffects,
    );
    return EdgeCatalog.fromItems(edges);
  }

  @override
  EdgeCatalog copyWith({List<Edge>? items}) {
    return EdgeCatalog._(items ?? edges, idBits: idBits);
  }

  /// The edges in this catalog.
  List<Edge> get edges => items;
}

/// Class to hold all known items.
class ItemCatalog extends Catalog<Item> {
  /// Create an ItemCatalog
  ItemCatalog.fromItems(super.items) : super(idBits: null);

  ItemCatalog._(super.items, {required super.idBits});

  /// Create an ItemCatalog from a yaml file.
  factory ItemCatalog.fromYaml(YamlList yaml) {
    final items = CatalogReader.parseYaml(
      yaml,
      Item.fromYaml,
      Item.orderedKeys.toSet(),
      itemEffects,
    );
    return ItemCatalog.fromItems(items);
  }

  @override
  ItemCatalog copyWith({List<Item>? items}) {
    return ItemCatalog._(items ?? this.items, idBits: idBits);
  }

  /// All the weapons in the catalog.
  List<Item> get weapons => items.where((i) => i.isWeapon).toList();

  /// All the non-weapon items in the catalog.
  List<Item> get nonWeapons => items.where((i) => !i.isWeapon).toList();

  /// Get a random weapon from the catalog.
  Item randomWeapon(Random random) => weapons[random.nextInt(weapons.length)];

  /// Get a random non-weapon item from the catalog.
  Item randomNonWeapon(Random random) =>
      nonWeapons[random.nextInt(nonWeapons.length)];
}

/// Class to hold all known Oils.
class OilCatalog extends Catalog<Oil> {
  /// Create an EdgeCatalog from a yaml file.
  factory OilCatalog.fromYaml(YamlList yaml) {
    final oils = CatalogReader.parseYaml(
      yaml,
      Oil.fromYaml,
      Oil.orderedKeys.toSet(),
      EffectCatalog({}), // No oils have effects in the game yet.
    );
    return OilCatalog.fromItems(oils);
  }

  /// Create an OilCatalog
  OilCatalog.fromItems(super.oils) : super(idBits: null);

  /// Create an OilCatalog
  OilCatalog._(super.oils, {required super.idBits});

  @override
  OilCatalog copyWith({List<Oil>? items}) {
    return OilCatalog._(items ?? oils, idBits: idBits);
  }

  /// The oils in this catalog.
  List<Oil> get oils => items;
}

/// Class to hold a set bonus.
class SetBonus extends CatalogItem {
  /// Create a new set bonus.
  SetBonus({
    required super.name,
    required this.parts,
    required this.stats,
    required super.effect,
    required super.id,
    required super.version,
  });

  /// Create a set bonus from a yaml map.
  factory SetBonus.fromYaml(YamlMap yaml, LookupEffect lookupEffect) {
    final name = yaml['name'] as String;
    final parts = (yaml['parts'] as YamlList).map((e) => e as String).toList();
    final stats = Stats.fromYaml(yaml);
    final effectText = yaml['effect'] as String?;
    final effect = lookupEffect(name: name, effectText: effectText);
    final id = yaml['id'] as int;
    final version = yaml['version'] as String?;
    return SetBonus(
      name: name,
      parts: parts,
      stats: stats,
      effect: effect,
      id: id,
      version: version,
    );
  }

  /// All the known keys in the set bonus yaml, in sorted order.
  static const List<String> orderedKeys = <String>[
    'name',
    'id',
    'parts',
    ...Stats.orderedKeys,
    'effect',
    'version',
  ];

  /// The parts required to get the bonus.
  final List<String> parts;

  /// The stats that are added by the bonus.
  final Stats stats;

  @override
  dynamic toJson() => {
        'name': name,
        'id': id,
        'parts': parts,
        ...stats.toJson(),
        if (effect != null) 'effect': effect.toString(),
        if (version != null) 'version': version,
      };

  @override
  SetBonus copyWith({int? id}) {
    return SetBonus(
      name: name,
      parts: parts,
      stats: stats,
      effect: effect,
      id: id ?? this.id,
      version: version,
    );
  }
}

/// Class to hold all known sets.
class SetBonusCatalog extends Catalog<SetBonus> {
  /// Create an SetBonusCatalog
  SetBonusCatalog.fromItems(super.sets) : super(idBits: null);

  SetBonusCatalog._(super.sets, {required super.idBits});

  /// Create an SetBonusCatalog from a yaml file.
  factory SetBonusCatalog.fromYaml(YamlList yaml) {
    final sets = CatalogReader.parseYaml(
      yaml,
      SetBonus.fromYaml,
      SetBonus.orderedKeys.toSet(),
      setEffects,
    );
    return SetBonusCatalog.fromItems(sets);
  }

  @override
  SetBonusCatalog copyWith({List<SetBonus>? items}) {
    return SetBonusCatalog._(items ?? sets, idBits: idBits);
  }

  /// The sets in this catalog.
  List<SetBonus> get sets => items;
}

/// Class to hold a position.
class Position {
  /// Create a new position.
  const Position(this.x, this.y);

  /// The x value.
  final int x;

  /// The y value.
  final int y;
}

/// Class to hold a challenge.
class Challenge extends CatalogItem {
  /// Create a new challenge.
  Challenge({
    required super.name,
    required this.unlock,
    required this.reward,
    required super.id,
    required super.version,
    this.position,
  });

  /// Create a challenge from a yaml map.
  factory Challenge.fromYaml(YamlMap yaml, LookupEffect _) {
    final name = yaml['name'] as String;
    final unlock = yaml['unlock'] as String;
    final reward = yaml['reward'] as String;
    final id = yaml['id'] as int;
    final version = yaml['version'] as String?;
    final x = yaml['x'] as int?;
    final y = yaml['y'] as int?;
    final position = x != null && y != null ? Position(x, y) : null;
    return Challenge(
      name: name,
      unlock: unlock,
      reward: reward,
      id: id,
      version: version,
      position: position,
    );
  }

  /// All the known keys in the challenge yaml, in sorted order.
  static const orderedKeys = <String>[
    'name',
    'id',
    'unlock',
    'reward',
    'x',
    'y',
    'version',
  ];

  /// The reward for completing the challenge.
  final String reward;

  /// Requirements to meet this challenge.
  final String unlock;

  // We have only recorded the position in the challenge map for a few.
  /// The position of the challenge in the challenge map.
  final Position? position;

  @override
  dynamic toJson() => {
        'name': name,
        'id': id,
        'unlock': unlock,
        'reward': reward,
        if (position != null) 'x': position!.x,
        if (position != null) 'y': position!.y,
        if (version != null) 'version': version,
      };

  @override
  Challenge copyWith({int? id}) {
    return Challenge(
      name: name,
      unlock: unlock,
      reward: reward,
      id: id ?? this.id,
      version: version,
      position: position,
    );
  }
}

/// Class to hold all known challenges.
class ChallengeCatalog extends Catalog<Challenge> {
  /// Create an ChallengeCatalog
  ChallengeCatalog.fromItems(super.challenges) : super(idBits: null);

  ChallengeCatalog._(super.challenges, {required super.idBits});

  /// Create an ChallengeCatalog from a yaml file.
  factory ChallengeCatalog.fromYaml(YamlList yaml) {
    final challenges = CatalogReader.parseYaml(
      yaml,
      Challenge.fromYaml,
      Challenge.orderedKeys.toSet(),
      EffectCatalog({}), // No challenges have effects in the game yet.
    );
    return ChallengeCatalog.fromItems(challenges);
  }

  @override
  ChallengeCatalog copyWith({List<Challenge>? items}) {
    return ChallengeCatalog._(items ?? challenges, idBits: idBits);
  }

  /// The challenges in this catalog.
  List<Challenge> get challenges => items;
}

/// Class to hold a trigger.
class TriggerItem extends CatalogItem {
  /// Create a new trigger.
  TriggerItem({
    required super.name,
    required this.detail,
    required super.id,
    required super.version,
  });

  /// Create a trigger from a yaml map.
  factory TriggerItem.fromYaml(YamlMap yaml, LookupEffect _) {
    final name = yaml['name'] as String;
    final detail = yaml['detail'] as String;
    final id = yaml['id'] as int;
    final version = yaml['version'] as String?;
    return TriggerItem(
      name: name,
      detail: detail,
      id: id,
      version: version,
    );
  }

  /// All the known keys in the trigger yaml, in sorted order.
  static const orderedKeys = <String>[
    'name',
    'id',
    'detail',
  ];

  /// The description of the trigger.
  final String detail;

  @override
  dynamic toJson() => {
        'name': name,
        'id': id,
        'detail': detail,
        if (version != null) 'version': version,
      };

  @override
  TriggerItem copyWith({int? id}) {
    return TriggerItem(
      name: name,
      detail: detail,
      id: id ?? this.id,
      version: version,
    );
  }
}

/// Class to hold all known triggers.
class TriggerCatalog extends Catalog<TriggerItem> {
  /// Create an TriggerCatalog
  TriggerCatalog.fromItems(super.triggers) : super(idBits: null);

  TriggerCatalog._(super.triggers, {required super.idBits});

  /// Create an TriggerCatalog from a yaml file.
  factory TriggerCatalog.fromYaml(YamlList yaml) {
    final triggers = CatalogReader.parseYaml(
      yaml,
      TriggerItem.fromYaml,
      TriggerItem.orderedKeys.toSet(),
      EffectCatalog({}), // No triggers have effects in the game yet.
    );
    return TriggerCatalog.fromItems(triggers);
  }

  @override
  TriggerCatalog copyWith({List<TriggerItem>? items}) {
    return TriggerCatalog._(items ?? triggers, idBits: idBits);
  }

  /// The triggers in this catalog.
  List<TriggerItem> get triggers => items;
}
