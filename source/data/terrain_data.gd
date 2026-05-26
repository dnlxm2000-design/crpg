# terrain_data.gd ??吏???ㅼ젙 由ъ냼??(Editor?먯꽌 ?ㅼ떆媛??몄쭛 媛??.
# @tool ?ㅽ겕由쏀듃濡?Inspector?먯꽌 吏곸젒 媛믪쓣 議곗젙?????덉쓬.
extends Resource
class_name TerrainData

## 吏????낅퀎 ?ㅼ젙
@export var terrain_types: Array[TerrainTypeDefinition] = []

## 怨좊룄蹂?異붽? ?됱긽 蹂??(0=蹂???놁쓬, 1=?꾩쟾 ?대몢?)
@export var height_darken: float = 0.12

## 臾??ㅼ젙
@export var water_color: Color = Color(0.2, 0.4, 0.7, 0.8)
@export var water_height: int = 0  # ??怨좊룄 ?댄븯??臾?


## 吏??????뺤쓽 (由ъ냼?ㅼ뿉 ?ы븿??inner class)
func _init() -> void:
	if terrain_types.is_empty():
		_default_types()


func _default_types() -> void:
	terrain_types = [
		TerrainTypeDefinition.new("GRASS", Color("#99C27C"), 0, 0, false),
		TerrainTypeDefinition.new("DIRT", Color("#6D5545"), 1, 1, false),
		TerrainTypeDefinition.new("PATH", Color("#D1B48C"), 2, 2, false),
		TerrainTypeDefinition.new("WATER", Color("#3377BB"), -1, -1, true),
		TerrainTypeDefinition.new("STONE", Color("#A0A4A6"), 4, 4, false),
		TerrainTypeDefinition.new("MOSS", Color("#6B8E4D"), 5, 5, false),
		TerrainTypeDefinition.new("STONE_L", Color("#707476"), -1, 4, false),
		TerrainTypeDefinition.new("STONE_R", Color("#4D5153"), -1, 5, false),
	]


## ?뱀젙 ???ID???뺤쓽 諛섑솚
func get_type(id: int) -> TerrainTypeDefinition:
	for t in terrain_types:
		if t.id == id:
			return t
	return terrain_types[0] if terrain_types.size() > 0 else null


## ?뱀젙 ????대쫫???뺤쓽 諛섑솚
func get_type_by_name(name: String) -> TerrainTypeDefinition:
	for t in terrain_types:
		if t.name == name:
			return t
	return null
