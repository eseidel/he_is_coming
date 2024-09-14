import 'dart:math';

import 'package:he_is_coming/src/catalog.dart';
import 'package:he_is_coming/src/creature.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/item.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:meta/meta.dart';

String _signed(int value) => value >= 0 ? '+$value' : '$value';

void _expectPositive(int value, String valueName) {
  if (value <= 0) {
    throw Exception('$valueName ($value) must be positive');
  }
}

void _expectNonNegative(int value, String valueName) {
  if (value < 0) {
    throw Exception('$valueName ($value) must be non-negative');
  }
}

/// Passed to all Effect callbacks.
class EffectContext {
  /// Create an EffectContext
  EffectContext({
    required BattleContext battle,
    required int meIndex,
    required int? attackerIndex,
    required String sourceName,
  })  : _battle = battle,
        _meIndex = meIndex,
        _attackerIndex = attackerIndex,
        _sourceName = sourceName;

  final BattleContext _battle;
  final int _meIndex;
  final int? _attackerIndex;
  final String _sourceName;

  /// Stats for the creature causing the effect.
  CreatureStats get my => _battle.stats[_meIndex];

  /// Stats for the enemy creature.
  CreatureStats get enemy => _battle.stats[_enemyIndex];

  /// Stats for the current attacker.
  CreatureStats get attacker {
    final attackerIndex = _attackerIndex;
    if (attackerIndex == null) {
      throw StateError('No current attacker.');
    }
    return _battle.stats[attackerIndex];
  }

  /// Stats for the current defender.
  CreatureStats get defender {
    final attackerIndex = _attackerIndex;
    if (attackerIndex == null) {
      throw StateError('No current defender.');
    }
    return _battle.stats[attackerIndex.isEven ? 1 : 0];
  }

  int get _enemyIndex => _meIndex.isEven ? 1 : 0;

  CreatureStats get _myStats => _battle.stats[_meIndex];
  set _myStats(CreatureStats stats) => _battle.setStats(_meIndex, stats);
  String get _playerName => _battle.creatures[_meIndex].name;

  /// Returns true if this this creatures's first turn of the battle.
  bool get isFirstTurn => _battle.turnNumber == 1;

  /// Returns true if this is "every other turn" for this creature.
  // I tested with Emerald Earning and it was first turn, then every other turn.
  bool get isEveryOtherTurn => _battle.turnNumber.isOdd;

  /// Returns the number of strikes I have made this battle.
  int get strikeCount => _battle.stats[_meIndex].strikesMade;

  /// Returns true if this is the nth strike for this creature.
  bool everyNStrikes(int n) => strikeCount % n == n - 1;

  /// true if creature's health was full at the start of the battle.
  bool get myHealthWasFullAtBattleStart {
    return _battle.initialCreatures[_meIndex].healthFull;
  }

  /// true if creature had more speed than enemy at the start of the battle.
  bool get hadMoreSpeedAtStart {
    final initialStats = _battle.initialCreatures[_meIndex].baseStats;
    return initialStats.speed > _battle.stats[_enemyIndex].speed;
  }

  /// Add an extra exposed trigger.
  void addExtraExposed(int count) {
    final exposedLimit = _myStats.exposedLimit + count;
    _myStats = _myStats.copyWith(exposedLimit: exposedLimit);
    _battle
        .log('$_playerName can now trigger exposed $exposedLimit extra times');
  }

  /// Add extra strikes for the attacker on next attack.
  void queueExtraStrike({int? damage}) {
    final extraStrike = ExtraStrike(source: _sourceName, damage: damage);
    _myStats =
        _myStats.copyWith(extraStrikes: _myStats.extraStrikes + [extraStrike]);
    _battle.log(
      '$_playerName queued extra strike (damage: $damage) from $_sourceName',
    );
  }

  /// Add gold.
  void gainGold(int gold) {
    _expectPositive(gold, 'gold');
    _myStats = _myStats.copyWith(gold: _myStats.gold + gold);
    _battle.log('$_playerName gold ${_signed(gold)} from $_sourceName');
  }

  /// Add armor.
  void gainArmor(int armor) {
    _expectPositive(armor, 'armor');
    _battle._adjustArmor(index: _meIndex, armor: armor, source: _sourceName);
  }

