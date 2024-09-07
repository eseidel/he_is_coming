import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:yaml/yaml.dart';

/// ItemException
class ItemException implements Exception {
  /// Create ItemException
  ItemException(this.message);

  /// Message
  final String message;
}

class _BitsBuilder {
  final BytesBuilder _builder = BytesBuilder();
  int _currentByte = 0;
  int _bitsUsed = 0;

  void add(int value, int bits) {
    var remainingValue = value;
    var remainingBits = bits;
    if (bits < 0) {
      throw ArgumentError.value(bits, 'bits', 'must be non-negative');
    }
    if (bits == 0) return;
    if (bits > 32) {
      throw ArgumentError.value(bits, 'bits', 'must be <= 32');
    }
    if (value < 0) {
      throw ArgumentError.value(value, 'value', 'must be non-negative');
    }
    if (value >= (1 << bits)) {
      throw ArgumentError.value(value, 'value', 'must fit in $bits bits');
    }

    while (remainingBits > 0) {
      final bitsToAdd = min(remainingBits, 8 - _bitsUsed);
      final bitsToShift = remainingBits - bitsToAdd;
      final bitsToKeep = bitsToAdd;
      final bitsToShiftedValue = remainingValue >> bitsToShift;
      final bitsToMask = (1 << bitsToKeep) - 1;
      final bitsToShiftedValueMasked = bitsToShiftedValue & bitsToMask;
      final bitsToShiftedValueMaskedShifted =
          bitsToShiftedValueMasked << (8 - _bitsUsed - bitsToAdd);
      _currentByte |= bitsToShiftedValueMaskedShifted;
      remainingValue &= (1 << bitsToShift) - 1;
      remainingBits -= bitsToAdd;
      _bitsUsed += bitsToAdd;
      if (_bitsUsed == 8) {
        _builder.addByte(_currentByte);
        _currentByte = 0;
        _bitsUsed = 0;
      }
    }
  }

  Uint8List toBytes() {
    if (_bitsUsed > 0) {
      _builder.addByte(_currentByte);
    }
    return _builder.toBytes();
  }
}

class _BitsReader {
  _BitsReader(this.bytes);

  final Uint8List bytes;
  int _byteIndex = 0;
  int _bitIndex = 0;

  int get remainingBits => (bytes.length - _byteIndex) * 8 - _bitIndex;

  int read(int bits) {
    var value = 0;
    var remainingBits = bits;
    while (remainingBits > 0) {
      if (_byteIndex >= bytes.length) {
        throw ArgumentError('Not enough bits to read');
      }
      final bitsToRead = min(remainingBits, 8 - _bitIndex);
      final bitsToShift = remainingBits - bitsToRead;
      final bitsToShiftedValue =
          bytes[_byteIndex] >> (8 - _bitIndex - bitsToRead);
      final bitsToMask = (1 << bitsToRead) - 1;
      final bitsToShiftedValueMasked = bitsToShiftedValue & bitsToMask;
      final bitsToShiftedValueMaskedShifted =
          bitsToShiftedValueMasked << bitsToShift;
      value |= bitsToShiftedValueMaskedShifted;
      remainingBits -= bitsToRead;
      _bitIndex += bitsToRead;
      if (_bitIndex == 8) {
        _byteIndex++;
        _bitIndex = 0;
      }
    }
    return value;
  }
}

class _InventoryCodec {
  _InventoryCodec(this.data);

  final Data data;

  /// Number of bits needed to encode an edge.
  int get edgeBits => data.edges.idBits;

  /// Number of bits needed to encode an item.
  int get itemBits => data.items.idBits;

  /// Number of bits needed to encode a set bonus.
  int get setBonusBits => data.sets.idBits;

  String encode(Inventory inventory) {
    final bits = _BitsBuilder()..add(data.edges.toId(inventory.edge), edgeBits);
    // Encode oils as a 3-bit bitfield since there are only 3 of them.
    var bitfield = 0;
    for (var i = 0; i < data.oils.length; i++) {
      final oil = data.oils.items[i];
      if (inventory.oils.contains(oil)) {
        bitfield |= 1 << i;
      }
    }
    bits.add(bitfield, 3);
    for (final item in inventory.items) {
      bits.add(data.items.toId(item), itemBits);
    }
    return hex.encode(bits.toBytes());
  }

