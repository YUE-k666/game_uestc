class_name DormitoryGroup
extends Resource

## 宿舍组团 Resource

@export var group_id: int = 0
@export var group_name: String = ""
@export var student_type: String = "undergraduate"
@export var buildings: Array[int] = []
@export var hot_water_start: int = 2
@export var hot_water_end: int = 6
@export var electricity_price: float = 0.55
@export var maintenance_frequency: int = 3
@export var cleanliness_level: int = 3
@export var curfew_period: int = 5
@export var upgrade_level: int = 1
@export var is_under_construction: bool = false

# 配置边界（从 JSON 读取）
var config_bounds: Dictionary = {}

## 计算运营成本
func calculate_cost() -> Dictionary:
	var building_count := buildings.size()
	if building_count == 0:
		building_count = 4  # 默认
	var params := GameConfig.game_params.get("宿舍运营基础值", {})
	var gas_base: float = params.get("gas_base", 500.0)
	var maint_base: float = params.get("maintenance_base", 300.0)
	var clean_base: float = params.get("cleaning_base", 200.0)

	var gas_cost := gas_base * (hot_water_end - hot_water_start) * building_count
	var maint_cost := maint_base * maintenance_frequency * building_count
	var clean_cost := clean_base * cleanliness_level * building_count

	return {
		"燃气费": gas_cost,
		"维修费": maint_cost,
		"保洁费": clean_cost,
		"总计": gas_cost + maint_cost + clean_cost,
		"楼栋数": building_count
	}

## 序列化
func to_dict() -> Dictionary:
	return {
		"group_id": group_id,
		"group_name": group_name,
		"student_type": student_type,
		"buildings": buildings,
		"hot_water_start": hot_water_start,
		"hot_water_end": hot_water_end,
		"electricity_price": electricity_price,
		"maintenance_frequency": maintenance_frequency,
		"cleanliness_level": cleanliness_level,
		"curfew_period": curfew_period,
		"upgrade_level": upgrade_level,
		"is_under_construction": is_under_construction,
	}

static func from_dict(data: Dictionary) -> DormitoryGroup:
	var g := DormitoryGroup.new()
	g.group_id = data.get("group_id", 0)
	g.group_name = data.get("group_name", "")
	g.student_type = data.get("student_type", "undergraduate")
	g.buildings = data.get("buildings", [])
	g.hot_water_start = data.get("hot_water_start", 2)
	g.hot_water_end = data.get("hot_water_end", 6)
	g.electricity_price = data.get("electricity_price", 0.55)
	g.maintenance_frequency = data.get("maintenance_frequency", 3)
	g.cleanliness_level = data.get("cleanliness_level", 3)
	g.curfew_period = data.get("curfew_period", 5)
	g.upgrade_level = data.get("upgrade_level", 1)
	g.is_under_construction = data.get("is_under_construction", false)
	g.config_bounds = data.get("config_bounds", {})
	return g
