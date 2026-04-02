extends Node2D

## 游戏入口控制器 — 管理系统初始化和生命周期

@onready var campus_map: Node2D = $CampusMap
@onready var student_renderer: Node2D = $StudentRenderer

func _ready() -> void:
	print("游戏启动 — 重生之我在电子科大干后勤")
	print("当前时间: %s" % TimeManager.get_date_description())
	_connect_signals()

func _connect_signals() -> void:
	GameEvents.time_period_changed.connect(_on_period_changed)
	GameEvents.satisfaction_overall_changed.connect(_on_satisfaction_changed)
	GameEvents.satisfaction_below_threshold.connect(_on_satisfaction_warning)

func _on_period_changed(period: int, day: int, dow: int) -> void:
	print("时段变更: %s" % TimeManager.get_date_description())

func _on_satisfaction_changed(value: float) -> void:
	pass

func _on_satisfaction_warning(value: float) -> void:
	push_warning("满意度低于阈值: %.1f" % value)

## 开始新游戏
func start_new_game(difficulty: String) -> void:
	GameConfig.current_difficulty = difficulty
	TimeManager.current_semester = 1
	TimeManager.current_week = 1
	TimeManager.current_day = 1
	TimeManager.current_period = 0
	TimeManager.set_speed(1)
