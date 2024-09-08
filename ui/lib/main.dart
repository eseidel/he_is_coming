import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:he_is_coming/he_is_coming.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:ui/src/battle.dart';
import 'package:ui/src/compendium.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runScoped(() => runApp(const MyApp()), values: {loggerRef});
}

/// Holds the static data for the game.
class _DataHolder extends StatefulWidget {
  /// Constructs a [_DataHolder]
  const _DataHolder({required this.child});

  /// The child widget.
  final Widget child;

  @override
  _DataHolderState createState() => _DataHolderState();
}

class _DataHolderState extends State<_DataHolder> {
  bool isLoading = true;
  late final Data data;

  @override
  void initState() {
    super.initState();
    isLoading = true;
    loadData().then((value) {
      setState(() {
        data = value.withoutEntriesMissingEffects();
        // TODO(eseidel): Remove defaultPlayerWeapon.
        Creature.defaultPlayerWeapon = data.items['Wooden Stick'];
        isLoading = false;
      });
    });
  }

  Future<Data> loadData() async {
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
    return InheritedData(
      data: data,
      child: widget.child,
    );
  }
}

/// A widget to look up the [Data] from the [InheritedData].
class InheritedData extends InheritedWidget {
  /// Constructs an [InheritedData]
  const InheritedData({
    required super.child,
    super.key,
    this.data,
  });

  /// The data to inherit.
  final Data? data;

  /// Look up the [InheritedData] from the [BuildContext].
  static InheritedData? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedData>();
  }

  @override
  bool updateShouldNotify(InheritedData oldWidget) {
    return oldWidget.data != data;
  }
}

/// A widget that uses the [Data] from the [InheritedData].
class UsesData extends StatelessWidget {
  /// Constructs a [UsesData]
  const UsesData({required this.builder, super.key});

  /// The builder to use with the [Data].
  final Widget Function(BuildContext context, Data data) builder;

  @override
  Widget build(BuildContext context) {
    final data = InheritedData.of(context)!.data;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return builder(context, data);
    }
  }
}

final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'root',
      builder: (BuildContext context, GoRouterState state) {
        return const TitleScreen();
      },
      routes: [
        GoRoute(
          path: 'battle',
          name: 'battle',
          builder: (BuildContext context, GoRouterState state) {
            final parameter = state.uri.queryParameters['c'];
            return UsesData(
              builder: (context, data) {
                return BattlePage(
                  data: data,
                  state: BuildIdCodec.tryDecode(
                        parameter,
                        data,
                      ) ??
                      BuildState.random(level: Level.one, data: data),
                );
              },
            );
          },
        ),
        GoRoute(
          path: 'compendium',
          name: 'compendium',
          builder: (context, _) {
            return UsesData(
              builder: (context, data) {
                return CompendiumPage(data: data);
              },
            );
          },
        ),
      ],
    ),
  ],
);

/// The main application widget.
class MyApp extends StatelessWidget {
  /// Constructs a [MyApp]
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _DataHolder(
      child: MaterialApp.router(
        routerConfig: _router,
        title: 'He is Coming',
        theme: flutterNesTheme(brightness: Brightness.dark),
      ),
    );
  }
}

/// The title screen for the game.
class TitleScreen extends StatelessWidget {
  /// Constructs a [TitleScreen]
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('He is Coming'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => _router.goNamed('battle'),
              child: const Text('Battle'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _router.goNamed('compendium'),
              child: const Text('Compendium'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SteamLink(),
                const SizedBox(width: 16),
                _GitHubLink(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SteamLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        launchUrl(
          Uri.parse(
            'https://store.steampowered.com/app/2824490/He_is_coming/',
          ),
        );
      },
      child: Center(
        child: Image.asset(
          'assets/steam_logo.png',
          width: 24,
          height: 24,
        ),
      ),
    );
  }
}

class _GitHubLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        launchUrl(
          Uri.parse('https://github.com/eseidel/he_is_coming'),
        );
      },
      child: Center(
        child: Image.asset(
          'assets/github-mark-white.png',
          width: 24,
          height: 24,
        ),
      ),
    );
  }
}
