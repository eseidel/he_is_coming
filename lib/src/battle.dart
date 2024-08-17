import 'dart:math';

import 'package:he_is_coming_sim/src/creatures.dart';
import 'package:he_is_coming_sim/src/logger.dart';

/// Passed to all Effect callbacks.
class EffectContext {
  /// Create an EffectContext
  EffectContext(this._battle, this._index);

  final BattleContext _battle;
  final int _index;

  CreatureStats get _stats => _battle.stats[_index];
  set _stats(CreatureStats stats) => _battle.setStats(_index, stats);

  /// Returns true if health is currently full.
  bool get isHealthFull => _stats.isHealthFull;

  /// Add or remove armor
  void adjustArmor(int armorDelta) {
    _stats = _stats.copyWith(armor: _stats.armor + armorDelta);
  }
}

/// Holds stats for a creature during battle.
class CreatureStats {
  /// Create a CreatureStats.
  CreatureStats({
    required this.maxHp,
    required this.hp,
    required this.armor,
    required this.speed,
    required this.attack,
    required this.gold,
  });

  /// Create a CreatureStats from a Creature.
  factory CreatureStats.fromCreature(Creature creature) {
    final stats = creature.startingStats;
    return CreatureStats(
      maxHp: stats.health,
      hp: creature.hp,
      armor: stats.armor,
      speed: stats.speed,
      attack: stats.attack,
      gold: creature.gold,
    );
  }

  /// Max health.
  final int maxHp;

  /// Current health.
  final int hp;

  /// Current armor.
  final int armor;

  /// Speed.
  final int speed;

  /// Attack.
  final int attack;

  /// Value if the creature is defeated.
  final int gold;

  /// Returns true if health is currently full.
  bool get isHealthFull => hp == maxHp;

  /// Create a copy of this with some fields updated.
  CreatureStats copyWith({
    int? hp,
    int? armor,
    int? maxHp,
  }) {
    return CreatureStats(
      maxHp: maxHp ?? this.maxHp,
      hp: hp ?? this.hp,
      armor: armor ?? this.armor,
      speed: speed,
      attack: attack,
      gold: gold,
    );
  }

  @override
  String toString() {
    return 'hp: $hp/$maxHp, armor: $armor, speed: $speed, attack: $attack, gold: $gold';
  }
}

/// Context for an in-progress battle.
class BattleContext {
  /// Create a BattleContext.
  BattleContext(this.creatures)
      : stats = creatures.map(CreatureStats.fromCreature).toList(),
        _attackerIndex = 0 {
    _attackerIndex = _firstAttackerIndex(stats);
  }

  static int _firstAttackerIndex(List<CreatureStats> stats) =>
      stats[0].speed >= stats[1].speed ? 0 : 1;

  /// Advance to the next attacker.
  void nextAttacker() {
    _attackerIndex = attackerIndex.isEven ? 1 : 0;
  }

  /// List of creatures in this battle.
  final List<Creature> creatures;

  /// Current stats for the battling creatures.
  final List<CreatureStats> stats;

  int _attackerIndex;

  /// Index of the current attacker.
  int get attackerIndex => _attackerIndex;

  /// Index of the current defender.
  int get defenderIndex => _attackerIndex.isEven ? 1 : 0;

  /// Stats for the current attacker.
  CreatureStats get attackerStats => stats[attackerIndex];

  /// Name of the current attacker.
  String get attackerName => creatures[attackerIndex].name;

  /// Stats for the current defender.
  CreatureStats get defenderStats => stats[defenderIndex];

  /// Name of the current defender.
  String get defenderName => creatures[defenderIndex].name;

  /// Set stats for the creature at `index`.
  void setStats(int index, CreatureStats newStats) {
    stats[index] = newStats;
  }

  Creature get _first => creatures[0];
  Creature get _second => creatures[1];

  /// The first creature in this battle with current stats.
  Creature get firstResolved {
    final goldDiff = _first.isAlive ? _second.gold : 0;
    return _first.copyWith(hp: stats[0].hp, gold: _first.gold + goldDiff);
  }

  /// The second creature in this battle with current stats.
  Creature get secondResolved {
    final goldDiff = _second.isAlive ? _first.gold : 0;
    return _second.copyWith(hp: stats[1].hp, gold: _second.gold + goldDiff);
  }

  /// Returns true if all participants are still alive.
  bool get allAlive => stats[0].hp > 0 && stats[1].hp > 0;

  /// Returns the Creature at `index` mod 2.
  Creature operator [](int index) => index.isEven ? _first : _second;
}

/// Represents the results of a battle.
class BattleResult {
  /// Create a BattleResult
  BattleResult(this.first, this.second);

  /// First creature in this battle.
  final Creature first;

  /// Second creature in this battle.
  final Creature second;

  /// Winner of the battle.
  /// By convention, the second creature wins if the first one is dead.
  /// The player is always the first creature and thus loses if they die.
  Creature get winner => first.hp > 0 ? first : second;
}

/// Class to represent a battle between two creatures.
/// The player should be the first creature.
class Battle {
  void _logSpoils({required Creature before, required Creature after}) {
    if (!after.isAlive) {
      return;
    }
    final diffStrings = <String>[];
    final hpDiff = after.hp - before.hp;
    if (hpDiff > 0) {
      diffStrings.add('hp +$hpDiff');
    } else if (hpDiff < 0) {
      diffStrings.add('hp $hpDiff');
    }
    final goldDiff = after.gold - before.gold;
    if (goldDiff > 0) {
      diffStrings.add('gold +$goldDiff');
    }
    if (diffStrings.isNotEmpty) {
      logger.info('${after.name} result: ${diffStrings.join(' ')}');
    }
  }

  void _onBattle(BattleContext battleCtx) {
    // send on battle to all items on both creatures
    for (final creature in battleCtx.creatures) {
      final effectCxt =
          EffectContext(battleCtx, battleCtx.creatures.indexOf(creature));
      for (final item in creature.items) {
        item.effect?.onBattle?.call(effectCxt);
      }
    }
  }

  /// Play out the battle and return the result.
  BattleResult resolve({required Creature first, required Creature second}) {
    logger
      ..info('${first.name}: ${first.baseStats}')
      ..info('${second.name}: ${first.baseStats}');

    final ctx = BattleContext([first, second]);
    _onBattle(ctx);

    logger
      ..info('${first.name}: ${ctx.stats[0]}')
      ..info('${second.name}: ${ctx.stats[1]}');
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
      final newHp = ctx.defenderStats.hp - remainingDamage;
      logger.info('${ctx.attackerName} attacks ($damage).');
      ctx
        ..setStats(
          ctx.defenderIndex,
          ctx.defenderStats.copyWith(
            armor: newArmor,
            hp: newHp,
          ),
        )
        // onHit
        // onExposed
        // onWounded
        // This doesn't handle "stunned" yet.
        ..nextAttacker();
    }

    // Print spoils for the player if they won.
    final firstResolved = ctx.firstResolved;
    _logSpoils(before: first, after: firstResolved);
    return BattleResult(firstResolved, ctx.secondResolved);
  }
}
