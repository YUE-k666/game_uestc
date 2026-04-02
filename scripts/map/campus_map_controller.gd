extends Node2D

## 校园地图控制器 — 根据配置实例化建筑节点

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var buildings_node: Node2D = $Buildings
@onready var students_node: Node2D = $Students

var tile_size: int = 48
var buildings: Dictionary = {}  # id -> Building Resource
var building_nodes: Dictionary = {}  # id -> Node2D

func _ready() -> void:
	_load_campus()

func _load_campus() -> void:
	var layout := GameConfig.campus_layout
	var building_list: Array = layout.get("建筑列表", [])
	tile_size = layout.get("瓦片尺寸", 48)

	for bdata in building_list:
		var b := Building.from_dict(bdata)
		buildings[b.id] = b
		_create_building_node(b)

	# 创建地面占位
	_create_ground(layout)

func _create_building_node(b: Building) -> void:
	var node := Node2D.new()
	node.name = b.id
	node.position = _grid_to_world(b.grid_position)
	node.set_meta("building_id", b.id)
	node.set_meta("building_type", b.type)

	# 创建精灵（占位色块）
	var sprite := ColorRect.new()
	sprite.size = Vector2(b.grid_size.x * tile_size, b.grid_size.y * tile_size)
	sprite.color = _get_type_color(b.type)
	sprite.mouse_filter = Control.MOUSE_FILTER_PASS

	# 建筑名称标签
	var label := Label.new()
	label.text = b.building_name
	label.position = Vector2(0, -20)
	label.add_theme_font_size_override("font_size", 10)

	# 点击区域
	var clickable := Area2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = sprite.size
	collision.shape = shape
	collision.position = sprite.size / 2
	clickable.add_child(collision)
	clickable.input_event.connect(_on_building_input_event.bind(b.id, b.type))

	node.add_child(sprite)
	node.add_child(label)
	node.add_child(clickable)
	buildings_node.add_child(node)
	building_nodes[b.id] = node

func _create_ground(layout: Dictionary) -> void:
	var map_width: int = layout.get("地图尺寸", {}).get("width", 120)
	var map_height: int = layout.get("地图尺寸", {}).get("height", 80)
	# 地面使用绿色占位
	var ground := ColorRect.new()
	ground.size = Vector2(map_width * tile_size, map_height * tile_size)
	ground.color = Color(0.36, 0.56, 0.27)  # 草地绿
	ground.z_index = -1
	add_child(ground)
	# 移到最前面
	move_child(ground, 0)

func _grid_to_world(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * tile_size, pos.y * tile_size)

func _get_type_color(type: String) -> Color:
	var colors := {
		"cafeteria": Color(1.0, 0.6, 0.0),     # 橙色
		"dormitory": Color(0.3, 0.69, 0.31),    # 绿色
		"teaching": Color(0.13, 0.59, 0.95),    # 蓝色
		"library": Color(0.61, 0.15, 0.69),     # 紫色
		"other": Color(0.38, 0.49, 0.55),       # 灰蓝色
	}
	return colors.get(type, Color.GRAY)

func _on_building_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, building_id: String, building_type: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GameEvents.building_clicked.emit(building_id, building_type)

## 获取建筑入口的世界坐标
func get_building_entrance(building_id: String) -> Vector2:
	if buildings.has(building_id):
		var b: Building = buildings[building_id]
		var entrance := Vector2i(b.grid_position.x + b.grid_size.x / 2, b.grid_position.y + b.grid_size.y)
		return _grid_to_world(entrance)
	return Vector2.ZERO

## 获取指定类型的所有建筑
func get_buildings_by_type(type: String) -> Array[String]:
	var result: Array[String] = []
	for id in buildings:
		if buildings[id].type == type:
			result.append(id)
	return result

## 获取学生容器节点
func get_students_node() -> Node2D:
	return students_node
