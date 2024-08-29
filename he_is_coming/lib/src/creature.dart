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

List<Item> _enforceItemRules(List<Item> unenforced) {
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

/// Create a player.
Player createPlayer({
  Stats intrinsic = const Stats(),
  List<Item> items = const <Item>[],
  Edge? edge,
  List<Oil> oils = const <Oil>[],
  int? hp,
  int? gold,
}) {
  return Creature(
    name: _kPlayerName,
    // If maxHp wasn't set, default to 10.
    intrinsic:
        (intrinsic.maxHp == 0) ? intrinsic.copyWith(maxHp: 10) : intrinsic,
    gold: gold ?? 0,
    hp: hp,
    items: _enforceItemRules(items),
    edge: edge,
    oils: oils,
  );
}

/// Create an enemy
@visibleForTesting
Creature makeEnemy({
  required int health,
  required int attack,
  int armor = 0,
  int speed = 0,
  EffectMap? effect,
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
    this.type = CreatureType.mob,
    this.items = const <Item>[],
    int? hp,
    super.effect,
    this.edge,
    this.level,
    this.oils = const <Oil>[],
  })  : _intrinsic = intrinsic,
        _lostHp = _computeLostHp(intrinsic, items, oils, hp);

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
    List<Item> items,
    List<Oil> oils,
    int? hp,
  ) {
    final maxHp = _statsWithItems(
      intrinsic,
      items,
      oils,
    ).maxHp;
    return maxHp - (hp ?? maxHp);
  }

  /// The default player item.
  static late final Item defaultPlayerWeapon;

  /// The intrinsic stats of this Creature without any items.
  final Stats _intrinsic;

  /// The edge on the weapon.
  final Edge? edge;

  /// Oils applied to the weapon.
  final List<Oil> oils;

  /// Items the creature or player is using.
  final List<Item> items;

  /// How much hp has been lost.
  final int _lostHp;

  /// How much gold is on this creature or player.
  final int gold;

  /// The level this creature appears in.
  // This belongs somewhere else.
  final Level? level;

  /// Returns true if this Creature is the player.
  bool get isPlayer => type == CreatureType.player;

  /// The type of creature.
  final CreatureType type;

  /// Current health of the creature.
  /// Combat can't change maxHp, so we can compute it from baseStats.
  int get hp => baseStats.maxHp - _lostHp;

  /// Returns true if the creature is still alive.
  bool get isAlive => hp > 0;

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

  static Stats _statsWithItems(Stats stats, List<Item> items, List<Oil> oils) {
    return [
      ...items.map((item) => item.stats),
      ...oils.map((oil) => oil.stats),
    ].fold<Stats>(
      stats,
      (acc, stats) => acc + stats,
    );
  }

  /// Stats as they would be in the over-world or at fight start.
  Stats get baseStats => _statsWithItems(_intrinsic, items, oils);

  /// Make a copy with a changed hp.
  Creature copyWith({int? hp, int? gold}) {
    return Creature(
      name: name,
      intrinsic: _intrinsic,
      items: items,
      hp: hp ?? this.hp,
      gold: gold ?? this.gold,
      effect: effect,
      edge: edge,
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
      if (level != null) 'level': level?.toJson(),
      ..._intrinsic.toJson(),
      if (gold != 1) 'gold': gold,
      'items': items.map((i) => i.toJson()).toList(),
      // Not including hp for now.
      'effect': effect?.toJson(),
      'edge': edge?.toJson(),
      'oils': oils.map((oil) => oil.toJson()).toList(),
    };
  }
}
