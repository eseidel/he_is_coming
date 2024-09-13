import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/item.dart';

// Dart doesn't have if-expressions, so made a helper function.
void _if(bool condition, void Function() fn) {
  if (condition) {
    fn();
  }
}

/// Effects that can be triggered by items.
final itemEffects = EffectCatalog(<String, EffectMap>{
  'Stone Steak': onBattle((c) => _if(c.my.isHealthFull, () => c.gainArmor(4))),
  'Redwood Cloak': onBattle((c) => c.restoreHealth(1)),
  'Golden Redwood Cloak': onBattle((c) => c.restoreHealth(2)),
  'Emergency Shield': onBattle(
    (c) => _if(c.my.speed < c.enemy.speed, () => c.gainArmor(4)),
  ),
  'Golden Emergency Shield': onBattle(
    (c) => _if(c.my.speed < c.enemy.speed, () => c.gainArmor(8)),
  ),
  'Granite Gauntlet': onBattle((c) => c.gainArmor(5)),
  'Ruby Earring': onTurn((c) => _if(c.isEveryOtherTurn, () => c.dealDamage(1))),
  'Firecracker Belt': onExposed((c) => [1, 1, 1].forEach(c.dealDamage)),
  'Golden Firecracker Belt':
      onExposed((c) => [1, 1, 1, 1, 1, 1].forEach(c.dealDamage)),
  'Redwood Helmet': onExposed((c) => c.restoreHealth(3)),
  'Golden Redwood Helmet': onExposed((c) => c.restoreHealth(6)),
  'Explosive Surprise': onExposed((c) => c.dealDamage(5)),
  'Cracked Bouldershield': onExposed((c) => c.gainArmor(5)),
  'Vampiric Wine': onWounded((c) => c.restoreHealth(4)),
  'Golden Vampiric Wine': onWounded((c) => c.restoreHealth(8)),
  'Mortal Edge': onWounded(
    (c) => c
      ..gainAttack(5)
      ..takeDamage(2),
  ),
  'Lifeblood Burst': onWounded((c) => c.dealDamage(c.my.maxHp ~/ 2)),
  'Chain Mail': onWounded((c) => c.gainArmor(3)),
  'Stoneslab Sword': onHit((c) => c.gainArmor(2)),
  'Heart Drinker': onHit((c) => c.restoreHealth(1)),
  'Gold Ring': onBattle((c) => c.gainGold(1)),
  'Ruby Ring': onBattle(
    (c) => c
      ..gainAttack(1)
      ..takeDamage(2),
  ),
  'Golden Ruby Ring': onBattle(
    (c) => c
      ..gainAttack(2)
      ..takeDamage(4),
  ),
  'Melting Iceblade': onHit((c) => c.loseAttack(1)),
  'Double-edged Sword': onHit((c) => c.takeDamage(1)),
  'Citrine Ring': onBattle(
    (c) => _if(c.my.speed > 0, () => c.dealDamage(c.my.speed)),
  ),
  'Marble Mirror': onBattle(
    (c) => _if(c.enemy.armor > 0, () => c.gainArmor(c.enemy.armor)),
  ),
  // This might be wrong, since this probably should be onTurn?
  // "If you have more speed than the enemy, gain 2 attack"
  'Leather Boots': onBattle(
    (c) => _if(c.my.speed > c.enemy.speed, () => c.gainAttack(2)),
  ),
  'Plated Helmet':
      onTurn((c) => _if(c.my.belowHalfHealth, () => c.gainArmor(2))),
  'Ore Heart': onBattle(
    (c) => c.gainArmor(c.materialCount(ItemMaterial.stone) * 2),
  ),
  'Granite Hammer': onHit(
    (c) => _if(
      c.my.armor > 0,
      () => c
        ..loseArmor(1)
        ..gainAttack(2),
    ),
  ),
  'Iron Transfusion': onTurn(
    (c) => c
      ..gainArmor(2)
      ..loseHealth(1),
  ),
  'Fortified Gauntlet':
      onTurn((c) => _if(c.my.armor > 0, () => c.gainArmor(1))),
  'Iron Rose': onHeal((c) => c.gainArmor(1)),
  'Featherweight Coat': onBattle(
    (c) => _if(
      c.my.armor > 0,
      () => c
        ..loseArmor(1)
        ..gainSpeed(3),
    ),
  ),
  'Sticky Web': onBattle(
    (c) => _if(c.my.speed < c.enemy.speed, () => c.stunEnemy(1)),
  ),
  'Impressive Physique': onExposed((c) => c.stunEnemy(1)),
  'Steelbond Curse': onBattle((c) => c.giveArmorToEnemy(8)),
  // Bejeweled Blade doesn't say "On Battle Start". This might be subtly wrong?
  'Bejeweled Blade': onBattle(
    (c) => _if(
      c.kindCount(ItemKind.jewelry) > 0,
      () => c.gainAttack(c.kindCount(ItemKind.jewelry) * 2),
    ),
  ),
  'Emerald Ring': onBattle((c) => c.restoreHealth(2)),
  'Golden Emerald Ring': onBattle((c) => c.restoreHealth(4)),
  'Ironskin Potion': onBattle(
    (c) => _if(c.my.lostHp > 0, () => c.gainArmor(c.my.lostHp)),
  ),
  'Double-plated Armor': onExposed((c) => c.gainArmor(3)),
  'Sapphire Earring':
      onTurn((c) => _if(c.isEveryOtherTurn, () => c.gainArmor(1))),
  'Golden Sapphire Earring':
      onTurn((c) => _if(c.isEveryOtherTurn, () => c.gainArmor(2))),
  'Emerald Earring': onTurn(
    (c) => _if(c.isEveryOtherTurn, () => c.restoreHealth(1)),
  ),
  'Golden Emerald Earring': onTurn(
    (c) => _if(c.isEveryOtherTurn, () => c.restoreHealth(2)),
  ),
  'Sapphire Ring': onBattle((c) => c.stealArmor(2)),
  'Horned Helmet': onBattle((c) => c.gainThorns(2)),
  'Golden Horned Helmet': onBattle((c) => c.gainThorns(4)),
  'Crimson Cloak': onTakeDamage((c) => c.restoreHealth(1)),
  'Tree Sap': onWounded((c) => [1, 1, 1, 1, 1].forEach(c.restoreHealth)),
  'Petrifying Flask': onWounded(
    (c) => c
      ..gainArmor(10)
      ..stunSelf(2),
  ),
  'Ruby Gemstone': onHit(
    (ctx) => _if(ctx.my.attack == 1, () => ctx.dealDamage(4)),
  ),
  'Bloody Steak': onWounded((c) => c.gainArmor(c.my.maxHp ~/ 2)),
  'Assault Greaves': onTakeDamage((c) => c.dealDamage(1)),
  'Thorn Ring': onBattle((c) => c..gainThorns(6)),
  'Bramble Buckler': onTurn(
    (c) => _if(
      c.my.armor > 0,
      () => c
        ..loseArmor(1)
        ..gainThorns(2),
    ),
  ),
  'Stormcloud Spear':
      onTurn((c) => _if(c.everyNStrikes(5), () => c.stunEnemy(2))),
  'Pinecone Plate': onTurn(
    (c) => _if(c.myHealthWasFullAtBattleStart, () => c.gainThorns(1)),
  ),
  'Gemstone Scepter': {
    Trigger.onHit: (c) {
      // "Draws power from emerald, ruby, sapphire and citrine items"
      final emeraldPower = c.gemCount(Gem.emerald);
      // These are supposedly one at a time rather than in bulk.
      // https://discord.com/channels/1041414829606449283/1209488593219756063/1283601378953924650
      for (var i = 0; i < emeraldPower; i++) {
        c.restoreHealth(1);
      }
      final rubyPower = c.gemCount(Gem.ruby);
      for (var i = 0; i < rubyPower; i++) {
        c.dealDamage(1);
      }
      final sapphirePower = c.gemCount(Gem.sapphire);
      for (var i = 0; i < sapphirePower; i++) {
        c.gainArmor(1);
      }
    },
    Trigger.onBattle: (c) {
      // Citrine means extra strikes on the first turn:
      // https://discord.com/channels/1041414829606449283/1209488302269534209/1278082886892781619
      for (var i = 0; i < c.gemCount(Gem.citrine); i++) {
        c.queueExtraStrike();
      }
    },
  },
  'Blacksmith Bond': onBattle((c) => c.addExtraExposed(1)),
  // This could also be done using computed stats once we have that.
  'Brittlebark Bow':
      // There are exactly 2 previous strikes during the 3rd strike.
      onHit((c) => _if(c.my.strikesMade == 2, () => c.loseAttack(2))),
  'Swiftstrike Rapier': onInitiative(
    (c) => _if(
      c.my.speed > c.enemy.speed,
      () => c
        ..queueExtraStrike()
        ..queueExtraStrike(),
    ),
  ),
  'Swiftstrike Gauntlet': onWounded((c) => c.queueExtraStrike()),
  'Bonespine Whip': onTurn(
    (c) => c
      ..queueExtraStrike(damage: 1)
      ..queueExtraStrike(damage: 1),
  ),
});
