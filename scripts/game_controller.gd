extends Node2D

## 游戏入口控制器 — 管理系统初始化和生命周期

@onready var campus_map: Node2D = $CampusMap
@onready var student_renderer: Node2D = $StudentRenderer

var _student_manager: Node
var _student_ai: Node
var _pathfinding: Node
var _cafeteria_system: Node
var _dormitory_system: Node
var _upgrade_system: Node
var _evaluation_system: Node
var _event_manager: Node
var _satisfaction_manager: Node
var _economy_manager: Node
var _reputation_manager: Node
var _save_manager: Node
var _tutorial: Node
var _dashboard: Node

func _ready() -> void:
	_init_systems()
	_connect_signals()

func _init_systems() -> void:
	# 系统已在 main.tscn 中作为子节点或 Autoload 加载
	# 获取引用并建立连接
	_student_manager = $Systems/StudentManager
	_student_ai = $Systems/StudentAI
	_pathfinding = $Systems/PathfindingHelper

	# 设置寻路系统
	if _pathfinding and campus_map:
		_pathfinding.setup(campus_map)

	# 设置学生AI
	if _student_ai and _pathfinding and _student_manager:
		_student_ai.setup(_pathfinding, _student_manager)

	# 初始化学生渲染
	if _student_manager and student_renderer:
		_render_initial_students()

func _render_initial_students() -> void:
	if not _student_manager or not student_renderer:
		return
	var students: Array = _student_manager.get_all_students()
	for s in students:
		var student: Student = s
		var pos := Vector2(student.grid_position.x, student.grid_position.y)
		student_renderer.update_position(student.id, pos)

func _connect_signals() -> void:
	GameEvents.time_period_changed.connect(_on_period_changed)
	GameEvents.student_state_changed.connect(_on_student_state_changed)
	GameEvents.semester_ended.connect(_on_semester_ended)

func _on_period_changed(period: int, day: int, dow: int) -> void:
	# 更新学生位置渲染
	if _student_manager and student_renderer:
		var students: Array = _student_manager.get_all_students()
		for s in students:
			var student: Student = s
			if student.state == "moving" and student.target_building != "":
				var entrance := campus_map.get_building_entrance(student.target_building)
				if entrance != Vector2.ZERO:
					student_renderer.move_student(student.id, entrance)

func _on_student_state_changed(student_id: int, new_state: String) -> void:
	if new_state == "idle":
		# 学生到达目的地，暂时不动
		pass

func _on_semester_ended(semester: int, rating: String) -> void:
	# 显示学期报告
	print("[学期结束] 第%d学期，评级: %s" % [semester, rating])

## 开始新游戏
func start_new_game(difficulty: String) -> void:
	GameConfig.current_difficulty = difficulty
	# 重置所有管理器
	TimeManager.current_semester = 1
	TimeManager.current_week = 1
	TimeManager.current_day = 1
	TimeManager.current_period = 0
	TimeManager.set_speed(1)

	# 重新生成学生
	if _student_manager:
		_student_manager.generate_students()
		_render_initial_students()

## 保存当前游戏
func save_game(slot_id: int) -> bool:
	if _save_manager:
		return _save_manager.save_game(slot_id)
	return false

## 加载游戏
func load_game(slot_id: int) -> bool:
	if _save_manager:
		return _save_manager.load_game(slot_id)
	return false
