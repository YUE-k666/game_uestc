extends Node

## 升级系统 — 管理食堂窗口和宿舍组团的升级

func _ready() -> void:
	GameEvents.upgrade_started.connect(_on_upgrade_started)

func can_upgrade(building_id: String, current_level: int) -> bool:
	if current_level >= 5:
		return false
	var next_level := current_level + 1
	var upgrade_def := _get_upgrade_definition(building_id, next_level)
	if upgrade_def.is_empty():
		return false
	var cost: float = float(upgrade_def.get("cost", 0.0))
	return _get_balance() >= cost

func start_upgrade(building_id: String, current_level: int) -> bool:
	if not can_upgrade(building_id, current_level):
		return false

	var next_level := current_level + 1
	var upgrade_def := _get_upgrade_definition(building_id, next_level)
	var cost: float = float(upgrade_def.get("cost", 0.0))
	var days: int = int(upgrade_def.get("construction_days", 1))

	# 扣款
	if not _spend(cost):
		return false

	# 标记施工
	GameEvents.upgrade_started.emit(building_id, days)
	return true

func complete_upgrade(building_id: String, new_level: int) -> void:
	var upgrade_def := _get_upgrade_definition(building_id, new_level)
	# 应用升级效果（由具体建筑系统读取 upgrade_definitions）
	GameEvents.upgrade_completed.emit(building_id)

func get_upgrade_info(building_id: String, current_level: int) -> Dictionary:
	var next_level := current_level + 1
	if next_level > 5:
		return {"max_level": true}
	var def := _get_upgrade_definition(building_id, next_level)
	if def.is_empty():
		return {"available": false}
	return {
		"available": true,
		"next_level": next_level,
		"cost": float(def.get("cost", 0.0)),
		"construction_days": int(def.get("construction_days", 0)),
		"description": def.get("description", ""),
	}

func _get_upgrade_definition(building_id: String, level: int) -> Dictionary:
	var upgrades := GameConfig.upgrade_definitions
	# 判断是食堂还是宿舍
	var category := "食堂窗口升级"
	if building_id.begins_with("dorm"):
		category = "宿舍组团升级"

	var level_data: Dictionary = upgrades.get(category, {}).get(str(level), {})
	return level_data

func _get_balance() -> float:
	var em := get_node_or_null("/root/Main/Systems/EconomyManager")
	if em and em.has_method("get_balance"):
		return em.get_balance()
	return 0.0

func _spend(amount: float) -> bool:
	var em := get_node_or_null("/root/Main/Systems/EconomyManager")
	if em and em.has_method("spend"):
		return em.spend(amount)
	return false

func _on_upgrade_started(building_id: String, duration_days: int) -> void:
	# 标记建筑为施工状态
	# 由具体建筑系统监听处理
	pass
