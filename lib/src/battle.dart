import 'dart:math';

import 'package:he_is_coming_sim/src/creature.dart';
import 'package:he_is_coming_sim/src/item.dart';
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

  int get _enemyIndex => _index.isEven ? 1 : 0;

  /// Stats for the enemy creature.
  CreatureStats get enemy => _battle.stats[_enemyIndex];

  CreatureStats get _stats => _battle.stats[_index];
  set _stats(CreatureStats stats) => _battle.setStats(_index, stats);
  String get _playerName => _battle.creatures[_index].name;

  /// Returns true if health is currently full.
  bool get isHealthFull => _stats.isHealthFull;

  /// Returns true if this this creatures's first turn of the battle.
  bool get isFirstTurn => _battle.turnNumber == 1;

  /// Returns true if this is "every other turn" for this creature.
  bool get isEveryOtherTurn => _battle.turnNumber.isOdd;

  void _expectPositive(int value) {
    if (value <= 0) {
      throw ArgumentError('value must be positive');
    }
  }

  void _expectNegative(int value) {
    if (value >= 0) {
      throw ArgumentError('value must be negative');
    }
  }

  /// Add gold.
  void gainGold(int gold) {
    _expectPositive(gold);
    _stats = _stats.copyWith(gold: _stats.gold + gold);
    logger.info('$_playerName gold ${_signed(gold)} from $_sourceName');
  }

  /// Add or remove armor.
  void _adjustArmor(int armor) {
    _stats = _stats.copyWith(armor: _stats.armor + armor);
    logger.info('$_playerName armor ${_signed(armor)} from $_sourceName');
  }

  /// Add armor.
  void gainArmor(int armor) {
    _expectPositive(armor);
    _adjustArmor(armor);
  }

  /// Remove armor.
  void loseArmor(int armor) {
    _expectNegative(armor);
    _adjustArmor(armor);
  }

  /// Add attack.
  void gainAttack(int attack) {
    _expectPositive(attack);
    _adjustAttack(attack);
  }

  /// Adjust by a negative attack.
  void loseAttack(int attack) {
    _expectNegative(attack);
    _adjustAttack(attack);
  }

  void _adjustAttack(int attackDelta) {
    // Unclear if attack is clamped at 1 or 0.
    _stats = _stats.copyWith(attack: max(_stats.attack + attackDelta, 0));
    logger
        .info('$_playerName attack ${_signed(attackDelta)} from $_sourceName');
  }

  void _adjustHp(int hp) {
    // clamp hp to [0, maxHp]
    _stats = _stats.copyWith(hp: min(max(_stats.hp + hp, 0), _stats.maxHp));
    logger.info('$_playerName hp ${_signed(hp)} from $_sourceName');
  }

  /// Restore health.
  void restoreHealth(int hp) {
    _expectPositive(hp);
    _adjustHp(hp);
  }

  /// Lose health.  Careful this is not the same as taking damage!
  /// This bypasses armor and is for special effects.
  void loseHealth(int hp) {
    _expectNegative(hp);
    _adjustHp(hp);
  }

  /// Deal damage to the enemy.
  /// This is not for normal attacks "strikes" but for special effects.
  void dealDamage(int damage) => _battle.dealDamage(
        damage: damage,
        targetIndex: _enemyIndex,
        source: _sourceName,
      );

  /// Take damage (from an item).
  void takeDamage(int damage) => _battle.dealDamage(
        damage: damage,
        targetIndex: _index,
        source: _sourceName,
      );

  /// Returns the number of items of a given material.
  int itemCount(Material material) {
    return _battle.creatures[_index].items
        .where((item) => item.material == material)
        .length;
  }
}

String? _diffString(String name, int before, int after) {
  final diff = after - before;
  // logger.info('$name: $before -> $after ($diff)');
  return diff != 0 ? '$name: ${_signed(diff)}' : null;
}

