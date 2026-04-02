extends Node

## 满意度管理器 — 计算加权综合满意度

var _category_satisfaction := {
	"cafeteria": 70.0,
	"dormitory": 80.0,
	"teaching": 70.0,
	"entertainment": 65.0,
}
var _overall: float = 72.5
var _daily_accumulator := {
	"cafeteria": 0.0,
	"dormitory": 0.0,
	"teaching": 0.0,
	"entertainment": 0.0,
}
var _student_count: int = 0

func _ready() -> void:
	GameEvents.satisfaction_category_changed.connect(_on_category_changed)
	GameEvents.day_started.connect(_on_day_started)

func _on_category_changed(category: String, value: float) -> void:
	_category_satisfaction[category] = clampf(value, 0.0, 100.0)
	_recalculate_overall()

func _recalculate_overall() -> void:
	var weights := GameConfig.get_satisfaction_weights()
	var total := 0.0
	var weight_sum := 0.0
	for cat in _category_satisfaction:
		var w: float = float(weights.get(cat, 0.25))
		total += _category_satisfaction[cat] * w
		weight_sum += w
	if weight_sum > 0.0:
		_overall = total / weight_sum
	GameEvents.satisfaction_overall_changed.emit(_overall)

	# 预警检查
	var threshold: float = float(GameConfig.game_params.get("游戏结束满意度阈值", 60.0))
	if _overall < threshold:
		GameEvents.satisfaction_below_threshold.emit(_overall)

func _on_day_started(_day: int, _dow: int) -> void:
	# 重置日累积器
	for key in _daily_accumulator:
		_daily_accumulator[key] = 0.0

## 获取综合满意度
func get_overall_satisfaction() -> float:
	return _overall

## 获取分维度满意度
func get_category_satisfaction(category: String) -> float:
	return _category_satisfaction.get(category, 0.0)

## 获取所有维度
func get_all_categories() -> Dictionary:
	return _category_satisfaction.duplicate()

## 更新学生满意度聚合
func update_from_students(students: Array) -> void:
	var counts := {"cafeteria": 0, "dormitory": 0}
	var sums := {"cafeteria": 0.0, "dormitory": 0.0}

	for s in students:
		var student: Student = s
		sums["cafeteria"] += student.satisfaction_cafeteria
		sums["dormitory"] += student.satisfaction_dormitory
		counts["cafeteria"] += 1
		counts["dormitory"] += 1

	for cat in counts:
		if counts[cat] > 0:
			_category_satisfaction[cat] = sums[cat] / counts[cat]

	_recalculate_overall()
