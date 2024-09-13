import 'package:he_is_coming/src/effects.dart';

// Dart doesn't have if-expressions, so made a helper function.
void _if(bool condition, void Function() fn) {
  if (condition) {
    fn();
  }
}

/// Effects that can be triggered by set bonuses.
final setEffects = EffectCatalog(<String, EffectMap>{
  'Redwood Crown': onWounded(
    (c) => _if(!c.my.isHealthFull, () => c.restoreHealth(c.my.lostHp)),
  ),
});
