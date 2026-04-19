# Silverhaven CRPG - Technical Specification

**Version:** 1.3.0
**Last Updated:** 2026-04-18
**Platform:** Godot 4.x + Web (WASM)

---

## Project Overview
- **Platform:** Godot 4.x + Web (WASM)
- **Combat:** Real-time + ATB hybrid
- **License:** D&D 5e SRD

---

## 1. Core Systems

### 1.1 Character System (Character, Player, Enemy)
Base class for all entities with HP/AP and 6 ability scores.

**Ability Scores (D&D 5e):**
```
STR - Strength (Melee damage, Athletics)
DEX - Dexterity (AC, Ranged, Stealth)
CON - Constitution (HP, Saves)
INT - Intelligence (Magic, Skills)
WIS - Wisdom (Perception, Saves)
CHA - Charisma (Social, Divine)
```

**Ability Modifier Formula:**
```
Modifier = floor((Score - 10) / 2)
Example: DEX 16 → Mod = floor(6/2) = +3
```

**HP System:**
```
current_hp: int      # Current hit points
max_hp: int         # Maximum hit points
take_damage(n):     # Reduces HP by n, returns death bool
heal(n):            # Restores HP, capped at max_hp
```

**AP (Action Points) System:**
```
current_ap: int     # Available AP
max_ap: int        # Max AP per turn
use_ap(cost): bool # Spends AP, returns success
restore_ap(n):      # Adds AP, capped at max_ap

Turn Start: current_ap = max_ap + floor(max_ap / 2)
Move Cost: 1 AP per tile
Attack Cost: 2 AP
```

### 1.2 Combat System (BattleSystem Autoload)
Manages turn-based combat with initiative order.

**Combat State Machine:**
```python
enum CombatPhase {
    INIT,           # Setup
    PLAYER_TURN,    # Player actions
    ENEMY_TURN,    # AI actions
    RESOLUTION     # Victory/defeat check
}
```

**Initiative Formula:**
```
initiative = d20 + DEX Modifier + Proficiency (if any)
Sort: descending order (highest goes first)
```

**Combat Flow:**
1. `start_combat(party[], enemies[])` - Initialize
2. Roll initiative for all participants
3. Sort by initiative value
4. `next_turn()` - Process each character's turn
5. `check_combat_end()` - Check victory/defeat
6. Emit `combat_ended(victory: bool)`

**Attack Formula (D&D 5e):**
```
Attack Roll = d20 + Ability Mod + Proficiency Bonus + Weapon Bonus
Damage Roll = Weapon Dice + Ability Mod + Special Bonuses

Example (Fighter with Longsword):
Attack = d20 + 3 (DEX) + 2 (Prof) + 0 = d20 + 5
Damage = 1d8 + 3 (DEX) = 1d8+3 (average 7.5)
```

**AC (Armor Class) Formula:**
```
AC = 10 + Armor + DEX Modifier (limited by armor type)

Light Armor: Full DEX (leather=11, studded=12)
Medium Armor: Max +2 DEX (chain=13-14, scale=14-15)
Heavy Armor: No DEX (chain=16, plate=18)
Shield: +2 AC bonus
Defend Action: +2 AC
```

### 1.3 Movement System (Pathfinding)
A* pathfinding on grid-based map.

**Grid Configuration:**
```
map_width: 20
map_height: 20
tile_size: 2.0 meters

Coordinate System:
- grid_position: Vector2i (grid coordinates)
- global_position: Vector3 (world coordinates)
- Conversion: world = grid * tile_size
```

**Movement Cost:**
```
Walkable: 1 AP per tile
Impassable: -1 (cannot move)
Cover: +1 AP additional cost
Elevated: +2 AP per level
```

### 1.4 Equipment System (D&D Style)

**Weapon Properties:**
```json
{
  "damage": "1d8",        // Dice notation
  "damage_type": "slashing",
  "range": 5,             // Melee in feet
  "properties": ["versatile", "finesse"]
}
```

**Armor Properties:**
```json
{
  "ac": 15,              // Base AC
  "type": "medium",      // light/medium/heavy
  "max_dex": 2           // DEX cap
}
```

**Default Starting Equipment (Fighter):**
- Weapon: Shortsword (1d6, piercing)
- Armor: Leather (AC 11)
- Shield: None

---

## 2. Class System

