# item_types.gd — Item category constants for the inventory system.
extends Node

enum ItemType {
	CONSUMABLE = 0,
	WEAPON = 1,       # right_hand
	ARMOR = 2,        # body
	KEY_ITEM = 3,
	HELMET = 4,       # head
	NECKLACE = 5,     # necklace
	CLOAK = 6,        # cloak
	BELT = 7,         # belt
	RING = 8,         # ring1 or ring2
	BOOTS = 9,        # boots
	OFF_HAND = 10,    # left_hand (shield, torch, etc.)
	GLOVE = 11,       # gloves
	AMMO = 12,        # arrows, bolts, darts
}

## Return the equipment slot name for a given item_type, or "" if not equippable.
static func slot_name(item_type: int) -> String:
	match item_type:
		ItemType.WEAPON:   return "right_hand"
		ItemType.ARMOR:    return "body"
		ItemType.HELMET:   return "head"
		ItemType.NECKLACE: return "necklace"
		ItemType.CLOAK:    return "cloak"
		ItemType.BELT:     return "belt"
		ItemType.RING:     return "ring"
		ItemType.BOOTS:    return "boots"
		ItemType.OFF_HAND: return "left_hand"
		ItemType.GLOVE:    return "gloves"
		_:                 return ""

## Human-readable Korean labels for each slot.
static func slot_label(slot: String) -> String:
	match slot:
		"head":       return "Head"
		"necklace":   return "Necklace"
		"right_hand": return "Right Hand"
		"left_hand":  return "Left Hand"
		"body":       return "Body"
		"belt":       return "Belt"
		"cloak":      return "Cloak"
		"ring":       return "Ring"
		"boots":      return "Boots"
		"gloves":     return "Gloves"
		_:            return slot
