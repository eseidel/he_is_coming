import 'package:he_is_coming/src/battle.dart';
import 'package:meta/meta.dart';

/// Function type for effect callbacks.
typedef EffectFn = void Function(EffectContext ctx);

/// Creates an [Effects] with an onBattle callback.
Effects onBattle(EffectFn fn) => Effects(onBattle: fn);

/// Creates an [Effects] with an onTurn callback.
Effects onTurn(EffectFn fn) => Effects(onTurn: fn);

/// Creates an [Effects] with an onHit callback.
Effects onHit(EffectFn fn) => Effects(onHit: fn);

/// Creates an [Effects] with an onTakeDamage callback.
Effects onTakeDamage(EffectFn fn) => Effects(onTakeDamage: fn);

/// Creates an [Effects] with an onExposed callback.
Effects onExposed(EffectFn fn) => Effects(onExposed: fn);

/// Creates an [Effects] with an onWounded callback.
Effects onWounded(EffectFn fn) => Effects(onWounded: fn);

/// Creates an [Effects] with an onHeal callback.
Effects onHeal(EffectFn fn) => Effects(onHeal: fn);

/// Enum representing the different effects that can be triggered.
enum Effect {
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
class Effects {
  /// Create a new Effect
  const Effects({
    this.onBattle,
    this.onTurn,
    this.onHit,
    this.onTakeDamage,
    this.onExposed,
    this.onWounded,
    this.onHeal,
  });

  /// Get the effect callback for a given effect.
  EffectFn? operator [](Effect effect) {
    return switch (effect) {
      Effect.onBattle => onBattle,
      Effect.onTurn => onTurn,
      Effect.onHit => onHit,
      Effect.onTakeDamage => onTakeDamage,
      Effect.onExposed => onExposed,
      Effect.onWounded => onWounded,
      Effect.onHeal => onHeal,
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
}

/// Type for looking up effects by name.
typedef EffectCatalog = Map<String, Effects>;

/// Type for looking up effects by name.
typedef LookupEffect = Effects? Function(String name);
