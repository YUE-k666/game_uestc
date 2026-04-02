extends Node

## 仪表盘数据控制器 — 监听信号实时更新显示

var _satisfaction_overall: float = 75.0
var _satisfaction_cafeteria: float = 70.0
var _satisfaction_dormitory: float = 80.0
var _satisfaction_teaching: float = 70.0
var _satisfaction_entertainment: float = 65.0
var _budget_balance: float = 500000.0
var _reputation: float = 70.0
var _history: Array[Dictionary] = []  # 每日快照
var _current_day_revenue: float = 0.0
var _total_profit: float = 0.0

func _ready() -> void:
	GameEvents.satisfaction_overall_changed.connect(_on_overall_changed)
	GameEvents.satisfaction_category_changed.connect(_on_category_changed)
	GameEvents.budget_balance_changed.connect(_on_budget_changed)
	GameEvents.daily_revenue_updated.connect(_on_daily_revenue)
	GameEvents.day_started.connect(_on_day_started)

func _on_overall_changed(value: float) -> void:
	_satisfaction_overall = value

func _on_category_changed(category: String, value: float) -> void:
	match category:
		"cafeteria": _satisfaction_cafeteria = value
		"dormitory": _satisfaction_dormitory = value
		"teaching": _satisfaction_teaching = value
		"entertainment": _satisfaction_entertainment = value

func _on_budget_changed(balance: float, delta: float) -> void:
	_budget_balance = balance
	if delta < 0:
		_total_profit += delta

func _on_daily_revenue(_rid: String, revenue: float) -> void:
	_current_day_revenue += revenue

func _on_day_started(_day: int, _dow: int) -> void:
	# 记录每日快照
	_history.append({
		"week": TimeManager.current_week,
		"day": TimeManager.current_day,
		"satisfaction": _satisfaction_overall,
		"revenue": _current_day_revenue,
	})
	_current_day_revenue = 0.0

	# 保留最近 30 天
	if _history.size() > 30:
		_history.pop_front()

## 获取当前所有指标
func get_metrics() -> Dictionary:
	return {
		"satisfaction_overall": _satisfaction_overall,
		"satisfaction_cafeteria": _satisfaction_cafeteria,
		"satisfaction_dormitory": _satisfaction_dormitory,
		"satisfaction_teaching": _satisfaction_teaching,
		"satisfaction_entertainment": _satisfaction_entertainment,
		"budget_balance": _budget_balance,
		"reputation": _reputation,
		"total_profit": _total_profit,
		"history": _history,
	}

## 获取历史趋势数据
func get_history(days: int = 7) -> Array[Dictionary]:
	var count := mini(days, _history.size())
	var start := _history.size() - count
	var result: Array[Dictionary] = []
	for i in range(start, _history.size()):
		result.append(_history[i])
	return result

## 获取预警状态
func get_warning_level() -> String:
	if _satisfaction_overall < 60.0:
		return "danger"
	elif _satisfaction_overall < 65.0:
		return "warning"
	return "normal"
