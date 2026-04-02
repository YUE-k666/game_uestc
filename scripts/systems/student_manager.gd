extends Node

## 学生管理器 — 批量生成和管理学生

var _students: Array[Student] = []

func _ready() -> void:
	generate_students()

func generate_students() -> void:
	_students.clear()
	var config := GameConfig.generation_config
	var total: int = config.get("学生总数", 500)
	var undergrad_ratio: float = config.get("本硕比例", {}).get("undergraduate", 0.7)
	var taste_dist: Dictionary = config.get("口味分布", {})
	var personality_dist: Dictionary = config.get("性格分布", {})
	var wallet_ranges: Dictionary = config.get("钱包范围", {})
	var name_lib: Dictionary = config.get("姓名库", {})
	var default_sat: Dictionary = config.get("默认满意度", {})

	var surnames: Array = name_lib.get("姓", ["张"])
	var given_names: Array = name_lib.get("名", ["伟"])

	var tastes: Array[String] = taste_dist.keys()
	var taste_weights: Array[float] = []
	for k in tastes:
		taste_weights.append(float(taste_dist[k]))

	var personalities: Array[String] = personality_dist.keys()
	var personality_weights: Array[float] = []
	for k in personalities:
		personality_weights.append(float(personality_dist[k]))

	for i in range(total):
		var s := Student.new()
		s.id = 1001 + i
		var is_undergrad := randf() < undergrad_ratio
		s.student_type = "undergraduate" if is_undergrad else "graduate"
		s.student_name = surnames[randi() % surnames.size()] + given_names[randi() % given_names.size()]

		# 随机分配宿舍组团（1-8）
		s.assigned_group = (i % 8) + 1
		s.assigned_building = (i % 4) + 1

		# 按概率分配口味
		s.taste_preference = _weighted_random(tastes, taste_weights)

		# 按概率分配性格
		s.personality_tag = _weighted_random(personalities, personality_weights)

		# 钱包
		var stype := "undergraduate" if is_undergrad else "graduate"
		var wrange: Dictionary = wallet_ranges.get(stype, {"min": 800.0, "max": 2000.0})
		s.wallet_balance = randf_range(float(wrange.get("min", 800.0)), float(wrange.get("max", 2000.0)))

		# 满意度
		s.satisfaction = float(default_sat.get("overall", 75.0))
		s.satisfaction_cafeteria = float(default_sat.get("cafeteria", 70.0))
		s.satisfaction_dormitory = float(default_sat.get("dormitory", 80.0))

		# 初始位置（宿舍附近）
		s.grid_position = Vector2i(randi_range(10, 100), randi_range(50, 58))
		s.state = "idle"

		_students.append(s)

func _weighted_random(items: Array, weights: Array[float]) -> String:
	var total := 0.0
	for w in weights:
		total += w
	var r := randf() * total
	var cumulative := 0.0
	for i in range(items.size()):
		cumulative += weights[i]
		if r <= cumulative:
			return items[i]
	return items[-1] if items.size() > 0 else ""

## 获取所有学生
func get_all_students() -> Array:
	return _students

## 获取指定学生
func get_student(id: int) -> Student:
	for s in _students:
		if s.id == id:
			return s
	return null

## 获取指定组团的学生
func get_students_by_group(group_id: int) -> Array[Student]:
	var result: Array[Student] = []
	for s in _students:
		if s.assigned_group == group_id:
			result.append(s)
	return result

## 重置每日状态
func reset_daily() -> void:
	for s in _students:
		s.meals_today = 0
		s.curfew_violated = false
