import 'package:he_is_coming/src/creature.dart';

/// Class holding predefined over-world enemies.
class Enemies {}

/// Class holding predefined bosses.
class Bosses {
  /// Hothead, level 1
  /// If Hothead has more speed than you, his first strike deals 10 additional
  /// damage.
  static final hothead = makeEnemy('Hothead', attack: 4, health: 5, speed: 4);

  /// Brittlebark Beast, level 1
  /// Whenever Brittlebark beast takes damage, he takes 2 additional damage.
  static final brittlebarkBeast =
      makeEnemy('Brittlebark Beast', health: 40, attack: 3, speed: 2);

  /// Ironstone, Level 1
  /// Exposed: Ironstone loses 3 attack
  static final ironstoneGolem =
      makeEnemy('Ironstone Golem', attack: 4, health: 5, armor: 15);

  /// Redwood Treant, level 2
  /// Redwood Treant's attack is halved against armor
  static final redwoodTreant =
      makeEnemy('Redwood Treant', attack: 6, health: 25, armor: 15);

  /// Razortusk Hog, level 2
  /// Battle Start: If Razortusk Hog has more speed than you, he strikes twice
  /// for the rest of the battle.
  static final razortuskHog =
      makeEnemy('Razortusk Hog', attack: 4, health: 20, speed: 4);

  /// Leshen, level 3
  static final leshen = makeEnemy('Leshen', attack: 7, health: 60, speed: 3);

  /// Woodland Abomination, End
  /// Turn Start: Woodland Abomination gains 1 attack
  static final woodlandAbomination = makeEnemy(
    'Woodland Abomination',
    attack: 0,
    health: 1000,
    speed: 2,
  );
}
