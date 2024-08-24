import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme
class Style {
  /// App Text Theme
  static final TextTheme textTheme = GoogleFonts.pressStart2pTextTheme().apply(
    bodyColor: Palette.text,
    displayColor: Palette.text,
  );

  /// Stats Text Style
  static final TextStyle stats = Style.textTheme.labelMedium!.apply();

  /// Tags Text Style
  static final TextStyle tags = Style.textTheme.labelSmall!.apply(
    color: Palette.black,
  );

  /// Effect Text Style
  static final TextStyle effect = Style.textTheme.labelSmall!;
}

/// Color palette
class Palette {
  /// White, used for all UI and text.
  static final Color white = Colors.brown[100]!;

  /// Black, used for all UI and text.
  static final Color black = Colors.brown[900]!;

  /// Text color.
  static final Color text = Palette.white;

  /// Weapon Items color.
  static const Color weapon = Palette.attack;

  /// Sanguine Items color.
  static final Color sanguine = Colors.red[900]!;

  /// Food Items color.
  static final Color food = Colors.green[800]!;

  /// Stone Items color.
  static final Color stone = Colors.grey[800]!;

  /// Heroic Rarity color.
  static const Color heroic = Colors.teal;

  /// Rare Rarity color.
  static const Color rare = Colors.blue;

  /// Common Rarity color.
  static const Color common = Colors.green;

  /// Golden Rarity color.
  static const Color golden = Colors.yellow;

  /// Cauldron Rarity color.
  static const Color cauldron = Colors.orange;

  /// Health stat color.
  static const Color health = Colors.green;

  /// Attack stat color.
  static const Color attack = Colors.red;

  /// Armor stat color.
  static const Color armor = Colors.grey;

  /// Speed stat color.
  static const Color speed = Colors.yellow;
}
