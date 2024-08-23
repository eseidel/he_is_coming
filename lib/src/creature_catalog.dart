import 'package:he_is_coming/src/catalog.dart';
import 'package:he_is_coming/src/creature.dart';
import 'package:he_is_coming/src/creature_effects.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/item.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:yaml/yaml.dart';

Creature? _creatureFromYaml(YamlMap yaml, LookupEffect lookupEffect) {
  final name = yaml['name'] as String;
  final level = yaml['level'] as int?;
  final attack = yaml['attack'] as int? ?? 0;
  final health = yaml['health'] as int? ?? 0;
  final armor = yaml['armor'] as int? ?? 0;
  final speed = yaml['speed'] as int? ?? 0;
  final effectText = yaml['effect'] as String?;
  final effect = lookupEffect(name: name, effectText: effectText);
  return Creature(
    name: name,
    level: level,
    intrinsic: Stats(
      maxHp: health,
      armor: armor,
      attack: attack,
      speed: speed,
    ),
    gold: 1,
    effect: effect,
  );
}

/// Class to hold all known creatures.
class CreatureCatalog extends Catalog<Creature> {
  /// Create an CreatureCatalog
  CreatureCatalog(super.creatures);

  /// Create an CreatureCatalog from a yaml file.
  factory CreatureCatalog.fromFile(String path) {
    final creatures = CatalogReader.read(
      path,
      _creatureFromYaml,
      orderedKeys.toSet(),
      creatureEffects,
    );
    logger.info('Loaded ${creatures.length} from $path');
    return CreatureCatalog(creatures);
  }

  /// All the known keys in the creatures yaml, in sorted order.
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
  List<Creature> get creatures => items;

  /// Lookup an Creature by name.
  @override
  Creature operator [](String name) =>
      creatures.firstWhere((i) => i.name == name);
}
