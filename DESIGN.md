# Design

Attempting to document He Is Coming design to see what we need to sim.

## Character
Has stats (attack, health, armor, speed)
Also has current hp and current gold.
Depending on your level you have N slots.
level 1: 1 weapon + 4 slots
level 2: 1 weapon + 6 slots
level 3: 1 weapon + 8 slots

## Items
Items have name, stats, effects, tags and rarity (another tag?).
Item effects:
- onTurn
- onBattle
- onHit
- onExposed
- onWounded

## Battle
There is an opponent during battle.
Items only matter during battle.
The resolution of battle is some change in hp as well as gold.

## Creatures
- Wolf (+X if below 5 hp)
- Spider (first turn dmg if slower than)
- Bear (+X dmg when armored)

## Bosses
Level 1
- Black Knight
- Hot Head

Level 2
- Mountain Troll
- Rock Golem

Level 3
- Leshen
- Gentle Giant

Final
- Woodland Abomination


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

## Achievements
These unlock additional items.