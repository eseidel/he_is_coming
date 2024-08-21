import 'package:he_is_coming/src/effects.dart';

/// Effects that can be triggered by edges.
final edgeEffects = <String, Effects>{
  'Bleeding Edge': Effects(onHit: (c) => c.restoreHealth(1)),
  'Blunt Edge': Effects(onHit: (c) => c.gainArmor(1)),
};
