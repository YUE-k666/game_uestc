extends Node

## 事件日志滚播 — 显示游戏事件历史

var _entries: Array[Dictionary] = []
var max_entries: int = 50

func _ready() -> void:
	GameEvents.event_triggered.connect(_on_event_triggered)
	GameEvents.event_resolved.connect(_on_event_resolved)

func _on_event_triggered(event_id: String, event_data: Dictionary) -> void:
	var entry := {
		"type": "triggered",
		"event_id": event_id,
		"name": event_data.get("name", event_id),
		"description": event_data.get("description", ""),
		"time": TimeManager.get_date_description(),
		"timestamp": Time.get_ticks_msec(),
	}
	_entries.append(entry)
	if _entries.size() > max_entries:
		_entries.pop_front()

func _on_event_resolved(event_id: String, choice_index: int) -> void:
	var entry := {
		"type": "resolved",
		"event_id": event_id,
		"choice_index": choice_index,
		"time": TimeManager.get_date_description(),
		"timestamp": Time.get_ticks_msec(),
	}
	_entries.append(entry)
	if _entries.size() > max_entries:
		_entries.pop_front()

## 获取所有日志条目（倒序）
func get_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(_entries.size() - 1, -1, -1):
		result.append(_entries[i])
	return result

## 获取最近 N 条
func get_recent(count: int = 10) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var start := maxi(0, _entries.size() - count)
	for i in range(start, _entries.size()):
		result.append(_entries[i])
	return result
