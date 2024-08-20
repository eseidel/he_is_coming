import 'dart:io';

import 'package:he_is_coming/src/item_catalog.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

int compareItemKeys(String a, String b) {
  const order = ItemCatalog.orderedItemKeys;
  final aIndex = order.indexOf(a);
  final bIndex = order.indexOf(b);
  if (aIndex == -1) {
    throw StateError('Unexpected key: $a');
  }
  if (bIndex == -1) {
    throw StateError('Unexpected key: $b');
  }
  return aIndex.compareTo(bIndex);
}

void main() {
  final itemsPath = p.join('data', 'items.yaml');
  final itemsFile = File(itemsPath);
  final itemsYaml = itemsFile.readAsStringSync();
  final originalItems = loadYaml(itemsYaml) as YamlList;

  // convert items to a list of maps
  final items = <Map<String, dynamic>>[];
  // Now build a map of items, sorting keys
  for (var i = 0; i < originalItems.length; i++) {
    final item = originalItems[i] as YamlMap;
    final sortedItem = <String, dynamic>{};
    for (final key in item.keys.toList().cast<String>()
      ..sort(compareItemKeys)) {
      sortedItem[key] = item[key];
    }
    items.add(sortedItem);
  }
  items.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

  // Convert jsonValue to YAML
  final yamlEditor = YamlEditor('')..update([], items);
  final sortedItemsYaml = yamlEditor.toString();
  itemsFile.writeAsStringSync(sortedItemsYaml);
}
