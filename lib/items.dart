import 'package:he_is_coming_sim/item.dart';

class Items {
  static final woodenStick = Item.weapon(
    'Wooden Stick',
    Rarity.common,
    Material.wood,
    attack: 1,
  );
  static final redwoodRod = Item.weapon(
    'Redwood Rod',
    Rarity.common,
    Material.wood,
    attack: 2,
    health: 4,
  );
  // Battle Start: If your health is full, gain 4 armor.
  static final stoneSteak =
      Item('Stone Steak', Kind.food, Rarity.common, Material.stone);
  static final leatherVest = Item(
    'Leather Vest',
    Kind.clothing,
    Rarity.common,
    Material.leather,
    armor: 2,
    speed: 1,
  );

  // Battle Start: If your health is not full, restore 1 health.
  static final redwoodCloak = Item(
    'Redwood Cloak',
    Kind.clothing,
    Rarity.common,
    Material.leather,
    health: 2,
  );

  // On Hit: Restore 1 health.
  static final heartDrinker = Item.weapon(
    'Heart Drinker',
    Rarity.common,
    Material.sanguine,
    attack: 2,
  );

  // Battle Start: If you have less speed than the enemy, gain 4 armor.
  static final emergencyShield = Item(
    'Emergency Shield',
    Kind.clothing,
    Rarity.common,
    Material.leather,
  );
  static final spearshieldLance = Item.weapon(
    'Spearshield Lance',
    Rarity.common,
    Material.leather,
    attack: 1,
    armor: 4,
  );
  // Exposed: Restore 3 health.
  static final redwoodHelmet = Item(
    'Redwood Helmet',
    Kind.clothing,
    Rarity.common,
    Material.wood,
    armor: 1,
  );

  static final ironGreatsword = Item.weapon(
    'Iron Greatsword',
    Rarity.common,
    Material.stone,
    attack: 4,
    speed: -2,
  );

  static final leatherGloves = Item(
    'Leather Gloves',
    Kind.clothing,
    Rarity.common,
    Material.leather,
    health: 3,
    speed: 1,
  );

  // Every 3 strikes, deal triple damage.
  static final haymaker =
      Item.weapon('Haymaker', Rarity.common, Material.leather, attack: 1);

  static final weightedBracelet = Item(
    'Weighted Bracelet',
    Kind.clothing,
    Rarity.common,
    Material.leather,
    attack: 1,
    speed: -1,
  );

  // Turn start: if you have armor, gain 1 additional armor.
  static final fortifiedGauntlet = Item(
    'Fortified Gauntlet',
    Kind.clothing,
    Rarity.rare,
    Material.leather,
  );

  // Enemies first strike ignores armor.
  static final phantomArmor = Item(
    'Phantom Armor',
    Kind.clothing,
    Rarity.rare,
    Material.leather,
    armor: 4,
  );
}
