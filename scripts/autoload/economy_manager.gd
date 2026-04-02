extends Node

## 经济管理器 — 追踪收入支出，日/周/学期结算

var _balance: float = 500000.0
var _semester_allocated: float = 500000.0
var _semester_spent: float = 0.0
var _daily_revenue: float = 0.0
var _daily_expense: float = 0.0
var _total_revenue: float = 0.0
var _total_expense: float = 0.0

func _ready() -> void:
	GameEvents.daily_revenue_updated.connect(_on_daily_revenue)
	GameEvents.day_started.connect(_on_day_started)
	GameEvents.semester_started.connect(_on_semester_started)

	# 初始化预算
	var difficulty := GameConfig.get_difficulty_config()
	_semester_allocated = float(difficulty.get("initial_budget", 500000.0))
	_balance = _semester_allocated

func _on_daily_revenue(_rid: String, revenue: float) -> void:
	_daily_revenue += revenue
	_balance += revenue
	_total_revenue += revenue
	GameEvents.budget_balance_changed.emit(_balance, revenue)

func _on_day_started(_day: int, _dow: int) -> void:
	# 日结算：扣除运营成本
	_daily_expense = _calculate_daily_expense()
	_balance -= _daily_expense
	_semester_spent += _daily_expense
	_total_expense += _daily_expense
	_daily_revenue = 0.0
	GameEvents.budget_balance_changed.emit(_balance, -_daily_expense)

func _on_semester_started(_semester: int) -> void:
	# 学期结算预算
	_total_revenue = 0.0
	_total_expense = 0.0
	_semester_spent = 0.0
	GameEvents.budget_balance_changed.emit(_balance, 0.0)

func _calculate_daily_expense() -> float:
	# 简化：按比例计算日运营成本
	var base_daily := _semester_allocated / (18.0 * 7.0) * 0.3  # 30% 预算用于日运营
	return base_daily

## 获取余额
func get_balance() -> float:
	return _balance

## 扣款
func spend(amount: float) -> bool:
	if _balance < amount:
		return false
	_balance -= amount
	_semester_spent += amount
	GameEvents.budget_balance_changed.emit(_balance, -amount)
	return true

## 获取财务概况
func get_financial_summary() -> Dictionary:
	return {
		"balance": _balance,
		"semester_allocated": _semester_allocated,
		"semester_spent": _semester_spent,
		"daily_revenue": _daily_revenue,
		"daily_expense": _daily_expense,
		"total_revenue": _total_revenue,
		"total_expense": _total_expense,
		"profit": _total_revenue - _total_expense,
	}
