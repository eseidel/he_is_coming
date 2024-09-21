import 'package:flutter/material.dart';
import 'package:he_is_coming/he_is_coming.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:ui/src/style.dart';

/// Adds a color property to ItemRarity.
extension ItemRarityColor on ItemRarity {
  /// Color for this rarity.
  Color get color {
    switch (this) {
      case ItemRarity.common:
        return Palette.common;
      case ItemRarity.rare:
        return Palette.rare;
      case ItemRarity.heroic:
        return Palette.heroic;
      case ItemRarity.golden:
        return Palette.golden;
      case ItemRarity.diamond:
        return Palette.diamond;
      case ItemRarity.cauldron:
        return Palette.cauldron;
    }
  }
}

/// UI extensions for edges.
extension EdgeUI on Edge {
  /// Color for this edge.
  Color get color {
    final map = {
      'Agile Edge': Palette.speed,
      'Bleeding Edge': Palette.sanguine,
      'Blunt Edge': Palette.armor,
      'Cutting Edge': Palette.attack,
      'Featherweight Edge': Palette.speed,
      'Jagged Edge': Palette.thorns,
      'Lightning Edge': Palette.speed,
      'Thieving Edge': Palette.gold,
      "Titan's Edge": Palette.attack,
    };
    final color = map[name];
    if (color == null) {
      return Palette.white;
    }
    return color;
  }

  /// Icon for this edge.
  Widget get icon => Icon(Icons.flash_on, color: color);
}

/// Adds a capitalize method to String.
extension StringCapitalize on String {
  /// Capitalize the first letter of this string.
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

/// Adds a color property to Item.
extension ItemUI on Item {
  /// Color for this item.
  Color get color {
    if (isWeapon) {
      return Palette.weapon;
    }
    if (hasTag(ItemTag.stone)) {
      return Palette.stone;
    }
    if (hasTag(ItemTag.sanguine)) {
      return Palette.sanguine;
    }
    return Colors.orange;
  }

  /// Border color for this item.
  Color get borderColor {
    if (isWeapon) {
      return Palette.weapon;
    }
    return Palette.white;
  }

  /// Icon for this item.
  IconData get icon {
    return Icons.help;
  }

  /// Rarity icon for this item.
  Widget get rarityIcon {
    return Icon(
      Icons.circle,
      color: rarity.color,
      size: 12,
    );
  }

  /// Tags to display for this item.
  List<String> get displayTags {
    return [
      if (isUnique) 'Unique',
      ...tags.map((tag) => tag.name.capitalize()),
    ];
  }

  /// Tags to filter on for this item.
  Set<String> get filterTags {
    return {
      ...tags.map((tag) => tag.name.capitalize()),
      if (isUnique) 'Unique',
      rarity.name.capitalize(),
    };
  }
}

/// Adds a color property to StatType.
extension StatColor on StatType {
  /// Color for this stat.
  Color get color {
    switch (this) {
      case StatType.attack:
        return Palette.attack;
      case StatType.health:
        return Palette.health;
      case StatType.armor:
        return Palette.armor;
      case StatType.speed:
        return Palette.speed;
    }
  }

  /// Icon for this stat.
  Widget icon(double size) {
    final nesSize = Size(size, size);
    switch (this) {
      case StatType.attack:
        return NesIcon(
          iconData: NesIcons.sword,
          primaryColor: Palette.attack,
          secondaryColor: Palette.black,
          size: nesSize,
        );
      case StatType.health:
        return Icon(
          Icons.favorite,
          color: Palette.health,
          size: size,
        );
      case StatType.armor:
        return NesIcon(
          iconData: NesIcons.shield,
          primaryColor: Palette.armor,
          accentColor: Palette.black,
          size: nesSize,
        );
      case StatType.speed:
        return Icon(
          Icons.directions_run,
          color: Palette.speed,
          size: size,
        );
    }
  }
}

/// Adds a color property to Oil.
extension OilUI on Oil {
  /// Color for this oil.
  Color get color {
    if (name == 'Attack Oil') {
      return Palette.attack;
    }
    if (name == 'Speed Oil') {
      return Palette.speed;
    }
    if (name == 'Armor Oil') {
      return Palette.armor;
    }
    throw UnimplementedError('Unknown oil: $name');
  }

  /// Icon for this oil.
  Widget get icon => Icon(Icons.water_drop, color: color);
}
