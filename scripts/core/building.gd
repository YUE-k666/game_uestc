class_name Building
extends Resource

## 建筑 Resource 基类

@export var id: String = ""
@export var building_name: String = ""
@export var type: String = "other"  # cafeteria / dormitory / teaching / library / other
@export var grid_position: Vector2i = Vector2i.ZERO
@export var grid_size: Vector2i = Vector2i(2, 2)
@export var is_interactable: bool = false
@export var open_periods: Array[int] = []
@export var upgrade_level: int = 1
@export var is_under_construction: bool = false
@export var construction_remaining_days: int = 0

## 是否在当前时段开放
func is_open_at(period: int) -> bool:
	if is_under_construction:
		return false
	return period in open_periods

## 序列化为字典
func to_dict() -> Dictionary:
	return {
		"id": id,
		"building_name": building_name,
		"type": type,
		"grid_position": {"x": grid_position.x, "y": grid_position.y},
		"grid_size": {"x": grid_size.x, "y": grid_size.y},
		"is_interactable": is_interactable,
		"open_periods": open_periods,
		"upgrade_level": upgrade_level,
		"is_under_construction": is_under_construction,
		"construction_remaining_days": construction_remaining_days,
	}

## 从字典反序列化
static func from_dict(data: Dictionary) -> Building:
	var b := Building.new()
	b.id = data.get("id", "")
	b.building_name = data.get("building_name", "")
	b.type = data.get("type", "other")
	var pos := data.get("grid_position", {"x": 0, "y": 0})
	b.grid_position = Vector2i(pos.get("x", 0), pos.get("y", 0))
	var size := data.get("grid_size", {"x": 2, "y": 2})
	b.grid_size = Vector2i(size.get("x", 2), size.get("y", 2))
	b.is_interactable = data.get("is_interactable", false)
	b.open_periods = data.get("open_periods", [])
	b.upgrade_level = data.get("upgrade_level", 1)
	b.is_under_construction = data.get("is_under_construction", false)
	b.construction_remaining_days = data.get("construction_remaining_days", 0)
	return b
