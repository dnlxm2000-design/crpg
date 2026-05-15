# terrain_data.gd — 지형 설정 리소스 (Editor에서 실시간 편집 가능).
# @tool 스크립트로 Inspector에서 직접 값을 조정할 수 있음.
class_name TerrainData
extends Resource

## 지형 타입별 설정
@export var terrain_types: Array[TerrainTypeDefinition] = []

## 고도별 추가 색상 변형 (0=변형 없음, 1=완전 어두움)
@export var height_darken: float = 0.12

## 물 설정
@export var water_color: Color = Color(0.2, 0.4, 0.7, 0.8)
@export var water_height: int = 0  # 이 고도 이하는 물


## 지형 타입 정의 (리소스에 포함된 inner class)
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


## 특정 타입 ID의 정의 반환
func get_type(id: int) -> TerrainTypeDefinition:
	for t in terrain_types:
		if t.id == id:
			return t
	return terrain_types[0] if terrain_types.size() > 0 else null


## 특정 타입 이름의 정의 반환
func get_type_by_name(name: String) -> TerrainTypeDefinition:
	for t in terrain_types:
		if t.name == name:
			return t
	return null
