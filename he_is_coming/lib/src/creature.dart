import 'dart:math';

import 'package:collection/collection.dart';
import 'package:he_is_coming/src/catalog.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

const _kPlayerName = 'Player';

/// Alias for Creature.
typedef Player = Creature;

/// Level
enum Level {
  /// Level 1
  one('Level 1'),

  /// Level 2
  two('Level 2'),

  /// Level 3
  three('Level 3'),

  /// Final boss
  end('End');

  const Level(this.name);

  /// Converts a (1-indexed) number into level enum.
  factory Level.fromJson(int level) => values[level - 1];

  /// Display name of this level.
  final String name;

  /// Converts to json.
  dynamic toJson() => index + 1;
}

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

    final weaponCount =
        items.where((item) => item.kind == ItemKind.weapon).length;
    if (weaponCount > 1) {
      throw ItemException('Player can only have one weapon.');
    }

    // Weapon is always first.
    items.sortBy<num>((item) => item.kind == ItemKind.weapon ? 0 : 1);
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
}

/// Create a player from a creature configuration.
Player playerWithInventory(Level level, Inventory inventory) {
  return Creature(
    name: _kPlayerName,
    intrinsic: const Stats(),
    gold: 0,
    level: level,
    inventory: inventory,
  );
}

/// Adds a method to create a player from a data object.
extension CreatePlayer on Data {
  /// Create a player.
  Player player({
    int maxHp = 10,
    int attack = 0,
    int armor = 0,
    int speed = 0,
    List<String> items = const <String>[],
    List<Item> customItems = const <Item>[],
    String? edge,
    List<String> oils = const <String>[],
    int? hp,
    int gold = 0,
    Level level = Level.end,
  }) {
    final intrinsic = Stats(
      maxHp: maxHp,
      attack: attack,
      armor: armor,
      speed: speed,
    );
    return Creature(
      name: _kPlayerName,
      level: level,
      intrinsic: intrinsic,
      gold: gold,
      hp: hp,
      inventory: Inventory(
        level: level,
        edge: edge != null ? edges[edge] : null,
        oils: oils.map((name) => this.oils[name]).toList(),
        items: [...customItems, ...items.map((name) => this.items[name])],
        setBonuses: sets,
      ),
    );
  }
}

/// Create an enemy
@visibleForTesting
Creature makeEnemy({
  required int health,
  required int attack,
  int armor = 0,
  int speed = 0,
  EffectMap? effect,
  Level level = Level.one,
}) {
  Effect? triggers;
  if (effect != null) {
    triggers = Effect(
      callbacks: effect,
      text: 'Enemy',
    );
  }
  return Creature(
    name: 'Enemy',
    level: level,
    inventory: null,
    intrinsic: Stats(
      maxHp: health,
      armor: armor,
      attack: attack,
      speed: speed,
    ),
    gold: 1,
    effect: triggers,
  );
}

/// Oil applied to a weapon.
class Oil extends CatalogItem {
  /// Create an Oil
  Oil({required super.name, required this.stats});

  /// Create an Oil from a yaml map.
  factory Oil.fromYaml(YamlMap yaml, LookupEffect _) {
    final name = yaml['name'] as String;
    final attack = yaml['attack'] as int? ?? 0;
    final armor = yaml['armor'] as int? ?? 0;
    final speed = yaml['speed'] as int? ?? 0;

    final stats = Stats(
      attack: attack,
      armor: armor,
      speed: speed,
    );
    return Oil(name: name, stats: stats);
  }

  /// The stats of the oil.
  final Stats stats;

  @override
  String toString() => name;

  /// All the known keys in the oils yaml, in sorted order.
  static const List<String> orderedKeys = <String>[
    'name',
    'attack',
    'armor',
    'speed',
  ];

  /// Convert to json.
  @override
  dynamic toJson() => <String, dynamic>{
        'name': name,
        ...stats.toJson(),
      };
}

/// An edge is a special effect that can be applied to a weapon.
class Edge extends CatalogItem {
  /// Create an Edge
  Edge({required super.name, required super.effect});

  /// Create an Edge from a yaml map.
  factory Edge.fromYaml(YamlMap yaml, LookupEffect lookupEffect) {
    final name = yaml['name'] as String;
    final effectText = yaml['effect'] as String?;
    final effect = lookupEffect(name: name, effectText: effectText);
    return Edge(name: name, effect: effect);
  }

