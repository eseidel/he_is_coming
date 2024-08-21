import 'package:he_is_coming/src/catalog.dart';
import 'package:he_is_coming/src/creature.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/item.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:yaml/yaml.dart';

Oil? _oilFromYaml(YamlMap yaml, LookupEffect lookupEffect) {
  final name = yaml['name'] as String;
  final attack = yaml['attack'] as int? ?? 0;
  final armor = yaml['armor'] as int? ?? 0;
  final speed = yaml['speed'] as int? ?? 0;

  final stats = Stats(
    attack: attack,
    armor: armor,
    speed: speed,
  );
  return Oil(name, stats);
}

/// Class to hold all known Oils.
class OilCatalog {
  /// Create an OilCatalog
  OilCatalog(this.oils);

  /// Create an EdgeCatalog from a yaml file.
  factory OilCatalog.fromFile(String path) {
    final edges = CatalogReader.read(
      path,
      _oilFromYaml,
      orderedKeys.toSet(),
      {}, // No oils have effects in the game yet.
    );
    logger.info('Loaded ${edges.length} from $path');
    return OilCatalog(edges);
  }

  /// All the known keys in the enemies yaml, in sorted order.
  static const List<String> orderedKeys = <String>[
    'name',
    'attack',
    'armor',
    'speed',
  ];

  /// The edges in this catalog.
  final List<Oil> oils;

  /// Lookup an Oil by name.
  Oil operator [](String name) => oils.firstWhere((i) => i.name == name);
}
