import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:scoped_deps/scoped_deps.dart';

// get all the first and last words in item names.
// Look for repeats.

String? implementedTrigger(CatalogItem item) {
  final effect = item.effect;
  if (effect == null) {
    return null;
  }
  final callbacks = effect.callbacks;
  if (callbacks.isEmpty) {
    return null;
  }
  final triggers = callbacks.keys.toList();
  if (triggers.length != 1) {
    logger.warn('${item.name} has multiple triggers: $triggers');
    return null;
  }
  final trigger = triggers.single;
  switch (trigger) {
    case Trigger.onBattle:
      return 'Battle Start';
    case Trigger.onInitiative:
      return 'Initiative';
    case Trigger.onTurn:
      return 'Turn Start';
    case Trigger.onHit:
      return 'On Hit';
    case Trigger.onTakeDamage:
      return 'Whenever you take damage';
    case Trigger.onExposed:
      return 'Exposed';
    case Trigger.onWounded:
      return 'Wounded';
    case Trigger.onRestoreHealth:
      return 'Whenever you restore health';
  }
}

String? writtenTrigger(CatalogItem item) {
  final effect = item.effect;
  if (effect == null) {
    return null;
  }
  var parts = effect.text.split(':');
  if (parts.length != 2) {
    parts = effect.text.split(',');
    if (parts.length != 2) {
      return null;
    }
  }
  return parts.first.trim();
}

void doMain(List<String> arguments) {
  final data = Data.load();

  for (final item in data.allItems) {
    if (!item.isImplemented) {
      continue;
    }
    final written = writtenTrigger(item);
    final implemented = implementedTrigger(item);
    if (written != implemented) {
      logger.warn('${item.name} Implemented: $implemented, Written: $written');
    }
  }
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
