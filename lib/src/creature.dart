import 'package:collection/collection.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/item.dart';
import 'package:meta/meta.dart';

const _kPlayerName = 'Player';

/// Alias for Creature.
typedef Player = Creature;

/// ItemException
class ItemException implements Exception {
  /// Create ItemException
  ItemException(this.message);

  /// Message
  final String message;
}

/// Create a player.
Player createPlayer({
  Stats intrinsic = const Stats(),
  List<Item> withItems = const <Item>[],
  Edge? edge,
  int? hp,
}) {
  // Player must always have a weapon.
  final items = [...withItems];
  if (items.every((item) => item.kind != Kind.weapon)) {
    items.add(data.items['Wooden Stick']);
  }

  final itemCounts = items.fold<Map<String, int>>(
    {},
    (counts, item) =>
        counts..update(item.name, (count) => count + 1, ifAbsent: () => 1),
  );
  for (final entry in itemCounts.entries) {
    if (entry.value > 1) {
      final item = items.firstWhere((item) => item.name == entry.key);
      if (item.isUnique) {
        throw ItemException(
          '${item.name} is unique and can only be equipped once.',
        );
      }
    }
  }

  final weaponCount = items.where((item) => item.kind == Kind.weapon).length;
  if (weaponCount > 1) {
    throw ItemException('Player can only have one weapon.');
  }

  // Weapon is always first.
  items.sortBy<num>((item) => item.kind == Kind.weapon ? 0 : 1);

  return Creature(
    name: _kPlayerName,
    // If maxHp wasn't set, default to 10.
    intrinsic:
        (intrinsic.maxHp == 0) ? intrinsic.copyWith(maxHp: 10) : intrinsic,
    gold: 0,
    hp: hp,
    items: items,
    edge: edge,
  );
}

/// Create an enemy
Creature makeEnemy(
  String name, {
  required int health,
  required int attack,
  int armor = 0,
  int speed = 0,
  Effects? effects,
}) {
  return Creature(
    name: name,
    intrinsic: Stats(
      maxHp: health,
      armor: armor,
      attack: attack,
      speed: speed,
    ),
    gold: 1,
    effects: effects,
  );
}

/// An edge is a special effect that can be applied to a weapon.
class Edge {
  /// Create an Edge
  Edge(this.name, this.effects);

  /// The name of the edge.
  final String name;

  /// The effects of the edge.
  final Effects? effects;
}

/// Class representing a player or an enemy.
@immutable
class Creature {
  /// Create a Creature (player or enemy).
  Creature({
    required this.name,
    required Stats intrinsic,
    required this.gold,
    this.items = const <Item>[],
    int? hp,
    this.effects,
    this.edge,
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

  /// Intrinsic effects of this creature.
  final Effects? effects;

  /// The edge on the weapon.
  final Edge? edge;

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
      effects: effects,
      edge: edge,
    );
  }
}
