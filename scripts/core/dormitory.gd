class_name DormitoryBuilding
extends Building

## 宿舍楼 Resource — Building 子类

@export var building_id: int = 0
@export var group_id: int = 0
@export var has_ac: bool = false
@export var has_private_bath: bool = false
@export var capacity: int = 200
@export var base_satisfaction_bonus: float = 0.0

## 获取入口位置
func get_entrance_position() -> Vector2i:
	return Vector2i(grid_position.x + grid_size.x / 2, grid_position.y + grid_size.y)

## 序列化
func to_dict() -> Dictionary:
	var d := super.to_dict()
	d["building_id"] = building_id
	d["group_id"] = group_id
	d["has_ac"] = has_ac
	d["has_private_bath"] = has_private_bath
	d["capacity"] = capacity
	d["base_satisfaction_bonus"] = base_satisfaction_bonus
	return d

static func from_dict(data: Dictionary) -> DormitoryBuilding:
	var db := DormitoryBuilding.new()
	db.id = data.get("id", "")
	db.building_name = data.get("building_name", data.get("name", ""))
	db.type = "dormitory"
	var pos := data.get("grid_position", {"x": 0, "y": 0})
	db.grid_position = Vector2i(pos.get("x", 0), pos.get("y", 0))
	var size := data.get("grid_size", {"x": 4, "y": 3})
	db.grid_size = Vector2i(size.get("x", 4), size.get("y", 3))
	db.building_id = data.get("building_id", 0)
	db.group_id = data.get("group_id", 0)
	db.has_ac = data.get("has_ac", false)
	db.has_private_bath = data.get("has_private_bath", false)
	db.capacity = data.get("capacity", 200)
	db.base_satisfaction_bonus = data.get("base_satisfaction_bonus", 0.0)
	return db
