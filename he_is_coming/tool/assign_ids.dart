import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:scoped_deps/scoped_deps.dart';

void assignIds<T extends CatalogItem>(Catalog<T> catalog) {
  var highestId =
      catalog.items.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b);
  for (var i = 0; i < catalog.length; i++) {
    final item = catalog.items[i];
    if (item.id == null) {
      catalog.items[i] = item.copyWith(id: highestId + 1) as T;
      highestId++;
    }
  }
}

void doMain(List<String> args) {
  final data = Data.load();
  // Walk all catalogs, find items missing ids, and assign them ids.
  assignIds(data.items);
  assignIds(data.oils);
  assignIds(data.edges);
  assignIds(data.creatures);
  assignIds(data.sets);
  assignIds(data.triggers);
  assignIds(data.challenges);

  data.save();
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
