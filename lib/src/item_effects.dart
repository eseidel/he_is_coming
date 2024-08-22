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
  'Stone Steak': Effects(
    onBattle: (c) => _if(c.isHealthFull, () => c.gainArmor(4)),
  ),
  'Redwood Cloak': Effects(onBattle: (c) => c.restoreHealth(1)),
  'Emergency Shield': Effects(
    onBattle: (c) => _if(c.my.speed < c.enemy.speed, () => c.gainArmor(4)),
  ),
  'Granite Gauntlet': Effects(onBattle: (c) => c.gainArmor(5)),
  'Ruby Earing': Effects(
    onTurn: (c) => _if(c.isEveryOtherTurn, () => c.dealDamage(1)),
  ),
  'Firecracker Belt':
      Effects(onExposed: (c) => [1, 1, 1].forEach(c.dealDamage)),
  'Redwood Helmet': Effects(onExposed: (c) => c.restoreHealth(3)),
  'Explosive Surprise': Effects(onExposed: (c) => c.dealDamage(5)),
  'Cracked Bouldershield': Effects(onExposed: (c) => c.gainArmor(5)),
  'Vampiric Wine': Effects(onWounded: (c) => c.restoreHealth(4)),
  'Mortal Edge': Effects(
    onWounded: (c) => c
      ..gainAttack(5)
      ..takeDamage(2),
  ),
  'Lifeblood Burst': Effects(onWounded: (c) => c.dealDamage(c.my.maxHp ~/ 2)),
  'Chain Mail': Effects(onWounded: (c) => c.gainArmor(3)),
  'Stoneslab Sword': Effects(onHit: (c) => c.gainArmor(2)),
  'Heart Drinker': Effects(onHit: (c) => c.restoreHealth(1)),
  'Gold Ring': Effects(onBattle: (c) => c.gainGold(1)),
  'Ruby Ring': Effects(
    onBattle: (c) => c
      ..gainAttack(1)
      ..takeDamage(2),
  ),
  'Ruby Crown': Effects(
    onBattle: (c) => _if(c.my.attack >= 6, () => c.gainAttack(2)),
  ),
  'Melting Iceblade': Effects(onHit: (c) => c.loseAttack(1)),
  'Double-edged Sword': Effects(onHit: (c) => c.takeDamage(1)),
  'Sapphire Crown': Effects(
    onBattle: (c) => _if(c.my.armor >= 15, () => c.gainArmor(10)),
  ),
  'Citrine Ring': Effects(
    onBattle: (c) => _if(c.my.speed > 0, () => c.dealDamage(c.my.speed)),
  ),
  'Marble Mirror': Effects(
    onBattle: (c) => _if(c.enemy.armor > 0, () => c.gainArmor(c.enemy.armor)),
  ),
  // This might be wrong, since this probably should be onTurn?
  // "If you have more speed than the enemy, gain 2 attack"
  'Leather Boots': Effects(
    onBattle: (c) => _if(c.my.speed > c.enemy.speed, () => c.gainAttack(2)),
  ),
  'Plated Helmet': Effects(
    onTurn: (c) => _if(c.my.belowHalfHp, () => c.gainArmor(2)),
  ),
  'Ore Heart': Effects(
    onBattle: (c) => c.gainArmor(c.materialCount(Material.stone) * 2),
  ),
  'Granite Hammer': Effects(
    onHit: (c) => _if(
      c.my.armor > 0,
      () => c
        ..loseArmor(-1)
        ..gainAttack(2),
    ),
  ),
  'Iron Transfusion': Effects(
    onTurn: (c) => c
      ..gainArmor(2)
      ..loseHealth(1),
  ),
  'Fortified Gauntlet': Effects(
    onTurn: (c) => _if(c.my.armor > 0, () => c.gainArmor(1)),
  ),
  'Iron Rose': Effects(onHeal: (c) => c.gainArmor(1)),
  'Featherweight Coat': Effects(
    onBattle: (c) => _if(
      c.my.armor > 0,
      () => c
        ..loseArmor(-1)
        ..gainSpeed(3),
    ),
  ),
  'Sticky Web': Effects(
    onBattle: (c) => _if(c.my.speed < c.enemy.speed, () => c.stunEnemy(1)),
  ),
  'Impressive Physique': Effects(onExposed: (c) => c.stunEnemy(1)),
  'Steelbond Curse': Effects(onBattle: (c) => c.giveArmorToEnemy(8)),
  // Bejeweled Blade doesn't say "On Battle Start". This might be subtly wrong?
  'Bejeweled Blade': Effects(
    onBattle: (c) => _if(
      c.kindCount(Kind.jewelry) > 0,
      () => c.gainAttack(c.kindCount(Kind.jewelry) * 2),
    ),
  ),
  "Woodcutter's Axe": Effects(onHit: (c) => c.reduceEnemyMaxHp(2)),
  'Emerald Ring': Effects(onBattle: (c) => c.restoreHealth(2)),
  'Ironskin Potion': Effects(
    onBattle: (c) => _if(c.my.lostHp > 0, () => c.gainArmor(c.my.lostHp)),
  ),
  'Double-plated Armor': Effects(onExposed: (c) => c.gainArmor(3)),
  'Sapphire Earing':
      Effects(onTurn: (c) => _if(c.isEveryOtherTurn, () => c.gainArmor(1))),
  'Emerald Earing': Effects(
    onTurn: (c) => _if(c.isEveryOtherTurn, () => c.restoreHealth(1)),
  ),
  'Emerald Crown': Effects(
    onBattle: (c) => _if(
      c.my.maxHp >= 20 && c.my.lostHp > 0,
      () => c.restoreHealth(c.my.lostHp),
    ),
  ),
  'Sapphire Ring': Effects(onBattle: (c) => c.stealArmor(2)),
  'Horned Helmet': Effects(onBattle: (c) => c.gainThorns(2)),
  'Crimson Cloak': Effects(onTakeDamage: (c) => c.restoreHealth(1)),
  'Tree Sap':
      Effects(onWounded: (c) => [1, 1, 1, 1, 1].forEach(c.restoreHealth)),
  'Petrifying Flask': Effects(
    onWounded: (c) => c
      ..gainArmor(10)
      ..stunSelf(2),
  ),
};
