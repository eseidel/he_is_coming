import 'package:he_is_coming/src/effects.dart';

Effect _spiderEffect({required int damage}) {
  return onBattle(
    (c) {
      if (c.my.speed > c.enemy.speed) {
        c.dealDamage(damage);
      }
    },
  );
}

Effect _batEffect({required int hp}) {
  return onHit(
    (c) {
      if (c.isEveryOtherTurn) {
        c.restoreHealth(hp);
      }
    },
  );
}

Effect _hedgehogEffect({required int thorns}) =>
    onBattle((c) => c.gainThorns(thorns));

/// Effects that can be triggered by creatures.
final creatureEffects = <String, Effect>{
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
  'Black Knight': onBattle((c) => c.gainAttack(c.enemy.attack)),
  'Ironstone Golem': onExposed((c) => c.loseAttack(3)),
  'Granite Griffin': onWounded(
    (c) => c
      ..gainArmor(30)
      ..stunSelf(2),
  ),
};
