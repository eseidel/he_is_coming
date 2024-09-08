import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:meta/meta.dart';

/// Used to build up a list of bytes from a series values and bit widths.
class BitsBuilder {
  final BytesBuilder _builder = BytesBuilder();
  int _currentByte = 0;
  int _bitsUsed = 0;

  /// Number of bits currently written to this builder.  Should always be
  /// equal to the sum of the bits passed to add().
  int get bitsWritten => _builder.length * 8 + _bitsUsed;

  void _pushCurrentByte() {
    if (_bitsUsed > 0) {
      _builder.addByte(_currentByte);
      _currentByte = 0;
      _bitsUsed = 0;
    }
  }

  /// Add the given value to the bit stream using the given number of bits.
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
        _pushCurrentByte();
      }
    }
  }

  /// Convert the current state of the builder to a list of bytes.
  /// Will convert the last byte to a byte if there are any bits left.
  Uint8List takeBytes() {
    _pushCurrentByte();
    return _builder.takeBytes();
  }
}

/// Used to read a series of bits from a list of bytes.
class BitsReader {
  /// Create a new bits reader.
  BitsReader(this.bytes);

  /// The bytes to read from.
  final Uint8List bytes;
  int _byteIndex = 0;
  int _bitIndex = 0;

  /// The number of bits remaining to be read.
  int get remainingBits => (bytes.length - _byteIndex) * 8 - _bitIndex;

  /// Read the given number of bits from the stream and update the current
  /// position.
  int read(int bits) {
    if (bits < 0) {
      throw ArgumentError.value(bits, 'bits', 'must be non-negative');
    }
    if (bits == 0) return 0;
    if (bits > 32) {
      throw ArgumentError.value(bits, 'bits', 'must be <= 32');
    }
    var value = 0;
    // Shadows the `remainingBits` getter (it's not needed in this scope).
    var remainingBits = bits;
    while (remainingBits > 0) {
      final bitsToRead = min(remainingBits, max(8 - _bitIndex, 0));
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

/// A build state is a combination of a level and an inventory.
@immutable
class BuildState {
  /// Create a new build state.
  const BuildState(this.level, this.inventory);

  /// Current level.
  final Level level;

  /// The inventory of the build.
  final Inventory inventory;
}

/// Encodes and decodes an inventory into a string.
class BuildIdCodec {
  static int _bitsNeededFor(int value) {
    if (value == 0) return 0;
    return (log(value) / ln2).ceil();
  }

  static final int _levelBits = _bitsNeededFor(Level.values.length);

  /// Encode the given inventory into a string.
  static String encode(BuildState state, Data data) {
    final inventory = state.inventory;
    final bits = BitsBuilder()
      ..add(state.level.index, _levelBits)
      ..add(data.edges.toId(inventory.edge), data.edges.idBits);
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
      bits.add(data.items.toId(item), data.items.idBits);
    }
    return hex.encode(bits.takeBytes());
  }

  /// Try to decode the given string into an inventory.
  static BuildState? tryDecode(String encoded, Data data) {
    try {
      return decode(encoded, data);
    } catch (e) {
      return null;
    }
  }

  /// Decode the given string into an inventory.
  static BuildState decode(String encoded, Data data) {
    final bytes = Uint8List.fromList(hex.decode(encoded));
    final bits = BitsReader(bytes);
    final levelIndex = bits.read(_levelBits);
    final level = Level.values[levelIndex];
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
    while (bits.remainingBits >= data.items.idBits) {
      final itemId = bits.read(data.items.idBits);
      items.add(data.items.fromId(itemId)!);
    }
    final paddingBits = bits.remainingBits;
    if (paddingBits > 0) {
      final padding = bits.read(paddingBits);
      if (padding != 0) {
        throw ArgumentError('Unexpected padding bits: $padding');
      }
    }
    return BuildState(
      level,
      Inventory(
        level: level,
        items: items,
        edge: edge,
        oils: oils,
        setBonuses: data.sets,
      ),
    );
  }
}