| Class | HP | Primary | Weapon | Special |
|-------|-----|---------|--------|---------|
| Fighter | d10 | STR | 1d8 | Second Wind (+heal) |
| Rogue | d8 | DEX | 1d6 | Sneak Attack, Cunning Action |
| Wizard | d6 | INT | 1d4 | Spellcasting |
| Cleric | d8 | WIS | 1d8 | Divine Magic |
| Ranger | d8 | DEX | 1d8 | Natural Explorer |
| Barbarian | d12 | STR | 1d12 | Rage (+2 damage) |
| Paladin | d10 | STR/CHA | 1d8 | Divine Smite |
| Bard | d8 | CHA | 1d6 | Inspiration |

---

## 3. Monster Categories

**By Type:**
- `beast` - Animals (spider, bear)
- `humanoid` - Orcs, goblins, elves
- `undead` - Skeletons, ghosts
- `aberration` - Mind flayers

**Challenge Rating (CR):**
```
CR 1/4 = Easy (1-2 goblins)
CR 1/2 = Medium (1-2 orcs)
CR 1-2 = Hard (3-4 enemies)
CR 3+ = Deadly (bosses)
```

**XP Rewards by CR:**
```
1/4: 50 XP
1/2: 100 XP
1: 200 XP
2: 450 XP
3: 700 XP
```

---

## 4. Dungeon Layers

| Layer | Name | Theme | Enemies |
|-------|------|-------|---------|
| 0 | Surface (Silverhaven) | City | None |
| 1 | Underground Prison | Dungeon | Goblin, Skeleton |
| 2 | Ancient Ruins | Ruins | Orc, Drow, Spider |
| 3 | Abyss Gate | Abyss | Mind Flayer, Basilisk, Demons |

---

## 5. 3-Layer Dungeon Manager

### Layer 1: Underground Prison
- Floor 1-3
- Theme: Dark, damp prison cells
- Enemies: Goblins (scouts), Skeletons (guards)
- Special: Locked doors, prisoner cells

### Layer 2: Ancient Ruins
- Floor 1-3
- Theme: Crumbling architecture, hidden passages
- Enemies: Orcs, Drow, Giant Spiders
- Special: Cover positions, trap areas

### Layer 3: Abyss Gate
- Floor 1-3
- Theme: Dark magic, demonic presence
- Enemies: Mind Flayer Spawn, Basilisk, Mist Shadows, Demon Lieutenants
- Special: Boss encounters, story progression

---

## 6. Hidden Lore (7 Truths)

1. **Humans = Living Seal Keys** - Humans are actually "living keys" to maintain the seal
2. **King Qeisar = Contract with Baal-Kar** - The ruler made a deal with the demon lord
3. **Empire's Prosperity = 1000-Year Debt** - The empire's wealth is built on ancient debt
4. **Luminus Magic = Seal-Eating Rituals** - The magic system consumes the seal
5. **Abyssal Apostles = Slave Sacrifice** - Demons use enslaved humans as offerings
6. **Fog-Eating Machine** - Under the village, a machine consumes fog
7. **Nightly Sacrifices** - Every night, slaves are offered to the abyss

---

## 7. Combat Encounter System

### Detection & Surprise
```python
# Stealth vs Perception
Stealth Roll = d20 + Stealth Skill + DEX Mod
Perception = 10 + WIS Mod + Proficiency

If Stealth > Perception: Attacker surprised defender
If Perception >= Stealth: No surprise, normal combat
```

### First Strike System
```
High initiative player ambushes enemy → "AMBUSH!" scene
High initiative enemy surprises player → "SURPRISED!" scene
```

### Combat Scene Overlay
```
Title: "AMBUSH!" or "SURPRISED!" or "COMBAT!"
Subtitle: Enemy name + detection result
Button: "START COMBAT"
```

### Death & Restart
```
Player HP <= 0:
- Log: "Player Died!"
- Scene: "YOU DIED" (red) + "Player has fallen"
- Button: "RESTART" → reload_current_scene()
```

---

## 8. Data Files

### data/terrain.json
```json
{
  "tiles": {
    "0": {"name": "Wall", "walkable": false, "height": 2.0},
    "1": {"name": "Floor", "walkable": true, "height": 0.1},
    "4": {"name": "Cover", "walkable": true, "defense_bonus": 2}
  }
}
```

### data/monsters.json
```json
{
  "monsters": {
    "goblin": {
      "cr": "1/4", "hp": 7, "ac": 13,
      "attacks": [{"name": "Dagger", "damage": "1d6+2"}],
      "xp": 50
    }
  }
}
```

