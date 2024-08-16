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
}

@immutable
class Item {
  Item(
    this.name, {
    int health = 0,
    int armor = 0,
    int attack = 0,
    int speed = 0,
    this.isWeapon = false,
  }) : stats = Stats(
          health: health,
          armor: armor,
          attack: attack,
          speed: speed,
        );

  Item.weapon(
    this.name, {
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
        isWeapon = true;

  final bool isWeapon;
  final String name;
  final Stats stats;
}

class Items {
  final woodenStick = Item.weapon('Wooden Stick', attack: 1);
}

@immutable
class Player {
  const Player({this.items = const <Item>[]});

  Stats get baseStats => const Stats(health: 10);
  final List<Item> items;
}

class Creature {
  Creature(
    this.name, {
    required int attack,
    required int health,
    int armor = 0,
    int speed = 0,
  }) : stats = Stats(
          health: health,
          armor: armor,
          attack: attack,
          speed: speed,
        );
  final String name;
  final Stats stats;
}

class Creatures {
  final wolf = Creature('Wolf', attack: 1, health: 5);
}

class Game {
  // Player, Level, Time, Next Boss
}

void runSim() {
  // This is mostly a placeholder for now.

  // Create a new Game
  // Simulate it until the player dies?
  // Print the results.
}
