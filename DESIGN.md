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

Add a trigger for death, rather than checking once a turn.  Otherwise it's
possible to go negative and heal up in the same turn (with separate triggers
for onTurn and onHit for example).

### Questions

Can attack go negative (e.g. multiple emerald crowns).  And if when attack is 0 does onHit fire?

Do negative onHit effects apply during the killing blow?
Positive onHit effects (like healing) resolve on the killing blow, so I suspect thorns do too?

Does a heal of 0 counts as triggering "whenever you restore health"?

## Missing Effects

### Damage Modifiers:
- Deal double damage to armor for Battle Axe
- Every 3 strikes, deal triple damage for Haymaker
- Ignores armor for Bearserker
- Redwood Treant's attack is halved against armor for Redwood Treant
- Strikes steal gold instead of dealing damage for Raven Level 2
- The first time the enemy strikes, their damage is halved for Protecting Charm

### Contextual Battle Stats
- Bear deals 3 additional damage while you have armor for Bear Level 1
- Bear deals 5 additional damage while you have armor for Bear Level 2
- Bear deals 5 additional damage while you have armor for Crazed Honeybear Level 3
- Bear deals 7 additional damage while you have armor for Bear Level 3
- Gain 2 attack for each thorns for Blackbriar Blade
- If Hothead has more speed than you, his first strike deals 10 additional damage for Hothead
- If player has 5 or less health, wolf gains 2 attack for Wolf Level 1
- If player has 5 or less health, wolf gains 3 attack for Wolf Level 2
- If player has 5 or less health, wolf gains 4 attack for Wolf Level 3
- When you have armor gain 3 attack for Ironstone Sandals

### Stat Modifiers
- Double your max health for Honey Ham

### Stat Overrides
- Attack is always equal to missing health for Bearclaw Blade
- Attack is always equal to speed for Tempest Blade
- Your speed stat is inverted for Citrine Gemstone

### Temporary Stats
- First Turn: Gain 2 attack for Cracked Whetstone
  Temporary Stat modifiers or onTurnEnd?

### OnEquip
- The next weapon you equip gains 2 attack for Grindstone Club
- Gets stronger for every new hidden dagger you find for Hidden Dagger

### Strike every other turn
- Mountain Troll only strikes every other turn for Mountain Troll
- Only strike every other turn, but deal double damage for Titan's Edge

### Other stuff
- Gain 15 gold after a boss is defeated for Boss Contract

- If Stormcloud Druid takes damage more than once per turn, stun the player for 1 turn for Stormcloud Druid
  Damage Counters?

- Initiative: If you have more speed than the enemy, lose 2 speed and trigger Initiative for Energy Crystal

- Lose all your armor after your opponent's first strike for Brittlebark Buckler
  afterEnemyStrike?

- Resilience: 50% chance to survive with 1 health for Lifethread Pendant
  onDeath

- When you are reduced to exactly 1 health for the first time, restore health to full for Heart-shaped Potion

- When the enemy has lost 50% health, trigger all of your wounded items for Blood Bond

- Whenever you deal damage to the enemy's armor, gain that much armor for Hook Blade
  onEnemyArmorDamage?

- Whenever you deal non-weapon damage to the enemy, deal 1 additional damage for Sword Talisman

