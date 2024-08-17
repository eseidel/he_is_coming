import 'package:meta/meta.dart';

/// Class representing stats for a Creature.
@immutable
class Stats {
  /// Create a new Stats.
  const Stats({
    this.health = 0,
    this.armor = 0,
    this.attack = 0,
    this.speed = 0,
  });

  /// Max health of the creature.
  final int health;

  /// Current armor of the creature.
  final int armor;

  /// Current attack of the creature.
  final int attack;

  /// Current speed.
  final int speed;

  /// Create a copy of Stats with updated values.
  Stats copyWith({
    int? health,
    int? armor,
    int? attack,
    int? speed,
  }) {
    return Stats(
      health: health ?? this.health,
      armor: armor ?? this.armor,
      attack: attack ?? this.attack,
      speed: speed ?? this.speed,
    );
  }

  @override
  String toString() {
    return 'Health: $health, Armor: $armor, Attack: $attack, Speed: $speed';
  }
}

/// Represents an item that can be equipped by the player.
@immutable
class Item {
  /// Create a new Item
  Item(
    this.name,
    this.kind,
    this.rarity,
    this.material, {
    int health = 0,
    int armor = 0,
    int attack = 0,
    int speed = 0,
  }) : stats = Stats(
          health: health,
          armor: armor,
          attack: attack,
          speed: speed,
        );

  /// Name of the item.
  final String name;

  /// Kind of the item.
  final Kind kind;

  /// Stats for the item.
  final Stats stats;

  /// Rarity of the item.
  final Rarity rarity;

  /// Material of the item.
  final Material material;
}

/// Enum representing Item kind.
enum Kind {
  /// Weapon, can only equip one of these.
  weapon,

  /// Food, can be combined in the cauldron.
  food,

  /// Clothing, nothing special this is the default.
  clothing,

  /// Jewelry
  jewelry,
}

/// Rarity class of an item.
/// Items within a given rarity can be re-rolled.
enum Rarity {
  /// Common, found in chests.
  common,

  /// Rare, found in shops.
  rare,

  /// Heroic, found in graves.
  heroic,
}

/// Represents the material of the item.
enum Material {
  /// Leather is essentially "none" and is the default material.
  leather,

  /// Wood, interacts with items sensitive to wood.
  wood,

  /// Stone, interacts with items sensitive to stone.
  stone,

  /// Sanguine
  sanguine,

  /// Bomb
  bomb,
}