  static Inventory decode(String encoded, Data data) {
    final bytes = Uint8List.fromList(hex.decode(encoded));
    final bits = _BitsReader(bytes);
    final edgeId = bits.read(data.edges.idBits);
    final edge = data.edges.fromId(edgeId);
    final oils = <Oil>[];
    final oilBitfield = bits.read(3);
    for (var i = 0; i < data.oils.length; i++) {
      if ((oilBitfield & (1 << i)) != 0) {
        oils.add(data.oils.items[i]);
      }
    }
    final items = <Item>[];
    while (bits.remainingBits > 0) {
      final itemId = bits.read(data.items.idBits);
      items.add(data.items.fromId(itemId)!);
    }
    return Inventory(
      level: Level.one,
      items: items,
      edge: edge,
      oils: oils,
      setBonuses: data.sets,
    );
  }
}

/// Player's inventory.
class Inventory {
  /// Create an inventory.
  Inventory({
    required Level level,
    required List<Item> items,
    required this.edge,
    required this.oils,
    required SetBonusCatalog setBonuses,
  }) {
    this.items = _enforceItemRules(level, items);
    if (oils.length > 3) {
      throw UnimplementedError('Too many oils');
    }
    sets = _resolveSetBonuses(this.items, edge, setBonuses);
  }

  /// Create an inventory from a url string.
  factory Inventory.fromUrlString(String encoded, Data data) {
    return _InventoryCodec.decode(encoded, data);
  }

  /// Create a random creature configuration.
  factory Inventory.random(Level level, Random random, Data data) {
    final slotCount = itemSlotCount(level);
    final items = _pickItems(random, slotCount, data.items);
    // Most edges are strictly beneficial, so just pick one at random.
    final edge = data.edges.random(random);
    // Currently there are only 3 oils, you can always only use each once.
    // No need to support random oils.
    final oils = data.oils.oils.toList();
    return Inventory(
      level: level,
      items: items,
      edge: edge,
      oils: oils,
      setBonuses: data.sets,
    );
  }

  /// Create an inventory from json.
  /// This expects names, not full item definitions.
  factory Inventory.fromJson(
    Map<String, dynamic> json,
    Level level,
    Data data,
  ) {
    final edge =
        json['edge'] != null ? data.edges[json['edge'] as String] : null;
    final oils = (json['oils'] as List? ?? [])
        .map<Oil>((name) => data.oils[name as String])
        .toList();
    final items = (json['items'] as List? ?? [])
        .map<Item>((name) => data.items[name as String])
        .toList();
    return Inventory(
      level: level,
      items: items,
      edge: edge,
      oils: oils,
      setBonuses: data.sets,
    );
  }

  /// Create an empty inventory.
  Inventory.empty()
      : edge = null,
        oils = const <Oil>[],
        items = [];

  static List<SetBonus> _resolveSetBonuses(
    List<Item> items,
    Edge? edge,
    SetBonusCatalog setBonuses,
  ) {
    String baseName(Item item) {
      final name = item.name;
      if (name.startsWith('Golden ')) {
        return name.substring(7);
      }
      if (name.startsWith('Diamond ')) {
        return name.substring(8);
      }
      return name;
    }

    // Gather all "names" in the inventory.
    final names = {
      for (final item in items) baseName(item),
      if (edge != null) edge.name,
    };
    // Walk through the set bonuses and see if any of them are satisfied.
    return setBonuses.items.where((bonus) {
      return bonus.parts.every(names.contains);
    }).toList();
  }

  /// Returns number of item slots for the level.
  static int itemSlotCount(Level level) {
    // 8 normal slots, 1 weapon.
    return switch (level) {
      Level.one => 5,
      Level.two => 7,
      Level.three => 9,
      Level.end => 9,
    };
  }