/// Holds stats for a creature during battle.
// This is probably really "CreatureBattleState" or something.
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
    this.hasBeenExposed = false,
    this.hasBeenWounded = false,
  });

  /// Create a CreatureStats from a Creature.
  factory CreatureStats.fromCreature(Creature creature) {
    final stats = creature.baseStats;
    return CreatureStats(
      maxHp: stats.maxHp,
      hp: creature.hp,
      armor: stats.armor,
      speed: stats.speed,
      attack: stats.attack,
      gold: creature.gold,
    );
  }

  /// Max health.  Does not change during battle.
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

  /// true if the creature has already sent onExposed this battle.
  final bool hasBeenExposed;

  /// true if the creature has already sent onWounded this battle.
  final bool hasBeenWounded;

  /// Returns true if health is currently full.
  bool get isHealthFull => hp == maxHp;

  /// Returns true if health is below half.
  bool get belowHalfHp => hp < maxHp / 2;

  /// Create a copy of this with some fields updated.
  CreatureStats copyWith({
    int? hp,
    int? armor,
    int? attack,
    int? gold,
    bool? hasBeenExposed,
    bool? hasBeenWounded,
  }) {
    // It's not possible to change maxHp during battle.
    // If it was, we'd need to be careful with Creature.hp.
    final newHp = hp ?? this.hp;
    if (newHp > maxHp) {
      throw ArgumentError('hp cannot be greater than maxHp');
    }
    return CreatureStats(
      maxHp: maxHp,
      hp: newHp,
      armor: armor ?? this.armor,
      speed: speed,
      // Attack needs to be clamped to 1?
      attack: attack ?? this.attack,
      gold: gold ?? this.gold,
      hasBeenExposed: hasBeenExposed ?? this.hasBeenExposed,
      hasBeenWounded: hasBeenWounded ?? this.hasBeenWounded,
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
    _turnsTaken++;
  }

  /// Deal damage to the defender.
  void dealDamage({
    required int damage,
    required int targetIndex,
    required String source,
  }) {
    if (damage < 0) {
      throw ArgumentError('damage must be positive');
    }

    final target = stats[targetIndex];
    final targetName = creatures[targetIndex].name;
    final armorReduction = min(target.armor, damage);
    final remainingDamage = damage - armorReduction;
    final newArmor = target.armor - armorReduction;
    final newHp = target.hp - remainingDamage;
    final armorBefore = target.armor;
    final newStats = target.copyWith(armor: newArmor, hp: max(newHp, 0));
    setStats(targetIndex, newStats);
    logger.info(
      '$source dealt $damage damage to $targetName '
      '${newStats.hp} / ${newStats.maxHp} hp '
      '${newStats.armor} armor',
    );

    // If previously target had armor but now it doesn't
    final armorWasBroken = armorBefore > 0 && newArmor == 0;
    if (armorWasBroken && !newStats.hasBeenExposed) {
      // Set "exposed" flag first to avoid infinite loops.
      setStats(targetIndex, newStats.copyWith(hasBeenExposed: true));
      _trigger(targetIndex, Effect.onExposed);
    }

    // Wounded occurs when you cross the 50% hp threshold.
    // https://discord.com/channels/1041414829606449283/1209488302269534209/1274771566231552151
    // Currently enforcing *below* 50% hp, not *at* 50% hp.
    if (!target.belowHalfHp &&
        newStats.belowHalfHp &&
        !newStats.hasBeenWounded) {
      // Set "wounded" flag first to avoid infinite loops.
      setStats(targetIndex, newStats.copyWith(hasBeenWounded: true));
      _trigger(targetIndex, Effect.onWounded);
    }
  }

  /// Strike the defender, defaults to the attacker's attack value.
  void strike([int? damage]) {
    if (damage != null && damage <= 0) {
      throw ArgumentError('explicit strike damage should be positive');
    }
    dealDamage(
      damage: damage ?? attacker.attack,
      targetIndex: defenderIndex,
      source: '$attackerName strike',
    );
    // OnHit only triggers on strikes.
    _trigger(attackerIndex, Effect.onHit);
  }

  void _trigger(int index, Effect effect) {
    final creature = creatures[index];
    final beforeStats = stats[index];
    for (final item in creature.items) {
      final effectCxt = EffectContext(this, index, item.name);
      item.effects?[effect]?.call(effectCxt);
    }
    final afterStats = stats[index];
    final diffString = beforeStats.diffString(afterStats);
    if (diffString != null) {
      logger.info('${creature.name} ${effect.name}: $diffString');
    }
  }

  void _triggerOnBattleStart() {
    for (var index = 0; index < creatures.length; index++) {
      _trigger(index, Effect.onBattle);
    }
  }

  void _triggerOnTurn() => _trigger(attackerIndex, Effect.onTurn);

  /// List of creatures in this battle.
  final List<Creature> creatures;

  /// Current stats for the battling creatures.
  final List<CreatureStats> stats;

  int _attackerIndex;

  // Counts all the turns taken by any player.
  int _turnsTaken = 0;

  /// Turn Number is 1-indexed, saying what number turn you're on.
  /// Lets effects that apply on the first turn, check turnNumber == 1.
  int get turnNumber => (_turnsTaken ~/ 2) + 1;

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

  /// Returns true if all participants are still alive.
  bool get allAlive => stats[0].hp > 0 && stats[1].hp > 0;

  /// Returns the Creature at `index` mod 2.
  Creature operator [](int index) => index.isEven ? _first : _second;

  void _logSpoils({required Creature before, required Creature after}) {
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

  /// Resolve the battle and return the spoils.
  BattleResult resolveWithSpoils() {
    // Settle up the spoils.
    final firstWon = stats[0].hp > 0;
    final combinedGold = stats[0].gold + stats[1].gold;
    final firstGold = firstWon ? combinedGold : 0;
    final secondGold = firstWon ? 0 : combinedGold;
    final first = _first.copyWith(hp: stats[0].hp, gold: firstGold);
    final second = _second.copyWith(hp: stats[1].hp, gold: secondGold);

    // Print spoils for the player if they won.
    _logSpoils(before: creatures[0], after: first);
    return BattleResult(first, second);
  }
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
  static BattleResult resolve({
    required Creature first,
    required Creature second,
  }) {
    logger
      ..info('${first.name}: ${first.baseStats}')
      ..info('${second.name}: ${first.baseStats}');

    final ctx = BattleContext([first, second]).._triggerOnBattleStart();

    logger
      ..info('${first.name}: ${ctx.stats[0]}')
      ..info('${second.name}: ${ctx.stats[1]}');
    while (ctx.allAlive) {
      // onTurn
      ctx
        .._triggerOnTurn()
        ..strike()
        // onHit
        ..nextAttacker();
    }

    return ctx.resolveWithSpoils();
  }
}
