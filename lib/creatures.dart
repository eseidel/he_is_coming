import 'package:he_is_coming_sim/item.dart';
import 'package:he_is_coming_sim/items.g.dart';
import 'package:meta/meta.dart';

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

  /// Create a player.
  Creature.player({int health = 10})
      : name = _kPlayerName,
        baseStats = Stats(health: health),
        items = <Item>[Items.woodenStick],
        hp = health;

  static const _kPlayerName = 'Player';

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

/// Class holding all predefined enemies.
class Enemies {
  /// Wolf Lvl 1
  /// If player has 5 or less health, wolf gains 2 attack.
  static final wolfLevel1 = Creature('Wolf', attack: 1, health: 3);

  /// Bear Lvl 1
  /// Bear deals 3 additional damage while you have armor.
  static final bearLevel1 = Creature('Bear', attack: 1, health: 3);
}
