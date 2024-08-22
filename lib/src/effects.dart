import 'package:he_is_coming/src/battle.dart';
import 'package:meta/meta.dart';

/// Function type for effect callbacks.
typedef EffectFn = void Function(EffectContext ctx);

/// Creates an [Effect] with an onBattle callback.
Effect onBattle(EffectFn fn) => Effect(onBattle: fn);

/// Creates an [Effect] with an onTurn callback.
Effect onTurn(EffectFn fn) => Effect(onTurn: fn);

/// Creates an [Effect] with an onHit callback.
Effect onHit(EffectFn fn) => Effect(onHit: fn);

/// Creates an [Effect] with an onTakeDamage callback.
Effect onTakeDamage(EffectFn fn) => Effect(onTakeDamage: fn);

/// Creates an [Effect] with an onExposed callback.
Effect onExposed(EffectFn fn) => Effect(onExposed: fn);

/// Creates an [Effect] with an onWounded callback.
Effect onWounded(EffectFn fn) => Effect(onWounded: fn);

/// Creates an [Effect] with an onHeal callback.
Effect onHeal(EffectFn fn) => Effect(onHeal: fn);

/// Enum representing the different effects that can be triggered.
enum Trigger {
  /// Called on battle start.
  onBattle,

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
    this.onBattle,
    this.onTurn,
    this.onHit,
    this.onTakeDamage,
    this.onExposed,
    this.onWounded,
    this.onHeal,
    // TODO(eseidel): Plumb effect text through.
    this.text = '',
  });

  /// Get the effect callback for a given effect.
  EffectFn? operator [](Trigger effect) {
    return switch (effect) {
      Trigger.onBattle => onBattle,
      Trigger.onTurn => onTurn,
      Trigger.onHit => onHit,
      Trigger.onTakeDamage => onTakeDamage,
      Trigger.onExposed => onExposed,
      Trigger.onWounded => onWounded,
      Trigger.onHeal => onHeal,
    };
  }

  /// Called on battle start.
  final EffectFn? onBattle;

  /// Called at the start of each turn.
  final EffectFn? onTurn;

  /// Called whenever the creature attacks.
  /// This does not include damage dealt by non-attack actions.
  final EffectFn? onHit;

  /// Called whenever the creature takes damage.
  final EffectFn? onTakeDamage;

  /// Called when armor is broken for the first time this battle.
  final EffectFn? onExposed;

  /// Called when hp is below 50% for the first time this battle.
  final EffectFn? onWounded;

  /// Called when any hp is restored.
  final EffectFn? onHeal;

  /// Returns a string representation of the effect.
  final String text;

  @override
  String toString() => text;

  /// Returns a json representation of the effect.
  dynamic toJson() => text;
}

/// Type for looking up effects by name.
typedef EffectCatalog = Map<String, Effect>;

/// Type for looking up effects by name.
typedef LookupEffect = Effect? Function(String name);
