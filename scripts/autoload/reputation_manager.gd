extends Node

## 声望管理器 — 根据满意度和事件处理调整声望

var _reputation: float = 70.0
var _satisfaction_trend: float = 0.0  # 最近满意度变化趋势
var _events_handled_well: int = 0
var _events_total: int = 0

func _ready() -> void:
	_reputation = float(GameConfig.game_params.get("声望初始值", 70.0))
	GameEvents.satisfaction_overall_changed.connect(_on_satisfaction_changed)
	GameEvents.event_resolved.connect(_on_event_resolved)
	GameEvents.day_started.connect(_on_day_started)

func _on_satisfaction_changed(value: float) -> void:
	# 追踪满意度趋势
	var prev := _reputation
	_satisfaction_trend = value - prev

func _on_event_resolved(_event_id: String, choice_index: int) -> void:
	_events_total += 1
	# 简化：选择索引0通常是最优选择
	if choice_index == 0:
		_events_handled_well += 1

func _on_day_started(_day: int, _dow: int) -> void:
	# 每日声望微调
	var params := GameConfig.game_params.get("声望影响", {})
	var sat_weight: float = float(params.get("满意度趋势权重", 0.6))
	var event_weight: float = float(params.get("事件处理权重", 0.4))

	var daily_change := _satisfaction_trend * sat_weight * 0.1
	if _events_total > 0:
		var event_ratio := float(_events_handled_well) / float(_events_total)
		daily_change += (event_ratio - 0.5) * event_weight

	_reputation = clampf(_reputation + daily_change, 0.0, 100.0)

## 获取当前声望
func get_reputation() -> float:
	return _reputation

## 声望对预算的影响系数
func get_budget_modifier() -> float:
	var params := GameConfig.game_params.get("声望影响", {})
	var impact: float = float(params.get("预算影响", 0.05))
	return 1.0 + (_reputation - 70.0) / 100.0 * impact
