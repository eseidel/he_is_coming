import 'package:he_is_coming_sim/item.dart';
import 'package:he_is_coming_sim/items.dart';
import 'package:meta/meta.dart';

@immutable
class Creature {
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

  Creature.player({int health = 10})
      : name = kPlayerName,
        baseStats = Stats(health: health),
        items = <Item>[Items.woodenStick],
        hp = health;

  static const kPlayerName = 'Player';

  bool get isPlayer => name == kPlayerName;

  final String name;
  final Stats baseStats;
  final List<Item> items;
  final int hp;

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

class Creatures {
  // Wolf Lvl 1
  // If player has 5 or less health, wolf gains 2 attack.
  static final wolfLevel1 = Creature('Wolf', attack: 1, health: 3);
  // Bear Lvl 1
  // Bear deals 3 additional damage while you have armor.
  static final bearLevel1 = Creature('Bear', attack: 1, health: 3);
}
