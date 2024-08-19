import 'package:he_is_coming_sim/src/battle.dart';
import 'package:meta/meta.dart';

/// Function type for effect callbacks.
typedef EffectFn = void Function(EffectContext ctx);

/// Enum representing the different effects that can be triggered.
enum Effect {
  /// Called on battle start.
  onBattle,

  /// Called at the start of each turn.
  onTurn,

  /// Called whenever the creature attacks.
  /// This does not include damage dealt by non-attack actions.
  /// Essentially, this "onStrike" or "onAttack".
  onHit,

  /// Called when armor is broken for the first time this battle.
  onExposed,

  /// Called when hp is below 50% for the first time this battle.
  onWounded,
}

/// Container for callbacks for items.
@immutable
class Effects {
  /// Create a new Effect
  const Effects({
    this.onBattle,
    this.onTurn,
    this.onHit,
    this.onExposed,
    this.onWounded,
  });

  /// Get the effect callback for a given effect.
  EffectFn? operator [](Effect effect) {
    return switch (effect) {
      Effect.onBattle => onBattle,
      Effect.onTurn => onTurn,
      Effect.onHit => onHit,
      Effect.onExposed => onExposed,
      Effect.onWounded => onWounded,
    };
  }

  /// Called on battle start.
  final EffectFn? onBattle;

  /// Called at the start of each turn.
  final EffectFn? onTurn;

  /// Called whenever the creature attacks.
  /// This does not include damage dealt by non-attack actions.
  final EffectFn? onHit;

  /// Called when armor is broken for the first time this battle.
  final EffectFn? onExposed;

  /// Called when hp is below 50% for the first time this battle.
  final EffectFn? onWounded;
}

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
    this.kind,
    this.rarity,
    this.material, {
    int health = 0,
    int armor = 0,
    int attack = 0,
    int speed = 0,
    this.effects,
  }) : stats = Stats(
          maxHp: health,
          armor: armor,
          attack: attack,
          speed: speed,
        ) {
    if (kind == Kind.weapon && attack == 0) {
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
