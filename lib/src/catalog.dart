import 'dart:io';

import 'package:collection/collection.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:yaml/yaml.dart';

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
  /// Validate the keys in the yaml.
  static void validateKeys(YamlMap yaml, Set<String> expectedKeys) {
    final unexpected =
        yaml.keys.cast<String>().toSet().difference(expectedKeys);
    if (unexpected.isEmpty) {
      return;
    }
    for (final key in unexpected) {
      logger.err('Unexpected key: $key in $yaml allowed: $expectedKeys');
    }
    throw StateError('Unexpected keys in yaml');
  }

  static String _pluralize(String typeName) => '${typeName}s';

  static void _warnAboutMissingEffects(
    YamlList itemsYaml,
    EffectCatalog effectsByName,
    String typeName,
  ) {
    final itemYamlWithEffectText = itemsYaml
        .cast<YamlMap>()
        .where((yaml) => yaml['effect'] != null)
        .toSet();
    final itemsWithEffectText =
        itemYamlWithEffectText.map((yaml) => yaml['name'] as String).toSet();
    final itemsWithEffects = effectsByName.keys.toSet();
    final missingEffects = itemsWithEffectText.difference(itemsWithEffects);
    if (missingEffects.isNotEmpty) {
      logger.warn(
        '${missingEffects.length} ${_pluralize(typeName)} '
        'have effect text but no code:',
      );
      for (final item in missingEffects) {
        final yaml =
            itemYamlWithEffectText.firstWhere((yaml) => yaml['name'] == item);
        logger.info('${yaml['effect']}, for $item');
      }
      logger.info(''); // Add a newline.
    }
    final unusedEffects = itemsWithEffects.difference(itemsWithEffectText);
    if (unusedEffects.isNotEmpty) {
      logger.warn('Unused effects for: $unusedEffects');
    }
  }

  /// Read a yaml file and return a list of items.
  static List<T> read<T extends Object>(
    String path,
    T? Function(YamlMap, LookupEffect) fromYaml,
    Set<String> validKeys,
    EffectCatalog effectsCatalog, {
    bool warnAboutMissingEffects = true,
  }) {
    final yamlList = loadYaml(File(path).readAsStringSync()) as YamlList;
    if (warnAboutMissingEffects) {
      _warnAboutMissingEffects(yamlList, effectsCatalog, T.toString());
    }
    Effect? lookupEffect(String name) => effectsCatalog[name];

    return yamlList
        .cast<YamlMap>()
        .map<T?>((yaml) {
          validateKeys(yaml, validKeys);
          return fromYaml(yaml, lookupEffect);
        })
        .nonNulls
        .toList();
  }
}

/// An item in the catalog.
abstract class CatalogItem {
  /// Create a catalog item with a name.
  CatalogItem({required this.name});

  /// The name of the item.
  final String name;

  @override
  String toString() {
    return name;
  }

  /// Convert the item to a json map.
  dynamic toJson();
}

/// A catalog of items.
class Catalog<T extends CatalogItem> {
  /// Create a catalog from a list of items.
  Catalog(this.items);

  /// The items in the catalog.
  final List<T> items;

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

  /// Convert the catalog to a json list.
  List<dynamic> toJson() => items.map((i) => i.toJson()).toList();
}
