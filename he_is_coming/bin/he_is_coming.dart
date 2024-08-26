import 'package:he_is_coming/he_is_coming.dart';

void doMain(List<String> arguments) {
  // Roll a new start and simulate.
  runSim();
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