  /// Remove armor.
  void loseArmor(int armor) {
    _expectPositive(armor, 'armor');
    _battle._adjustArmor(index: _meIndex, armor: -armor, source: _sourceName);
  }

  /// Add speed.
  void gainSpeed(int speed) {
    _expectPositive(speed, 'speed');
    _battle._adjustSpeed(speed: speed, index: _meIndex, source: _sourceName);
  }

  /// Remove speed.
  void loseSpeed(int speed) {
    _expectPositive(speed, 'speed');
    _battle._adjustSpeed(speed: -speed, index: _meIndex, source: _sourceName);
  }

  /// Add attack.
  void gainAttack(int attack) {
    _expectPositive(attack, 'speed');
    _battle._adjustAttack(attack: attack, index: _meIndex, source: _sourceName);
  }

  /// Add thorns.
  void gainThorns(int thorns) {
    _expectPositive(thorns, 'thorns');
    _myStats = _myStats.copyWith(thorns: _myStats.thorns + thorns);
    _battle.log('$_playerName thorns ${_signed(thorns)} from $_sourceName');
  }

  /// Adjust by a negative attack.
  void loseAttack(int attack) {
    _expectPositive(attack, 'attack');
    _battle._adjustAttack(
      attack: -attack,
      index: _meIndex,
      source: _sourceName,
    );
  }

  /// Stun the enemy for a number of turns.
  void stunEnemy(int turns) {
    _expectPositive(turns, 'turns');
    _battle._adjustStun(turns: turns, index: _enemyIndex, source: _sourceName);
  }

  /// Stun self for a number of turns.
  void stunSelf(int turns) {
    _expectPositive(turns, 'turns');
    _battle._adjustStun(turns: turns, index: _meIndex, source: _sourceName);
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
        index: _meIndex,
        armor: stolen,
        source: _sourceName,
      );
  }

  /// Restore health.
  void restoreHealth(int hp) => _battle._restoreHealth(
        hp: hp,
        targetIndex: _meIndex,
        source: _sourceName,
      );

  /// Restore health to full.
  void healToFull() {
    if (!_myStats.isHealthFull) {
      restoreHealth(_myStats.lostHp);
    }
  }

  /// Lose health.  Careful this is not the same as taking damage!
  /// This bypasses armor and is for special effects.
  void loseHealth(int hp) {
    _expectPositive(hp, 'hp');
    // Don't clamp hp here, let it go below zero and then when copied
    // back into the stats it will be clamped to 0.
    final delta = -hp;
    final newHp = min(_myStats.hp + delta, _myStats.maxHp);
    _myStats = _myStats.copyWith(hp: newHp);
    _battle.log('$_playerName hp $delta from $_sourceName');
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
        targetIndex: _meIndex,
        source: _sourceName,
      );

  /// Returns the number of items of a given material.
  int materialCount(ItemMaterial material) {
    final inventory = _battle.creatures[_meIndex].inventory;
    return inventory == null ? 0 : inventory.materialCount(material);
  }

  /// Returns the number of items of a given kind.
  int kindCount(ItemKind kind) {
    final inventory = _battle.creatures[_meIndex].inventory;
    return inventory == null ? 0 : inventory.kindCount(kind);
  }

  /// Returns the number of items with a given gem.
  int gemCount(Gem gem) {
    final inventory = _battle.creatures[_meIndex].inventory;
    return inventory == null ? 0 : inventory.gemCount(gem);
  }
}

String? _diffString(String name, int before, int after) {
  final diff = after - before;
  return diff != 0 ? '$name: ${_signed(diff)}' : null;
}

/// Extra strike for a creature.
class ExtraStrike {
  /// Create an ExtraStrike.
  ExtraStrike({required this.source, this.damage});

  /// Source of the extra strike.
  final String source;

  /// Damage of the extra strike, defaults to the attacker's attack
  /// if not provided.
  final int? damage;
}

