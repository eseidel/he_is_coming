import 'dart:math';

import 'package:he_is_coming/src/creature.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/item.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:meta/meta.dart';

String _signed(int value) => value >= 0 ? '+$value' : '$value';

void _expectPositive(int value, String valueName) {
  if (value <= 0) {
    throw ArgumentError('$valueName ($value) must be positive');
  }
}

void _expectNonNegative(int value, String valueName) {
  if (value < 0) {
    throw ArgumentError('$valueName ($value) must be non-negative');
  }
}

void _expectNegative(int value, String valueName) {
  if (value >= 0) {
    throw ArgumentError('$valueName ($value) must be negative');
  }
}

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

  /// Returns true if this this creatures's first turn of the battle.
  bool get isFirstTurn => _battle.turnNumber == 1;

  /// Returns true if this is "every other turn" for this creature.
  // I tested with Emerald Earning and it was first turn, then every other turn.
  bool get isEveryOtherTurn => _battle.turnNumber.isOdd;

  /// Add gold.
  void gainGold(int gold) {
    _expectPositive(gold, 'gold');
    _stats = _stats.copyWith(gold: _stats.gold + gold);
    _battle.log('$_playerName gold ${_signed(gold)} from $_sourceName');
  }

  /// Add armor.
  void gainArmor(int armor) {
    _expectPositive(armor, 'armor');
    _battle._adjustArmor(index: _index, armor: armor, source: _sourceName);
  }

  /// Remove armor.
  void loseArmor(int armor) {
    _expectNegative(armor, 'armor');
    _battle._adjustArmor(index: _index, armor: armor, source: _sourceName);
  }

  /// Add speed.
  void gainSpeed(int speed) {
    _expectPositive(speed, 'speed');
    _stats = _stats.copyWith(speed: _stats.speed + speed);
    _battle.log('$_playerName speed ${_signed(speed)} from $_sourceName');
  }

  /// Add attack.
  void gainAttack(int attack) {
    _expectPositive(attack, 'speed');
    _battle._adjustAttack(attack: attack, index: _index, source: _sourceName);
  }

  /// Add thorns.
  void gainThorns(int thorns) {
    _expectPositive(thorns, 'thorns');
    _stats = _stats.copyWith(thorns: _stats.thorns + thorns);
    _battle.log('$_playerName thorns ${_signed(thorns)} from $_sourceName');
  }

  /// Adjust by a negative attack.
  void loseAttack(int attack) {
    _expectPositive(attack, 'attack');
    _battle._adjustAttack(attack: -attack, index: _index, source: _sourceName);
  }

  /// Stun the enemy for a number of turns.
  void stunEnemy(int turns) {
    _expectPositive(turns, 'turns');
    _battle._adjustStun(turns: turns, index: _enemyIndex, source: _sourceName);
  }

  /// Stun self for a number of turns.
  void stunSelf(int turns) {
    _expectPositive(turns, 'turns');
    _battle._adjustStun(turns: turns, index: _index, source: _sourceName);
  }

  /// Give armor to the enemy.
  void giveArmorToEnemy(int armor) {
    _expectPositive(armor, 'armor');
    _battle._adjustArmor(index: _enemyIndex, armor: armor, source: _sourceName);
  }

  /// Steal armor from the enemy.
  void stealArmor(int armor) {
    _expectPositive(armor, 'armor');
    final target = _battle.stats[_enemyIndex];
    final stolen = min(target.armor, armor);
    if (stolen == 0) {
      return;
    }
    _battle
      .._adjustArmor(
        index: _enemyIndex,
        armor: -stolen,
        source: _sourceName,
      )
      .._adjustArmor(
        index: _index,
        armor: stolen,
        source: _sourceName,
      );
  }

  /// Restore health.
  void restoreHealth(int hp) => _battle._restoreHealth(
        hp: hp,
        targetIndex: _index,
        source: _sourceName,
      );

  /// Lose health.  Careful this is not the same as taking damage!
  /// This bypasses armor and is for special effects.
  void loseHealth(int hp) {
    _expectPositive(hp, 'hp');
    // Don't clamp hp here, let it go below zero and then when copied
    // back into the stats it will be clamped to 0.
    final delta = -hp;
    final newHp = min(_stats.hp + delta, _stats.maxHp);
    _stats = _stats.copyWith(hp: newHp);
    _battle.log('$_playerName hp $delta from $_sourceName');
  }

  /// Reduce the enemy's max hp by a given amount.
  void reduceEnemyMaxHp(int hp) {
    _expectPositive(hp, 'hp');
    _battle._adjustMaxHp(delta: -hp, index: _enemyIndex, source: _sourceName);
  }

  /// Deal damage to the enemy.
  /// This is not for normal attacks "strikes" but for special effects.
  void dealDamage(int damage) => _battle.dealDamage(
        damage: damage,
        targetIndex: _enemyIndex,
        source: _sourceName,
      );

  /// Take damage (from an item), will trigger onTakeDamage, hits armor first.
  void takeDamage(int damage) => _battle.dealDamage(
        damage: damage,
        targetIndex: _index,
        source: _sourceName,
      );

  /// Returns the number of items of a given material.
  int materialCount(ItemMaterial material) {
    return _battle.creatures[_index].items
        .where((item) => item.material == material)
        .length;
  }

  /// Returns the number of items of a given kind.
  int kindCount(ItemKind kind) {
    return _battle.creatures[_index].items
        .where((item) => item.kind == kind)
        .length;
  }
}

