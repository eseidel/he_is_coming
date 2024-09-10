import 'dart:math';

import 'package:collection/collection.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:yaml/yaml.dart';

/// ItemException
class ItemException implements Exception {
  /// Create ItemException
  ItemException(this.message);

  /// Message
  final String message;
}

/// Player's inventory.
class Inventory {
  /// Create an inventory.
  Inventory({
    required Level level,
    required List<Item> items,
    required this.edge,
    required this.oils,
    required SetBonusCatalog setBonuses,
  }) {
    this.items = _enforceItemRules(level, items);
    if (oils.length > 3) {
      throw UnimplementedError('Too many oils');
    }
    sets = _resolveSetBonuses(this.items, edge, setBonuses);
  }

  /// Create a random creature configuration.
  factory Inventory.random(Level level, Random random, Data data) {
    final slotCount = itemSlotCount(level);
    final items = _pickItems(random, slotCount, data.items);
    // Most edges are strictly beneficial, so just pick one at random.
    final edge = data.edges.random(random);
    // Currently there are only 3 oils, you can always only use each once.
    // No need to support random oils.
    final oils = data.oils.oils.toList();
    return Inventory(
      level: level,
      items: items,
      edge: edge,
      oils: oils,
      setBonuses: data.sets,
    );
  }

  /// Create an inventory from json.
  /// This expects names, not full item definitions.
  factory Inventory.fromJson(
    Map<String, dynamic> json,
    Level level,
    Data data,
  ) {
    final edge =
        json['edge'] != null ? data.edges[json['edge'] as String] : null;
    final oils = (json['oils'] as List? ?? [])
        .map<Oil>((name) => data.oils[name as String])
        .toList();
    final items = (json['items'] as List? ?? [])
        .map<Item>((name) => data.items[name as String])
        .toList();
    return Inventory(
      level: level,
      items: items,
      edge: edge,
      oils: oils,
      setBonuses: data.sets,
    );
  }

  /// Create an empty inventory.
  Inventory.empty()
      : edge = null,
        oils = const <Oil>[],
        items = [];

  static List<SetBonus> _resolveSetBonuses(
    List<Item> items,
    Edge? edge,
    SetBonusCatalog setBonuses,
  ) {
    String baseName(Item item) {
      final name = item.name;
      if (name.startsWith('Golden ')) {
        return name.substring(7);
      }
      if (name.startsWith('Diamond ')) {
        return name.substring(8);
      }
      return name;
    }

    // Gather all "names" in the inventory.
    final names = {
      for (final item in items) baseName(item),
      if (edge != null) edge.name,
    };
    // Walk through the set bonuses and see if any of them are satisfied.
    return setBonuses.items.where((bonus) {
      return bonus.parts.every(names.contains);
    }).toList();
  }

  /// Returns number of item slots for the level.
  static int itemSlotCount(Level level) {
    // 8 normal slots, 1 weapon.
    return switch (level) {
      Level.one => 5,
      Level.two => 7,
      Level.three => 9,
      Level.end => 9,
    };
  }

  static List<Item> _pickItems(
    Random random,
    int count,
    ItemCatalog itemCatalog,
  ) {
    final items = <Item>[
      itemCatalog.randomWeapon(random),
    ];
    while (items.length < count) {
      final item = itemCatalog.randomNonWeapon(random);
      if (item.isUnique && items.any((i) => i.name == item.name)) continue;
      items.add(item);
    }
    return items;
  }

  static List<Item> _enforceItemRules(Level level, List<Item> unenforced) {
    if (unenforced.length > itemSlotCount(level)) {
      throw ItemException('Too many items for level $level.');
    }

    // Player must always have a weapon.
    final items = [...unenforced];
    if (items.every((item) => item.kind != ItemKind.weapon)) {
      items.add(Creature.defaultPlayerWeapon);
    }

    final itemCounts = items.fold<Map<String, int>>(
      {},
      (counts, item) =>
          counts..update(item.name, (count) => count + 1, ifAbsent: () => 1),
    );
    for (final entry in itemCounts.entries) {
      if (entry.value > 1) {
        final item = items.firstWhere((item) => item.name == entry.key);
        if (item.isUnique) {
          throw ItemException(
            '${item.name} is unique and can only be equipped once.',
          );
        }
      }
    }

    final weaponCount = items.where((item) => item.isWeapon).length;
    if (weaponCount > 1) {
      throw ItemException('Player can only have one weapon.');
    }

    // Weapon is always first.
    items.sortBy<num>((item) => item.isWeapon ? 0 : 1);
    return items;
  }

