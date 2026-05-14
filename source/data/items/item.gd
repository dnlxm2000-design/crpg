# item.gd — Base item resource for the inventory system.
class_name Item
extends Resource

## Unique identifier for this item type (e.g. "health_potion").
@export var id: String = ""
## Display name shown in UI.
@export var item_name: String = "Item"
## Flavor / effect description.
@export var description: String = ""
## Item icon texture (null = placeholder colored rect will be used).
@export var icon: Texture2D = null
## Item category (ItemType enum: CONSUMABLE=0, WEAPON=1, ARMOR=2, KEY_ITEM=3).
@export var item_type: int = 0
## Base gold value.
@export var value: int = 0
## Health restored on use (for consumables).
@export var heal_amount: int = 0
## AP cost to use this item in combat.
@export var ap_cost: int = 1
## Can multiple copies occupy the same slot?
@export var stackable: bool = true
## Attack bonus when equipped (for weapons).
@export var damage_bonus: int = 0
## Defense bonus when equipped (for armor).
@export var defense_bonus: int = 0
## Accuracy bonus when equipped (for weapons, gloves, rings).
@export var accuracy_bonus: int = 0
## Evasion bonus when equipped (for armor, boots, cloaks, etc.).
@export var evasion_bonus: int = 0