/// Holds stats for a creature during battle.
// This is probably really "CreatureBattleState" or something.
@immutable
class CreatureStats {
  /// Create a CreatureStats.
  const CreatureStats({
    required this.baseStats,
    required this.hp,
    required this.armor,
    required this.speed,
    required this.attack,
    required this.gold,
    this.exposedCount = 0,
    this.exposedLimit = 1,
    this.hasBeenWounded = false,
    this.stunCount = 0,
    this.thorns = 0,
    this.strikesMade = 0,
    this.extraStrikes = const [],
  });

  /// Create a CreatureStats from a Creature.
  factory CreatureStats.fromCreature(Creature creature) {
    final stats = creature.baseStats;
    return CreatureStats(
      baseStats: stats,
      hp: creature.hp,
      armor: stats.armor,
      speed: stats.speed,
      attack: stats.attack,
      gold: creature.gold,
    );
  }

  /// Base stats for the creature.  Does not change during battle.
  final Stats baseStats;

  /// Maximum health.
  int get maxHp => baseStats.maxHp;

  /// Base armor.
  int get baseArmor => baseStats.armor;

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

  /// How many times exposed has triggered.
  final int exposedCount;

  /// How many times exposed can trigger.
  final int exposedLimit;

  /// true if the creature can still be exposed this battle.
  bool get canBeExposed => exposedCount < exposedLimit;

  /// true if the creature has already sent onWounded this battle.
  final bool hasBeenWounded;

  /// Number of turns remaining the creature is stunned.
  final int stunCount;

  /// Number of strikes this creature has made this battle.
  final int strikesMade;

  /// Extra strikes this creature gets on next attack.
  /// Resets after attacking.
  final List<ExtraStrike> extraStrikes;

  /// Damage returned to the attacker when attacking this creature.
  /// Thorns are cleared after each attack.
  final int thorns;

  /// Returns true if health is currently full.
  bool get isHealthFull => hp == maxHp;

  /// Returns true if health is below half.  Used for wounded.
  bool get atOrBelowHalfHealth => hp <= maxHp / 2;

  /// Returns true if health is below half.
  bool get belowHalfHealth => hp < maxHp / 2;

  /// Returns the amount of health lost.
  int get lostHp => maxHp - hp;

