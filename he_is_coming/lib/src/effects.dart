import 'package:he_is_coming/src/battle.dart';
import 'package:meta/meta.dart';

/// Function type for effect callbacks.
typedef EffectFn = void Function(EffectContext ctx);

/// Callbacks for effects.
typedef EffectMap = Map<Trigger, EffectFn>;

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

/// Creates an [Effect] with an onHeal callback.
EffectMap onHeal(EffectFn fn) => {Trigger.onHeal: fn};

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
  onHeal,
}

/// Container for callbacks for items.
@immutable
class Effect {
  /// Create a new Effect
  const Effect({
    required this.text,
    required this.callbacks,
  });

  /// Get the effect callback for a given effect.
  EffectFn? operator [](Trigger effect) => callbacks[effect];

  /// Returns a new effect with the given callback added.
  final Map<Trigger, EffectFn> callbacks;

  /// Returns a string representation of the effect.
  final String text;

  /// Returns true if the effect has no callbacks.
  bool get isEmpty => callbacks.isEmpty;

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
  final Map<String, EffectMap> catalog;

  /// Look up an effect by name.
  Effect? lookup({required String name, required String? effectText}) {
    if (effectText == null) {
      return null;
    }
    return Effect(
      callbacks: catalog[name] ?? {},
      text: effectText,
    );
  }
}

/// Type for looking up effects by name.
typedef LookupEffect = Effect? Function({
  required String name,
  required String? effectText,
});
