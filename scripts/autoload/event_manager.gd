extends Node

## 事件管理器 — 随机触发和管理游戏事件

var _active_events: Array[Dictionary] = []
var _triggered_ids: Array[String] = []
var _days_since_last_event: int = 0
var _min_days_between_events: int = 2
var _max_active_events: int = 3

func _ready() -> void:
	GameEvents.day_started.connect(_on_day_started)
	GameEvents.week_started.connect(_on_week_started)

func _on_day_started(day: int, _dow: int) -> void:
	_days_since_last_event += 1
	_try_trigger_random_events(day)
	_process_periodic_events()

func _on_week_started(week: int) -> void:
	# 检查周期性事件（考试周等）
	_check_periodic_events(week)

func _try_trigger_random_events(day: int) -> void:
	if _active_events.size() >= _max_active_events:
		return
	if _days_since_last_event < _min_days_between_events:
		return

	var difficulty := GameConfig.get_difficulty_config()
	var freq_mult: float = float(difficulty.get("event_frequency", 1.0))

	var events_list: Array = GameConfig.event_definitions.get("事件", [])
	for edata in events_list:
		var e := GameEventResource.from_dict(edata)
		if e.is_periodic:
			continue  # 周期事件单独处理
		if e.event_id in _triggered_ids:
			continue

		var conditions: Dictionary = e.trigger_conditions
		var min_day: int = int(conditions.get("min_day", 0))
		if day < min_day:
			continue

		var prob: float = float(conditions.get("probability", 0.1)) * freq_mult
		if randf() <= prob:
			_trigger_event(e)
			_days_since_last_event = 0
			break  # 每天最多触发一个

func _check_periodic_events(week: int) -> void:
	var events_list: Array = GameConfig.event_definitions.get("事件", [])
	for edata in events_list:
		var e := GameEventResource.from_dict(edata)
		if not e.is_periodic:
			continue

		var trigger_weeks: Array = e.period_trigger.get("semester_week", [])
		if week in trigger_weeks:
			_trigger_event(e)

func _process_periodic_events() -> void:
	pass

func _trigger_event(event: GameEventResource) -> void:
	_triggered_ids.append(event.event_id)
	_active_events.append(event.to_dict())
	GameEvents.event_triggered.emit(event.event_id, event.to_dict())

## 玩家选择后解决事件
func resolve_event(event_id: String, choice_index: int) -> void:
	for i in range(_active_events.size()):
		if _active_events[i].get("event_id", "") == event_id:
			var event_data: Dictionary = _active_events[i]
			var choices: Array = event_data.get("choices", [])
			if choice_index >= 0 and choice_index < choices.size():
				var choice: Dictionary = choices[choice_index]
				_apply_choice_effects(event_data, choice)
			_active_events.remove_at(i)
			GameEvents.event_resolved.emit(event_id, choice_index)
			return

func _apply_choice_effects(event_data: Dictionary, choice: Dictionary) -> void:
	# 应用满意度恢复
	var recovery: float = float(choice.get("satisfaction_recovery", 0.0))
	var effects: Array = event_data.get("effects", [])
	for effect in effects:
		var target: String = effect.get("target", "")
		var base_change: float = float(effect.get("change", 0.0))
		var final_change := base_change + recovery
		GameEvents.satisfaction_category_changed.emit(target, final_change)

func get_active_events() -> Array[Dictionary]:
	return _active_events

func get_triggered_count() -> int:
	return _triggered_ids.size()
