#!/usr/bin/env python3
"""ASCII Art to PNG Image Generator for Silverhaven World Map"""

from PIL import Image, ImageDraw, ImageFont
import os

def ascii_to_image(ascii_art: str, output_path: str, 
                   font_size: int = 12, 
                   bg_color: str = "#1a1a2e",
                   text_color: str = "#e0e0e0",
                   padding: int = 20):
    """Convert ASCII art to PNG image"""
    
    lines = ascii_art.strip().split('\n')
    
    # Try to use a monospace font
    font_sizes = [14, 12, 10, 8]
    font = None
    
    for size in font_sizes:
        try:
            font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", size)
            font_size = size
            break
        except:
            try:
                font = ImageFont.truetype("C:/Windows/Fonts/cour.ttf", size)
                font_size = size
                break
            except:
                continue
    
    if font is None:
        font = ImageFont.load_default()
    
    # Calculate dimensions
    dummy_img = Image.new('RGB', (1, 1))
    dummy_draw = ImageDraw.Draw(dummy_img)
    
    max_width = 0
    for line in lines:
        bbox = dummy_draw.textbbox((0, 0), line, font=font)
        width = bbox[2] - bbox[0]
        max_width = max(max_width, width)
    
    line_height = font.getmetrics()[0] + font.getmetrics()[1] + 2
    
    img_width = max_width + (padding * 2)
    img_height = (len(lines) * line_height) + (padding * 2)
    
    # Create image
    img = Image.new('RGB', (img_width, img_height), bg_color)
    draw = ImageDraw.Draw(img)
    
    # Draw text
    y = padding
    for line in lines:
        draw.text((padding, y), line, font=font, fill=text_color)
        y += line_height
    
    img.save(output_path)
    print(f"Saved: {output_path}")

