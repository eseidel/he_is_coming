import 'package:he_is_coming/src/effects.dart';

EffectMap _spiderEffect({required int damage}) {
  return onBattle(
    (c) {
      if (c.my.speed > c.enemy.speed) {
        c.dealDamage(damage);
      }
    },
  );
}

EffectMap _batEffect({required int hp}) {
  return onHit(
    (c) {
      if (c.isEveryOtherTurn) {
        c.restoreHealth(hp);
      }
    },
  );
}

EffectMap _hedgehogEffect({required int thorns}) =>
    onBattle((c) => c.gainThorns(thorns));

// Dart doesn't have if-expressions, so made a helper function.
void _if(bool condition, void Function() fn) {
  if (condition) {
    fn();
  }
}

/// Effects that can be triggered by creatures.
final creatureEffects = EffectCatalog(<String, EffectMap>{
  'Spider Level 1': _spiderEffect(damage: 3),
  'Spider Level 2': _spiderEffect(damage: 4),
  'Spider Level 3': _spiderEffect(damage: 5),
  'Bat Level 1': _batEffect(hp: 1),
  'Bat Level 2': _batEffect(hp: 2),
  'Hedgehog Level 1': _hedgehogEffect(thorns: 3),
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
});
