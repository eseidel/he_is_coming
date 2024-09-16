import 'package:he_is_coming/src/catalog.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

/// A type of stat.
enum StatType {
  /// Health (max hp) of the creature.
  health,

  /// Armor of the creature.
  armor,

  /// Attack of the creature.
  attack,

  /// Speed of the creature.
  speed,
}

/// Class representing stats for a Creature.
@immutable
class Stats {
  /// Create a new Stats.
  const Stats({
    this.maxHp = 0,
    this.armor = 0,
    this.attack = 0,
    this.speed = 0,
  });

  /// Create stats from a yaml map.
  factory Stats.fromYaml(YamlMap yaml) {
    final health = yaml['health'] as int? ?? 0;
    final armor = yaml['armor'] as int? ?? 0;
    final attack = yaml['attack'] as int? ?? 0;
    final speed = yaml['speed'] as int? ?? 0;
    return Stats(
      maxHp: health,
      armor: armor,
      attack: attack,
      speed: speed,
    );
  }

  /// Max health of the creature.
  final int maxHp;

  /// Current armor of the creature.
  final int armor;

  /// Current attack of the creature.
  final int attack;

  /// Current speed.
  final int speed;

  /// Return true if all stats are 0.
  bool get isEmpty => this == const Stats();

  /// All the known keys in the stats yaml, in sorted order.
  static const List<String> orderedKeys = <String>[
    'health',
    'armor',
    'attack',
    'speed',
  ];

  /// Add two Stats together.
  Stats operator +(Stats other) {
    return copyWith(
      maxHp: maxHp + other.maxHp,
      armor: armor + other.armor,
      attack: attack + other.attack,
      speed: speed + other.speed,
    );
  }

  /// Multiply all stats by a factor.
  Stats operator *(int factor) {
    return copyWith(
      maxHp: maxHp * factor,
      armor: armor * factor,
      attack: attack * factor,
      speed: speed * factor,
    );
  }

  /// return the stat value for a given type.
  int operator [](StatType type) {
    switch (type) {
      case StatType.health:
        return maxHp;
      case StatType.armor:
        return armor;
      case StatType.attack:
        return attack;
      case StatType.speed:
        return speed;
    }
  }

  /// Create a copy of Stats with updated values.
  Stats copyWith({
    int? maxHp,
    int? armor,
    int? attack,
    int? speed,
  }) {
    return Stats(
      maxHp: maxHp ?? this.maxHp,
      attack: attack ?? this.attack,
      armor: armor ?? this.armor,
      speed: speed ?? this.speed,
    );
  }

  @override
  String toString() {
    return 'MaxHP: $maxHp, Armor: $armor, Attack: $attack, Speed: $speed';
  }

  /// Convert to json.
  Map<String, dynamic> toJson() {
    return {
      if (maxHp != 0) 'health': maxHp,
      if (attack != 0) 'attack': attack,
      if (armor != 0) 'armor': armor,
      if (speed != 0) 'speed': speed,
    };
  }
}

/// Represents an item that can be equipped by the player.
@immutable
class Item extends CatalogItem {
  /// Create a new Item
  Item({
    required String name,
    required this.rarity,
    required super.id,
    required super.version,
    this.isWeapon = false,
    this.tags = const {},
    this.stats = const Stats(),
    this.isUnique = false,
    super.effect,
    super.inferred = false,
    this.parts = const [],
  }) : super(name: name) {
    if (isWeapon && stats.attack == 0) {
      if (_intentionallyZeroAttackItems.contains(name)) {
        return;
      }
      throw ArgumentError('Weapon $name must have attack');
    }
  }

  /// Create a test item.
  @visibleForTesting
  factory Item.test({
    String? name,
    EffectMap? effect,
    ItemRarity rarity = ItemRarity.common,
    bool isWeapon = false,
    Set<ItemTag> tags = const {},
    bool isUnique = false,
    int? attack,
    int? armor,
    int? speed,
    int? health,
  }) {
    Effect? triggers;
    if (effect != null) {
      triggers = Effect(
        callbacks: effect,
        text: 'test',
        onDynamicStats: null,
      );
    }
    final stats = Stats(
      attack: attack ?? 0,
      armor: armor ?? 0,
      speed: speed ?? 0,
      maxHp: health ?? 0,
    );
    return Item(
      name: name ?? 'test',
      id: 0, // Unique ids are not required for test items.
      rarity: rarity,
      isWeapon: isWeapon,
      tags: tags,
      stats: stats,
      effect: triggers,
      isUnique: isUnique,
      version: null,
    );
  }

