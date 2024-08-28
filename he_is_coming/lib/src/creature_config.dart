import 'dart:math';

import 'package:he_is_coming/src/data.dart';

List<Item> _pickItems(Random random, int count, ItemCatalog itemCatalog) {
  final items = <Item>[
    itemCatalog.randomWeapon(random),
  ];
  while (items.length < count) {
    final item = itemCatalog.randomNonWeapon(random);
    if (item.isUnique && items.any((i) => i.name == item.name)) continue;
    items.add(item);
  }
  return items;
}

/// Configuration for a creature.
class CreatureConfig {
  /// Create a new creature configuration.
  CreatureConfig({
    required this.items,
    required this.edge,
    required this.oils,
  });

  /// Create a random creature configuration.
  factory CreatureConfig.random(Random random, Data data) {
    final items = _pickItems(random, 9, data.items);
    // Most edges are strictly beneficial, so just pick one at random.
    final edge = data.edges.random(random);
    // Currently there are only 3 oils, you can always only use each once.
    // No need to support random oils.
    if (data.oils.oils.length > 3) {
      throw UnimplementedError('Too many oils');
    }
    return CreatureConfig(items: items, edge: edge, oils: data.oils.oils);
  }

  /// Create a creature configuration from JSON.
  factory CreatureConfig.fromJson(Map<String, dynamic> json, Data data) {
    final itemNames = (json['items'] as List).cast<String>();
    final items = itemNames.map<Item>((n) => data.items[n]).toList();
    final edgeName = json['edge'] as String?;
    final edge = edgeName != null ? data.edges[edgeName] : null;
    final oilNames = (json['oils'] as List? ?? []).cast<String>();
    final oils = oilNames.map<Oil>((n) => data.oils[n]).toList();
    return CreatureConfig(items: items, edge: edge, oils: oils);
  }

  /// Create a creature configuration from a player.
  factory CreatureConfig.fromPlayer(Player player) {
    return CreatureConfig(
      items: player.items,
      edge: player.edge,
      oils: player.oils,
    );
  }

  /// Convert this creature configuration to JSON.
  Map<String, dynamic> toJson() {
    return {
      'items': items.map((i) => i.name).toList(),
      'edge': edge?.name,
      'oils': oils.map((o) => o.name).toList(),
    };
  }

  /// The items the creature should have.
  final List<Item> items;

  /// The edge the creature should have.
  final Edge? edge;

  /// The oils the creature should have.
  final List<Oil> oils;
}

/// Create a player from a creature configuration.
Player playerForConfig(CreatureConfig config) {
  return createPlayer(
    items: config.items,
    edge: config.edge,
    oils: config.oils,
  );
}
