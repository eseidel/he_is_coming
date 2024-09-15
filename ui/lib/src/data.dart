import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:he_is_coming/he_is_coming.dart';

/// Holds the static data for the game.
class DataHolder extends StatefulWidget {
  /// Constructs a [DataHolder]
  const DataHolder({required this.child, super.key});

  /// The child widget.
  final Widget child;

  @override
  DataHolderState createState() => DataHolderState();
}

/// The state for the [DataHolder].
class DataHolderState extends State<DataHolder> {
  bool _isLoading = true;
  late final Data _data;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _loadData().then((value) {
      setState(() {
        _data = value;
        // TODO(eseidel): Remove defaultPlayerWeapon.
        Creature.defaultPlayerWeapon = _data.items['Wooden Stick'];
        _isLoading = false;
      });
    });
  }

  Future<Data> _loadData() async {
    Future<String> load(String name) {
      return rootBundle.loadString('packages/he_is_coming/data/$name.yaml');
    }

    return Data.fromStrings(
      creatures: load('creatures'),
      edges: load('edges'),
      items: load('items'),
      oils: load('blade_oils'),
      challenges: load('challenges'),
      triggers: load('triggers'),
      sets: load('sets'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return InheritedData(
      data: _data,
      child: widget.child,
    );
  }
}

/// A widget to look up the [Data] from the [InheritedData].
class InheritedData extends InheritedWidget {
  /// Constructs an [InheritedData]
  const InheritedData({
    required super.child,
    required this.data,
    super.key,
  });

  /// The data to inherit.
  final Data data;

  /// Look up the [InheritedData] from the [BuildContext].
  static InheritedData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedData>()!;
  }

  @override
  bool updateShouldNotify(InheritedData oldWidget) {
    return oldWidget.data != data;
  }
}
