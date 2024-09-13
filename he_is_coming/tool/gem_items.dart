import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:scoped_deps/scoped_deps.dart';

void doMain(List<String> arguments) {
  final data = Data.load();

  for (final item in data.items.items) {
    final gem = item.gem;
    if (gem == null) {
      continue;
    }
    logger.info('${gem.name}: ${item.name}');
  }
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
