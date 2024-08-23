import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:scoped_deps/scoped_deps.dart';

void doMain(List<String> arguments) {
  // Just loading the data should print the effects warnings.
  Data.load();
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
