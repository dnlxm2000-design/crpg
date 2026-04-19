# TileData - Tile type data and properties

extends Node

# Tile type enumeration
enum TileType {
	WALL = 0,      # 벽 - 이동 불가
	FLOOR = 1,     # 바닥 - 일반 이동
	DOOR = 2,     # 문 - 개방 가능
	WATER = 3,     # 물/함정 - 이동 불가
	COVER = 4,     # 커버 - 이동 가능 but 방어 보너스
	STAIRS_UP = 5,   #stairs up
	STAIRS_DOWN = 6 # stairs down
}

# Tile type data table
# move_cost: 이동 비용 (-1 = 이동 불가)
# transparent: 시야 통과 여부
var tile_data = {
	TileType.WALL: {"name": "Wall", "move_cost": -1, "transparent": false},
	TileType.FLOOR: {"name": "Floor", "move_cost": 1, "transparent": true},
	TileType.DOOR: {"name": "Door", "move_cost": 2, "transparent": true},
	TileType.WATER: {"name": "Water", "move_cost": -1, "transparent": true},
	TileType.COVER: {"name": "Cover", "move_cost": 2, "transparent": false},
	TileType.STAIRS_UP: {"name": "Stairs Up", "move_cost": 1, "transparent": true},
	TileType.STAIRS_DOWN: {"name": "Stairs Down", "move_cost": 1, "transparent": true}
}

# Get move cost for tile type
func get_move_cost(tile_type: TileType) -> int:
	if tile_data.has(tile_type):
		return tile_data[tile_type].get("move_cost", -1)
	return -1

# Check if tile is walkable
func is_walkable(tile_type: TileType) -> bool:
	return get_move_cost(tile_type) >= 0

# Check if tile is transparent (for line of sight)
func is_transparent(tile_type: TileType) -> bool:
	if tile_data.has(tile_type):
		return tile_data[tile_type].get("transparent", false)
	return false