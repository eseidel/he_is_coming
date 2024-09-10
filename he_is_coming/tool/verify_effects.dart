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
      return 'On Damage';
    case Trigger.onExposed:
      return 'Exposed';
    case Trigger.onWounded:
      return 'Wounded';
    case Trigger.onHeal:
      return 'On Heal';
  }
}

String? writtenTrigger(CatalogItem item) {
  final effect = item.effect;
  if (effect == null) {
    return null;
  }
  final words = effect.text.split(':');
  if (words.length != 2) {
    return null;
  }
  return words.first.trim();
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
