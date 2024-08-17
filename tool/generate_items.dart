import 'dart:io';

import 'package:collection/collection.dart';
import 'package:he_is_coming_sim/src/item.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

Item itemFromYaml(YamlMap yaml) {
  final name = yaml['name'] as String;
  final yamlKind = yaml['kind'];
  final kind = yamlKind == null
      ? Kind.clothing
      : Kind.values.firstWhere((k) => k.name == yamlKind);
  final rarity = Rarity.values.firstWhere((r) => r.name == yaml['rarity']);
  final yamlMaterial = yaml['material'];
  final material = yamlMaterial == null
      ? Material.leather
      : Material.values.firstWhere((m) => m.name == yamlMaterial);
  // final effect = yaml['effect'] as String?;
  return Item(name, kind, rarity, material);
}

String camelCase(String sentenceCase) {
  final parts = sentenceCase.split(' ');
  final joined = parts.join();
  return joined[0].toLowerCase() + joined.substring(1);
}

Map<String, dynamic> toTemplateMap(Item item) {
  return {
    'camelName': camelCase(item.name),
    'name': item.name,
    'kind': item.kind,
    'rarity': item.rarity,
    'material': item.material,
    'effect': '',
  };
}

// Could turn this into a build_runner extension at some point.
void main() {
  final itemsString = File('items.yaml').readAsStringSync();
  final itemsYaml = loadYaml(itemsString) as YamlList;
  final items = itemsYaml
      .cast<YamlMap>()
      .map<Item>(itemFromYaml)
      .sortedBy<String>((i) => i.name);
  final templateString = File('templates/items.mustache').readAsStringSync();
  final template = Template(templateString, name: 'items.g.dart');

  final output =
      template.renderString({'items': items.map(toTemplateMap).toList()});
  final outPath = p.join('lib', 'src', 'items.g.dart');
  File(outPath).writeAsStringSync(output);

  Process.runSync(Platform.executable, ['format', outPath]);
}