  static List<Item> _pickItems(
    Random random,
    int count,
    ItemCatalog itemCatalog,
  ) {
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

  static List<Item> _enforceItemRules(Level level, List<Item> unenforced) {
    if (unenforced.length > itemSlotCount(level)) {
      throw ItemException('Too many items for level $level.');
    }

    // Player must always have a weapon.
    final items = [...unenforced];
    if (items.every((item) => item.kind != ItemKind.weapon)) {
      items.add(Creature.defaultPlayerWeapon);
    }

    final itemCounts = items.fold<Map<String, int>>(
      {},
      (counts, item) =>
          counts..update(item.name, (count) => count + 1, ifAbsent: () => 1),
    );
    for (final entry in itemCounts.entries) {
      if (entry.value > 1) {
        final item = items.firstWhere((item) => item.name == entry.key);
        if (item.isUnique) {
          throw ItemException(
            '${item.name} is unique and can only be equipped once.',
          );
        }
      }
    }

    final weaponCount = items.where((item) => item.isWeapon).length;
    if (weaponCount > 1) {
      throw ItemException('Player can only have one weapon.');
    }

    // Weapon is always first.
    items.sortBy<num>((item) => item.isWeapon ? 0 : 1);
    return items;
  }

  /// Resolve stats with items.
  Stats statsWithItems(Stats intrinsic) {
    return [
      ...items.map((item) => item.stats),
      ...oils.map((oil) => oil.stats),
      ...sets.map((set) => set.stats),
    ].fold<Stats>(
      intrinsic,
      (acc, stats) => acc + stats,
    );
  }

  /// The edge on the weapon.
  final Edge? edge;

  /// Oils applied to the weapon.
  final List<Oil> oils;

  /// Items in the inventory.
  late final List<Item> items;

  /// Set bonuses applied to the inventory.
  late final List<SetBonus> sets;

  /// Count of items in the inventory.
  int materialCount(ItemMaterial material) {
    return items.where((item) => item.material == material).length;
  }

  /// Count of items in the inventory.
  int kindCount(ItemKind kind) {
    return items.where((item) => item.kind == kind).length;
  }

  /// Convert to json.
  Map<String, dynamic> toJson() {
    // This is not meant for defining items, so we only serialize the names.
    return {
      if (items.isNotEmpty) 'items': items.map((item) => item.name).toList(),
      if (edge != null) 'edge': edge!.name,
      if (oils.isNotEmpty) 'oils': oils.map((oil) => oil.name).toList(),
    };
  }

  /// Convert to a url string.
  String toUrlString(Data data) => _InventoryCodec(data).encode(this);

  /// Copy with changes.
  Inventory copyWith({
    required Level level,
    required SetBonusCatalog setBonuses,
    Edge? edge,
    List<Oil>? oils,
    List<Item>? items,
  }) {
    return Inventory(
      level: level,
      edge: edge ?? this.edge,
      oils: oils ?? this.oils,
      items: items ?? this.items,
      setBonuses: setBonuses,
    );
  }
}

/// Oil applied to a weapon.
class Oil extends CatalogItem {
  /// Create an Oil
  Oil({required super.name, required this.stats});

  /// Create an Oil from a yaml map.
  factory Oil.fromYaml(YamlMap yaml, LookupEffect _) {
    final name = yaml['name'] as String;
    final attack = yaml['attack'] as int? ?? 0;
    final armor = yaml['armor'] as int? ?? 0;
    final speed = yaml['speed'] as int? ?? 0;

    final stats = Stats(
      attack: attack,
      armor: armor,
      speed: speed,
    );
    return Oil(name: name, stats: stats);
  }

  /// The stats of the oil.
  final Stats stats;

  @override
  String toString() => name;

  /// All the known keys in the oils yaml, in sorted order.
  static const List<String> orderedKeys = <String>[
    'name',
    'attack',
    'armor',
    'speed',
  ];

  /// Convert to json.
  @override
  dynamic toJson() => <String, dynamic>{
        'name': name,
        ...stats.toJson(),
      };
}

/// An edge is a special effect that can be applied to a weapon.
class Edge extends CatalogItem {
  /// Create an Edge
  Edge({required super.name, required super.effect});

  /// Create an Edge from a yaml map.
  factory Edge.fromYaml(YamlMap yaml, LookupEffect lookupEffect) {
    final name = yaml['name'] as String;
    final effectText = yaml['effect'] as String?;
    final effect = lookupEffect(name: name, effectText: effectText);
    return Edge(name: name, effect: effect);
  }

  @override
  String toString() => name;

  @override
  dynamic toJson() {
    return {
      'name': name,
      'effect': effect?.toJson(),
    };
  }
}
