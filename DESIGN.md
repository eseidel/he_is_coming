# Design

Attempting to document He Is Coming design to see what we need to sim.

## Events
Campfire (+10 hp, skip to morning)
House (full hp, skip to morning)
Chest (common items)
Jewelry Box (Jewelry Items)
Grave (epic items)
Anvil (weapon edge)
Oil (weapon oil)
Merchant (items for sale)
Lookout Tower (reveal map, ignored)
Crystal Ball (reveal event, ignored)
Golem (weapon combiner)
Cauldron (food combiner)

## TODO

Confirm Cracked Bouldershield is common.
Confirm Granite Hammer has attack 2.

Add a trigger for death, rather than checking once a turn.  Otherwise it's
possible to go negative and heal up in the same turn (with separate triggers
for onTurn and onHit for example).


To Test:

Heart Drinker + Jagged Edge + Speed Oil
Horned Helmet
Iron Rose
Crimson Cloak
Impressive Physique
Iron Transfusion
Tree Sap
Sapphire Earing
Emerald Earing

58 dmg, 15 turns.

Currently our sim says:
Woodland Abomination wins in 15 turns with 60 damage taken.
Probably thorns doesn't apply once we're dead?


To Test:

Granite Hammer
Sapphire Gemstone
Iron Rose
Iron Rose
Sanguine Rose
Crimson Cloak
Golden Sapphire Earing
Fortified Gauntlet
Fortified Gauntlet

146 dmg, turn 13


## Missing Effects

### Damage Modifiers:
  Deal double damage to armor for Battle Axe
- onModifyDamageThem(c.multiplyArmorDamage(2))

  Take 3 additional damage from the enemies first strike for Bearpelt Plate
- onModifyDamageMe((c) => _if(c.them.isFirstStrike, c.addDamage(3))

  Whenever you take damage, take 1 additional damage for Brittlebark Armor
- onModifyDamageMe((c) => c.addDamage(1))

  Battle Start: If your speed is 6 or higher, your strikes deal double damage for Citrine Crown
- onBattle(_if(c.me.speed >= 6))

  Enemies first strike ignores armor for Phantom Armor
- onModifyDamageMe(_if(c.them.isFirstStrike, c.ignoreArmor))

  The first time the enemy strikes, their damage is halved for Protecting Charm
- onModifyDamageMe(_if(c.them.isFirstStrike, c.multiplyDamage(.5)))

  Whenever Brittlebark Beast takes damage, he takes 2 additional damage for Brittlebark Beast
- onModifyDamageMe((c.addDamage(2)))

  Whenever Gentle Giant takes damage he gains 2 thorns.  Wounded: Gain 4 thorns instead for Gentle Giant
- onTakeDamage(c.gainThorns(c.isWounded ? 4 : 2))

### Computed Stats
  Your speed stat is inverted for Citrine Gemstone
- Computed Stats

  Gain 2 health for each equipped wood item for Oak Heart
- Computed Stats


### Temporary Stats
  Gain 2 attack for each thorns for Blackbriar Blade
- Temporary Stats modifiers

  When you have armor gain 3 attack for Ironstone Sandals
- Computed Stats

  First Turn: Gain 2 attack for Cracked Whetstone
- Temporary Stat modifiers or onTurnEnd?


### Other stuff

  Exposed can trigger one additional time for Blacksmith Bond
- Expose Counter

  Do two additional strikes that always deal 1 damage for Bonespine Whip
- Additional Strikes?  or onAfterAttack?

  Wounded: Do an additional strike on your next turn for Dueling Gauntlet
- Additional Strikes

  First Turn: If you have more speed than the enemy, do 2 additional strikes for Swiftstrike Rapier
- OnAfterAttack?

  After 3 strikes, lose 2 attack for Brittlebark Bow
- onAfterStrike?

  Exposed & Wounded: Lose 2 attack for Brittlebark Club
- wasExposed/wasWounded?

  Overhealing is dealt as damage for Emerald Gemstone
- onOverheal?

  Draws power from emerald, ruby, sapphire and citrine items for Gemstone Scepter
- Unclear effects

  The next weapon you equip gains 2 attack for Grindstone Club
- onWeaponEquip

  Every 3 strikes, deal triple damage for Haymaker
- Strike Counter
- Damage Modifier

  Gets stronger for every new hidden dagger you find for Hidden Dagger
- OnWeaponEquip?

  Whenever you deal damage to the enemy's armor, gain that much armor for Hook Blade
- onEnemyArmorDamage?

  Resilience: 50% chance to survive with 1 health for Lifethread Pendant
- Random

  Battle Start: If your health is full, gain 1 thorn at turn start for the rest of battle for Pinecone Plate
- Per-effect state?

  Exposed: Armor now deals damage when removed for Razor Scales
- OnArmorDamage

  Whenever you lose armor, restore that much health for Sapphire Gemstone
- OnArmorDamage

  Whenever you gain thorns, gain 1 additional thorn for Razorvine Talisman
- OnGainThorn

  Whenever you restore health, restore 1 additional health for Sanguine Rose
- Health adjust modifiers


WARNING: 15 Creatures with missing effects found:
  Bear deals 3 additional damage while you have armor for Bear Level 1
- ComputedStats?  OnEnemyGainArmor?
  Bear deals 5 additional damage while you have armor for Bear Level 2
  Bear deals 7 additional damage while you have armor for Bear Level 3
  Ignores armor for Bearserker

- Possible today
  If Hothead has more speed than you, his first strike deals 10 additional damage for Hothead
- Damage Modifier?  Or onHit?
  Mountain Troll only strikes every other turn for Mountain Troll
- onWillStrike?  How does this interact with stun?
  Strikes steal gold instead of dealing damage for Raven Level 2
- Damage modifier?
  Battle Start: If Razortusk Hog has more speed than you, he strikes twice for the rest of the battle for Razortusk Hog
- HadMoreSpeedAtStart?
- OnExtraStrikes?
  Redwood Treant's attack is halved against armor for Redwood Treant
- DamageModifiers?
  If Stormcloud Druid takes damage more than once per turn, stun the player for 1 turn for Stormcloud Druid
- Damage Counters?
  If player has 5 or less health, wolf gains 2 attack for Wolf Level 1
- ComputedStats?
  If player has 5 or less health, wolf gains 3 attack for Wolf Level 2
  If player has 5 or less health, wolf gains 4 attack for Wolf Level 3
All Oil effects found.
WARNING: 2 Edges with missing effects found:
  Do an additional strike on your first turn for Agile Edge
- OnExtraStrikes
  Only strike every other turn, but deal double damage for Titan's Edge
- StrikeEveryOtherTurn