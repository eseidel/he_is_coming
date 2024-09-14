import 'package:he_is_coming/src/effects.dart';

/// Effects that can be triggered by set bonuses.
final setEffects = EffectCatalog(<String, EffectMap>{
  'Redwood Crown': onWounded((c) => c.healToFull()),
});
