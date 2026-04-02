extends Node

## 建筑面板控制器 — 根据 building_type 动态切换面板

var _current_panel: Control = null

func _ready() -> void:
	GameEvents.building_clicked.connect(_on_building_clicked)

func _on_building_clicked(building_id: String, building_type: String) -> void:
	close_panel()
	match building_type:
		"cafeteria":
			_show_cafeteria_panel(building_id)
		"dormitory":
			_show_dormitory_panel(building_id)

func _show_cafeteria_panel(building_id: String) -> void:
	var panel := _create_cafeteria_panel(building_id)
	if panel:
		_show_panel(panel)

func _show_dormitory_panel(building_id: String) -> void:
	var panel := _create_dormitory_panel(building_id)
	if panel:
		_show_panel(panel)

func _create_cafeteria_panel(building_id: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 500)
	panel.position = Vector2(880, 40)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "食堂管理: %s" % building_id
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	# 窗口列表占位
	var info := Label.new()
	info.text = "窗口配置加载中..."
	vbox.add_child(info)

	# 关闭按钮
	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.pressed.connect(close_panel)
	vbox.add_child(close_btn)

	return panel

func _create_dormitory_panel(building_id: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 400)
	panel.position = Vector2(880, 40)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "宿舍管理: %s" % building_id
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	var info := Label.new()
	info.text = "参数配置加载中..."
	vbox.add_child(info)

	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.pressed.connect(close_panel)
	vbox.add_child(close_btn)

	return panel

func _show_panel(panel: Control) -> void:
	_current_panel = panel
	# 添加到场景树（需要找到 CanvasLayer）
	var canvas := get_tree().get_first_node_in_group("hud_canvas")
	if canvas:
		canvas.add_child(panel)
	else:
		get_tree().root.add_child(panel)

func close_panel() -> void:
	if _current_panel and is_instance_valid(_current_panel):
		_current_panel.queue_free()
	_current_panel = null
