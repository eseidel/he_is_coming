import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nes_ui/nes_ui.dart';

/// Icon size configuration
@immutable
class IconSize {
  /// Icon size configuration
  const IconSize({
    required this.border,
    required this.icon,
  });

  /// Border size
  final double border;

  /// Icon size
  final double icon;
}

/// App theme
class Style {
  /// App Text Theme
  static final TextTheme textTheme = GoogleFonts.pressStart2pTextTheme().apply(
    bodyColor: Palette.text,
    displayColor: Palette.text,
    decorationColor: Palette.text,
  );

  /// App Theme
  static ThemeData get theme {
    final baseTheme = flutterNesTheme(brightness: Brightness.dark);
    return baseTheme.copyWith(
      textTheme: Style.textTheme,
      buttonTheme: baseTheme.buttonTheme.copyWith(buttonColor: Palette.white),
    );
  }

  /// Stats Text Style
  static final TextStyle stats = Style.textTheme.labelMedium!.apply();

  /// Tags Text Style
  static final TextStyle tags = Style.textTheme.labelSmall!.apply(
    color: Palette.black,
  );

  /// Effect Text Style
  static final TextStyle effect = Style.textTheme.labelSmall!;

  /// Stat Icons when displayed alone
  static const statIconSize = IconSize(border: 36, icon: 24);

  /// Stat Icons when displayed inline
  static const inlineStatIconSize = IconSize(border: 24, icon: 16);
}

/// Color palette
class Palette {
  /// White, used for all UI and text.
  static const Color white = Color.fromARGB(255, 226, 219, 196);

  /// Black, used for all UI and text.
  static final Color black = Colors.brown[900]!;

  /// Text color.
  static const Color text = Palette.white;

  /// Weapon Items color.
  static const Color weapon = Palette.attack;

  /// Sanguine Items color.
  static const Color sanguine = Color.fromARGB(255, 194, 51, 74);

  /// Stone Items color.
  static const Color stone = Color.fromARGB(255, 150, 132, 113);

  /// Heroic Rarity color.
  static const Color heroic = Color.fromARGB(255, 166, 110, 187);

  /// Rare Rarity color.
  static const Color rare = Color.fromARGB(255, 113, 168, 210);

  /// Common Rarity color.
  static const Color common = Color.fromARGB(255, 156, 195, 67);

  /// Golden Rarity color.
  static const Color golden = Colors.yellow;

  /// Cauldron Rarity color.
  static const Color cauldron = Colors.orange;

  /// Health stat color.
  static const Color health = Color.fromARGB(255, 156, 195, 67);

  /// Attack stat color.
  static const Color attack = Color.fromARGB(255, 217, 83, 73);

  /// Armor stat color.
  static const Color armor = Color.fromARGB(255, 113, 168, 210);

  /// Speed stat color.
  static const Color speed = Color.fromARGB(255, 249, 212, 108);

  /// Gold (money) color.
  static const Color gold = Color.fromARGB(255, 198, 135, 40);

  /// Thorns color.
  static const Color thorns = Color.fromARGB(255, 138, 148, 36);

  /// Creature color.
  static const Color creature = Palette.attack;
}