String? _diffString(String name, int before, int after) {
  final diff = after - before;
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
    this.stunCount = 0,
    this.thorns = 0,
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

  /// Number of turns remaining the creature is stunned.
  final int stunCount;

  /// Damage returned to the attacker when attacking this creature.
  /// Thorns are cleared after each attack.
  final int thorns;

  /// Returns true if health is currently full.
  bool get isHealthFull => hp == maxHp;

  /// Returns true if health is below half.
  bool get belowHalfHp => hp < maxHp / 2;

  /// Returns the amount of health lost.
  int get lostHp => maxHp - hp;

  /// Create a copy of this with some fields updated.
  CreatureStats copyWith({
    int? maxHp,
    int? hp,
    int? armor,
    int? attack,
    int? speed,
    int? gold,
    bool? hasBeenExposed,
    bool? hasBeenWounded,
    int? stunCount,
    int? thorns,
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
      speed: speed ?? this.speed,
      // Attack needs to be clamped to 1?
      attack: attack ?? this.attack,
      gold: gold ?? this.gold,
      hasBeenExposed: hasBeenExposed ?? this.hasBeenExposed,
      hasBeenWounded: hasBeenWounded ?? this.hasBeenWounded,
      stunCount: stunCount ?? this.stunCount,
      thorns: thorns ?? this.thorns,
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
      _diffString('stun', stunCount, other.stunCount),
      _diffString('thorns', thorns, other.thorns),
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

class _DeathException implements Exception {
  _DeathException(this.creature);

  final Creature creature;

  @override
  String toString() => 'DeathException: $creature';
}

/// Context for an in-progress battle.
class BattleContext {
  /// Create a BattleContext.
  BattleContext(this.creatures, {this.verbose = false})
      : stats = creatures.map(CreatureStats.fromCreature).toList() {
    log('${_first.name}: ${_first.baseStats}');
    log('${_second.name}: ${_second.baseStats}');
  }

  /// Coordinated logging for the battle.
  void log(String message) {
    if (verbose) {
      logger.info(message);
    }
  }

  static int _firstAttackerIndex(List<CreatureStats> stats) =>
      stats[0].speed >= stats[1].speed ? 0 : 1;

  /// Advance to the next non-stunned creature.
  void _nextAttacker() {
    while (allAlive) {
      _attackerIndex = attackerIndex.isEven ? 1 : 0;
      _turnsTaken++;

      if (attacker.stunCount < 1) {
        break;
      }
      setStats(
        attackerIndex,
        attacker.copyWith(stunCount: attacker.stunCount - 1),
      );
      log('$attackerName is stunned, skipping turn');
    }
  }

  /// Decide who goes first.
  void _decideFirstAttacker() {
    _attackerIndex = _firstAttackerIndex(stats);
  }

  void _adjustAttack({
    required int attack,
    required int index,
    required String source,
  }) {
    final target = stats[index];
    // Unclear if attack is clamped?  Probably strike values are just clamped?
    setStats(index, target.copyWith(attack: max(target.attack + attack, 0)));
    log('${creatures[index].name} attack ${_signed(attack)} from $source');
  }

  void _adjustMaxHp({
    required int delta,
    required int index,
    required String source,
  }) {
    final target = stats[index];
    final newMaxHp = target.maxHp + delta;
    if (delta < 0 && target.hp > newMaxHp) {
      // If we're reducing maxHp, we need to reduce hp as well.
      setStats(index, target.copyWith(maxHp: newMaxHp, hp: newMaxHp));
    } else {
      // Increasing maxHp doesn't change current hp.
      setStats(index, target.copyWith(maxHp: newMaxHp));
    }
    log('${creatures[index].name} maxHp ${_signed(delta)} from $source');
  }

  void _adjustStun({
    required int turns,
    required int index,
    required String source,
  }) {
    final target = stats[index];
    setStats(index, target.copyWith(stunCount: target.stunCount + turns));
    log('${creatures[index].name} stun ${_signed(turns)} turns by $source');
  }

  /// Add or remove armor.
  void _adjustArmor({
    required int armor,
    required int index,
    required String source,
  }) {
    final target = stats[index];
    setStats(index, target.copyWith(armor: target.armor + armor));
    log('${creatures[index].name} armor ${_signed(armor)} from $source');
  }

  /// Restore health to a creature.
  void _restoreHealth({
    required int hp,
    required int targetIndex,
    required String source,
  }) {
    _expectPositive(hp, 'hp');
    final target = stats[targetIndex];
    final newHp = min(target.hp + hp, target.maxHp);
    final newStats = target.copyWith(hp: newHp);
    setStats(targetIndex, newStats);
    final restored = newHp - target.hp;
    log('$source restored $restored hp to ${creatures[targetIndex].name}');

    // If we successfully restored health, trigger onHeal.
    if (restored > 0) {
      _trigger(targetIndex, Trigger.onHeal);
    }
  }

  /// Deal damage to the defender.
  void dealDamage({
    required int damage,
    required int targetIndex,
    required String source,
  }) {
    _expectNonNegative(damage, 'damage');
    final target = stats[targetIndex];
    final targetName = creatures[targetIndex].name;
    final armorReduction = min(target.armor, damage);
    final remainingDamage = damage - armorReduction;
    final newArmor = target.armor - armorReduction;
    final newHp = target.hp - remainingDamage;
    final armorBefore = target.armor;
    // newStats is not valid after setStats (which can happen inside a trigger)
    {
      final newStats = target.copyWith(armor: newArmor, hp: max(newHp, 0));
      setStats(targetIndex, newStats);
      log(
        '$source dealt $damage damage to $targetName '
        '${newStats.hp} / ${newStats.maxHp} hp '
        '${newStats.armor} armor',
      );
    }

    // Does it count as damage if it's absorbed by armor?
    _trigger(targetIndex, Trigger.onTakeDamage);

    // newStats is not valid after setStats (which can happen inside a trigger)
    {
      final newStats = stats[targetIndex];
      // If previously target had armor but now it doesn't
      final armorWasBroken = armorBefore > 0 && newArmor == 0;
      if (armorWasBroken && !newStats.hasBeenExposed) {
        // Set "exposed" flag first to avoid infinite loops.
        setStats(targetIndex, newStats.copyWith(hasBeenExposed: true));
        _trigger(targetIndex, Trigger.onExposed);
      }
    }

    // Wounded occurs when you cross the 50% hp threshold.
    // https://discord.com/channels/1041414829606449283/1209488302269534209/1274771566231552151
    // Currently enforcing *below* 50% hp, not *at* 50% hp.
    final newStats = stats[targetIndex];
    if (!target.belowHalfHp &&
        newStats.belowHalfHp &&
        !newStats.hasBeenWounded) {
      // Set "wounded" flag first to avoid infinite loops.
      setStats(targetIndex, newStats.copyWith(hasBeenWounded: true));
      _trigger(targetIndex, Trigger.onWounded);
    }
  }

  /// Strike the defender, defaults to the attacker's attack value.
  void _strike([int? damage]) {
    if (damage != null && damage <= 0) {
      throw ArgumentError('explicit strike damage should be positive');
    }
    dealDamage(
      damage: damage ?? attacker.attack,
      targetIndex: defenderIndex,
      source: '$attackerName strike',
    );
    // OnHit only triggers on strikes.
    _trigger(attackerIndex, Trigger.onHit);

    // Thorns only trigger on strikes.
    if (defender.thorns > 0) {
      dealDamage(
        damage: defender.thorns,
        targetIndex: attackerIndex,
        source: '$defenderName thorns',
      );
      setStats(defenderIndex, defender.copyWith(thorns: 0));
    }
  }

  /// Probably this only needs to happen within the takeDamage effect?
  void _checkForDeath() {
    if (stats[0].hp <= 0) {
      throw _DeathException(creatures[0]);
    }
    if (stats[1].hp <= 0) {
      throw _DeathException(creatures[1]);
    }
  }

  void _trigger(int index, Trigger trigger) {
    final creature = creatures[index];
    final beforeStats = stats[index];
    if (creature.effect != null) {
      final effectCxt = EffectContext(this, index, creature.name);
      creature.effect?[trigger]?.call(effectCxt);
      _checkForDeath();
    }

    // Slightly odd to have the edge trigger before the weapon.
    if (creature.edge != null) {
      final effectCxt = EffectContext(this, index, creature.edge!.name);
      creature.edge!.effect?[trigger]?.call(effectCxt);
      _checkForDeath();
    }

    for (final item in creature.items) {
      final effectCxt = EffectContext(this, index, item.name);
      item.effect?[trigger]?.call(effectCxt);
      _checkForDeath();
    }
    final afterStats = stats[index];
    final diffString = beforeStats.diffString(afterStats);
    // TODO(eseidel):  This can show diffs twice for nested effects.
    // e.g. if onHit triggers a heal and then onHeal does +1 armor, we'll
    // show +1 armor from the onHeal in both the onHit and onHeal logs.
    if (diffString != null) {
      log('${creature.name} ${trigger.name}: $diffString');
    }
  }

  void _triggerOnBattleStart() {
    for (var index = 0; index < creatures.length; index++) {
      // OnBattleStart happens before we decide who the attacker is.
      // Pretend whoever is being triggered is the attacker to allow
      // effects that depend on attacker/defender to work.
      _attackerIndex = index;
      _trigger(index, Trigger.onBattle);
    }
  }

  void _triggerOnTurn() => _trigger(attackerIndex, Trigger.onTurn);

  /// List of creatures in this battle.
  final List<Creature> creatures;

  /// Current stats for the battling creatures.
  final List<CreatureStats> stats;

  late int _attackerIndex;

  /// If true, log more detailed information.
  final bool verbose;

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
      log('${after.name} result: ${diffStrings.join(' ')}');
    }
  }

  /// Resolve the battle and return the spoils.
  BattleResult _resolveWithSpoils() {
    // Settle up the spoils.
    final firstWon = stats[0].hp > 0;
    final combinedGold = stats[0].gold + stats[1].gold;
    final firstGold = firstWon ? combinedGold : 0;
    final secondGold = firstWon ? 0 : combinedGold;
    // hp can go below 0 during battle, but copy it out as 0 in the end.
    final first = _first.copyWith(hp: max(stats[0].hp, 0), gold: firstGold);
    final second = _second.copyWith(hp: max(stats[1].hp, 0), gold: secondGold);

    // Print spoils for the player if they won.
    _logSpoils(before: creatures[0], after: first);
    return BattleResult(
      first: first,
      second: second,
      // _turnsTaken is 0-indexed, as is turns
      turns: _turnsTaken ~/ 2,
    );
  }

  /// Run the battle and return the result.
  BattleResult run() {
    try {
      _triggerOnBattleStart();
      _decideFirstAttacker();
      log('${creatures[0].name}: ${stats[0]}');
      log('${creatures[1].name}: ${stats[1]}');
      while (allAlive) {
        log('$attackerName turn $turnNumber');
        _triggerOnTurn();
        _strike();
        // Might advance multiple turns if both creatures are stunned.
        _nextAttacker();
      }
    } on _DeathException catch (e) {
      log('${e.creature.name} has died');
    }
    return _resolveWithSpoils();
  }
}

/// Represents the results of a battle.
class BattleResult {
  /// Create a BattleResult
  BattleResult({
    required this.first,
    required this.second,
    required this.turns,
  });

  /// First creature in this battle.
  final Creature first;

  /// Second creature in this battle.
  final Creature second;

  /// Number of turns taken in this battle.
  int turns;

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
    bool verbose = false,
  }) {
    final ctx = BattleContext([first, second], verbose: verbose);
    return ctx.run();
  }
}
