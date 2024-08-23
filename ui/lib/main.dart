import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:he_is_coming/src/data.dart';

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
            : Text(data.creatures.creatures.first.name),
      ),
    );
  }
}
