extends Node

## 存档系统 — JSON 序列化存档管理

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 5

func _ready() -> void:
	_ensure_save_dir()

func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

## 保存游戏到指定存档位
func save_game(slot_id: int) -> bool:
	if slot_id < 1 or slot_id > MAX_SLOTS:
		return false

	var snapshot := _capture_snapshot()
	snapshot["slot_id"] = slot_id
	snapshot["updated_at"] = Time.get_datetime_string_from_system()

	var json_str := JSON.stringify(snapshot, "\t")
	var path := SAVE_DIR + "slot_%d.json" % slot_id
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("无法写入存档: %s" % path)
		return false
	file.store_string(json_str)
	file.close()
	return true

## 读取存档
func load_game(slot_id: int) -> bool:
	if slot_id < 1 or slot_id > MAX_SLOTS:
		return false

	var path := SAVE_DIR + "slot_%d.json" % slot_id
	if not FileAccess.file_exists(path):
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("存档解析失败: %s" % path)
		return false

	_restore_snapshot(json.data)
	return true

## 获取存档位信息
func get_slot_info(slot_id: int) -> Dictionary:
	var path := SAVE_DIR + "slot_%d.json" % slot_id
	if not FileAccess.file_exists(path):
		return {"empty": true, "slot_id": slot_id}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {"empty": true, "slot_id": slot_id}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {"empty": true, "slot_id": slot_id}

	var data: Dictionary = json.data
	return {
		"empty": false,
		"slot_id": slot_id,
		"updated_at": data.get("updated_at", ""),
		"semester_number": data.get("time", {}).get("semester_number", 1),
		"current_week": data.get("time", {}).get("current_week", 1),
		"overall_satisfaction": data.get("satisfaction", {}).get("overall", 0.0),
		"latest_rating": data.get("latest_rating", "B"),
	}

## 删除存档
func delete_save(slot_id: int) -> bool:
	var path := SAVE_DIR + "slot_%d.json" % slot_id
	if FileAccess.file_exists(path):
		return DirAccess.remove_absolute(path) == OK
	return false

## 捕获游戏快照
func _capture_snapshot() -> Dictionary:
	return {
		"time": {
			"semester_number": TimeManager.current_semester,
			"current_week": TimeManager.current_week,
			"current_day": TimeManager.current_day,
			"current_period": TimeManager.current_period,
		},
		"budget": {
			"balance": 0.0,
			"semester_allocated": 0.0,
			"semester_spent": 0.0,
		},
		"satisfaction": {
			"overall": 75.0,
			"cafeteria": 70.0,
			"dormitory": 80.0,
			"teaching": 70.0,
			"entertainment": 65.0,
		},
		"reputation": 70.0,
		"latest_rating": "B",
		"difficulty": GameConfig.current_difficulty,
		"save_version": "1.0",
	}

## 恢复游戏快照
func _restore_snapshot(data: Dictionary) -> void:
	var time_data: Dictionary = data.get("time", {})
	TimeManager.current_semester = int(time_data.get("semester_number", 1))
	TimeManager.current_week = int(time_data.get("current_week", 1))
	TimeManager.current_day = int(time_data.get("current_day", 1))
	TimeManager.current_period = int(time_data.get("current_period", 0))

	GameConfig.current_difficulty = data.get("difficulty", "普通")
