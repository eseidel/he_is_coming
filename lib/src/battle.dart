import 'dart:math';

import 'package:he_is_coming_sim/creatures.dart';
import 'package:he_is_coming_sim/item.dart';
import 'package:he_is_coming_sim/logger.dart';

/// Context for an in-progress battle.
class BattleContext {
  /// Create a BattleContext.
  BattleContext(this.creatures)
      : stats = creatures.map((c) => c.startingStats).toList(),
        _attackerIndex = 0 {
    _attackerIndex = _firstAttackerIndex(stats);
  }

  static int _firstAttackerIndex(List<Stats> stats) =>
      stats[0].speed >= stats[1].speed ? 0 : 1;

  /// Advance to the next attacker.
  void nextAttacker() {
    _attackerIndex = attackerIndex.isEven ? 1 : 0;
  }

  /// List of creatures in this battle.
  final List<Creature> creatures;

  /// Current stats for the battling creatures.
  final List<Stats> stats;

  int _attackerIndex;

  /// Index of the current attacker.
  int get attackerIndex => _attackerIndex;

  /// Index of the current defender.
  int get defenderIndex => _attackerIndex.isEven ? 1 : 0;

  /// Stats for the current attacker.
  Stats get attackerStats => stats[attackerIndex];

  /// Name of the current attacker.
  String get attackerName => creatures[attackerIndex].name;

  /// Stats for the current defender.
  Stats get defenderStats => stats[defenderIndex];

  /// Name of the current defender.
  String get defenderName => creatures[defenderIndex].name;

  /// Set stats for the creature at `index`.
  void setStats(int index, Stats newStats) {
    stats[index] = newStats;
  }

  Creature get _first => creatures[0];
  Creature get _second => creatures[1];

  /// The first creature in this battle with current stats.
  Creature get firstResolved => _first.copyWith(hp: stats[0].health);

  /// The second creature in this battle with current stats.
  Creature get secondResolved => _second.copyWith(hp: stats[1].health);

  /// Returns true if all participants are still alive.
  bool get allAlive => stats[0].health > 0 && stats[1].health > 0;

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
  /// Play out the battle and return the result.
  BattleResult resolve({required Creature first, required Creature second}) {
    final ctx = BattleContext([first, second]);
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
        '${ctx.attackerName} attacks ($damage).',
      );
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
    return BattleResult(ctx.firstResolved, ctx.secondResolved);
  }
}