  /// Resolve stats with items.
  Stats statsWithItems(Stats intrinsic) {
    return [
      ...items.map((item) => item.stats),
      ...oils.map((oil) => oil.stats),
      ...sets.map((set) => set.stats),
    ].fold<Stats>(
      intrinsic,
      (acc, stats) => acc + stats,
    );
  }

  /// The edge on the weapon.
  final Edge? edge;

  /// Oils applied to the weapon.
  final List<Oil> oils;

  /// Items in the inventory.
  late final List<Item> items;

  /// Set bonuses applied to the inventory.
  late final List<SetBonus> sets;

  /// Count of items in the inventory.
  int materialCount(ItemMaterial material) {
    return items.where((item) => item.material == material).length;
  }

  /// Count of items in the inventory.
  int kindCount(ItemKind kind) {
    return items.where((item) => item.kind == kind).length;
  }

  /// Convert to json.
  Map<String, dynamic> toJson() {
    // This is not meant for defining items, so we only serialize the names.
    return {
      if (items.isNotEmpty) 'items': items.map((item) => item.name).toList(),
      if (edge != null) 'edge': edge!.name,
      if (oils.isNotEmpty) 'oils': oils.map((oil) => oil.name).toList(),
    };
  }

  /// Copy with changes.
  Inventory copyWith({
    required Level level,
    required SetBonusCatalog setBonuses,
    Edge? edge,
    List<Oil>? oils,
    List<Item>? items,
  }) {
    return Inventory(
      level: level,
      edge: edge ?? this.edge,
      oils: oils ?? this.oils,
      items: items ?? this.items,
      setBonuses: setBonuses,
    );
  }

  @override
  String toString() {
    return 'Inventory: ${items.join(', ')} with $edge and $oils';
  }
}

/// Oil applied to a weapon.
class Oil extends CatalogItem {
  /// Create an Oil
  Oil({
    required super.name,
    required this.stats,
    required super.id,
    required super.version,
  });

  /// Create an Oil from a yaml map.
  factory Oil.fromYaml(YamlMap yaml, LookupEffect _) {
    final name = yaml['name'] as String;
    final attack = yaml['attack'] as int? ?? 0;
    final armor = yaml['armor'] as int? ?? 0;
    final speed = yaml['speed'] as int? ?? 0;
    final id = yaml['id'] as int;
    final version = yaml['version'] as String?;

    final stats = Stats(
      attack: attack,
      armor: armor,
      speed: speed,
    );
    return Oil(name: name, stats: stats, id: id, version: version);
  }

  /// The stats of the oil.
  final Stats stats;

  @override
  String toString() => name;

  /// All the known keys in the oils yaml, in sorted order.
  static const List<String> orderedKeys = <String>[
    'name',
    'id',
    'attack',
    'armor',
    'speed',
    'version',
  ];

  /// Convert to json.
  @override
  dynamic toJson() => <String, dynamic>{
        'name': name,
        'id': id,
        ...stats.toJson(),
      };

  @override
  Oil copyWith({int? id}) {
    return Oil(name: name, stats: stats, id: id ?? this.id, version: version);
  }
}

/// An edge is a special effect that can be applied to a weapon.
class Edge extends CatalogItem {
  /// Create an Edge
  Edge({
    required super.name,
    required super.effect,
    required super.id,
    required super.version,
  });

  /// Create an Edge from a yaml map.
  factory Edge.fromYaml(YamlMap yaml, LookupEffect lookupEffect) {
    final name = yaml['name'] as String;
    final effectText = yaml['effect'] as String?;
    final effect = lookupEffect(name: name, effectText: effectText);
    final id = yaml['id'] as int;
    final version = yaml['version'] as String?;
    return Edge(name: name, effect: effect, id: id, version: version);
  }

  @override
  String toString() => name;

  @override
  dynamic toJson() {
    return {
      'name': name,
      'id': id,
      'effect': effect?.toJson(),
      if (version != null) 'version': version,
    };
  }

  @override
  Edge copyWith({int? id}) {
    return Edge(
      name: name,
      effect: effect,
      id: id ?? this.id,
      version: version,
    );
  }
}