  @override
  String toString() => name;

  @override
  dynamic toJson() {
    return {
      'name': name,
      'effect': effect?.toJson(),
    };
  }
}

/// The type of creature.
enum CreatureType {
  /// A player.
  player,

  /// An overland enemy.
  mob,

  /// A boss.
  boss,
}

/// Class representing a player or an enemy.
@immutable
class Creature extends CatalogItem {
  /// Create a Creature (player or enemy).
  Creature({
    required super.name,
    required Stats intrinsic,
    required this.gold,
    required this.level,
    required this.inventory,
    this.type = CreatureType.mob,
    int? hp,
    super.effect,
  })  : _intrinsic = intrinsic,
        _lostHp = _computeLostHp(intrinsic, inventory, hp);

  /// Create a creature from a yaml map.
  factory Creature.fromYaml(YamlMap yaml, LookupEffect lookupEffect) {
    final name = yaml['name'] as String;
    final levelNumber = yaml['level'] as int?;
    if (levelNumber == null) {
      throw ArgumentError('Creature $name must have a level.');
    }
    final level = Level.fromJson(levelNumber);
    final attack = yaml['attack'] as int? ?? 0;
    final health = yaml['health'] as int? ?? 0;
    final armor = yaml['armor'] as int? ?? 0;
    final speed = yaml['speed'] as int? ?? 0;
    final effectText = yaml['effect'] as String?;
    final effect = lookupEffect(name: name, effectText: effectText);
    final type = yaml['boss'] == true ? CreatureType.boss : CreatureType.mob;
    return Creature(
      name: name,
      level: level,
      inventory: null,
      intrinsic: Stats(
        maxHp: health,
        armor: armor,
        attack: attack,
        speed: speed,
      ),
      gold: 1,
      effect: effect,
      type: type,
    );
  }

  static int _computeLostHp(
    Stats intrinsic,
    Inventory? inventory,
    int? hp,
  ) {
    final maxHp = inventory?.statsWithItems(intrinsic).maxHp ?? intrinsic.maxHp;
    return maxHp - (hp ?? maxHp);
  }

  /// The default player item.
  // TODO(eseidel): Remove defaultPlayerWeapon.
  static late final Item defaultPlayerWeapon;

  /// The intrinsic stats of this Creature without any items.
  final Stats _intrinsic;

  /// Inventory of the player or null for non-players.
  final Inventory? inventory;

  /// How much hp has been lost.
  final int _lostHp;

  /// How much gold is on this creature or player.
  final int gold;

  /// The level this creature appears in or Level the player is on.
  final Level level;

  /// Returns true if this Creature is the player.
  bool get isPlayer => type == CreatureType.player;

  /// The type of creature.
  final CreatureType type;

  /// Current health of the creature.
  /// Combat can't change maxHp, so we can compute it from baseStats.
  int get hp => baseStats.maxHp - _lostHp;

  /// Returns true if the creature is still alive.
  bool get isAlive => hp > 0;

  /// Stats as they would be in the over-world or at fight start.
  Stats get baseStats => inventory?.statsWithItems(_intrinsic) ?? _intrinsic;

  /// Make a copy with a changed hp.
  Creature copyWith({int? hp, int? gold}) {
    return Creature(
      name: name,
      intrinsic: _intrinsic,
      inventory: inventory,
      hp: hp ?? this.hp,
      gold: gold ?? this.gold,
      effect: effect,
      level: level,
    );
  }

  /// All the known keys in the creatures yaml, in sorted order.
  static List<String> orderedKeys = <String>[
    'name',
    'level',
    'boss',
    'attack',
    'health',
    'armor',
    'speed',
    'gold',
    'items',
    'effect',
    'edge',
    'oils',
    'unlock',
  ];

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      // We don't currently serialize the player type.
      if (type == CreatureType.boss) 'boss': true,
      'level': level.toJson(),
      ..._intrinsic.toJson(),
      if (gold != 1) 'gold': gold,
      if (inventory != null) ...?inventory?.toJson(),
      // Not including hp for now.
      'effect': effect?.toJson(),
    };
  }
}
