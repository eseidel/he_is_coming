import 'package:he_is_coming/src/effects.dart';

// Dart doesn't have if-expressions, so made a helper function.
void _if(bool condition, void Function() fn) {
  if (condition) {
    fn();
  }
}

/// Effects that can be triggered by edges.
final edgeEffects = <String, Effects>{
  'Bleeding Edge': Effects(onHit: (c) => c.restoreHealth(1)),
  'Blunt Edge': Effects(onHit: (c) => c.gainArmor(1)),
  'Lightning Edge': Effects(onBattle: (c) => c.stunEnemy(1)),
  'Thieving Edge':
      Effects(onHit: (c) => _if(c.my.gold < 10, () => c.gainGold(1))),
  'Jagged Edge': Effects(
    onHit: (c) => c
      ..gainThorns(2)
      ..takeDamage(1),
  ),
};
