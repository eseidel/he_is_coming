import 'package:he_is_coming/he_is_coming.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:scoped_deps/scoped_deps.dart';

void doMain(List<String> arguments) {
  // Roll a new start and simulate.
  runSim();
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
