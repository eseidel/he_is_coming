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
Player playerWithInventory(Level level, Inventory inventory) {
  return Creature(
    name: _kPlayerName,
    intrinsic: playerIntrinsicStats,
    gold: 0,
    level: level,
    id: _kPlayerId,
    inventory: inventory,
    version: null,
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
    return Creature(
      name: _kPlayerName,
      level: level,
      intrinsic: intrinsic,
      gold: gold,
      hp: hp,
      id: _kPlayerId,
      version: null,
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
      onDynamicStats: null,
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
    required this.gold,
    required this.level,
    required this.inventory,
    required super.id,
    required super.version,
    this.type = CreatureType.mob,
    int? hp,
    super.effect,
  })  : _intrinsic = intrinsic,
        lostHp = _computeLostHp(intrinsic, inventory, hp);

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
      gold: 1,
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
  Stats get baseStats => inventory?.statsWithItems(_intrinsic) ?? _intrinsic;

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
    'gold',
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
      if (gold != 1) 'gold': gold,
      if (inventory != null) ...?inventory?.toJson(),
      // Not including hp for now.
      'effect': effect?.toJson(),
      if (version != null) 'version': version,
    };
  }
}
