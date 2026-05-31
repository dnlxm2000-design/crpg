# 실버헤븐 (Silverhaven) — 마을 모습

## Reference Image
MOUSEDON (Watabou village generator, seed 1985091567)

---

## Style Guide

```
Type: A clean, classic fantasy RPG settlement map.

Art Style: Clear hand-drawn digital illustration line art with muted, rustic colors
(deep greens, soft blues, earthy browns).

Viewpoint: Top-down, birds-eye grid perspective.

Tone: Cozy, secluded, and organized rural village.
```

---

## Geography & Environment

### The River
```
A wide, calm river flows from the left side of the map to the right side,
carving through the southern half of the settlement. The river enters from the
west (middle height), curves through the lower-center with a gentle S-curve,
and exits to the east. The river is wide (6-8 tiles width) with tree-lined
banks on both sides. Two simple wooden plank bridges cross the river from
the village to the southwestern bank, where a faint dotted dirt path
continues off-map.
```

### The Forest
```
Dense, thick clusters of dark green pine and deciduous trees surround the
entire clearing on the north, east, and south sides, creating a highly
isolated "pocket" in nature. The forest acts like a natural wall around
the village — thickest on the outer edges, thinning slightly near the
village perimeter. Only the river corridor breaks the forest wall.
```

### Agricultural Fields
```
Northern Sector (main): Large, plowed farming plots neatly carved out of
the forest at the top of the map, north of the village center. These form
the primary agricultural area, roughly 10×10 tiles in size.

Southeastern Sector: Two smaller, rectangular crop fields nestled inside
the village clearing, bordered by trees. Located southeast of the village
center, north of the river, roughly 5×8 tiles each.
```

---

## Village Infrastructure

### The Settlement
```
Name: 실버하벤 (Silverhaven)
Population: ~100
Type: Tight-knit frontier hamlet

A small frontier hamlet sits in the upper-center of the map, north of the
river. Approximately 20-25 rustic cottages with gabled roofs cluster tightly
around a central open plaza or village green. Winding dirt paths snake
through the clearing, converging into the central plaza. The buildings
are arranged organically, not in a strict grid pattern.
```

### Castle / Dungeon
```
A stone castle or dungeon ruin sits at the top-right (northeast) of the
village, elevated on a small hill. It is the largest structure in the area,
constructed from weathered grey stone. A dirt path connects it to the
village center.
```

### Roads & Plaza
```
Winding dirt paths connect all buildings to each other and to the central
plaza. The plaza is an organic, open village green where paths converge.
Main paths lead from the village center to each bridge, and from the
village to the castle in the northeast.
```

### Bridges
```
Two simple wooden plank bridges cross the river:
- Bridge 1: Western crossing — connects village to southwestern bank
- Bridge 2: Eastern crossing — connects village center to southwestern bank
Each bridge is wide enough for foot traffic and carts.
```

---

## Grid Layout (63×126)

```
[North y=0]
  ┌─────────────────────────────────────────────────┐
  │  🌲🌲🌲🌲🌲🌲  FOREST  🌲🌲🌲🌲🌲🌲          │
  │         ┌─────────────────────┐                  │
  │    🏰   │   NORTH FIELDS     │  🌲🌲🌲🌲        │
  │  (성)   │  (큰 농경지)       │                  │
  │         └─────────────────────┘                  │
  │   🌲🌲  ┌──┐   ┌──┐   ┌──┐   ┌──┐   🌲🌲       │
  │         │집│   │집│   │집│   │집│                │
  │         ├──┤   ├──┤   ├──┤   ├──┤               │
  │   🌲    │집│   │■광장│   │집│   │집│    🌲       │
  │         ├──┤   ├──┤   ├──┤   ├──┤               │
  │   🌲🌲  └──┘   └──┘   └──┘   └──┘   🌲🌲       │
  │                      ┌──┐  ┌──┐                 │
  │  🌲🌲   SOUTHEAST    │밭│  │밭│   🌲🌲          │
  │         FIELDS       └──┘  └──┘                  │
  │  🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲               │
  ├─────────────────────────────────────────────────┤
  │  ═══════  RIVER  ═══════  (wide, S-curve)  ═══  │
  │  🌲🌲🌲  🌲🌲🌲  🌲🌲🌲  🌲🌲🌲  🌲🌲🌲       │
  └─────────────────────────────────────────────────┘
[South y=126]
```

### Grid Coordinates

| Element | Grid Position | Size / Radius |
|---------|--------------|---------------|
| Village center | (30, 45) | ~20-25 buildings |
| Castle | (46, 25) | ~4×4 tiles |
| North fields | (30, 18) | ~10×10 tiles |
| SE fields | (45, 63) | ~5×8 tiles each |
| River | y≈80-100 | 6-8 tiles wide |
| Bridge 1 | x≈16, y≈88 | 8-12 tiles long |
| Bridge 2 | x≈38, y≈95 | 8-12 tiles long |
| Forest margin | all edges | 5-15 tiles deep |

---

## Implementation Prompt

```prompt
Top-down fantasy RPG settlement map. A clean, classic medieval village layout.

GEOGRAPHY:
- A wide river flows from left to right through the southern half of the map
- Gentle S-curve river path with tree-lined banks
- Dense forest surrounds the clearing on north, east, and south sides
- River acts as the southern border of the settlement

VILLAGE:
- ~20-25 rustic cottages with gabled roofs clustered around a central plaza
- Winding dirt paths connecting buildings to plaza and bridges
- Located in the upper-center, north of the river
- Secluded, cozy frontier hamlet feel

SPECIAL STRUCTURES:
- Stone castle/dungeon ruin on a hill in the northeast
- Two wooden plank bridges crossing the river to the southwest bank
- Large plowed farming fields in the northern sector
- Two smaller rectangular crop fields in the southeast

STYLE:
- Clear hand-drawn line art style
- Muted rustic colors: deep greens, soft blues, earthy browns
- Top-down birds-eye grid perspective
- Cozy, organized, secluded rural village tone
```
