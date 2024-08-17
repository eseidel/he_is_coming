import 'dart:math';

import 'package:he_is_coming_sim/logger.dart';
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
  static final woodenStick = Item.weapon('Wooden Stick', attack: 1);
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
  static final wolf = Creature('Wolf', attack: 1, health: 5);
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
}

class BattleContext {
  BattleContext(this.creatures)
      : stats = creatures.map((c) => c.startingStats).toList(),
        _attackerIndex = 0 {
    _attackerIndex = firstAttackerIndex(stats);
  }

  static int firstAttackerIndex(List<Stats> stats) =>
      stats[0].speed >= stats[1].speed ? 0 : 1;

  void nextAttacker() {
    _attackerIndex = attackerIndex.isEven ? 1 : 0;
  }

  void onBattle() {
    // This is a placeholder for now.
  }

  final List<Creature> creatures;
  final List<Stats> stats;
  int _attackerIndex;

  int get attackerIndex => _attackerIndex;
  int get defenderIndex => _attackerIndex.isEven ? 1 : 0;

  Stats get attackerStats => stats[attackerIndex];
  String get attackerName => creatures[attackerIndex].name;
  Stats get defenderStats => stats[defenderIndex];
  String get defenderName => creatures[defenderIndex].name;

  void setStats(int index, Stats newStats) {
    stats[index] = newStats;
  }

  Creature get _first => creatures[0];
  Creature get _second => creatures[1];

  Creature get firstResolved => _first.copyWith(hp: stats[0].health);
  Creature get secondResolved => _second.copyWith(hp: stats[1].health);

  bool get allAlive => stats[0].health > 0 && stats[1].health > 0;

  Creature operator [](int index) => index.isEven ? _first : _second;
}

class Battle {
  Combatants resolve({required Creature first, required Creature second}) {
    final ctx = BattleContext([first, second])..onBattle();
    while (ctx.allAlive) {
      // onBattle
      // onTurn
      // apply the damage
      // figure out how much damage to apply
      // apply it to armor, then apply it to hp
      final damage = ctx.attackerStats.attack;
      final armorReduction = min(ctx.defenderStats.armor, damage);
      final remainingDamage = damage - armorReduction;
      final newArmor = ctx.defenderStats.armor - armorReduction;
      final newHp = ctx.defenderStats.health - remainingDamage;
      logger.info(
          '${ctx.attackerName} attacks ${ctx.defenderName} for $damage damage. '
          'Armor absorbs $armorReduction damage. '
          '${ctx.defenderName} has $newArmor armor and $newHp health remaining.');
      ctx
        ..setStats(
          ctx.defenderIndex,
          ctx.defenderStats.copyWith(
            armor: newArmor,
            health: newHp,
          ),
        )
        // onHit
        // onExposed
        // onWounded
        // This doesn't handle "stunned" yet.
        ..nextAttacker();
    }

    // While neither of them is dead.
    // Resolve a turn
    return Combatants([ctx.firstResolved, ctx.secondResolved]);
  }
}

void runSim() {
  // This is mostly a placeholder for now.

  final player = Creature.player();
  final wolf = Creatures.wolf;
  logger
    ..info('Player: ${player.startingStats}')
    ..info('Wolf: ${wolf.startingStats}');

  final battle = Battle();
  final combatants = battle.resolve(first: player, second: wolf);
  final winner =
      combatants.creatures.firstWhere((c) => c.startingStats.health > 0);
  logger.info('${winner.name} wins!');

  // Create a new Game
  // Simulate it until the player dies?
  // Print the results.
}
