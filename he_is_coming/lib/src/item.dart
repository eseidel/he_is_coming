import 'package:he_is_coming/src/catalog.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

/// Class representing stats for a Creature.
@immutable
class Stats {
  /// Create a new Stats.
  const Stats({
    this.maxHp = 0,
    this.armor = 0,
    this.attack = 0,
    this.speed = 0,
  });

  /// Max health of the creature.
  final int maxHp;

  /// Current armor of the creature.
  final int armor;

  /// Current attack of the creature.
  final int attack;

  /// Current speed.
  final int speed;

  /// Return true if all stats are 0.
  bool get isEmpty => this == const Stats();

  /// Add two Stats together.
  Stats operator +(Stats other) {
    return copyWith(
      maxHp: maxHp + other.maxHp,
      armor: armor + other.armor,
      attack: attack + other.attack,
      speed: speed + other.speed,
    );
  }

  /// Create a copy of Stats with updated values.
  Stats copyWith({
    int? maxHp,
    int? armor,
    int? attack,
    int? speed,
  }) {
    return Stats(
      maxHp: maxHp ?? this.maxHp,
      attack: attack ?? this.attack,
      armor: armor ?? this.armor,
      speed: speed ?? this.speed,
    );
  }

  @override
  String toString() {
    return 'MaxHP: $maxHp, Armor: $armor, Attack: $attack, Speed: $speed';
  }

  /// Convert to json.
  Map<String, dynamic> toJson() {
    return {
      if (maxHp != 0) 'health': maxHp,
      if (attack != 0) 'attack': attack,
      if (armor != 0) 'armor': armor,
      if (speed != 0) 'speed': speed,
    };
  }
}

/// Represents an item that can be equipped by the player.
@immutable
class Item extends CatalogItem {
  /// Create a new Item
  Item(
    String name,
    this.rarity, {
    this.kind,
    this.material,
    int health = 0,
    int armor = 0,
    int attack = 0,
    int speed = 0,
    this.isUnique = false,
    super.effect,
    super.unlock,
    this.parts = const [],
  })  : stats = Stats(
          maxHp: health,
          armor: armor,
          attack: attack,
          speed: speed,
        ),
        super(name: name) {
    if (kind == ItemKind.weapon && attack == 0) {
      if (name == 'Bejeweled Blade') {
        // Bejeweled Blade is a special case, it is intentionally 0.
        return;
      }
      throw ArgumentError('Weapon $name must have attack');
    }
  }

  /// Create a test item.
  @visibleForTesting
  factory Item.test({EffectMap? effect}) {
    Effect? triggers;
    if (effect != null) {
      triggers = Effect(
        callbacks: effect,
        text: 'test',
      );
    }
    return Item('test', ItemRarity.common, effect: triggers);
  }

  /// Create an item from a yaml map.
  factory Item.fromYaml(YamlMap yaml, LookupEffect lookupEffect) {
    final name = yaml['name'] as String;
    final kind = yaml.get('kind', ItemKind.values);
    final rarity = yaml.expect('rarity', ItemRarity.values);
    final material = yaml.get('material', ItemMaterial.values);
    final attack = yaml['attack'] as int? ?? 0;
    final health = yaml['health'] as int? ?? 0;
    final armor = yaml['armor'] as int? ?? 0;
    final speed = yaml['speed'] as int? ?? 0;
    final unlock = yaml['unlock'] as String?;
    final unique = yaml['unique'] as bool? ?? false;
    final effectText = yaml['effect'] as String?;
    final parts = yaml['parts'] as List?;
    final effect = lookupEffect(name: name, effectText: effectText);
    return Item(
      name,
      kind: kind,
      rarity,
      material: material,
      attack: attack,
      health: health,
      armor: armor,
      speed: speed,
      effect: effect,
      isUnique: unique,
      unlock: unlock,
      parts: parts?.cast<String>(),
    );
  }

  /// Kind of the item.
  final ItemKind? kind;

  /// Stats for the item.
  final Stats stats;

  /// Rarity of the item.
  final ItemRarity rarity;

  /// Material of the item.
  final ItemMaterial? material;

  /// Is the item unique.
  /// Unique items can only be equipped once.
  final bool isUnique;

  /// Items combined to make this item.
  final List<String>? parts;

  /// All the known keys in the item yaml, in sorted order.
  static const List<String> orderedKeys = <String>[
    'name',
    'unique',
    'kind',
    'rarity',
    'material',
    'unlock', // ignored for now
    'parts', // ignored for now
    'attack',
    'health',
    'armor',
    'speed',
    'effect',
  ];

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (isUnique) 'unique': isUnique,
      'kind': kind?.toJson(),
      'rarity': rarity.toJson(),
      'parts': parts,
      'material': material?.toJson(),
      ...stats.toJson(),
      'unlock': unlock,
      'effect': effect?.toJson(),
    };
  }
}

/// Enum representing Item kind.
enum ItemKind {
  /// Weapon, can only equip one of these.
  weapon,

  // Are food and jewelry just "tags"?  The only reason why Food is separate
  // is that there are food + stone items.
  // I'm not aware of jewelry + material items.

  /// Food, can be combined in the cauldron.
  food,

  /// Jewelry, interacts with items sensitive to jewelry.
  jewelry;

  /// Create a kind from a json string.
  factory ItemKind.fromJson(String json) {
    return ItemKind.values.firstWhere((e) => e.name == json);
  }

  /// Convert the kind to a json string.
  String toJson() => name;
}

/// Rarity class of an item.
enum ItemRarity {
  /// Common, found in chests.
  common,

  /// Rare, found in shops.
  rare,

  /// Heroic, found in graves.
  heroic,

  /// Golden, made by combining commons
  golden,

  /// Cauldron, made by combining food in the cauldron.
  cauldron;

  /// Create a rarity from a json string.
  factory ItemRarity.fromJson(String json) {
    return ItemRarity.values.firstWhere((e) => e.name == json);
  }

  /// Convert the rarity to a json string.
  String toJson() => name;
}

/// Represents the material of the item.
// These maybe should just be "tags".
enum ItemMaterial {
  /// Wood, interacts with items sensitive to wood.
  wood,

  /// Stone, interacts with items sensitive to stone.
  stone,

  /// Sanguine
  sanguine,

  /// Bomb
  bomb;

  /// Create a material from a json string.
  factory ItemMaterial.fromJson(String json) {
    return ItemMaterial.values.firstWhere((e) => e.name == json);
  }

  /// Convert the material to a json string.
  String toJson() => name;
}
