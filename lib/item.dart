import 'package:meta/meta.dart';

@immutable
class Stats {
  const Stats({
    this.health = 0,
    this.armor = 0,
    this.attack = 0,
    this.speed = 0,
  });

  final int health;
  final int armor;
  final int attack;
  final int speed;

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

@immutable
class Item {
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

  Item.weapon(
    this.name,
    this.rarity,
    this.material, {
    required int attack,
    int health = 0,
    int armor = 0,
    int speed = 0,
  })  : stats = Stats(
          health: health,
          armor: armor,
          attack: attack,
          speed: speed,
        ),
        kind = Kind.weapon;

  final Kind kind;
  final String name;
  final Stats stats;
  final Rarity rarity;
  final Material material;
}

enum Kind {
  weapon,
  food,
  clothing,
  jewelry,
}

enum Rarity {
  common,
  rare,
  heroic,
}

enum Material {
  wood,
  stone,
  leather,
// leather is essentially "none"
  sanguine
}
