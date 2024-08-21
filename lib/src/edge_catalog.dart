import 'dart:math';

import 'package:he_is_coming/src/catalog.dart';
import 'package:he_is_coming/src/creature.dart';
import 'package:he_is_coming/src/edge_effects.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:yaml/yaml.dart';

Edge? _edgeFromYaml(YamlMap yaml, LookupEffect lookupEffect) {
  final name = yaml['name'] as String;
  final effectText = yaml['effect'] as String?;
  final effects = lookupEffect(name);
  if (effectText != null && effects == null) {
    return null;
  }

  return Edge(name, effects);
}

/// Class to hold all known edges.
class EdgeCatalog {
  /// Create an EdgeCatalog
  EdgeCatalog(this.edges);

  /// Create an EdgeCatalog from a yaml file.
  factory EdgeCatalog.fromFile(String path) {
    final edges = CatalogReader.read(
      path,
      _edgeFromYaml,
      orderedKeys.toSet(),
      edgeEffects,
    );
    logger.info('Loaded ${edges.length} from $path');
    return EdgeCatalog(edges);
  }

  /// All the known keys in the enemies yaml, in sorted order.
  static const List<String> orderedKeys = <String>[
    'name',
    'unlock', // ignored for now
    'effect',
  ];

  /// The edges in this catalog.
  final List<Edge> edges;

  /// Get a random Edge.
  Edge random(Random random) => edges[random.nextInt(edges.length)];

  /// Lookup an Edge by name.
  Edge operator [](String name) => edges.firstWhere((i) => i.name == name);
}
