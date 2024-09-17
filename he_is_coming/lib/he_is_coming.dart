import 'package:he_is_coming/src/build_id.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/logger.dart';

export 'package:he_is_coming/src/battle.dart';
export 'package:he_is_coming/src/build_id.dart';
export 'package:he_is_coming/src/data.dart';
export 'package:he_is_coming/src/inventory.dart';
export 'package:he_is_coming/src/logger.dart';
export 'package:scoped_deps/scoped_deps.dart';

/// Log the passed build state.
void logBuildState(BuildState state, Data data) {
  final inventory = state.inventory;
  final stats = inventory.resolveBaseStats();
  logger
    ..info('Stats: $stats')
    ..info('Items:');
  for (final item in inventory.items) {
    logger.info('  ${item.name}');
  }
  if (inventory.edge != null) {
    logger.info('Edge: ${inventory.edge!.name}');
  }
  logger.info('Oils: ${inventory.oils.map((o) => o.name).join(', ')}');
  final encoded = BuildStateCodec.encode(state, data);
  logger.info('Code: $encoded');
}
