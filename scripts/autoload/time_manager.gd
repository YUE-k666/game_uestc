extends Node

## 时间系统 — 管理7个时段循环、日/周/学期推进、四档速度控制

# 当前时间状态
var current_period: int = 0
var current_day: int = 1
var current_week: int = 1
var current_semester: int = 1
var current_speed: int = 1  # 0=暂停, 1=正常, 2=快进, 3=极速

# 时段计时器
var _period_timer: float = 0.0
var _period_durations: Array = []  # 每个时段的真实秒数（倍率前）

func _ready() -> void:
	_load_time_config()
	_period_timer = 0.0

func _load_time_config() -> void:
	var periods := GameConfig.get_period_definitions()
	_period_durations.clear()
	for p in periods:
		_period_durations.append(float(p.get("duration_real_seconds", 15.0)))

func _process(delta: float) -> void:
	if current_speed == 0:
		return
	if _period_durations.is_empty():
		return

	var speed_multiplier := _get_speed_multiplier()
	_period_timer += delta * speed_multiplier

	var duration := _period_durations[current_period]
	if _period_timer >= duration:
		_period_timer -= duration
		_advance_period()

func _get_speed_multiplier() -> float:
	match current_speed:
		1: return 1.0
		2: return 2.0
		3: return 4.0
		_: return 0.0

func _advance_period() -> void:
	current_period += 1
	if current_period >= 7:
		current_period = 0
		_advance_day()
	else:
		GameEvents.time_period_changed.emit(current_period, current_day, _get_day_of_week())

func _advance_day() -> void:
	current_day += 1
	if current_day > 7:
		current_day = 1
		_advance_week()
	else:
		var dow := _get_day_of_week()
		GameEvents.day_started.emit(current_day, dow)
		GameEvents.time_period_changed.emit(current_period, current_day, dow)

func _advance_week() -> void:
	current_week += 1
	if current_week > 18:
		current_week = 1
		_advance_semester()
	else:
		GameEvents.week_started.emit(current_week)
		var dow := _get_day_of_week()
		GameEvents.day_started.emit(current_day, dow)
		GameEvents.time_period_changed.emit(current_period, current_day, dow)

func _advance_semester() -> void:
	current_semester += 1
	GameEvents.semester_started.emit(current_semester)
	GameEvents.week_started.emit(current_week)
	var dow := _get_day_of_week()
	GameEvents.day_started.emit(current_day, dow)
	GameEvents.time_period_changed.emit(current_period, current_day, dow)

func _get_day_of_week() -> int:
	# 1=周一, 7=周日
	return current_day

## 设置游戏速度
func set_speed(speed: int) -> void:
	current_speed = clampi(speed, 0, 3)
	GameEvents.time_speed_changed.emit(current_speed)

## 是否周末
func is_weekend() -> bool:
	return current_day >= 6

## 获取速度名称
func get_speed_name() -> String:
	match current_speed:
		0: return "暂停"
		1: return "正常"
		2: return "快进"
		3: return "极速"
		_: return "未知"

## 获取当前时段名称
func get_period_name() -> String:
	var def := GameConfig.get_period_definition(current_period)
	return def.get("name", "未知")

## 获取当前时段显示时间
func get_period_display_time() -> String:
	var def := GameConfig.get_period_definition(current_period)
	return def.get("display_name", "")

## 获取当前日期描述
func get_date_description() -> String:
	var day_names := ["", "周一", "周二", "周三", "周四", "周五", "周六", "周日"]
	var day_name := day_names[current_day] if current_day >= 1 and current_day <= 7 else "未知"
	return "第%d周 %s %s" % [current_week, day_name, get_period_name()]
