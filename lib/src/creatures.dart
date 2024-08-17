import 'package:he_is_coming_sim/src/item.dart';
import 'package:he_is_coming_sim/src/item_catalog.dart';
import 'package:meta/meta.dart';

const _kPlayerName = 'Player';

/// Create a player.
Creature createPlayer() {
  return Creature(
    _kPlayerName,
    health: 10,
    attack: 0,
    items: [itemCatalog['Wooden Stick']],
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
  Creature copyWith({int? hp}) {
    return Creature(
      name,
      attack: baseStats.attack,
      health: baseStats.health,
      armor: baseStats.armor,
      speed: baseStats.speed,
      items: items,
      hp: hp ?? this.hp,
    );
  }
}

/// Class holding predefined over-world enemies.
class Enemies {
  /// Wolf Level 1
  /// If player has 5 or less health, wolf gains 2 attack.
  static final wolfLevel1 = Creature('Wolf', attack: 1, health: 3);

  /// Wolf Level 2
  /// If player has 5 or less health, wolf gains 3 attack.
  static final wolfLevel2 = Creature('Wolf', attack: 2, health: 6, speed: 1);

  /// Wolf Level 3
  /// If player has 5 or less health, wolf gains 4 attack.
  static final wolfLevel3 = Creature('Wolf', attack: 2, health: 9, speed: 2);

  /// Bear Level 1
  /// Bear deals 3 additional damage while you have armor.
  static final bearLevel1 = Creature('Bear', attack: 1, health: 3);

  /// Bear Level 3
  /// Bear deals 5 additional damage while you have armor.
  static final bearLevel3 = Creature('Bear', attack: 2, health: 8, speed: 2);

  /// Spider Level 1
  /// Battle Start: If Spider has more speed than you, it deals 3 damage
  static final spiderLevel1 =
      Creature('Spider', attack: 1, health: 3, speed: 3);

  /// Spider Level 2
  /// Battle Start: If Spider has more speed than you, it deals 4 damage
  static final spiderLevel2 =
      Creature('Spider', attack: 1, health: 3, speed: 3);

  /// Spider Level 3
  /// Battle Start: If Spider has more speed than you, it deals 5 damage
  static final spiderLevel3 =
      Creature('Spider', attack: 1, health: 4, speed: 4);
}

/// Class holding predefined bosses.
class Bosses {
  /// Hothead, level 1
  /// If Hothead has more speed than you, his first strike deals 10 additional
  /// damage.
  static final hothead = Creature('Hothead', attack: 4, health: 5, speed: 4);

  /// Redwood Treant, level 2
  /// Redwood Treant's attack is halved against armor
  static final redwoodTreant =
      Creature('Redwood Treant', attack: 6, health: 25, armor: 15);

  /// Leshen, level 3
  static final leshen = Creature('Leshen', attack: 7, health: 60, speed: 3);
}
