extends Node

## 食堂运营系统 — 窗口管理、排队处理、营收追踪

var _cafeterias: Dictionary = {}  # restaurant_id -> Cafeteria

func _ready() -> void:
	_init_cafeterias()
	GameEvents.time_period_changed.connect(_on_period_changed)
	GameEvents.day_started.connect(_on_day_started)

func _init_cafeterias() -> void:
	var restaurants := GameConfig.get_all_restaurant_defs()
	for rdef in restaurants:
		var rid: String = rdef.get("restaurant_id", "")
		var c := Cafeteria.new()
		c.restaurant_id = rid
		c.restaurant_name = rdef.get("restaurant_name", "")
		c.area = rdef.get("area", "")
		c.floors = rdef.get("floors", [1])
		c.menu_scope = rdef.get("menu_scope", [])
		c.id = rdef.get("building_id", rid)
		c.building_name = c.restaurant_name
		c.type = "cafeteria"

		# 创建窗口
		var window_count: int = rdef.get("window_count", 6)
		var all_dishes := _get_available_dishes(rid)
		for i in range(window_count):
			var w := WindowSlot.new()
			w.window_id = "%s_w%d" % [rid, i + 1]
			if all_dishes.size() > 0:
				w.dish_id = all_dishes[i % all_dishes.size()].id
				w.price = all_dishes[i % all_dishes.size()].base_cost * 1.8
			w.service_speed = 30.0
			c.windows.append(w.to_dict())

		_cafeterias[rid] = c

func _get_available_dishes(restaurant_id: String) -> Array[Dish]:
	var result: Array[Dish] = []
	var all_dishes := GameConfig.get_all_dishes()
	var rdef := GameConfig.get_restaurant_def(restaurant_id)
	var scope: Array = rdef.get("menu_scope", [])

	for ddata in all_dishes:
		var dish := Dish.from_dict(ddata)
		if dish.available_for.has(restaurant_id) or scope.has(dish.category):
			result.append(dish)
	return result

func _on_period_changed(period: int, _day: int, _dow: int) -> void:
	# 处理排队：每个时段处理一轮服务
	for rid in _cafeterias:
		var c: Cafeteria = _cafeterias[rid]
		if not c.is_open_at(period):
			continue
		_process_service(c)

func _on_day_started(_day: int, _dow: int) -> void:
	# 每日重置
	for rid in _cafeterias:
		var c: Cafeteria = _cafeterias[rid]
		c.daily_revenue = 0.0
		c.daily_customer_count = 0
		for wdata in c.windows:
			var w := WindowSlot.from_dict(wdata)
			w.reset_daily()

func _process_service(c: Cafeteria) -> void:
	var rice_cost: float = GameConfig.game_params.get("米饭成本", 0.5)
	var speed_mult := 1.0 + (0.1 * TimeManager.current_speed)

	for i in range(c.windows.size()):
		var wdata: Dictionary = c.windows[i]
		var w := WindowSlot.from_dict(wdata)
		if not w.is_active or w.is_under_construction:
			continue

		# 根据服务速度和技能处理排队
		var serve_count := int(w.service_speed * speed_mult * (1.0 + 0.1 * w.staff_skill_level) / 30.0)
		serve_count = mini(serve_count, w.queue.size())

		for _j in range(serve_count):
			var sid := w.dequeue()
			if sid >= 0:
				var dish_data := GameConfig.get_dish(w.dish_id)
				var dish_cost: float = float(dish_data.get("base_cost", 3.0))
				var actual_price := w.get_actual_price(dish_cost)
				var profit := actual_price - dish_cost - rice_cost
				c.daily_revenue += actual_price
				c.daily_customer_count += 1

		c.windows[i] = w.to_dict()

	GameEvents.daily_revenue_updated.emit(c.restaurant_id, c.daily_revenue)

## 获取指定餐厅
func get_restaurant(restaurant_id: String) -> Cafeteria:
	return _cafeterias.get(restaurant_id, null) as Cafeteria

## 获取所有餐厅
func get_all_restaurants() -> Dictionary:
	return _cafeterias

## 获取窗口效用值
func get_window_utility(wdata: Dictionary, student: Student) -> float:
	var weights := GameConfig.get_utility_weights()
	var norm := GameConfig.game_params.get("效用归一化", {})
	var max_price: float = float(norm.get("max_price", 25.0))
	var max_distance: float = float(norm.get("max_distance", 100.0))
	var queue_max: int = int(norm.get("queue_max", 20))

	var w := WindowSlot.from_dict(wdata)
	var dish_data := GameConfig.get_dish(w.dish_id)

	# 口味匹配
	var taste_match := 1.0 if dish_data.get("taste_tag", "") == student.taste_preference else 0.0
	# 价格因子
	var price_factor := 1.0 - (w.get_actual_price(float(dish_data.get("base_cost", 3.0))) / max_price)
	# 排队因子
	var queue_factor := 1.0 - (float(w.queue.size()) / float(queue_max))
	# 质量因子
	var quality_factor := float(dish_data.get("quality_score", 50.0)) / 100.0
	# 距离因子（简化）
	var distance_factor := 0.5

	var utility := (
		taste_match * float(weights.get("taste_match", 0.25))
		+ price_factor * float(weights.get("price", 0.20))
		+ distance_factor * float(weights.get("distance", 0.15))
		+ queue_factor * float(weights.get("queue", 0.20))
		+ quality_factor * float(weights.get("quality", 0.20))
	)
	return utility

## 学生入队
func add_student_to_queue(window_id: String, student_id: int) -> bool:
	for rid in _cafeterias:
		var c: Cafeteria = _cafeterias[rid]
		for i in range(c.windows.size()):
			var wdata: Dictionary = c.windows[i]
			if wdata.get("window_id", "") == window_id:
				var w := WindowSlot.from_dict(wdata)
				if w.enqueue(student_id):
					c.windows[i] = w.to_dict()
					GameEvents.student_queue_joined.emit(window_id, student_id)
					return true
	return false

## 更新窗口菜品
func update_dish(window_id: String, dish_id: String) -> void:
	for rid in _cafeterias:
		var c: Cafeteria = _cafeterias[rid]
		for i in range(c.windows.size()):
			if c.windows[i].get("window_id", "") == window_id:
				c.windows[i]["dish_id"] = dish_id
				GameEvents.building_config_changed.emit(rid)
				return

## 更新窗口价格
func update_price(window_id: String, new_price: float) -> void:
	for rid in _cafeterias:
		var c: Cafeteria = _cafeterias[rid]
		for i in range(c.windows.size()):
			if c.windows[i].get("window_id", "") == window_id:
				c.windows[i]["price"] = new_price
				c.windows[i]["markup_rate"] = 0.0
				GameEvents.building_config_changed.emit(rid)
				return

## 设置加成率
func set_markup_rate(restaurant_id: String, rate: float) -> void:
	var c: Cafeteria = _cafeterias.get(restaurant_id, null)
	if c:
		for i in range(c.windows.size()):
			c.windows[i]["markup_rate"] = rate
		GameEvents.building_config_changed.emit(restaurant_id)