### data/items.json
```json
{
  "categories": {
    "weapon": {
      "melee": [{"id": "longsword", "damage": "1d8"}],
      "ranged": [{"id": "shortbow", "damage": "1d6", "range": 80}]
    },
    "armor": {
      "light": [{"id": "leather", "ac": 11}],
      "medium": [{"id": "chain_shirt", "ac": 13}]
    }
  }
}
```

### data/classes.json
```json
{
  "classes": {
    "fighter": {
      "action_types": {
        "standard": ["Attack", "Charge", "Taunt"],
        "bonus": {"second_wind": {"type": "heal"}}
      }
    }
  }
}
```

---

## 9. Terrain Generation (Future)

### Noise Algorithm Parameters
```
Mountain: High frequency, high amplitude → craggy peaks
Hills: Medium frequency, medium amplitude → gentle slopes
Basin: Low frequency, low amplitude → flat with rim
Delta: Combined river simulation
```

### Elevation-Temperature Formula
```
T = T_sea_level - (0.0065 × height_meters)
Every 100m up = -0.65°C
```

---

## 10. UI System

### Layout
```
+------------------------------------------+
|  [HP Bar] [AP Bar]  |  [Equipment Slots] |
|---------------------|---------------------|
|                      | [Inventory Tabs]    |
|   (Game World)      | [Skills]            |
|                      |---------------------|
|                      | [Game Log - Bottom] |
+------------------------------------------+
         [Inventory] [Skills] (Popup)
```

