import 'package:he_is_coming_sim/src/item.dart';
import 'package:he_is_coming_sim/src/item_catalog.dart';
import 'package:meta/meta.dart';

const _kPlayerName = 'Player';

/// Create a player.
Creature createPlayer({
  Stats intrinsic = const Stats(),
  List<Item> withItems = const <Item>[],
  int? hp,
}) {
  // Player must always have a weapon.
  final items = [...withItems];
  if (items.every((item) => item.kind != Kind.weapon)) {
    items.add(itemCatalog['Wooden Stick']);
  }

  return Creature(
    name: _kPlayerName,
    intrinsic: intrinsic.copyWith(maxHp: 10),
    gold: 0,
    hp: hp,
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
    name: name,
    intrinsic: Stats(
      maxHp: health,
      armor: armor,
      attack: attack,
      speed: speed,
    ),
    gold: gold,
    items: items,
    hp: hp,
  );
}

/// Class representing a player or an enemy.
@immutable
class Creature {
  /// Create an enemy.
  Creature({
    required this.name,
    required Stats intrinsic,
    required this.gold,
    this.items = const <Item>[],
    int? hp,
  })  : _intrinsic = intrinsic,
        _lostHp = _computeLostHp(intrinsic, items, hp);

  static int _computeLostHp(Stats intrinsic, List<Item> items, int? hp) {
    final maxHp = _statsWithItems(intrinsic, items).maxHp;
    return maxHp - (hp ?? maxHp);
  }

  /// Returns true if this Creature is the player.
  bool get isPlayer => name == _kPlayerName;

  /// Name of the creature or 'Player' if the player.
  final String name;

  /// The intrinsic stats of this Creature without any items.
  final Stats _intrinsic;

  /// Items the creature or player is using.
  final List<Item> items;

  /// How much hp has been lost.
  final int _lostHp;

  /// How much gold is on this creature or player.
  final int gold;

  /// Current health of the creature.
  int get hp => startingStats.maxHp - _lostHp;

  /// Returns true if the creature is still alive.
  bool get isAlive => hp > 0;

  static Stats _statsWithItems(Stats stats, List<Item> items) {
    return items.fold(
      stats,
      (stats, item) => stats.copyWith(
        maxHp: stats.maxHp + item.stats.maxHp,
        armor: stats.armor + item.stats.armor,
        attack: stats.attack + item.stats.attack,
        speed: stats.speed + item.stats.speed,
      ),
    );
  }

  /// Stats as they would be in the over-world or at fight start.
  Stats get startingStats => _statsWithItems(_intrinsic, items);

  /// Make a copy with a changed hp.
  Creature copyWith({int? hp, int? gold}) {
    return Creature(
      name: name,
      intrinsic: _intrinsic,
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
