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

/// Effects that can be triggered by creatures.
final creatureEffects = <String, Effects>{
  'Spider Level 1': _spiderEffect(damage: 3),
  'Spider Level 2': _spiderEffect(damage: 4),
  'Spider Level 3': _spiderEffect(damage: 5),
  'Woodland Abomination': Effects(onTurn: (c) => c.gainAttack(1)),
};
