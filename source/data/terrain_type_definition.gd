# terrain_type_definition.gd — 단일 지형 타입 정의.
# TerrainData 리소스에서 배열로 사용됨.
class_name TerrainTypeDefinition
extends Resource

## 표시 이름
@export var name: String = "GRASS"
## 고유 ID (아틀라스 열 인덱스, -1 = side-only)
@export var id: int = 0
## 아틀라스 열(윗면), -1이면 별도 윗면 없음
@export var atlas_top_col: int = 0
## 아틀라스 열(옆면)
@export var atlas_side_col: int = 0
## 이 타입이 물인가?
@export var is_water: bool = false
## 기본 색상 (Editor 표시용)
@export var base_color: Color = Color.WHITE


func _init(p_name: String = "GRASS", p_color: Color = Color.WHITE, p_top: int = 0, p_side: int = 0, p_water: bool = false) -> void:
	name = p_name
	base_color = p_color
	atlas_top_col = p_top
	atlas_side_col = p_side
	is_water = p_water
	id = p_top if p_top >= 0 else p_side
