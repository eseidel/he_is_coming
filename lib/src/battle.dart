import 'dart:math';

import 'package:he_is_coming_sim/src/creatures.dart';
import 'package:he_is_coming_sim/src/logger.dart';
import 'package:meta/meta.dart';

String _signed(int value) => value >= 0 ? '+$value' : '$value';

/// Passed to all Effect callbacks.
class EffectContext {
  /// Create an EffectContext
  EffectContext(this._battle, this._index, this._sourceName);

  final BattleContext _battle;
  final int _index;
  final String _sourceName;

  /// Stats for the creature with this effect.
  CreatureStats get my => _battle.stats[_index];

  /// Stats for the enemy creature.
  CreatureStats get enemy => _battle.stats[_index.isEven ? 1 : 0];

  CreatureStats get _stats => _battle.stats[_index];
  set _stats(CreatureStats stats) => _battle.setStats(_index, stats);
  String get _playerName => _battle.creatures[_index].name;

  /// Returns true if health is currently full.
  bool get isHealthFull => _stats.isHealthFull;

  /// Add or remove armor
  void adjustArmor(int armorDelta, {bool ifTrue = true}) {
    if (!ifTrue) {
      return;
    }
    _stats = _stats.copyWith(armor: _stats.armor + armorDelta);
    logger.info('$_playerName armor ${_signed(armorDelta)} from $_sourceName');
  }

  /// Restore health.
  void restoreHealth(int hp) {
    if (_stats.hp == _stats.maxHp) {
      return;
    }
    _stats = _stats.copyWith(hp: _stats.hp + hp);
    logger.info('$_playerName hp ${_signed(hp)} from $_sourceName');
  }
}

String? _diffString(String name, int before, int after) {
  final diff = after - before;
  // logger.info('$name: $before -> $after ($diff)');
  return diff != 0 ? '$name: ${_signed(diff)}' : null;
}

/// Holds stats for a creature during battle.
@immutable
class CreatureStats {
  /// Create a CreatureStats.
  const CreatureStats({
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
      maxHp: stats.maxHp,
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
    final newMaxHp = maxHp ?? this.maxHp;
    final newHp = hp ?? this.hp;
    if (newHp > newMaxHp) {
      throw ArgumentError('hp cannot be greater than maxHp');
    }
    return CreatureStats(
      maxHp: newMaxHp,
      hp: newHp,
      armor: armor ?? this.armor,
      speed: speed,
      attack: attack,
      gold: gold,
    );
  }

  /// Returns a string describing the difference between this and `other`
  /// or null if there is no difference.
  String? diffString(CreatureStats other) {
    final diffStrings = <String?>[
      _diffString('hp', hp, other.hp),
      _diffString('maxHp', maxHp, other.maxHp),
      _diffString('armor', armor, other.armor),
      _diffString('speed', speed, other.speed),
      _diffString('attack', attack, other.attack),
      _diffString('gold', gold, other.gold),
    ].nonNulls;
    if (diffStrings.isNotEmpty) {
      return diffStrings.join(' ');
    }
    return null;
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
  CreatureStats get attacker => stats[attackerIndex];

  /// Name of the current attacker.
  String get attackerName => creatures[attackerIndex].name;

  /// Stats for the current defender.
  CreatureStats get defender => stats[defenderIndex];

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
    logger.info('firstResolved HP: ${stats[0].hp}');
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
  static void _logSpoils({required Creature before, required Creature after}) {
    if (!after.isAlive) {
      return;
    }
    final diffStrings = <String?>[
      _diffString('hp', before.hp, after.hp),
      _diffString('gold', before.gold, after.gold),
    ].nonNulls;
    if (diffStrings.isNotEmpty) {
      logger.info('${after.name} result: ${diffStrings.join(' ')}');
    }
  }

  static void _onBattle(BattleContext battleCtx) {
    // send on battle to all items on both creatures
    for (var index = 0; index < battleCtx.creatures.length; index++) {
      final creature = battleCtx.creatures[index];
      final beforeStats = battleCtx.stats[index];
      for (final item in creature.items) {
        final effectCxt = EffectContext(battleCtx, index, item.name);
        item.effect?.onBattle?.call(effectCxt);
      }
      final afterStats = battleCtx.stats[index];
      final diffString = beforeStats.diffString(afterStats);
      if (diffString != null) {
        logger.info('${creature.name} onBattle: $diffString');
      }
    }
  }

  /// Play out the battle and return the result.
  static BattleResult resolve({
    required Creature first,
    required Creature second,
  }) {
    logger
      ..info('${first.name}: ${first.startingStats}')
      ..info('${second.name}: ${first.startingStats}');

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
      final damage = ctx.attacker.attack;
      final armorReduction = min(ctx.defender.armor, damage);
      final remainingDamage = damage - armorReduction;
      final newArmor = ctx.defender.armor - armorReduction;
      final newHp = ctx.defender.hp - remainingDamage;
      logger.info('${ctx.attackerName} attacks ($damage).');
      ctx.setStats(
        ctx.defenderIndex,
        ctx.defender.copyWith(
          armor: newArmor,
          hp: newHp,
        ),
      );
      logger.info(
        '${ctx.defenderName} ${ctx.defender.hp} / ${ctx.defender.maxHp} hp '
        '${ctx.defender.armor} armor',
      );
      // onHit
      // onExposed
      // onWounded
      // This doesn't handle "stunned" yet.
      ctx.nextAttacker();
    }

    // Print spoils for the player if they won.
    final firstResolved = ctx.firstResolved;
    _logSpoils(before: first, after: firstResolved);
    return BattleResult(firstResolved, ctx.secondResolved);
  }
}
