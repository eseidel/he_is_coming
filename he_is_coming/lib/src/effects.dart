import 'package:he_is_coming/he_is_coming.dart';
import 'package:meta/meta.dart';

/// Function type for effect callbacks.
typedef EffectFn = void Function(EffectContext ctx);

/// Map from Trigger to callback function.
typedef EffectMap = Map<Trigger, EffectFn>;

/// Callbacks for an Effect.
class EffectCallbacks {
  /// Construct a new EffectCallbacks.
  const EffectCallbacks({
    this.triggers = const {},
    this.dynamicStats,
    this.overrideStats,
  });

  /// Returns true if the effect has no callbacks.
  bool get isEmpty =>
      triggers.isEmpty && dynamicStats == null && overrideStats == null;

  /// Callbacks for triggers.
  final EffectMap triggers;

  /// Callback for computing dynamic stats.
  final StatsFn? dynamicStats;

  /// Callback for overriding stats.
  final OverrideStatsFn? overrideStats;
}

/// Function type for dynamic stats callbacks.
typedef StatsFn = Stats Function(Inventory inventory);

/// Function type for stats override callbacks.
typedef OverrideStatsFn = Stats Function(Stats stats);

/// Create an [EffectCallbacks] with the given triggers.
EffectCallbacks triggers(EffectMap triggers) =>
    EffectCallbacks(triggers: triggers);

/// Create an [EffectCallbacks] with the given dynamic stats callback.
EffectCallbacks dynamicStats(StatsFn fn) =>
    EffectCallbacks(dynamicStats: fn, triggers: {});

/// Create an [EffectCallbacks] with the given override stats callback.
EffectCallbacks overrideStats(OverrideStatsFn fn) =>
    EffectCallbacks(overrideStats: fn, triggers: {});

/// Creates an [Effect] with an onBattle callback.
EffectCallbacks onBattle(EffectFn fn) => triggers({Trigger.onBattle: fn});

/// Creates an [Effect] with an onInitiative callback.
EffectCallbacks onInitiative(EffectFn fn) =>
    triggers({Trigger.onInitiative: fn});

/// Creates an [Effect] with an onTurn callback.
EffectCallbacks onTurn(EffectFn fn) => triggers({Trigger.onTurn: fn});

/// Creates an [Effect] with an onHit callback.
EffectCallbacks onHit(EffectFn fn) => triggers({Trigger.onHit: fn});

/// Creates an [Effect] with an onTakeDamage callback.
EffectCallbacks onTakeDamage(EffectFn fn) =>
    triggers({Trigger.onTakeDamage: fn});

/// Creates an [Effect] with an onExposed callback.
EffectCallbacks onExposed(EffectFn fn) => triggers({Trigger.onExposed: fn});

/// Creates an [Effect] with an onWounded callback.
EffectCallbacks onWounded(EffectFn fn) => triggers({Trigger.onWounded: fn});

/// Creates an [Effect] with multiple triggers.
EffectCallbacks multiTrigger(List<Trigger> triggers, EffectFn fn) =>
    EffectCallbacks(
      triggers:
          Map.fromEntries(triggers.map((trigger) => MapEntry(trigger, fn))),
    );

/// Creates an [Effect] with onExposed and onWounded callbacks.
EffectCallbacks onExposedAndWounded(EffectFn fn) => multiTrigger(
      [Trigger.onExposed, Trigger.onWounded],
      fn,
    );

/// Creates an [Effect] with an onRestoreHealth callback.
EffectCallbacks onRestoreHealth(EffectFn fn) =>
    triggers({Trigger.onRestoreHealth: fn});

/// Creates an [Effect] with an onOverheal callback.
EffectCallbacks onOverheal(EffectFn fn) => triggers({Trigger.onOverheal: fn});

/// Creates an [Effect] with an onGainArmor callback.
EffectCallbacks onGainArmor(EffectFn fn) => triggers({Trigger.onGainArmor: fn});

/// Creates an [Effect] with an onLoseArmor callback.
EffectCallbacks onLoseArmor(EffectFn fn) => triggers({Trigger.onLoseArmor: fn});

/// Creates an [Effect] with an onGainThorns callback.
EffectCallbacks onGainThorns(EffectFn fn) =>
    triggers({Trigger.onGainThorns: fn});

/// Enum representing the different effects that can be triggered.
enum Trigger {
  /// Called on battle start.
  onBattle,

  /// Called just after battle start.
  onInitiative,

  /// Called at the start of each turn.
  onTurn,

  /// Called at the end of each turn.
  onEndTurn,

  /// Called whenever the creature attacks.
  /// This does not include damage dealt by non-attack actions.
  /// This really should be named onStrike or onAttack.
  onHit,

  /// Called whenever the creature takes damage.
  onTakeDamage,

  /// Called when armor is broken for the first time this battle.
  onExposed,

  /// Called when hp is below 50% for the first time this battle.
  onWounded,

  /// Called when any hp is restored.
  onRestoreHealth,

  /// Called when hp is not restored due to overheal.
  /// Read EffectContext.overhealValue for amount.
  onOverheal,

  /// Called when any armor is gained.
  onGainArmor,

  /// Called when any amor is removed.
  /// Check EffectContext.armorValue for amount.
  onLoseArmor,

  /// Called when any thorns are gained.
  onGainThorns,

  /// Called when any thorns are removed.
  /// Check EffectContext.thornsValue for amount.
  onLoseThorns,
}

/// Container for callbacks for items.
@immutable
class Effect {
  /// Create a new Effect
  const Effect({required this.text, required this.callbacks});

  /// Create an effect without any callbacks.
  const Effect.textOnly(this.text) : callbacks = const EffectCallbacks();

  /// Create a test effect.
  const Effect.test({this.callbacks, this.text = 'test'});

  /// Get the effect callback for a given effect.
  EffectFn? operator [](Trigger effect) => callbacks?.triggers[effect];

  /// Callbacks for the effect.
  final EffectCallbacks? callbacks;

  /// Get the dynamic stats callback for the effect.
  StatsFn? get onDynamicStats => callbacks?.dynamicStats;

  /// Get the override stats callback for the effect.
  OverrideStatsFn? get onOverrideStats => callbacks?.overrideStats;

  /// Returns a string representation of the effect.
  final String text;

  /// Returns true if the effect has no callbacks.
  bool get isEmpty => callbacks == null || callbacks!.isEmpty;

  @override
  String toString() => text;

  /// Returns a json representation of the effect.
  dynamic toJson() => text;
}

/// Catalog of effects.
class EffectCatalog {
  /// Create a new EffectCatalog
  EffectCatalog(this.catalog);

  /// The catalog of effects.
  final Map<String, EffectCallbacks> catalog;

  /// Get the list of implemented effects.
  Set<String> get implemented => catalog.keys.toSet();

  /// Look up an effect by name.
  Effect? lookup({required String name, required String? effectText}) {
    if (effectText == null) {
      return null;
    }
    // This is a bit of a hack for Items, unclear where this should go?
    // Maybe items should have an effectName in the yaml?
    final String lookupName;
    if (name.startsWith('Golden ')) {
      lookupName = name.substring(7);
    } else if (name.startsWith('Diamond ')) {
      lookupName = name.substring(8);
    } else {
      lookupName = name;
    }
    final callbacks = catalog[lookupName];

    return Effect(
      callbacks: callbacks,
      text: effectText,
    );
  }
}

/// Type for looking up effects by name.
typedef LookupEffect = Effect? Function({
  required String name,
  required String? effectText,
});
