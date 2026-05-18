# class_definition.gd — 직업 정의 리소스.
class_name ClassDefinition
extends Resource

@export var class_id: String = ""           # "fighter", "mage", "ranger", "rogue"
@export var display_name: String = ""       # "전사(Fighter)"
@export var description: String = ""

## 부여 스킬: {skill_id: starting_level}
@export var skill_levels: Dictionary = {}

## 스탯 보정: {str: 2, dex: -1, ...}
@export var stat_modifiers: Dictionary = {}

## 시작 아이템: [{item_path: "...", quantity: 1}, ...]
@export var starting_items: Array = []
