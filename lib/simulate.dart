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
class Creature {
  Creature(
    this.name, {
    required int attack,
    required int health,
    int armor = 0,
    int speed = 0,
    this.items = const <Item>[],
  })  : baseStats = Stats(
          health: health,
          armor: armor,
          attack: attack,
          speed: speed,
        ),
        hp = health;

  Creature.player({int health = 10})
      : name = kPlayerName,
        baseStats = Stats(health: health),
        items = const <Item>[],
        hp = health;

  static const kPlayerName = 'Player';

  bool get isPlayer => name == kPlayerName;

  final String name;
  final Stats baseStats;
  final List<Item> items;
  final int hp;

  Stats get stats => baseStats;

  bool get isAlive => hp > 0;
}

class Creatures {
  final wolf = Creature('Wolf', attack: 1, health: 5);
}

// Named Floor to not conflict with "Level" from mason_logger.
@immutable
class Floor {
  const Floor({required this.number, required this.boss, this.length = 100});

  final int number;
  final Creature boss;
  final int length;
}

class Game {
  Game({
    required this.player,
    required this.floor,
    this.currentTime = 0,
  });
  // Player, Level, Time, Next Boss
  Creature player;
  Floor floor;
  int currentTime;
}

class Combatants {
  // By convention the player should be passed first, as the first will win
  // the tie for who goes first in equal speed, etc.
  Combatants(this.creatures);
  final List<Creature> creatures;

  Creature get _first => creatures[0];
  Creature get _second => creatures[1];

  int get startIndex => _first.stats.speed >= _second.stats.speed ? 0 : 1;

  Creature get player => _first.isPlayer ? _first : _second;
  Creature get mob => _first.isPlayer ? _second : _first;

  bool get allAlive => _first.isAlive && _second.isAlive;

  Creature operator [](int index) => index.isEven ? _first : _second;
}

class Battle {
  Combatants hit({required Creature attacker, required Creature defender}) {
    return Combatants([attacker, defender]);
  }

  Combatants resolve({required Creature first, required Creature second}) {
    var combatants = Combatants([first, second]);
    var attackerIndex = combatants.startIndex;
    while (combatants.allAlive) {
      final attacker = combatants[attackerIndex];
      final defender = combatants[attackerIndex];
      // onBattle
      // onTurn
      // apply the damage
      combatants = hit(attacker: attacker, defender: defender);
      // onHit
      // onExposed
      // onWounded
      // This doesn't handle "stunned" yet.
      attackerIndex++;
    }

    // While neither of them is dead.
    // Resolve a turn
    return combatants;
  }
}

void runSim() {
  // This is mostly a placeholder for now.

  // Create a new Game
  // Simulate it until the player dies?
  // Print the results.
}
