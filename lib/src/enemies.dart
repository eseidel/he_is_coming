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
  static final bearLevel1 = makeEnemy('Bear Level 1', attack: 1, health: 3);

  /// Bear deals 5 additional damage while you have armor.
  static final bearLevel3 =
      makeEnemy('Bear Level 3', attack: 2, health: 8, speed: 2);

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

  /// Redwood Treant, level 2
  /// Redwood Treant's attack is halved against armor
  static final redwoodTreant =
      makeEnemy('Redwood Treant', attack: 6, health: 25, armor: 15);

  /// Leshen, level 3
  static final leshen = makeEnemy('Leshen', attack: 7, health: 60, speed: 3);
}
