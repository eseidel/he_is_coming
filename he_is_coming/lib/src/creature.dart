import 'package:he_is_coming/src/build_id.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

const _kPlayerName = 'Player';
const _kPlayerId = 0;

/// Alias for Creature.
typedef Player = Creature;

/// Stats in-built to the player.
// TODO(eseidel): Move into the creatures.yaml instead.
const playerIntrinsicStats = Stats(
  maxHp: 10,
);

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

/// Create a player from a creature configuration.
Player playerFromState(BuildState state) {
  return Creature(
    name: _kPlayerName,
    intrinsic: playerIntrinsicStats,
    level: state.level,
    id: _kPlayerId,
    inventory: state.inventory,
    version: null,
    type: CreatureType.player,
    gold: 0,
  );
}

/// Adds a method to create a player from a data object.
extension CreatePlayer on Data {
  /// Create a player.
  Player player({
    int? maxHp,
    int? attack,
    int? armor,
    int? speed,
    List<String> items = const <String>[],
    List<Item> customItems = const <Item>[],
    String? edge,
    Edge? customEdge,
    List<String> oils = const <String>[],
    int? hp,
    int gold = 0,
    Level level = Level.end,
  }) {
    final intrinsic = Stats(
      maxHp: maxHp ?? playerIntrinsicStats.maxHp,
      attack: attack ?? playerIntrinsicStats.attack,
      armor: armor ?? playerIntrinsicStats.armor,
      speed: speed ?? playerIntrinsicStats.speed,
    );
    if (edge != null && customEdge != null) {
      throw ArgumentError('Cannot specify both edge and customEdge.');
    }
    final edgeObject = customEdge ?? (edge != null ? edges[edge] : null);
    var inventory = Inventory.fromNames(
      items: items,
      edge: edge,
      oils: oils,
      data: this,
      level: level,
    );
    if (edgeObject != null) {
      inventory =
          inventory.copyWith(edge: edgeObject, level: level, data: this);
    }
    if (customItems.isNotEmpty) {
      // Remove the default weapon to avoid a custom weapon triggering a
      // "can't have two weapons" Exception.
      final items = (inventory.items + customItems)
          .where((i) => i.name != 'Wooden Stick')
          .toList();
      inventory = inventory.copyWith(
        items: items,
        level: level,
        data: this,
      );
    }
    return Creature(
      name: _kPlayerName,
      level: level,
      intrinsic: intrinsic,
      hp: hp,
      id: _kPlayerId,
      version: null,
      inventory: inventory,
      type: CreatureType.player,
      gold: gold,
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
  EffectCallbacks? effect,
  Level level = Level.one,
  bool isBoss = false,
}) {
  Effect? triggers;
  if (effect != null) {
    triggers = Effect.test(
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
    type: isBoss ? CreatureType.boss : CreatureType.mob,
    effect: triggers,
    version: null,
    id: 0, // Test enemies don't require unique ids.
  );
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
    required this.level,
    required this.inventory,
    required super.id,
    required super.version,
    required this.type,
    int? hp,
    int? gold,
    super.effect,
  })  : _intrinsic = intrinsic,
        lostHp = _computeLostHp(intrinsic, inventory, hp),
        gold = _computeGold(gold, type);

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
    final id = yaml['id'] as int;
    final effect = lookupEffect(name: name, effectText: effectText);
    final type = yaml['boss'] == true ? CreatureType.boss : CreatureType.mob;
    final version = yaml['version'] as String?;
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
      effect: effect,
      type: type,
      id: id,
      version: version,
    );
  }

  static int _computeLostHp(
    Stats intrinsic,
    Inventory? inventory,
    int? hp,
  ) {
    final maxHp =
        inventory?.resolveBaseStats(intrinsic: intrinsic, lostHp: 0).maxHp ??
            intrinsic.maxHp;
    return maxHp - (hp ?? maxHp);
  }

  static int _computeGold(int? gold, CreatureType type) {
    return switch (type) {
      CreatureType.player => gold!,
      CreatureType.mob => gold ?? 1,
      CreatureType.boss => gold ?? 0,
    };
  }

  /// The intrinsic stats of this Creature without any items.
  final Stats _intrinsic;

  /// Inventory of the player or null for non-players.
  final Inventory? inventory;

  /// How much hp has been lost.
  final int lostHp;

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
  int get hp => baseStats.maxHp - lostHp;

  /// Returns true if the creature is still alive.
  bool get isAlive => hp > 0;

  /// Returns true if the creature is at full health.
  bool get healthFull => lostHp == 0;

  /// Stats as they would be in the over-world or at fight start.
  Stats get baseStats =>
      inventory?.resolveBaseStats(intrinsic: _intrinsic, lostHp: lostHp) ??
      _intrinsic;

  /// Make a copy with a changed hp.
  @override
  Creature copyWith({int? id, int? hp, int? gold}) {
    return Creature(
      name: name,
      intrinsic: _intrinsic,
      inventory: inventory,
      hp: hp ?? this.hp,
      gold: gold ?? this.gold,
      effect: effect,
      level: level,
      id: id ?? this.id,
      type: type,
      version: version,
    );
  }

  /// All the known keys in the creatures yaml, in sorted order.
  static List<String> orderedKeys = <String>[
    'name',
    'id',
    'level',
    'boss',
    'attack',
    'health',
    'armor',
    'speed',
    'items',
    'effect',
    'edge',
    'oils',
    'unlock',
    'version',
  ];

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      // We don't currently serialize the player type.
      if (type == CreatureType.boss) 'boss': true,
      'level': level.toJson(),
      ..._intrinsic.toJson(),
      if (inventory != null) ...?inventory?.toJson(),
      // Not including hp for now.
      'effect': effect?.toJson(),
      if (version != null) 'version': version,
    };
  }
}
