import 'package:collection/collection.dart';
import 'package:he_is_coming/src/data.dart';
import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/logger.dart';
import 'package:scoped_deps/scoped_deps.dart';

// get all the first and last words in item names.
// Look for repeats.

class TriggerMap {
  TriggerMap(this.triggers, this.regexps);

  final Set<Trigger> triggers;
  List<RegExp> regexps;
}

List<RegExp> expectedText(CatalogItem item) {
  RegExp startsWith(String text) => RegExp('^$text');
  RegExp endsWith(String text) => RegExp('$text\$');
  RegExp contains(String text) => RegExp(text);
  RegExp whenever(String text) => RegExp('^Whenever .+ $text');
  final takesDamage = RegExp('^Whenever .+ takes? damage');

  final effect = item.effect;
  if (effect == null) {
    return [];
  }
  final callbacks = effect.callbacks;
  if (callbacks == null || callbacks.isEmpty) {
    return [];
  }
  final triggers = callbacks.triggers.keys.toSet();
  if (triggers.isEmpty) {
    // Could add for dynamicStats and overrideStats.
    if (callbacks.dynamicStats != null) {
      return [contains('for each')];
    }
    return [];
  }
  TriggerMap map(Set<Trigger> triggers, List<RegExp> regexps) {
    return TriggerMap(triggers, regexps);
  }

  TriggerMap setToOne(Set<Trigger> triggers, RegExp regexp) {
    return TriggerMap(triggers, [regexp]);
  }

  TriggerMap one(Trigger triggers, RegExp regexp) {
    return TriggerMap({triggers}, [regexp]);
  }

  TriggerMap many(Trigger triggers, List<RegExp> regexps) {
    return TriggerMap({triggers}, regexps);
  }

  final matchers = [
    setToOne(
      {Trigger.onExposed, Trigger.onWounded},
      startsWith('Exposed & Wounded'),
    ),
    setToOne(
      {Trigger.onBattle, Trigger.onWounded},
      startsWith('Battle Start & Wounded'),
    ),
    // This isn't always true, but close enough.
    setToOne({Trigger.onTurn, Trigger.onEndTurn}, startsWith('First Turn')),
    setToOne(
      {Trigger.onGainThorns, Trigger.onLoseThorns},
      contains('for each thorns'),
    ),
    one(Trigger.onBattle, startsWith('Battle Start')),
    one(Trigger.onInitiative, startsWith('Initiative')),
    many(Trigger.onTurn, [
      startsWith('Turn Start'),
      contains('every other turn'),
      contains('at turn start'),
    ]),
    many(Trigger.onHit, [startsWith('On Hit'), endsWith('on hit')]),
    one(Trigger.onTakeDamage, takesDamage),
    one(Trigger.onExposed, startsWith('Exposed')),
    one(Trigger.onWounded, startsWith('Wounded')),
    one(Trigger.onRestoreHealth, whenever('restore health')),
    one(Trigger.onGainArmor, whenever('gain armor')),
    one(Trigger.onLoseArmor, whenever('lose armor')),
    one(Trigger.onGainThorns, whenever('gain thorns')),
    one(Trigger.onOverheal, startsWith('Overhealing')),
  ];

  const equality = SetEquality<Trigger>();
  for (final matcher in matchers) {
    if (equality.equals(matcher.triggers, triggers)) {
      return matcher.regexps;
    }
  }
  return [];
}

void doMain(List<String> arguments) {
  final data = Data.load();

  for (final item in data.allItems) {
    if (!item.isImplemented) {
      continue;
    }
    // Ignore golden/diamond items.
    if (item.effectMultiplier != 1) continue;
    final written = item.effect?.text;
    if (written == null && item.effect != null) {
      logger.warn('${item.name} has unexpected effects.');
    }
    final regexps = expectedText(item);
    if (written != null && !regexps.any((r) => r.hasMatch(written))) {
      final patterns = regexps.map((r) => r.pattern);
      logger.info('$written on ${item.name} expected one of: $patterns');
    }
  }
}

void main(List<String> args) {
  return runScoped(() => doMain(args), values: {loggerRef});
}
