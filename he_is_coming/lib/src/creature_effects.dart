import 'package:he_is_coming/src/battle.dart';
import 'package:he_is_coming/src/effects.dart';

EffectCallbacks _spiderEffect({required int damage}) {
  return onBattle(
    (c) {
      if (c.my.speed > c.enemy.speed) {
        c.dealDamage(damage);
      }
    },
  );
}

EffectCallbacks _batEffect({required int hp}) {
  return onHit(
    (c) {
      if (c.isEveryOtherTurn) {
        c.restoreHealth(hp);
      }
    },
  );
}

EffectCallbacks _hedgehogEffect({required int thorns}) =>
    onBattle((c) => c.gainThorns(thorns));

EffectFn _temporaryAttack({
  required int baseAttack,
  required int bonus,
  required bool Function(EffectContext) shouldHaveBonus,
}) {
  // We have no way for effects to have their own state, so we have to hard
  // code the base/bonus within this effect so we can tell during the effect
  // which state we're in.
  return (EffectContext c) {
    final has = c.my.attack == baseAttack + bonus;
    final shouldHave = shouldHaveBonus(c);
    if (!{baseAttack, baseAttack + bonus}.contains(c.my.attack)) {
      throw StateError('Unexpected attack value.');
    }
    if (has && !shouldHave) {
      c.loseAttack(bonus);
    } else if (!has && shouldHave) {
      c.gainAttack(bonus);
    }
  };
}

EffectCallbacks _wolfEffect({required int baseAttack, required int bonus}) {
  return multiTrigger(
    [Trigger.onBattle, Trigger.onEnemyHpChanged],
    _temporaryAttack(
      baseAttack: baseAttack,
      bonus: bonus,
      shouldHaveBonus: (c) => c.enemy.hp < 5,
    ),
  );
}

EffectCallbacks _bearEffect({required int baseAttack, required int bonus}) {
  return multiTrigger(
    [Trigger.onBattle, Trigger.onEnemyArmorChanged],
    _temporaryAttack(
      baseAttack: baseAttack,
      bonus: bonus,
      shouldHaveBonus: (c) => c.enemy.armor > 0,
    ),
  );
}

// Dart doesn't have if-expressions, so made a helper function.
void _if(bool condition, void Function() fn) {
  if (condition) {
    fn();
  }
}

/// Effects that can be triggered by creatures.
final creatureEffects = EffectCatalog(<String, EffectCallbacks>{
  'Spider Level 1': _spiderEffect(damage: 3),
  'Spider Level 2': _spiderEffect(damage: 4),
  'Spider Level 3': _spiderEffect(damage: 5),
  'Bat Level 1': _batEffect(hp: 1),
  'Bat Level 2': _batEffect(hp: 2),
  'Bat Level 3': _batEffect(hp: 3),
  'Hedgehog Level 1': _hedgehogEffect(thorns: 3),
  'Hedgehog Level 2': _hedgehogEffect(thorns: 4),
  'Hedgehog Level 3': _hedgehogEffect(thorns: 5),
  'Woodland Abomination': onTurn(
    (c) {
      // The game lets the abomination attack once for 0 for whatever reason.
      if (c.isFirstTurn) {
        return;
      }
      c.gainAttack(1);
    },
  ),
  'Black Knight': onBattle(
    (c) => _if(c.enemy.attack > 0, () => c.gainAttack(c.enemy.attack)),
  ),
  'Ironstone Golem': onExposed((c) => c.loseAttack(3)),
  'Granite Griffin': onWounded(
    (c) => c
      ..gainArmor(30)
      ..stunSelf(2),
  ),
  'Razortusk Hog':
      onTurn((c) => _if(c.hadMoreSpeedAtStart, () => c.queueExtraStrike())),
  'Gentle Giant':
      onTakeDamage((c) => c.gainThorns(c.my.atOrBelowHalfHealth ? 4 : 2)),
  'Bloodmoon Werewolf': onTurn(
    (c) => _if(c.enemy.atOrBelowHalfHealth, () => c.executeEnemy()),
  ),
  'Brittlebark Beast': onTakeDamage((c) => c.takeDamage(3)),
  'Wolf Level 1': _wolfEffect(baseAttack: 1, bonus: 2),
  'Wolf Level 2': _wolfEffect(baseAttack: 2, bonus: 3),
  'Wolf Level 3': _wolfEffect(baseAttack: 3, bonus: 4),
  'Bear Level 1': _bearEffect(baseAttack: 1, bonus: 3),
  'Bear Level 2': _bearEffect(baseAttack: 2, bonus: 5),
  'Bear Level 3': _bearEffect(baseAttack: 3, bonus: 7),
  'Crazed Honeybear Level 3': _bearEffect(baseAttack: 6, bonus: 5),
  'Hothead': multiTrigger(
    [Trigger.onBattle, Trigger.onEndTurn],
    _temporaryAttack(
      baseAttack: 4,
      bonus: 10,
      shouldHaveBonus: (c) => c.my.speed > c.enemy.speed && c.isFirstTurn,
    ),
  ),
});
