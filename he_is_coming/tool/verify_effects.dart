import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:scoped_deps/scoped_deps.dart';

// get all the first and last words in item names.
// Look for repeats.

String? expectedPrefix(CatalogItem item) {
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

void doMain(List<String> arguments) {
  final data = Data.load();

  for (final item in data.allItems) {
    final effect = item.effect;
    if (effect == null) {
      continue;
    }
    final words = effect.text.split(':');
    if (words.length != 2) {
      // Effects without trigger words hit this case.
      continue;
    }
    final actual = words.first.trim();
    final expected = expectedPrefix(item);
    if (actual != expected) {
      logger.warn('${item.name} Expected: $expected, Actual: $actual');
    }
  }
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
