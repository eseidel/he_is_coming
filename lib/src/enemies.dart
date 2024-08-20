import 'package:he_is_coming/src/creature.dart';

/// Class holding predefined over-world enemies.
class Enemies {
  /// If player has 5 or less health, wolf gains 2 attack.
  static final wolfLevel1 = makeEnemy('Wolf Level 1', attack: 1, health: 3);

  /// If player has 5 or less health, wolf gains 3 attack.
  static final wolfLevel2 =
      makeEnemy('Wolf Level 2', attack: 2, health: 6, speed: 1);

  /// If player has 5 or less health, wolf gains 4 attack.
  static final wolfLevel3 =
      makeEnemy('Wolf Level 3', attack: 2, health: 9, speed: 2);

  /// Bear deals 3 additional damage while you have armor.
  static final bearLevel1 =
      makeEnemy('Bear Level 1', attack: 1, health: 3, armor: 2);

  /// Bear deals 4 additional damage while you have armor.
  static final bearLevel2 =
      makeEnemy('Bear Level 2', attack: 2, health: 5, speed: 1, armor: 3);

  /// Bear deals 5 additional damage while you have armor.
  static final bearLevel3 =
      makeEnemy('Bear Level 3', attack: 3, health: 7, speed: 2, armor: 4);

  /// Battle Start: If Spider has more speed than you, it deals 3 damage
  static final spiderLevel1 =
      makeEnemy('Spider Level 1', attack: 1, health: 3, speed: 3);

  /// Battle Start: If Spider has more speed than you, it deals 4 damage
  static final spiderLevel2 =
      makeEnemy('Spider Level 2', attack: 1, health: 3, speed: 3);

  /// Battle Start: If Spider has more speed than you, it deals 5 damage
  static final spiderLevel3 =
      makeEnemy('Spider Level 3', attack: 1, health: 4, speed: 4);
}

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
