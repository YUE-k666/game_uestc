extends Node

## 学生 AI 行为决策 — 根据时段决定目标建筑

var _pathfinding: Node = null
var _student_manager: Node = null

func setup(pathfinding: Node, student_manager: Node) -> void:
	_pathfinding = pathfinding
	_student_manager = student_manager

func _ready() -> void:
	GameEvents.time_period_changed.connect(_on_period_changed)

func _on_period_changed(period: int, _day: int, _day_of_week: int) -> void:
	if not _student_manager:
		return
	# 每个时段变更时，为学生分配新目标
	var students: Array = _student_manager.get_all_students()
	for s in students:
		if s.state == "sleeping" or s.state == "eating":
			continue
		_evaluate_schedule(s, period)

## 根据时段评估日程
func evaluate_schedule(student: Student) -> void:
	_evaluate_schedule(student, TimeManager.current_period)

func _evaluate_schedule(student: Student, period: int) -> void:
	var target_type := _get_target_type_for_period(period, student)
	if target_type == "":
		student.state = "idle"
		return

	# 选择目标建筑
	var target_id := _choose_target_building(student, target_type)
	if target_id == "":
		student.state = "idle"
		return

	student.target_building = target_id
	student.state = "moving"
	GameEvents.student_state_changed.emit(student.id, "moving")

	# 通知渲染器移动学生
	if _pathfinding:
		var path: Array[Vector2] = _pathfinding.get_path_to_building(
			Vector2(student.grid_position.x, student.grid_position.y),
			target_id
		)
		if path.size() > 0:
			# 通过信号或直接调用渲染器
			student.grid_position = Vector2i(int(path[-1].x), int(path[-1].y))

func _get_target_type_for_period(period: int, student: Student) -> String:
	var def := GameConfig.get_period_definition(period)
	var default_target: String = def.get("学生目标", "")

	# 根据性格调整
	if student.personality_tag == "athlete" and period == 5:
		return "other"  # 运动型学生晚上去体育馆
	if student.personality_tag == "scholar" and period == 5:
		return "library"  # 学霸晚上去图书馆

	return default_target

func _choose_target_building(student: Student, target_type: String) -> String:
	if target_type == "cafeteria":
		return _choose_cafeteria(student)
	elif target_type == "dormitory":
		return _choose_dormitory(student)
	elif target_type == "teaching" or target_type == "library" or target_type == "other":
		if _pathfinding and _pathfinding._campus_map:
			return _pathfinding.find_nearest_building(
				Vector2(student.grid_position.x, student.grid_position.y),
				target_type
			)
	return ""

## 选择食堂 — 效用模型：遍历所有开放窗口，选择最高效用
func _choose_cafeteria(student: Student) -> String:
	var cafeteria_system := _get_cafeteria_system()
	if not cafeteria_system:
		return ""

	var all_restaurants := cafeteria_system.get_all_restaurants()
	var threshold: float = float(GameConfig.game_params.get("放弃阈值", 0.3))
	var difficulty := GameConfig.get_difficulty_config()
	threshold = float(difficulty.get("utility_abandon_threshold", threshold))

	var best_utility := -1.0
	var best_window_id := ""
	var best_restaurant_id := ""

	for rid in all_restaurants:
		var c: Cafeteria = all_restaurants[rid]
		if not c.is_open_at(TimeManager.current_period):
			continue
		for wdata in c.windows:
			var utility := cafeteria_system.get_window_utility(wdata, student)
			if utility > best_utility:
				best_utility = utility
				best_window_id = wdata.get("window_id", "")
				best_restaurant_id = rid

	# 效用低于阈值则放弃就餐
	if best_utility < threshold:
		student.satisfaction_cafeteria -= 3.0
		GameEvents.satisfaction_category_changed.emit("cafeteria", student.satisfaction_cafeteria)
		return ""

	# 加入排队
	if best_window_id != "":
		cafeteria_system.add_student_to_queue(best_window_id, student.id)
		student.state = "queuing_cafeteria"

	return best_restaurant_id

func _get_cafeteria_system() -> Node:
	var systems := get_tree().get_first_node_in_group("systems")
	if systems:
		return systems.get_node_or_null("CafeteriaSystem")
	# 尝试直接查找
	return get_node_or_null("/root/Main/Systems/CafeteriaSystem")

## 选择宿舍
func _choose_dormitory(student: Student) -> String:
	# 返回学生所属宿舍楼
	var dorm_id := "dorm_group_%d_b1" % student.assigned_group
	return dorm_id
