class_name Cafeteria
extends Building

## 食堂 Resource — Building 子类

@export var restaurant_id: String = ""
@export var restaurant_name: String = ""
@export var area: String = ""
@export var floors: Array[int] = [1]
@export var menu_scope: Array[String] = []
@export var daily_revenue: float = 0.0
@export var daily_customer_count: int = 0
@export var total_revenue_semester: float = 0.0
@export var satisfaction_score: float = 70.0

# 窗口列表：每个窗口是一个字典
var windows: Array[Dictionary] = []

## 获取入口位置（建筑中心底部）
func get_entrance_position() -> Vector2i:
	return Vector2i(grid_position.x + grid_size.x / 2, grid_position.y + grid_size.y)

## 获取指定窗口
func get_window(window_id: String) -> Dictionary:
	for w in windows:
		if w.get("window_id", "") == window_id:
			return w
	return {}

## 序列化
func to_dict() -> Dictionary:
	var d := super.to_dict()
	d["restaurant_id"] = restaurant_id
	d["restaurant_name"] = restaurant_name
	d["area"] = area
	d["floors"] = floors
	d["menu_scope"] = menu_scope
	d["daily_revenue"] = daily_revenue
	d["daily_customer_count"] = daily_customer_count
	d["total_revenue_semester"] = total_revenue_semester
	d["satisfaction_score"] = satisfaction_score
	d["windows"] = windows
	return d

static func from_dict(data: Dictionary) -> Cafeteria:
	var c := Cafeteria.new()
	c.id = data.get("id", "")
	c.building_name = data.get("building_name", data.get("name", ""))
	c.type = "cafeteria"
	var pos := data.get("grid_position", {"x": 0, "y": 0})
	c.grid_position = Vector2i(pos.get("x", 0), pos.get("y", 0))
	var size := data.get("grid_size", {"x": 6, "y": 4})
	c.grid_size = Vector2i(size.get("x", 6), size.get("y", 4))
	c.is_interactable = data.get("is_interactable", true)
	c.open_periods = data.get("open_periods", [0, 2, 4])
	c.restaurant_id = data.get("restaurant_id", "")
	c.restaurant_name = data.get("restaurant_name", "")
	c.area = data.get("area", "")
	c.floors = data.get("floors", [1])
	c.menu_scope = data.get("menu_scope", [])
	c.windows = data.get("windows", [])
	c.satisfaction_score = data.get("satisfaction_score", 70.0)
	return c
