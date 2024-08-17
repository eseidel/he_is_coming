import 'package:he_is_coming_sim/creatures.dart';
import 'package:meta/meta.dart';

/// Represents a single level or floor during a run.
// Named Floor to not conflict with "Level" from mason_logger.
@immutable
class Floor {
  /// Create a floor.
  const Floor({required this.number, required this.boss, this.length = 100});

  /// The number of this floor (1, 2, 3)
  final int number;

  /// The boss at the end of this floor.
  final Creature boss;

  /// The number of time steps in this floor.
  final int length;
}

/// Holds the state of the entire run.
class Game {
  /// Create a new Game.
  Game({
    required this.player,
    required this.floor,
    this.currentTime = 0,
  });

  /// State of the player
  Creature player;

  /// State of the floor the player is on.
  Floor floor;

  /// Time elapsed on this floor.
  int currentTime;
}