def main():
    # Ensure output directory exists
    os.makedirs("crpg_prototype/docs/maps", exist_ok=True)
    
    # Silverhaven Continent Map
    continent_map = """\
┌─────────────────────────────────────────────────────────────────────────┐
│                     【 SILVERHAVEN CONTINENT 】                             │
│                                                                             │
│    ════════════════════════════════════════════════════════                 │
│    ║                    【 NORTHERN ICEWALL 】                ║            │
│    ════════════════════════════════════════════════════════                 │
│                             ┃┃┃┃┃┃                                         │
│                      EDELWEISS (Alliances)                               │
│    ┌────────────────────────┼────────────────────────────────┐          │
│    │                         ┃                                │          │
│    │  ┌─────────┐    ┌──────┼──────┐    ┌─────────┐     │          │
│    │  │IRON GUARD│────│CENTRAL │────│ ETHERIA │     │          │
│    │  │(Military)│    │ HIGHLAND│    │(Religious)│     │          │
│    │  └─────────┘    └────────┘    └─────────┘     │          │
│    │       ┃                                     ┃              │          │
│    │  ┌────┼────┐                        ┌────┼────┐     │          │
│    │  │NOVA│    │                        │VENTUS│    │     │          │
│    │  │(Magic)│    │                        │(Trade)│    │     │          │
│    │  └────────┘    │                        └────────┘     │          │
│    │                  │                                              │          │
│    │  ┌──────────────┼──────────────────────────────────┐        │          │
│    │  │              ┃                                      │        │          │
│    │  │     ┌───────┴───────┐    ┌────────────┐        │        │          │
│    │  │     │   MISTRAL     │    │  SOLARIS  │        │        │          │
│    │  │     │  (SILVERHAVEN)│    │  (Desert) │        │        │          │
│    │  │     │      ★        │    │           │        │        │          │
│    │  │     └───────────────┘    └────────────┘        │        │          │
│    │  │                                                   │        │          │
│    │  └─────────────────────────────────────────────────┘        │          │
│    └───────────────────────────────────────────────────────────────┘          │
│                                                                             │
│    ════════════════════════════════════════════════════════════                 │
│    ║               【 FREE PORTS - Sea of Lawlessness 】          ║          │
│    ════════════════════════════════════════════════════════════                 │
└─────────────────────────────────────────────────────────────────────────┘"""

    ascii_to_image(continent_map, "crpg_prototype/docs/maps/continent_map.png")
    
    # Silverhaven Village Detail Map
    village_map = """\
┌────────────────────────────────────────────────────────────────────────┐
│                    【 SILVERHAVEN VILLAGE DETAIL 】                        │
│                                                                         │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │ 【 UPPER DISTRICT 】 ⬆️                                        │   │
│  │                                                              │   │
│  │    ┌──────────────┐      ┌──────────────┐                 │   │
│  │    │ Restoration │      │Ether Guardian│                │   │
│  │    │  Territory  │      │   Academy    │                │   │
│  │    └──────────────┘      └──────────────┘                 │   │
│  │           ┃                    ┃                            │   │
│  │           ┃            ┌─────┴─────┐                    │   │
│  │           ┃            │ Central   │                    │   │
│  │           ┃            │  Plaza ★  │                    │   │
│  │           ┃            │Parliament │                    │   │
│  │           ┃            └───────────┘                    │   │
│  └───────────┼───────────────────────────────────────────────┘   │
│              ┃                                                          │
│  ═══════════╋═══════════════════════════════════════════════════   │
│              ┃                    【 MIDDLE DISTRICT 】            │
│  ┌───────────┼───────────────────────────────────────────────┐   │
│  │           ┃                                                 │   │
│  │    ┌──────┴──────┐           ┌──────────────┐            │   │
│  │    │  Forge Zone  │           │  Market Zone │            │   │
│  │    │ (Artisans)  │           │  (Shops)    │            │   │
│  │    └──────────────┘           └──────────────┘            │   │
│  │                                                         │   │
│  │           ┃            ┌──────────────┐                  │   │
│  │           ┃            │  Amplifier   │                  │   │
│  │           ┃            │    ◆        │                  │   │
│  │           ┃            │(Central Amp.)│                  │   │
│  │           ┃            └──────────────┘                  │   │
│  └───────────┼───────────────────────────────────────────────┘   │
│              ┃                                                          │
│  ═══════════╋═══════════════════════════════════════════════════   │
│              ┃                    【 LOWER DISTRICT 】 ⬇️          │
│  ┌───────────┼───────────────────────────────────────────────┐   │
│  │           ┃                                                 │   │
│  │    ┌──────┴──────┐                                       │   │
│  │    │ Slave Quarters│  ← ⚠️ Underground Connection         │   │
│  │    │  (Graveyard) │                                       │   │
│  │    └──────────────┘                                       │   │
│  │                                                         │   │
│  │    ┌──────────────┐      ┌──────────────┐               │   │
│  │    │  Back Alley  │      │  Back Alley  │               │   │
│  │    │  (Slums)    │      │ (Information)│               │   │
│  │    └──────────────┘      └──────────────┘               │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ════════════════════════════════════════════════════════════════════   │
│  【 CITY WALLS 】 🔒                                                    │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │                                                              │   │
│  │   [N]     [W]      [E]      [S]                           │   │
│  │    🚪        🚪         🚪        🚪                        │   │
│  │                                                              │   │
│  │         ★ Silverhaven Protected by Walls ★                   │   │
│  │                                                              │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  【 UNDERGROUND 】 ⬇️                                                 │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  Underground 1F: Slave Quarters → Machine Room → ???         │   │
│  │           ☢ Void-Eating Machine Location                  │   │
│  └────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────┘"""

    ascii_to_image(village_map, "crpg_prototype/docs/maps/village_map.png")
    
    # Continent with Factions
    faction_map = """\
┌────────────────────────────────────────────────────────────────────────┐
│                    【 FACTION DISTRIBUTION MAP 】                          │
│                                                                         │
│  【 LEGEND 】                                                          │
│  🔵 ALLIANCE (Order)   🔴 HORDE (Orcs)   ⚫ DEMON ARMY                │
│  🟢 ELVES              🟡 MERCHANTS     ⚪ NEUTRAL/LAWLESS           │
│                                                                         │
│  ════════════════════════════════════════════                            │
│  ║                    【 NORTHERN ICEWALL 】                ║            │
│  ════════════════════════════════════════════                            │
│       🔵🔵🔵              🔵🔵🔵              ⚫⚫⚫                   │
│      EDELWEISS        IRON GUARD          ???                       │
│         ⚫                🔴                                      │
│       ⚫⚫                ⚫   ← Demon Army Infiltration                │
│                                                                         │
│  ═════════════════════════════════════════════════════════════════════  │
│                                                                         │
│       🔵               🔵🔵🔵               🔵                     │
│     ETHERIA         CENTRAL HIGHLAND       ??? (NOVA)                │
│        🟡            ⚫⚫⚫⚫⚫             ⚫                         │
│       🔵🟡🟡         ⚫⚫⚫⚫⚫             ⚫⚫                       │
│                        ⚫⚫⚫⚫⚫                                    │
│                                                                         │
│  ═════════════════════════════════════════════════════════════════════  │
│                                                                         │
│       🟢                🟡🔵                    🔴                     │
│     ELVES            MISTRAL               SOLARIS                   │
│      LEAF           (SILVERHAVEN)★            FALLEN                   │
│      KINGDOM             🟢              🔴🔴🔴                      │
│         🟢           ┌───────┐            🔴 BONE WALKER              │
│         🟢           │  ★   │            🔴🔴                         │
│         🟢           │ AMP   │                                         │
│         🟢           └───────┘                                         │
│                                                                         │
│  ═════════════════════════════════════════════════════════════════════  │
│       🟡🟡🟡               🔴🔴🔴               ▽▽▽▽▽                │
│       VENTUS            ORC HORDE           FREE PORTS                 │
│       🟡                  🔴                  ⚪                       │
│       🟡                  🔴                  ⚪⚪                      │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘"""

    ascii_to_image(faction_map, "crpg_prototype/docs/maps/faction_map.png")
    
    # Current Frontlines
    frontlines = """\
┌────────────────────────────────────────────────────────────────────────┐
│                  【 SILVERHAVEN SURROUNDING FRONTLINES 】               │
│                                                                         │
│                            【 NORTH 】                                  │
│                      🔵 Alliance Territory                              │
│                             ┃┃┃┃                                        │
│    ┌────────────────────────┼─────────────────────────┐          │
│    │                         ┃                         │          │
│    │   🔵 IRON GUARD    ┃🔵 ETHERIA               │          │
│    │   (NW)             ┃  (N)                      │          │
│    │                    ┃                          │          │
│    │                    ┃                          │          │
│    │   🔴 IRON SKULL  ┃                          │          │
│    │   ⚔️⚔️⚔️        ┃   ┌────────────────┐   │          │
│    │   ⚔️⚔️⚔️        ┃   │   MISTRAL      │   │          │
│    │   ⚔️⚔️⚔️        ┃   │   🌲 FOREST   │   │          │
│    │       ⚔️⚔️⚔️    ┃   │  🟢 ELVES     │   │          │
│    │                    ┃   │   (Barrier)   │   │          │
│    │                    ┃   │     🌳        │   │          │
│    │                    ┃   └───────┬──────┘   │          │
│    │                    ┃           │          │          │
│    │                    ┃     ┌─────┴─────┐   │          │
│    │   🔴 IRON SKULL ┃     │ SILVERHAVEN★│   │          │
│    │   (W Siege)     ┃     │  🔵🟡🟢    │   │          │
│    │   ⚔️⚔️⚔️⚔️⚔️⚔️┃     │   ⛺⛺⛺    │   │          │
│    │   ⚔️⚔️⚔️⚔️⚔️⚔️┃     └───────────┘   │          │
│    │                    ┃                         │          │
│    │   🔴 IRON SKULL ┃     🔴 BLOOD MOON        │          │
│    │   (SW)           ┃     (E)                   │          │
│    │   ⚔️⚔️⚔️       ┃     ⬛⬛⬛               │          │
│    │                    ┃     (Target: Amplifier)   │          │
│    │                    ┃                         │          │
│    │   🔴 BONE WALKER┃     🦅 SKY FANG          │          │
│    │   (S)           ┃     (Sky Route)          │          │
│    │   🔧🔧🔧        ┃     🦅🦅🦅              │          │
│    │                    ┃                         │          │
│    └─────────────────────┴─────────────────────────┘          │
│                             ┃                                     │
│                        【 SOUTH 】                                   │
│                  🔴 SOLARIS (Falling)                               │
│                  💀💀💀💀💀 Refugee Camp                            │
│                                                                         │
│  【 CURRENT BATTLE LINES 】                                           │
│  ════════════════════════════════════════════════                       │
│  ⚔️ WEST: Iron Skull Siege (West Gate)                               │
│  ⚔️ EAST: Blood Moon Threat (Amplifier Target)                      │
│  🦅 ABOVE: Sky Fang Patrol (Aerial Route)                            │
│  🔧 SOUTH: Bone Walker Guerrillas (Outer Wall Breach)               │
│  📜 DIPLOMACY: Silver Tongue Negotiation (5km S)                    │
└────────────────────────────────────────────────────────────────────────┘"""

    ascii_to_image(frontlines, "crpg_prototype/docs/maps/frontlines_map.png")
    
    print("\n✅ All maps generated successfully!")
    print("📁 Location: crpg_prototype/docs/maps/")

if __name__ == "__main__":
    main()
