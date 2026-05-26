# terrain_type_definition.gd ???⑥씪 吏??????뺤쓽.
# TerrainData 由ъ냼?ㅼ뿉??諛곗뿴濡??ъ슜??
extends Resource
class_name TerrainTypeDefinition

## ?쒖떆 ?대쫫
@export var name: String = "GRASS"
## 怨좎쑀 ID (?꾪??쇱뒪 ???몃뜳?? -1 = side-only)
@export var id: int = 0
## ?꾪??쇱뒪 ???쀫㈃), -1?대㈃ 蹂꾨룄 ?쀫㈃ ?놁쓬
@export var atlas_top_col: int = 0
## ?꾪??쇱뒪 ???녿㈃)
@export var atlas_side_col: int = 0
## ????낆씠 臾쇱씤媛?
@export var is_water: bool = false
## 湲곕낯 ?됱긽 (Editor ?쒖떆??
@export var base_color: Color = Color.WHITE


func _init(p_name: String = "GRASS", p_color: Color = Color.WHITE, p_top: int = 0, p_side: int = 0, p_water: bool = false) -> void:
	name = p_name
	base_color = p_color
	atlas_top_col = p_top
	atlas_side_col = p_side
	is_water = p_water
	id = p_top if p_top >= 0 else p_side
