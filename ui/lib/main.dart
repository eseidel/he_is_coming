import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:he_is_coming/he_is_coming.dart';
import 'package:ui/src/battle.dart';
import 'package:ui/src/compendium.dart';
import 'package:ui/src/data.dart';
import 'package:ui/src/style.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runScoped(() => runApp(const MyApp()), values: {loggerRef});
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
          name: 'random_battle',
          redirect: (BuildContext context, GoRouterState state) {
            final data = InheritedData.of(context).data;
            return state.namedLocation(
              'battle',
              pathParameters: {
                BuildStateCodec.parameterName: BuildStateCodec.encode(
                  BuildState.random(level: Level.one, data: data),
                  data,
                ),
              },
            );
          },
        ),
        GoRoute(
          path: 'battle/:state',
          name: 'battle',
          builder: (BuildContext context, GoRouterState state) {
            final parameter =
                state.pathParameters[BuildStateCodec.parameterName];
            final allData = InheritedData.of(context).data;
            final data = allData.withoutMissingEffects();
            return BattlePage(
              data: data,
              state: BuildStateCodec.tryDecode(
                    parameter,
                    data,
                  ) ??
                  BuildState.random(level: Level.one, data: data),
            );
          },
        ),
        GoRoute(
          path: 'compendium',
          name: 'compendium',
          builder: (context, _) {
            final data = InheritedData.of(context).data;
            return CompendiumPage(data: data);
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
    return DataHolder(
      child: MaterialApp.router(
        routerConfig: _router,
        title: 'He is Coming',
        theme: Style.theme,
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Spacer(),
            Expanded(
              flex: 2,
              child: Text(
                'He Is\nComing',
                style: Style.title,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _router.goNamed('random_battle'),
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
            const Spacer(),
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
