import 'package:he_is_coming/src/effects.dart';

// Dart doesn't have if-expressions, so made a helper function.
void _if(bool condition, void Function() fn) {
  if (condition) {
    fn();
  }
}

/// Effects that can be triggered by edges.
final edgeEffects = <String, EffectMap>{
  'Bleeding Edge': onHit((c) => c.restoreHealth(1)),
  'Blunt Edge': onHit((c) => c.gainArmor(1)),
  'Lightning Edge': onBattle((c) => c.stunEnemy(1)),
  'Thieving Edge': onHit((c) => _if(c.my.gold < 10, () => c.gainGold(1))),
  'Jagged Edge': onHit(
    (c) => c
      ..gainThorns(2)
      ..takeDamage(1),
  ),
  'Cutting Edge': onHit((c) => c.dealDamage(1)),
};