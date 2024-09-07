import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:he_is_coming/src/data.dart';

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

/// Encodes and decodes an inventory into a string.
class BuildIdCodec {
  /// Encode the given inventory into a string.
  static String encode(Inventory inventory, Data data) {
    final bits = _BitsBuilder()
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
    return hex.encode(bits.toBytes());
  }

  /// Decode the given string into an inventory.
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