  /// Create an item from a yaml map.
  factory Item.fromYaml(YamlMap yaml, LookupEffect lookupEffect) {
    final name = yaml['name'] as String;
    final weapon = yaml['weapon'] as bool? ?? false;
    final tags = Item._tagsFromYaml(yaml['tags']) ?? {};
    final rarity = yaml.expect('rarity', ItemRarity.values);
    final stats = Stats.fromYaml(yaml);
    final unique = yaml['unique'] as bool? ?? false;
    final effectText = yaml['effect'] as String?;
    final parts = yaml['parts'] as List?;
    final effect = lookupEffect(name: name, effectText: effectText);
    final inferred = yaml['inferred'] as bool? ?? false;
    final id = yaml['id'] as int;
    final version = yaml['version'] as String?;
    return Item(
      name: name,
      isWeapon: weapon,
      tags: tags,
      rarity: rarity,
      stats: stats,
      effect: effect,
      isUnique: unique,
      parts: parts?.cast<String>(),
      inferred: inferred,
      id: id,
      version: version,
    );
  }
  static const _intentionallyZeroAttackItems = {
    'Bejeweled Blade',
    "Woodcutter's Axe",
    'Tempest Blade',
    'Bearclaw Blade',
  };

  /// Tags on the item.
  final Set<ItemTag> tags;

  /// Stats for the item.
  final Stats stats;

  /// Rarity of the item.
  final ItemRarity rarity;

  /// Is the item unique.
  /// Unique items can only be equipped once.
  final bool isUnique;

  /// Is the item a weapon.
  final bool isWeapon;

  /// Returns true if the item has the given tag.
  bool hasTag(ItemTag tag) => tags.contains(tag);

  /// Is the item a food item.
  bool get isFood => hasTag(ItemTag.food);

  /// Items combined to make this item.
  final List<String>? parts;

  /// The gem type of the item.
  Gem? get gem {
    final nameParts = name.split(' ').map((s) => s.toLowerCase()).toSet();
    for (final gem in Gem.values) {
      if (nameParts.contains(gem.name)) {
        return gem;
      }
    }
    return null;
  }

  /// Returns true if the item has a gem of the given type.
  bool hasGem(Gem gem) => this.gem == gem;

  /// All the known keys in the item yaml, in sorted order.
  static const List<String> orderedKeys = <String>[
    'name',
    'id',
    'weapon',
    'tags',
    'unique',
    'rarity',
    'unlock', // ignored for now
    'parts', // ignored for now
    ...Stats.orderedKeys,
    'effect',
    'inferred',
    'version',
  ];

  static Set<ItemTag>? _tagsFromYaml(dynamic json) {
    if (json == null) {
      return null;
    }
    if (json is String) {
      return {ItemTag.fromJson(json)};
    }
    if (json is List) {
      return json.map((e) => ItemTag.fromJson(e as String)).toSet();
    }
    throw UnimplementedError('Unknown tag type: $json');
  }

  static dynamic _tagsToJson(Set<ItemTag> tags) {
    if (tags.length == 1) {
      return tags.first.toJson();
    }
    return tags.map((t) => t.toJson()).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      if (isWeapon) 'weapon': isWeapon,
      if (tags.isNotEmpty) 'tags': _tagsToJson(tags),
      if (isUnique) 'unique': isUnique,
      'rarity': rarity.toJson(),
      if (parts != null && parts!.isNotEmpty) 'parts': parts,
      ...stats.toJson(),
      'effect': effect?.toJson(),
      if (inferred) 'inferred': inferred,
      if (version != null) 'version': version,
    };
  }

  /// Create a copy of the item with updated values.
  @override
  Item copyWith({
    String? name,
    int? id,
    Set<ItemTag>? tags,
    ItemRarity? rarity,
    Stats? stats,
    bool? isUnique,
    Effect? effect,
    bool? inferred,
    List<String>? parts,
  }) {
    return Item(
      name: name ?? this.name,
      rarity: rarity ?? this.rarity,
      tags: tags ?? this.tags,
      id: id ?? this.id,
      stats: stats ?? this.stats,
      isUnique: isUnique ?? this.isUnique,
      effect: effect ?? this.effect,
      inferred: inferred ?? this.inferred,
      parts: parts ?? this.parts,
      version: version,
    );
  }
}

/// The types of gem sets.
enum Gem {
  /// Ruby (attack / damage) set.
  ruby,

  /// Sapphire (armor) set.
  sapphire,

  /// Emerald (health) set.
  emerald,

  /// Citrine (speed) set.
  citrine,
}

/// Rarity class of an item.
enum ItemRarity {
  /// Common, found in chests.
  common,

  /// Rare, found in shops.
  rare,

  /// Heroic, found in graves.
  heroic,

  /// Golden, made by combining commons
  golden,

  /// Cauldron, made by combining food in the cauldron.
  cauldron;

  /// Create a rarity from a json string.
  factory ItemRarity.fromJson(String json) {
    return ItemRarity.values.firstWhere((e) => e.name == json);
  }

  /// Convert the rarity to a json string.
  String toJson() => name;
}

/// Represents the tags on the item.
enum ItemTag {
  /// Food, can be combined in the cauldron.
  food,

  /// Jewelry, interacts with items sensitive to jewelry.
  jewelry,

  /// Wood, interacts with items sensitive to wood.
  wood,

  /// Stone, interacts with items sensitive to stone.
  stone,

  /// Sanguine
  sanguine,

  /// Bomb
  bomb;

  /// Create a tag from a json string.
  factory ItemTag.fromJson(String json) {
    return ItemTag.values.firstWhere((e) => e.name == json);
  }

  /// Convert the tag to a json string.
  String toJson() => name;
}
