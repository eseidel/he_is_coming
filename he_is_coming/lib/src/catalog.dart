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
    throw StateError('Unexpected keys');
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
    this.effect,
    this.inferred = false,
  });

  /// The name of the item.
  final String name;

  /// The effect of the item.
  final Effect? effect;

  /// Returns true if the item has been fully implemented.
  bool get isImplemented => effect == null || !effect!.isEmpty;

  /// If the item was inferred rather  than seen in the wild.
  final bool inferred;

  @override
  String toString() => name;

  /// Convert the item to a json map.
  dynamic toJson();
}

/// A catalog of items.
class Catalog<T extends CatalogItem> {
  /// Create a catalog from a list of items.
  Catalog(this.items);

  /// The items in the catalog.
  final List<T> items;

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

  /// Get a random item.
  T random(Random random) => items[random.nextInt(items.length)];

  /// Convert the catalog to a json list.
  List<dynamic> toJson() {
    final sorted = items.toList()..sort((a, b) => a.name.compareTo(b.name));
    return sorted.map((item) => item.toJson()).toList();
  }
}
