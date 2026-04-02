extends Node

## 游戏配置加载器 — 启动时加载所有 JSON 数据文件

var game_params: Dictionary = {}
var time_config: Dictionary = {}
var semester_config: Dictionary = {}
var difficulty_presets: Dictionary = {}
var generation_config: Dictionary = {}
var campus_layout: Dictionary = {}
var building_types: Dictionary = {}
var dormitory_groups: Dictionary = {}
var restaurant_defs: Dictionary = {}
var dish_database: Dictionary = {}
var event_definitions: Dictionary = {}
var upgrade_definitions: Dictionary = {}
var window_templates: Dictionary = {}

# 当前难度设定
var current_difficulty: String = "普通"

func _ready() -> void:
	_load_all_configs()

func _load_all_configs() -> void:
	game_params = _load_json("res://data/balance/game_params.json")
	time_config = _load_json("res://data/balance/time_config.json")
	semester_config = _load_json("res://data/balance/semester_config.json")
	difficulty_presets = _load_json("res://data/difficulty/difficulty_presets.json")
	generation_config = _load_json("res://data/students/generation_config.json")
	# 以下文件可能尚未创建，使用 _load_json_or_empty 避免报错
	campus_layout = _load_json_or_empty("res://data/buildings/campus_layout.json")
	building_types = _load_json_or_empty("res://data/buildings/building_types.json")
	dormitory_groups = _load_json_or_empty("res://data/buildings/dormitory_groups.json")
	restaurant_defs = _load_json_or_empty("res://data/cafeterias/restaurant_defs.json")
	dish_database = _load_json_or_empty("res://data/dishes/dish_database.json")
	event_definitions = _load_json_or_empty("res://data/events/event_definitions.json")
	upgrade_definitions = _load_json_or_empty("res://data/upgrades/upgrade_definitions.json")
	window_templates = _load_json_or_empty("res://data/cafeterias/window_templates.json")

func _load_json(path: String) -> Dictionary:
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var json := JSON.new()
			var err := json.parse(file.get_as_text())
			if err == OK:
				return json.data
			push_error("JSON 解析失败 %s: %s" % [path, json.get_error_message()])
	else:
		push_warning("配置文件不存在: %s" % path)
	return {}

func _load_json_or_empty(path: String) -> Dictionary:
	if FileAccess.file_exists(path):
		return _load_json(path)
	return {}

## 获取当前难度的配置
func get_difficulty_config() -> Dictionary:
	if difficulty_presets.has(current_difficulty):
		return difficulty_presets[current_difficulty]
	return difficulty_presets.get("普通", {})

## 获取效用权重
func get_utility_weights() -> Dictionary:
	return game_params.get("效用权重", {})

## 获取满意度权重
func get_satisfaction_weights() -> Dictionary:
	return game_params.get("满意度权重", {})

## 获取时段定义列表
func get_period_definitions() -> Array:
	return time_config.get("时段定义", [])

## 获取指定时段的定义
func get_period_definition(index: int) -> Dictionary:
	var periods := get_period_definitions()
	if index >= 0 and index < periods.size():
		return periods[index]
	return {}

## 获取评级阈值
func get_rating_thresholds() -> Dictionary:
	return semester_config.get("评级阈值", {})

## 获取菜品数据
func get_dish(dish_id: String) -> Dictionary:
	var dishes := dish_database.get("菜品", [])
	for dish in dishes:
		if dish.get("id", "") == dish_id:
			return dish
	return {}

## 获取所有菜品
func get_all_dishes() -> Array:
	return dish_database.get("菜品", [])

## 获取餐厅定义
func get_restaurant_def(restaurant_id: String) -> Dictionary:
	var restaurants := restaurant_defs.get("餐厅", [])
	for r in restaurants:
		if r.get("restaurant_id", "") == restaurant_id:
			return r
	return {}

## 获取所有餐厅定义
func get_all_restaurant_defs() -> Array:
	return restaurant_defs.get("餐厅", [])