### Game Log
- System: Gray text (prefixed with #)
- Combat: Orange text (prefixed with >)
- Updates every frame with scroll follow

---

## 11. Input Controls

| Input | Action |
|-------|--------|
| WASD | Movement (grid-based) |
| Mouse Click | Path move to target |
| Enter/Space | End turn / Attack |
| I Key | Toggle Inventory |
| K Key | Toggle Skills |

---

## 12. File Structure

```
crpg_prototype/
├── project.godot           # Engine config (autoloads)
├── scenes/
│   └── main.tscn           # Main game scene
├── scripts/
│   ├── autoload/
│   │   └── game_manager.gd
│   ├── entities/
│   │   ├── character.gd    # Base class
│   │   ├── player.gd       # Player subclass
│   │   └── enemy.gd        # Enemy subclass
│   ├── systems/
│   │   ├── main_controller.gd
│   │   ├── combat_manager.gd
│   │   ├── pathfinding.gd
│   │   ├── ui_manager.gd
│   │   └── level_manager.gd
│   └── data/
│       └── content.gd
├── data/
│   ├── terrain.json
│   ├── monsters.json
│   ├── items.json
│   ├── classes.json
│   ├── bloodlines.json
│   └── monsters_additional.json
└── docs/
    └── research.md          # This file
```

---

## 13. Race System (D&D 5e SRD)

| Race | Ability Score Increases | Traits |
|------|-------------------|--------|
| Human | +1 all | - |
| Elf | +2 DEX | Darkvision 60ft, Fey Ancestry |
| Dwarf | +2 CON, +1 WIS | Darkvision, Dwarven Resilience |
| Halfling | +2 DEX, +1 CHA | Lucky, Brave |
| Orc | +2 STR, -2 INT | Aggressive, Menacing |
| Dragonborn | +2 STR, +1 CHA | Breath Weapon, Draconic Resistance |
| Gnome | +2 INT, +1 DEX | Darkvision, Gnome Cunning |
| Half-Elf | +2 CHA | Darkvision, Fey Ancestry |
| Half-Orc | +2 STR, +1 CON | Relentless Endurance, Aggressive |
| Tiefling | +2 CHA, +1 INT | Hellish Resistance, Infernal Legacy |

---

## 14. Character Creation Flow

```
[1] Race Selection (10 races)
    ↓
[2] Bloodline/Clan Selection (Human→4 Bloodlines, Orc→5 Clans)
    ↓
[3] Class Selection (8 classes)
    ↓
[4] Background (bloodlines.json)
    ↓
[5] Point Buy Stats (27 points) → Race/Bloodline bonuses
    ↓
[6] Title Selection (Class-based)
    ↓
[7] Name Input
    ↓
[8] Starting Location (Auto-determined by Bloodline/Clan)
    ↓
[9] Tutorial Start
```

---

## 15. Implementation Plan

| Step | Task | File | Dependency |
|------|------|------|-----------|
| 1 | Create races.json | data/races.json | D&D 5e SRD |
| 2 | Create backgrounds.json | data/backgrounds.json | bloodlines.json |
| 3 | Create character_creation.tscn | scenes/character_creation.tscn | - |
| 4 | Create character_creation.gd | scripts/systems/character_creation.gd | races.json, backgrounds.json |

---

## 13. TODO Status

### Completed
- [x] Grid-based movement
- [x] A* pathfinding
- [x] Turn-based combat
- [x] D&D attack/damage formulas
- [x] Equipment system
- [x] Monster spawn (beasts)
- [x] Combat encounter detection
- [x] Surprise system
- [x] Death/restart
- [x] UI (HP/AP/Equipment/Inventory)
- [x] Game log
- [x] 3-layer dungeon structure

### In Progress
- [x] races.json (Character Creation)
- [x] backgrounds.json
- [x] character_creation.tscn
- [x] character_creation.gd

### Character Creation (COMPLETED 2026-04-15)
- [x] 10 races with D&D 5e SRD abilities
- [x] 4 bloodlines for humans
- [x] Point Buy system (27 points)
- [x] Class selection (8 classes)
- [x] Auto start location by bloodline

### Phase 2: Simulation Systems (COMPLETED 2026-04-15)
- [x] Resources: food, mineral, magic_crystal, trade_goods
- [x] Settlements: 8 major locations
- [x] Trade routes (graph-based)
- [x] Political factions: 8 factions with personality templates
- [x] World simulation: fog_density, grid_resonance, orc_disposition
- [x] Emergent events: famine, plague, invasion, grid_surge

### Phase 3: Monster + Item Systems (COMPLETED 2026-04-15)
- [x] New beasts (monsters.json): rabbit, deer, wolf, dire_wolf, boar, bear, tiger, grizzly
- [x] New humanoids: kobold, bugbear
- [x] New undead: zombie, ghoul
- [x] Session monsters (monsters_session.json): fog_beast, noise_creature, demon_hunter, void_construct, abyssal_spawn
- [x] Monster spawner: Session variable integration (fog/orc/grid modifiers)
- [x] Loot system: Gold + item drops by CR, session variable bonuses

### Future
- [x] Tutorial scenario (IMPLEMENTED 2026-04-15)
- [ ] Skill system (47 skills)
- [ ] Spell system
- [ ] Cover/flanking mechanics

---

## 16. Bug Fixes (2026-04-18)

### Bug: OptionButton text not visible (Race/Class dropdown)

**Symptom:**
- Race/Class dropdowns show item_count (10/8) but text is invisible
- Bloodline dropdown works (code-based add_item)

**Cause:**
- TSCN-defined static items have theme/rendering issues in Godot 4.x
- Dynamic add_item() rebuilds theme, making text visible

**Solution:**
```gdscript
func _populate_race_options():
    option.clear()  # Clear TSCN items
    var race_names = ["인간", "엘프", "드워프", ...]
    for i in range(race_names.size()):
        option.add_item(race_names[i], i)  # Recreate in code
```

### Bug: JSON parsing failure (Korean characters)

**Symptom:**
- "Parse JSON failed. Error at line 43: Unexpected character"

**Cause:**
- Korean special characters in JSON files cause Godot parser to fail
- Files have UTF-8 BOM but parser still fails

**Solution:**
- Added fallback hardcoded data in game_manager.gd
- Functions: `_get_default_races()`, `_get_default_backgrounds()`

### Bug: session_setup.gd node not found

**Solution:**
- Changed get_node() to find_child() for all nodes

### Bug: Autoload node duplicate creation

**Solution:**
- Removed _create_simulation_nodes() 
- Modified _configure_simulation() to use existing Autoload nodes

### Bug: wfc_system.gd Parse error

**Solution:**
- Changed _init() to _ready() + set_size()

### Bug: world_simulation.gd integer division

**Solution:**
- Changed `int(day_count / 90)` to `int(day_count / 90.0)`

### Bug: character_creation.gd race selection not applying bonuses

**Solution:**
- Added `race_keys` array to map index to correct race ID
- Connected `item_selected.connect(_on_race_selected)` signal
- Fixed `_apply_bloodline_bonus()` to properly apply bloodline ability scores
- Added direct backgrounds_data loading fallback

### Bug: ui_manager.gd English labels

**Solution:**
- Translated STATUS → 상태
- Translated MINIMAP → 미니맵
- Translated EQUIPMENT → 장비
- Translated GAME LOG → 게임 로그
- Translated Skills → 스킬
- Translated Inventory → 인벤토리
- [ ] Story progression