# skill_types.gd — 스킬 타입 enum.
class_name SkillTypes
extends RefCounted

enum Type {
	WEAPON = 0,    # 무기 (검술/창술/펜싱/둔기/궁술/격투)
	SUPPORT = 1,   # 보조 (전술/해부학/치료/마법저항)
	MAGIC = 2,     # 마법 (마법학/명상/지능측정)
	UTILITY = 3,   # 유틸 (은신/추적)
}
