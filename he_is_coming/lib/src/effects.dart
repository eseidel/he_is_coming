import 'package:he_is_coming/he_is_coming.dart';
import 'package:meta/meta.dart';

/// Function type for effect callbacks.
typedef EffectFn = void Function(EffectContext ctx);

/// Callbacks for effects.
typedef EffectMap = Map<Trigger, EffectFn>;

/// Function type for dynamic stats callbacks.
typedef StatsFn = Stats Function(Inventory inventory);

/// Function type for stats override callbacks.
typedef OverrideStatsFn = Stats Function(Stats stats);

/// Creates an [Effect] with an onBattle callback.
EffectMap onBattle(EffectFn fn) => {Trigger.onBattle: fn};

/// Creates an [Effect] with an onInitiative callback.
EffectMap onInitiative(EffectFn fn) => {Trigger.onInitiative: fn};

/// Creates an [Effect] with an onTurn callback.
EffectMap onTurn(EffectFn fn) => {Trigger.onTurn: fn};

/// Creates an [Effect] with an onHit callback.
EffectMap onHit(EffectFn fn) => {Trigger.onHit: fn};

/// Creates an [Effect] with an onTakeDamage callback.
EffectMap onTakeDamage(EffectFn fn) => {Trigger.onTakeDamage: fn};

/// Creates an [Effect] with an onExposed callback.
EffectMap onExposed(EffectFn fn) => {Trigger.onExposed: fn};

/// Creates an [Effect] with an onWounded callback.
EffectMap onWounded(EffectFn fn) => {Trigger.onWounded: fn};

/// Creates an [Effect] with multiple triggers.
EffectMap multiTrigger(List<Trigger> triggers, EffectFn fn) =>
    Map.fromEntries(triggers.map((trigger) => MapEntry(trigger, fn)));

/// Creates an [Effect] with onExposed and onWounded callbacks.
EffectMap onExposedAndWounded(EffectFn fn) => multiTrigger(
      [Trigger.onExposed, Trigger.onWounded],
      fn,
    );

/// Creates an [Effect] with an onRestoreHealth callback.
EffectMap onRestoreHealth(EffectFn fn) => {Trigger.onRestoreHealth: fn};

/// Creates an [Effect] with an onOverheal callback.
EffectMap onOverheal(EffectFn fn) => {Trigger.onOverheal: fn};

/// Creates an [Effect] with an onGainArmor callback.
EffectMap onGainArmor(EffectFn fn) => {Trigger.onGainArmor: fn};

/// Creates an [Effect] with an onLoseArmor callback.
EffectMap onLoseArmor(EffectFn fn) => {Trigger.onLoseArmor: fn};

/// Creates an [Effect] with an onGainThorns callback.
EffectMap onGainThorns(EffectFn fn) => {Trigger.onGainThorns: fn};

/// Enum representing the different effects that can be triggered.
enum Trigger {
  /// Called on battle start.
  onBattle,

  /// Called just after battle start.
  onInitiative,

  /// Called at the start of each turn.
  onTurn,

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
  const Effect({
    required this.text,
    required this.callbacks,
    required this.onDynamicStats,
    required this.onOverrideStats,
  });

  /// Create an effect without any callbacks.
  Effect.textOnly(this.text)
      : callbacks = {},
        onDynamicStats = null,
        onOverrideStats = null;

  /// Get the effect callback for a given effect.
  EffectFn? operator [](Trigger effect) => callbacks[effect];

  /// Returns a new effect with the given callback added.
  final Map<Trigger, EffectFn> callbacks;

  /// Callback for dynamic stats.
  final StatsFn? onDynamicStats;

  /// Callback for overriding stats.
  final OverrideStatsFn? onOverrideStats;

  /// Returns a string representation of the effect.
  final String text;

  /// Returns true if the effect has no callbacks.
  bool get isEmpty =>
      callbacks.isEmpty && onDynamicStats == null && onOverrideStats == null;

  @override
  String toString() => text;

  /// Returns a json representation of the effect.
  dynamic toJson() => text;
}

/// Catalog of effects.
class EffectCatalog {
  /// Create a new EffectCatalog
  EffectCatalog(
    this.catalog, {
    this.dynamicStats = const {},
    this.overrideStats = const {},
  });

  /// The catalog of effects.
  final Map<String, EffectMap> catalog;

  /// Callbacks for dynamic stats.
  final Map<String, StatsFn> dynamicStats;

  /// Callbacks for overriding stats.
  final Map<String, OverrideStatsFn> overrideStats;

  /// Get the list of implemented effects.
  Set<String> get implemented {
    return <String>{
      ...catalog.keys,
      ...dynamicStats.keys,
      ...overrideStats.keys,
    };
  }

  /// Look up an effect by name.
  Effect? lookup({required String name, required String? effectText}) {
    if (effectText == null) {
      return null;
    }
    return Effect(
      callbacks: catalog[name] ?? {},
      onDynamicStats: dynamicStats[name],
      onOverrideStats: overrideStats[name],
      text: effectText,
    );
  }
}

/// Type for looking up effects by name.
typedef LookupEffect = Effect? Function({
  required String name,
  required String? effectText,
});
