import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:scoped_deps/scoped_deps.dart';

void doMain(List<String> arguments) {
  final data = Data.load();

  // Read in all the kinds and materials and build the tag list.
  // Also add a weapon: true key for weapons.
  for (var i = 0; i < data.items.length; i++) {
    final item = data.items.items[i];
    final tags = <ItemTag>{};
    final kind = item.kind;
    if (kind == ItemKind.food) {
      tags.add(ItemTag.food);
    } else if (kind == ItemKind.jewelry) {
      tags.add(ItemTag.jewelry);
    }
    final material = item.material;
    if (material == ItemMaterial.stone) {
      tags.add(ItemTag.stone);
    } else if (material == ItemMaterial.sanguine) {
      tags.add(ItemTag.sanguine);
    } else if (material == ItemMaterial.wood) {
      tags.add(ItemTag.wood);
    }
    if (tags != item.tags) {
      logger.info('Updating ${item.name}');
      data.items.items[i] = item.copyWith(tags: tags);
    }
  }

  data.save();
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
