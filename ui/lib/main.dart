import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/item.dart' as i;

void main() {
  runApp(const MyApp());
}

/// MyApp widget
class MyApp extends StatelessWidget {
  /// MyApp constructor
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

/// MyHomePage widget
class MyHomePage extends StatefulWidget {
  /// MyHomePage constructor
  const MyHomePage({required this.title, super.key});

  /// Title
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

extension on i.Item {
  Color get color {
    if (kind == i.Kind.weapon) {
      return Colors.red;
    }
    if (material == i.Material.stone) {
      return Colors.grey;
    }
    if (material == i.Material.sanguine) {
      return Colors.red;
    }
    return Colors.orange;
  }

  IconData get icon {
    return Icons.help;
  }

  String get description {
    final parts = <String>[];
    if (effect != null) {
      parts.add(effect!.text);
    }
    if (stats.attack > 0) {
      parts.add('⚔️ ${stats.attack}');
    }
    if (stats.maxHp > 0) {
      parts.add('❤️ ${stats.maxHp}');
    }
    if (stats.armor > 0) {
      parts.add('🛡️ ${stats.armor}');
    }
    if (stats.speed > 0) {
      parts.add('👟 ${stats.speed}');
    }
    // Tags
    if (isUnique) {
      parts.add('unique');
    }
    if (kind == i.Kind.food) {
      parts.add('food');
    }
    if (kind == i.Kind.jewelry) {
      parts.add('jewelry');
    }
    if (material == i.Material.stone) {
      parts.add('stone');
    }
    if (material == i.Material.sanguine) {
      parts.add('sanguine');
    }
    if (material == i.Material.wood) {
      parts.add('wood');
    }
    return parts.join(' ');
  }
}

class ItemView extends StatelessWidget {
  const ItemView({
    required this.item,
    super.key,
  });
  final i.Item item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(item.icon, color: item.color),
      title: Text(item.name),
      subtitle: Text(item.description),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  bool isLoading = true;
  late final Data data;

  @override
  void initState() {
    super.initState();
    isLoading = true;
    loadData().then((value) {
      setState(() {
        data = value;
        isLoading = false;
      });
    });
  }

  Future<Data> loadData() async {
    final creatures =
        rootBundle.loadString('packages/he_is_coming/data/creatures.yaml');
    final items =
        rootBundle.loadString('packages/he_is_coming/data/items.yaml');
    final edges =
        rootBundle.loadString('packages/he_is_coming/data/edges.yaml');
    final oils =
        rootBundle.loadString('packages/he_is_coming/data/blade_oils.yaml');
    return Data.fromStrings(
      creatures: creatures,
      items: items,
      edges: edges,
      oils: oils,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : ListView.builder(
                itemCount: data.items.items.length,
                itemBuilder: (context, index) {
                  return ItemView(item: data.items.items[index]);
                },
              ),
      ),
    );
  }
}