  /// Create a copy of this with some fields updated.
  CreatureStats copyWith({
    Stats? baseStats,
    int? hp,
    int? armor,
    int? attack,
    int? speed,
    int? gold,
    int? exposedCount,
    int? exposedLimit,
    bool? hasBeenWounded,
    int? stunCount,
    int? thorns,
    List<ExtraStrike>? extraStrikes,
    int? strikesMade,
  }) {
    final newMaxHp = baseStats != null ? baseStats.maxHp : maxHp;
    final newHp = hp ?? this.hp;
    if (newHp > newMaxHp) {
      throw ArgumentError('hp cannot be greater than maxHp');
    }
    return CreatureStats(
      baseStats: baseStats ?? this.baseStats,
      hp: newHp,
      armor: armor ?? this.armor,
      speed: speed ?? this.speed,
      // Attack needs to be clamped to 1?
      attack: attack ?? this.attack,
      gold: gold ?? this.gold,
      exposedCount: exposedCount ?? this.exposedCount,
      exposedLimit: exposedLimit ?? this.exposedLimit,
      hasBeenWounded: hasBeenWounded ?? this.hasBeenWounded,
      stunCount: stunCount ?? this.stunCount,
      thorns: thorns ?? this.thorns,
      extraStrikes: extraStrikes ?? this.extraStrikes,
      strikesMade: strikesMade ?? this.strikesMade,
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
      _diffString('strikeCount', strikesMade, other.strikesMade),
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
      : stats = creatures.map(CreatureStats.fromCreature).toList(),
        initialCreatures = List.unmodifiable(creatures) {
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

  void _adjustSpeed({
    required int speed,
    required int index,
    required String source,
  }) {
    final target = stats[index];
    setStats(index, target.copyWith(speed: target.speed + speed));
    log('${creatures[index].name} speed ${_signed(speed)} from $source');
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
      _trigger(
        Trigger.onHeal,
        meIndex: targetIndex,
        attackerIndex: _attackerIndex,
      );
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
    _trigger(
      Trigger.onTakeDamage,
      meIndex: targetIndex,
      attackerIndex: _attackerIndex,
    );

    // newStats is not valid after setStats (which can happen inside a trigger)
    {
      final newStats = stats[targetIndex];
      // If previously target had armor but now it doesn't
      final armorWasBroken = armorBefore > 0 && newArmor == 0;
      if (armorWasBroken && newStats.canBeExposed) {
        // Set "exposed" flag first to avoid infinite loops.
        setStats(
          targetIndex,
          newStats.copyWith(exposedCount: newStats.exposedCount + 1),
        );
        _trigger(
          Trigger.onExposed,
          meIndex: targetIndex,
          attackerIndex: _attackerIndex,
        );
      }
    }

    // Wounded occurs when you cross the 50% hp threshold.
    // https://discord.com/channels/1041414829606449283/1209488302269534209/1274771566231552151
    // As of 0.3.5 wounded triggers at 50% hp.
    final newStats = stats[targetIndex];
    if (!target.atOrBelowHalfHealth &&
        newStats.atOrBelowHalfHealth &&
        !newStats.hasBeenWounded) {
      // Set "wounded" flag first to avoid infinite loops.
      setStats(targetIndex, newStats.copyWith(hasBeenWounded: true));
      _trigger(
        Trigger.onWounded,
        meIndex: targetIndex,
        attackerIndex: _attackerIndex,
      );
    }
  }

  /// Strike the defender, defaults to the attacker's attack value.
  void _strike([int? damage]) {
    if (damage != null && damage <= 0) {
      throw ArgumentError('explicit strike damage should be positive');
    }
    // Collect and clear thorns before takeDamage and onHit triggers.
    final thorns = defender.thorns;
    if (thorns > 0) {
      setStats(defenderIndex, defender.copyWith(thorns: 0));
    }
    // Some items provide negative attack, so clamp to 0.
    final clampedAttack = max(attacker.attack, 0);
    dealDamage(
      damage: damage ?? clampedAttack,
      targetIndex: defenderIndex,
      source: '$attackerName strike',
    );
    // OnHit only triggers on strikes.
    _trigger(
      Trigger.onHit,
      meIndex: attackerIndex,
      attackerIndex: defenderIndex,
    );

    // Thorns only trigger on strikes.
    if (thorns > 0) {
      dealDamage(
        damage: thorns,
        targetIndex: attackerIndex,
        source: '$defenderName thorns',
      );
    }

    setStats(
      attackerIndex,
      attacker.copyWith(strikesMade: attacker.strikesMade + 1),
    );
  }

  void _handleExtraStrikes() {
    final extraStrikes = attacker.extraStrikes;
    // Clear the extra strikes before handling them.  Any new extra strikes
    // added during handling will be handled on the next turn.
    setStats(attackerIndex, attacker.copyWith(extraStrikes: []));
    for (final extraStrike in extraStrikes) {
      _strike(extraStrike.damage);
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

  void _trigger(Trigger trigger, {required int meIndex, int? attackerIndex}) {
    void callTrigger(CatalogItem item) {
      final effectCxt = EffectContext(
        battle: this,
        meIndex: meIndex,
        attackerIndex: attackerIndex,
        sourceName: item.name,
      );
      item.effect?[trigger]?.call(effectCxt);
      _checkForDeath();
    }

    final creature = creatures[meIndex];
    final beforeStats = stats[meIndex];
    if (creature.effect != null) {
      callTrigger(creature);
    }

    final inventory = creature.inventory;
    if (inventory != null) {
      // Slightly odd to have the edge trigger before the weapon.
      final edge = inventory.edge;
      if (edge != null) {
        callTrigger(edge);
      }

      inventory.items.forEach(callTrigger);
      inventory.sets.forEach(callTrigger);
    }

    final afterStats = stats[meIndex];
    final diffString = beforeStats.diffString(afterStats);
    // TODO(eseidel):  This can show diffs twice for nested effects.
    // e.g. if onHit triggers a heal and then onHeal does +1 armor, we'll
    // show +1 armor from the onHeal in both the onHit and onHeal logs.
    if (diffString != null) {
      log('${creature.name} ${trigger.name}: $diffString');
    }
  }

  void _triggerOnBattleStart() {
    // OnBattleStart happens before we decide who the attacker is.
    // So intentionally do not pass an attackerIndex here.
    for (var index = 0; index < creatures.length; index++) {
      _trigger(Trigger.onBattle, meIndex: index);
    }
  }

  void _triggerInitiative() {
    // Initiative triggers after battle start so we know who the attacker is
    // but we're still not passing an attackerIndex here.
    for (var index = 0; index < creatures.length; index++) {
      _trigger(Trigger.onInitiative, meIndex: index);
    }
  }

  void _triggerOnTurn() => _trigger(
        Trigger.onTurn,
        meIndex: attackerIndex,
        attackerIndex: attackerIndex,
      );

  /// Initial list of creatures in this battle.
  final List<Creature> initialCreatures;

  /// List of creatures in this battle, includes changes during battle.
  final List<Creature> creatures;

  /// Current stats for the battling creatures.
  final List<CreatureStats> stats;

  int? _attackerIndex;

  /// If true, log more detailed information.
  final bool verbose;

  // Counts all the turns taken by any player.
  int _turnsTaken = 0;

  /// Turn Number is 1-indexed, saying what number turn you're on.
  /// Lets effects that apply on the first turn, check turnNumber == 1.
  int get turnNumber => (_turnsTaken ~/ 2) + 1;

  /// Index of the current attacker.
  int get attackerIndex {
    if (_attackerIndex == null) {
      throw StateError('No current attacker.');
    }
    return _attackerIndex!;
  }

  /// Index of the current defender.
  int get defenderIndex => attackerIndex.isEven ? 1 : 0;

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
    final firstDelta = CreatureDelta(
      gold: firstGold - initialCreatures[0].gold,
      hp: first.hp - initialCreatures[0].hp,
    );
    final secondDelta = CreatureDelta(
      gold: secondGold - initialCreatures[1].gold,
      hp: second.hp - initialCreatures[1].hp,
    );

    // Print spoils for the player if they won.
    _logSpoils(before: creatures[0], after: first);
    return BattleResult(
      first: first,
      firstDelta: firstDelta,
      second: second,
      secondDelta: secondDelta,
      // _turnsTaken is 0-indexed, as is turns
      turns: _turnsTaken ~/ 2,
    );
  }

  /// Run the battle and return the result.
  BattleResult run() {
    try {
      _triggerOnBattleStart();
      _triggerInitiative();
      _decideFirstAttacker();
      log('${creatures[0].name}: ${stats[0]}');
      log('${creatures[1].name}: ${stats[1]}');
      while (allAlive) {
        log('$attackerName turn $turnNumber');
        _triggerOnTurn();
        _strike();
        _handleExtraStrikes();
        // Might advance multiple turns if both creatures are stunned.
        _nextAttacker();
        if (attackerIndex == 1 && turnNumber > 100) {
          // https://discord.com/channels/1041414829606449283/1209488593219756063/1276997595071512596
          dealDamage(
            damage: 10,
            targetIndex: attackerIndex,
            source: 'Time Limit',
          );
        }
      }
    } on _DeathException catch (e) {
      log('${e.creature.name} has died');
    }
    return _resolveWithSpoils();
  }
}

/// Represents a change to a creature from the start of a battle.
@immutable
class CreatureDelta {
  /// Create a CreatureDelta.
  const CreatureDelta({
    required this.gold,
    required this.hp,
  });

  /// Gold change.
  final int gold;

  /// HP change.
  final int hp;

  @override
  String toString() {
    final parts = <String>[];
    if (gold != 0) {
      parts.add('gold: $gold');
    }
    if (hp != 0) {
      parts.add('hp: $hp');
    }
    if (parts.isEmpty) {
      return 'no change';
    }
    return parts.join(', ');
  }
}

/// Represents the results of a battle.
@immutable
class BattleResult {
  /// Create a BattleResult
  const BattleResult({
    required this.first,
    required this.firstDelta,
    required this.second,
    required this.secondDelta,
    required this.turns,
  });

  /// First creature in this battle.
  final Creature first;

  /// Changes relative to the start of the battle.
  final CreatureDelta firstDelta;

  /// Second creature in this battle.
  final Creature second;

  /// Changes relative to the start of the battle.
  final CreatureDelta secondDelta;

  /// Number of turns taken in this battle.
  final int turns;

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
