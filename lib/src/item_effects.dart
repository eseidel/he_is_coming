import 'package:he_is_coming/src/effects.dart';
import 'package:he_is_coming/src/item.dart';

// Dart doesn't have if-expressions, so made a helper function.
void _if(bool condition, void Function() fn) {
  if (condition) {
    fn();
  }
}

/// Effects that can be triggered by items.
final itemEffects = <String, Effects>{
  'Stone Steak': onBattle((c) => _if(c.my.isHealthFull, () => c.gainArmor(4))),
  'Redwood Cloak': onBattle((c) => c.restoreHealth(1)),
  'Emergency Shield': onBattle(
    (c) => _if(c.my.speed < c.enemy.speed, () => c.gainArmor(4)),
  ),
  'Granite Gauntlet': onBattle((c) => c.gainArmor(5)),
  'Ruby Earing': onTurn((c) => _if(c.isEveryOtherTurn, () => c.dealDamage(1))),
  'Firecracker Belt': onExposed((c) => [1, 1, 1].forEach(c.dealDamage)),
  'Redwood Helmet': onExposed((c) => c.restoreHealth(3)),
  'Explosive Surprise': onExposed((c) => c.dealDamage(5)),
  'Cracked Bouldershield': onExposed((c) => c.gainArmor(5)),
  'Vampiric Wine': onWounded((c) => c.restoreHealth(4)),
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
  'Ruby Crown': onBattle((c) => _if(c.my.attack >= 6, () => c.gainAttack(2))),
  'Melting Iceblade': onHit((c) => c.loseAttack(1)),
  'Double-edged Sword': onHit((c) => c.takeDamage(1)),
  'Sapphire Crown': onBattle(
    (c) => _if(c.my.armor >= 15, () => c.gainArmor(10)),
  ),
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
  'Plated Helmet': onTurn((c) => _if(c.my.belowHalfHp, () => c.gainArmor(2))),
  'Ore Heart': onBattle(
    (c) => c.gainArmor(c.materialCount(Material.stone) * 2),
  ),
  'Granite Hammer': onHit(
    (c) => _if(
      c.my.armor > 0,
      () => c
        ..loseArmor(-1)
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
  'Iron Rose': Effects(onHeal: (c) => c.gainArmor(1)),
  'Featherweight Coat': onBattle(
    (c) => _if(
      c.my.armor > 0,
      () => c
        ..loseArmor(-1)
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
      c.kindCount(Kind.jewelry) > 0,
      () => c.gainAttack(c.kindCount(Kind.jewelry) * 2),
    ),
  ),
  "Woodcutter's Axe": onHit((c) => c.reduceEnemyMaxHp(2)),
  'Emerald Ring': onBattle((c) => c.restoreHealth(2)),
  'Ironskin Potion': onBattle(
    (c) => _if(c.my.lostHp > 0, () => c.gainArmor(c.my.lostHp)),
  ),
  'Double-plated Armor': onExposed((c) => c.gainArmor(3)),
  'Sapphire Earing':
      Effects(onTurn: (c) => _if(c.isEveryOtherTurn, () => c.gainArmor(1))),
  'Emerald Earing': onTurn(
    (c) => _if(c.isEveryOtherTurn, () => c.restoreHealth(1)),
  ),
  'Emerald Crown': onBattle(
    (c) => _if(
      c.my.maxHp >= 20 && c.my.lostHp > 0,
      () => c.restoreHealth(c.my.lostHp),
    ),
  ),
  'Sapphire Ring': onBattle((c) => c.stealArmor(2)),
  'Horned Helmet': onBattle((c) => c.gainThorns(2)),
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
};
