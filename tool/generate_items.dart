import 'dart:io';

import 'package:collection/collection.dart';
import 'package:he_is_coming_sim/src/item.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

extension Lookup on YamlMap {
  T lookupOr<T extends Enum>(String key, List<T> values, T defaultValue) {
    final toFind = this[key] as String?;
    if (toFind == null) {
      return defaultValue;
    }
    final found = values.firstWhereOrNull((v) => v.name == toFind);
    if (found == null) {
      throw Exception('Unexpected $toFind in $this, expected in $values');
    }
    return found;
  }

  T lookup<T extends Enum>(String key, List<T> values) {
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

Item itemFromYaml(YamlMap yaml) {
  final name = yaml['name'] as String;
  final kind = yaml.lookupOr('kind', Kind.values, Kind.clothing);
  final rarity = yaml.lookup('rarity', Rarity.values);
  final material = yaml.lookupOr('material', Material.values, Material.leather);
  // final effect = yaml['effect'] as String?;
  return Item(name, kind, rarity, material);
}

String camelCase(String sentenceCase) {
  final parts = sentenceCase.split(' ');
  final joined = parts.join().replaceAll('-', '').replaceAll("'", '');
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

int runDartFormat(String path) {
  final result = Process.runSync(Platform.executable, ['format', path]);
  if (result.exitCode != 0) {
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    return result.exitCode;
  }
  return 0;
}

// Could turn this into a build_runner extension at some point.
int main() {
  final itemsPath = p.join('data', 'items.yaml');
  final templatePath = p.join('templates', 'items.mustache');
  final outputPath = p.join('lib', 'src', 'items.g.dart');

  final itemsYaml = loadYaml(File(itemsPath).readAsStringSync()) as YamlList;
  final items = itemsYaml
      .cast<YamlMap>()
      .map<Item>(itemFromYaml)
      .sortedBy<String>((i) => i.name)
      .map(toTemplateMap)
      .toList();

  final templateString = File(templatePath).readAsStringSync();
  final template = Template(templateString, name: p.basename(outputPath));

  final output = template.renderString({'items': items});
  File(outputPath).writeAsStringSync(output);

  return runDartFormat(outputPath);
}
