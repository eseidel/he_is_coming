import 'package:he_is_coming/src/effects.dart';

Effects _spiderEffect({required int damage}) {
  return Effects(
    onBattle: (c) {
      if (c.my.speed > c.enemy.speed) {
        c.dealDamage(damage);
      }
    },
  );
}

Effects _batEffect({required int hp}) {
  return Effects(
    onHit: (c) {
      if (c.isEveryOtherTurn) {
        c.restoreHealth(hp);
      }
    },
  );
}

/// Effects that can be triggered by creatures.
final creatureEffects = <String, Effects>{
  'Spider Level 1': _spiderEffect(damage: 3),
  'Spider Level 2': _spiderEffect(damage: 4),
  'Spider Level 3': _spiderEffect(damage: 5),
  'Bat Level 1': _batEffect(hp: 1),
  'Bat Level 2': _batEffect(hp: 2),
  'Woodland Abomination': Effects(
    onTurn: (c) {
      // The game lets the abomination attack once for 0 for whatever reason.
      if (c.isFirstTurn) {
        return;
      }
      c.gainAttack(1);
    },
  ),
  'Black Knight': Effects(onBattle: (c) => c.gainAttack(c.enemy.attack)),
  'Ironstone Golem': Effects(onExposed: (c) => c.loseAttack(3)),
  'Granite Griffin': Effects(
    onWounded: (c) => c
      ..gainArmor(30)
      ..stunSelf(2),
  ),
};
