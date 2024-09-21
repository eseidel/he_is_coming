import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Extensions for reading yaml files.
extension LookupOr on YamlMap {
  /// Lookup a key in the yaml, and return the value if it exists.
  /// If the key is missing, return the default value.
  T? get<T extends Enum>(String key, List<T> values) {
    final toFind = this[key] as String?;
    if (toFind == null) {
      return null;
    }
    final found = values.firstWhereOrNull((v) => v.name == toFind);
    if (found == null) {
      throw Exception('Unexpected $toFind in $this, expected in $values');
    }
    return found;
  }

  /// Lookup a key in the yaml, and return the value if it exists.
  /// If the key is missing, throw an exception.
  T expect<T extends Enum>(String key, List<T> values) {
    final toFind = this[key] as String?;
    if (toFind == null) {
      throw Exception('$key is missing from $this');
    }
    final found = values.firstWhereOrNull((v) => v.name == toFind);
    if (found == null) {
      throw Exception('Unexpected $toFind in $this, expected in $values');
    }
    return found;
  }
}

/// Read a yaml file and validate the keys.
class CatalogReader {
  /// Validate the keys in the json.
  static void validateKeys(
    YamlMap yaml,
    Set<String> expectedKeys,
  ) {
    final unexpected = yaml.keys.toSet().difference(expectedKeys);
    if (unexpected.isEmpty) {
      return;
    }
    for (final key in unexpected) {
      logger.err('Unexpected key: $key in $yaml allowed: $expectedKeys');
    }
    throw StateError('Unexpected keys: $unexpected in $yaml');
  }

  /// Read a yaml file and return a list of items.
  static List<T> parseYaml<T extends Object>(
    YamlList yaml,
    T Function(YamlMap, LookupEffect) fromYaml,
    Set<String> validKeys,
    EffectCatalog effects,
  ) {
    return yaml
        .cast<YamlMap>()
        .map<T?>((yaml) {
          validateKeys(yaml, validKeys);
          return fromYaml(yaml, effects.lookup);
        })
        .nonNulls
        .toList();
  }
}

/// An item in the catalog.
abstract class CatalogItem {
  /// Create a catalog item with a name.
  CatalogItem({
    required this.name,
    required this.id,
    required this.version,
    this.effect,
    this.inferred = false,
  });

  /// The name of the item.
  final String name;

  /// The version the item was last validated in.
  final String? version;

  /// The effect of the item.
  final Effect? effect;

  /// The id of the item.
  /// Currently these are only unique within the catalog, not across catalogs.
  final int id;

  /// Returns true if the item has been fully implemented.
  bool get isImplemented => effect == null || !effect!.isEmpty;

  /// If the item was inferred rather  than seen in the wild.
  final bool inferred;

  /// The multiplier for the effect.
  // Should this move onto Item?
  int get effectMultiplier {
    if (name.startsWith('Golden')) {
      return 2;
    }
    if (name.startsWith('Diamond')) {
      return 4;
    }
    return 1;
  }

  @override
  String toString() => name;

  /// Convert the item to a json map.
  dynamic toJson();

  /// Copy the item with a new id.
  CatalogItem copyWith({int? id});
}

/// A catalog of items.
abstract class Catalog<T extends CatalogItem> {
  /// Create a catalog from a list of items.
  Catalog(this.items, {required int? idBits})
      : idBits = idBits ?? _bitsNeededFor(items.length) {
    if (this.idBits < _bitsNeededFor(items.length)) {
      throw ArgumentError('Not enough bits for ${items.length} items');
    }
    final seenIds = <int>{};
    for (final item in items) {
      if (seenIds.contains(item.id)) {
        throw ArgumentError('Duplicate id: ${item.id} in $T catalog');
      }
      seenIds.add(item.id);
    }
    final seenNames = <String>{};
    for (final item in items) {
      if (seenNames.contains(item.name)) {
        throw ArgumentError('Duplicate name: ${item.name} in $T catalog');
      }
      seenNames.add(item.name);
    }
  }

  /// Create a catalog from a list of items.
  Catalog copyWith({List<T>? items});

  /// The items in the catalog.
  final List<T> items;

  /// Number of bits needed to represent the id.
  final int idBits;

  bool _removeEmptyValues(dynamic json) {
    if (json is Map) {
      final keys = json.keys.toList();
      for (final key in keys) {
        final value = json[key];
        if (value is Map || value is List) {
          if (_removeEmptyValues(value)) {
            json.remove(key);
          }
        } else if (value == null) {
          json.remove(key);
        }
      }
      return json.isEmpty;
    } else if (json is List) {
      for (var i = 0; i < json.length; i++) {
        if (_removeEmptyValues(json[i])) {
          json.removeAt(i);
          i--;
        }
      }
      return json.isEmpty;
    }
    return false;
  }

  /// Save the catalog to a yaml file.
  void save(String path) {
    final json = toJson();
    _removeEmptyValues(json);

    final yamlEditor = YamlEditor('')..update([], json);
    final sortedItemsYaml = yamlEditor.toString();
    File(path).writeAsStringSync(sortedItemsYaml);
  }

  /// Get an item by name or return null if it doesn't exist.
  T? get(String name) => items.firstWhereOrNull((item) => item.name == name);

  /// Get an item by name, or throw an exception if it doesn't exist.
  T operator [](String name) {
    final item = get(name);
    if (item == null) {
      throw Exception('Missing $name in $T catalog');
    }
    return item;
  }

  /// Number of items in the catalog.
  int get length => items.length;

  static int _bitsNeededFor(int value) {
    if (value == 0) return 0;
    return (log(value) / ln2).ceil();
  }

  /// Convert an id to an item.  0 represents null.
  T? fromId(int id) {
    if (id == 0) {
      return null;
    }
    return items.firstWhereOrNull((item) => item.id == id);
  }

  /// Get a random item.
  T random(Random random) => items[random.nextInt(items.length)];

  /// Get a random item or null.
  T? randomIncludingNull(Random random) {
    final count = items.length + 1;
    final index = random.nextInt(count);
    if (index == items.length) {
      return null;
    }
    return items[index];
  }

  /// Convert the catalog to a json list.
  List<dynamic> toJson() {
    final sorted = items.toList()..sort((a, b) => a.name.compareTo(b.name));
    return sorted.map((item) => item.toJson()).toList();
  }
}
