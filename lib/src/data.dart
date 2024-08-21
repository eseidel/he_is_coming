import 'package:he_is_coming/src/creature_catalog.dart';
import 'package:he_is_coming/src/edge_catalog.dart';
import 'package:he_is_coming/src/item_catalog.dart';
import 'package:path/path.dart' as p;

export 'package:he_is_coming/src/creature_catalog.dart';
export 'package:he_is_coming/src/item_catalog.dart';

final _creaturesPath = p.join('data', 'creatures.yaml');
final _defaultItemsPath = p.join('data', 'items.yaml');
final _edgesPath = p.join('data', 'edges.yaml');

/// The data for the game.
class Data {
  /// Create a new data object.
  Data({required this.creatures, required this.items, required this.edges});

  /// Load the data from the yaml files.
  factory Data.load() {
    final creatures = CreatureCatalog.fromFile(_creaturesPath);
    final items = ItemCatalog.fromFile(_defaultItemsPath);
    final edges = EdgeCatalog.fromFile(_edgesPath);
    return Data(creatures: creatures, items: items, edges: edges);
  }

  /// The creatures in this catalog.
  final CreatureCatalog creatures;

  /// The items in this catalog.
  final ItemCatalog items;

  /// The edges in this catalog.
  final EdgeCatalog edges;
}

/// Global data object.
late final Data data;
