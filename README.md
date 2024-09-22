A simulator for the indie-game "He is Coming"
https://store.steampowered.com/app/2824490/He_is_coming/

"He is Coming" is a NES-styled 2d RPG auto-battler with rogue-lite elements.

Developed by Chronocle: https://www.chronocle.com/

Go buy it! https://store.steampowered.com/app/2824490/He_is_coming/
Or join the Discord: https://discord.com/invite/w6rDh4gRPN

## Usage

There is both a command line interface as well as a UI.

The easiest way to use is via the web interface:
https://eseidel.github.io/he_is_coming/

### Development

You'll need Flutter installed:  https://flutter.dev.  Flutter comes with Dart.

All the data recorded from the game is stored in `he_is_coming/lib/data`.

You can run the tests with:
```
cd he_is_coming
dart test
```

My typical dev cycle involves running one of the debugging scripts
e.g. `dart run bin/missing_effects.dart`, picking an effect and implementing
it in the correct `*_effects.dart` file.  All the easy ones are implemented
see `DESIGN.md` for thoughts on how to implement the rest.

Adding an Item, Creature or Set is often as simple as adding an entry into one
of the data files.  To add effects for the item, you may need to edit one of the
effects.dart files.

### Building the Flutter app

You can also use the Flutter app locally, typically I use the mac version
when developing and then publish to the Web via Github Actions and Github pages.

```
cd ui
flutter run -d macos
```
is my typical development flow when I'm working on the UI.

Even better, is to run from within Visual Studio Code, so that it will notice
edits and reload automatically.

### Status

No promises that any of the data here reflects the current game.
At time of writing that is Demo Patch 4 (0.3.5, September 4, 2024).