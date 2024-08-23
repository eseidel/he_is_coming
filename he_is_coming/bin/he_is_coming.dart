import 'package:args/args.dart';
import 'package:he_is_coming/he_is_coming.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:scoped_deps/scoped_deps.dart';

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
  logger
    ..info('Usage: dart he_is_coming_sim.dart <flags> [arguments]')
    ..info(argParser.usage);
}

void doMain(List<String> arguments) {
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

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
