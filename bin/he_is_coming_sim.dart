import 'package:args/args.dart';
import 'package:he_is_coming_sim/logger.dart';
import 'package:he_is_coming_sim/simulate.dart';

ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    );
}

void printUsage(ArgParser argParser) {
  print('Usage: dart he_is_coming_sim.dart <flags> [arguments]');
  print(argParser.usage);
}

void main(List<String> arguments) {
  final argParser = buildParser();
  final results = argParser.parse(arguments);
  final verbose = results.wasParsed('verbose');

  if (results.wasParsed('help')) {
    printUsage(argParser);
    return;
  }
  if (verbose) {
    logger.level = Level.debug;
  }

  // Roll a new start and simulate.
  runSim();
}
