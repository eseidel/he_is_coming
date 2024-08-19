import 'package:he_is_coming/src/item.dart';
import 'package:he_is_coming/src/item_catalog.dart';
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
    // If maxHp wasn't set, default to 10.
    intrinsic:
        (intrinsic.maxHp == 0) ? intrinsic.copyWith(maxHp: 10) : intrinsic,
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
  /// Combat can't change maxHp, so we can compute it from baseStats.
  int get hp => baseStats.maxHp - _lostHp;

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
  Stats get baseStats => _statsWithItems(_intrinsic, items);

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
