import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:scoped_deps/scoped_deps.dart';

void doMain(List<String> args) {
  // Load in the data and save it again and it should sort itself.
  Data.load().save();
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
