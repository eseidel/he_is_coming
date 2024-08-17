import 'package:he_is_coming_sim/src/item.dart';
import 'package:he_is_coming_sim/src/item_catalog.dart';
import 'package:meta/meta.dart';

const _kPlayerName = 'Player';

/// Create a player.
Creature createPlayer({List<Item> withItems = const <Item>[]}) {
  // Player must always have a weapon.
  final items = [...withItems];
  if (items.every((item) => item.kind != Kind.weapon)) {
    items.add(itemCatalog['Wooden Stick']);
  }

  return Creature(
    _kPlayerName,
    health: 10,
    attack: 0,
    gold: 0,
    items: items,
  );
}

/// Create an enemy
Creature makeEnemy(
  String name, {
  required int attack,
  required int health,
  int gold = 1,
  int armor = 0,
  int speed = 0,
  List<Item> items = const <Item>[],
  int? hp,
}) {
  return Creature(
    name,
    attack: attack,
    health: health,
    speed: speed,
    gold: gold,
    items: items,
    hp: hp,
  );
}

/// Class representing a player or an enemy.
@immutable
class Creature {
  /// Create an enemy.
  Creature(
    this.name, {
    required int attack,
    required int health,
    required this.gold,
    int armor = 0,
    int speed = 0,
    this.items = const <Item>[],
    int? hp,
  })  : baseStats = Stats(
          health: health,
          armor: armor,
          attack: attack,
          speed: speed,
        ),
        hp = hp ?? health;

  /// Returns true if this Creature is the player.
  bool get isPlayer => name == _kPlayerName;

  /// Name of the creature or 'Player' if the player.
  final String name;

  /// The intrinsic stats of this Creature without any items.
  final Stats baseStats;

  /// Items the creature or player is using.
  final List<Item> items;

  /// The current hp of the enemy or player.
  final int hp;

  /// How much gold is on this creature or player.
  final int gold;

  /// Returns true if the creature is still alive.
  bool get isAlive => hp > 0;

  /// Stats as they would be in the over-world or at fight start.
  Stats get startingStats {
    return items.fold(
      baseStats,
      (stats, item) => stats.copyWith(
        health: stats.health + item.stats.health,
        armor: stats.armor + item.stats.armor,
        attack: stats.attack + item.stats.attack,
        speed: stats.speed + item.stats.speed,
      ),
    );
  }

  /// Make a copy with a changed hp.
  Creature copyWith({int? hp, int? gold}) {
    return Creature(
      name,
      attack: baseStats.attack,
      health: baseStats.health,
      armor: baseStats.armor,
      speed: baseStats.speed,
      items: items,
      hp: hp ?? this.hp,
      gold: gold ?? this.gold,
    );
  }
}

/// Class holding predefined over-world enemies.
class Enemies {
  /// If player has 5 or less health, wolf gains 2 attack.
  static final wolfLevel1 = makeEnemy('Wolf Level 1', attack: 1, health: 3);

  /// If player has 5 or less health, wolf gains 3 attack.
  static final wolfLevel2 =
      makeEnemy('Wolf Level 2', attack: 2, health: 6, speed: 1);

  /// If player has 5 or less health, wolf gains 4 attack.
  static final wolfLevel3 =
      makeEnemy('Wolf Level 3', attack: 2, health: 9, speed: 2);

  /// Bear deals 3 additional damage while you have armor.
  static final bearLevel1 = makeEnemy('Bear Level 1', attack: 1, health: 3);

  /// Bear deals 5 additional damage while you have armor.
  static final bearLevel3 =
      makeEnemy('Bear Level 3', attack: 2, health: 8, speed: 2);

  /// Battle Start: If Spider has more speed than you, it deals 3 damage
  static final spiderLevel1 =
      makeEnemy('Spider Level 1', attack: 1, health: 3, speed: 3);

  /// Battle Start: If Spider has more speed than you, it deals 4 damage
  static final spiderLevel2 =
      makeEnemy('Spider Level 2', attack: 1, health: 3, speed: 3);

  /// Battle Start: If Spider has more speed than you, it deals 5 damage
  static final spiderLevel3 =
      makeEnemy('Spider Level 3', attack: 1, health: 4, speed: 4);
}

/// Class holding predefined bosses.
class Bosses {
  /// Hothead, level 1
  /// If Hothead has more speed than you, his first strike deals 10 additional
  /// damage.
  static final hothead = makeEnemy('Hothead', attack: 4, health: 5, speed: 4);

  /// Redwood Treant, level 2
  /// Redwood Treant's attack is halved against armor
  static final redwoodTreant =
      makeEnemy('Redwood Treant', attack: 6, health: 25, armor: 15);

  /// Leshen, level 3
  static final leshen = makeEnemy('Leshen', attack: 7, health: 60, speed: 3);
}
