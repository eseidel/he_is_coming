import 'package:he_is_coming/src/effects.dart';
import 'package:meta/meta.dart';

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
      armor: armor ?? this.armor,
      attack: attack ?? this.attack,
      speed: speed ?? this.speed,
    );
  }

  @override
  String toString() {
    return 'MaxHP: $maxHp, Armor: $armor, Attack: $attack, Speed: $speed';
  }
}

/// Represents an item that can be equipped by the player.
@immutable
class Item {
  /// Create a new Item
  Item(
    this.name,
    this.rarity, {
    this.kind = Kind.notSpecified,
    this.material = Material.notSpecified,
    int health = 0,
    int armor = 0,
    int attack = 0,
    int speed = 0,
    this.isUnique = false,
    this.effects,
  }) : stats = Stats(
          maxHp: health,
          armor: armor,
          attack: attack,
          speed: speed,
        ) {
    if (kind == Kind.weapon && attack == 0) {
      if (name == 'Bejeweled Blade') {
        // Bejeweled Blade is a special case, it is intentionally 0.
        return;
      }
      throw ArgumentError('Weapon $name must have attack');
    }
  }

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

  /// Effect of the item.
  final Effects? effects;

  /// Is the item unique.
  /// Unique items can only be equipped once.
  final bool isUnique;

  @override
  String toString() {
    return name;
  }
}

/// Enum representing Item kind.
enum Kind {
  /// Weapon, can only equip one of these.
  weapon,

  /// Not displayed in the UI.
  notSpecified,

  // Are food and jewelry just "tags"?  The only reason why Food is separate
  // is that there are food + stone items.
  // I'm not aware of jewelry + material items.

  /// Food, can be combined in the cauldron.
  food,

  /// Jewelry, interacts with items sensitive to jewelry.
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

  /// Golden, made by combining commons
  golden,

  /// Cauldron, made by combining food in the cauldron.
  cauldron,
}

/// Represents the material of the item.
// These maybe should just be "tags".
enum Material {
  /// Not displayed in the UI.
  notSpecified,

  /// Wood, interacts with items sensitive to wood.
  wood,

  /// Stone, interacts with items sensitive to stone.
  stone,

  /// Sanguine
  sanguine,

  /// Bomb
  bomb,
}
