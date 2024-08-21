import 'package:he_is_coming/src/catalog.dart';
import 'package:he_is_coming/src/creature.dart';
import 'package:he_is_coming/src/creature_effects.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:yaml/yaml.dart';

Creature? _creatureFromYaml(YamlMap yaml, LookupEffect lookupEffect) {
  final name = yaml['name'] as String;
  final attack = yaml['attack'] as int? ?? 0;
  final health = yaml['health'] as int? ?? 0;
  final armor = yaml['armor'] as int? ?? 0;
  final speed = yaml['speed'] as int? ?? 0;
  final effectText = yaml['effect'] as String?;
  final effects = lookupEffect(name);
  if (effectText != null && effects == null) {
    return null;
  }

  return makeEnemy(
    name,
    health: health,
    attack: attack,
    armor: armor,
    speed: speed,
    effects: effects,
  );
}

/// Class to hold all known items.
class CreatureCatalog {
  /// Create an CreatureCatalog
  CreatureCatalog(this.creatures);

  /// Create an CreatureCatalog from a yaml file.
  factory CreatureCatalog.fromFile(String path) {
    // Effects not implemented for creatures yet.
    final creatures = CatalogReader.read(
      path,
      _creatureFromYaml,
      orderedKeys.toSet(),
      creatureEffects,
    );
    logger.info('Loaded ${creatures.length} from $path');
    return CreatureCatalog(creatures);
  }

  /// All the known keys in the enemies yaml, in sorted order.
  static const List<String> orderedKeys = <String>[
    'name',
    'unlock', // ignored for now
    'level', // ignored for now
    'attack',
    'health',
    'armor',
    'speed',
    'effect',
  ];

  /// The creatures in this catalog.
  final List<Creature> creatures;

  /// Lookup an Creature by name.
  Creature operator [](String name) =>
      creatures.firstWhere((i) => i.name == name);
}
