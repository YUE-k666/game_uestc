extends Node

## 建筑交互控制器 — 处理建筑点击事件

var _current_panel: Control = null

func _ready() -> void:
	GameEvents.building_clicked.connect(_on_building_clicked)

func _on_building_clicked(building_id: String, building_type: String) -> void:
	# 建筑点击事件已由信号总线广播
	# 具体 UI 面板的打开由 building_panel_controller.gd 处理
	pass

## 关闭当前面板
func close_current_panel() -> void:
	if _current_panel:
		_current_panel.queue_free()
		_current_panel = null

## 设置当前面板
func set_current_panel(panel: Control) -> void:
	close_current_panel()
	_current_panel = panel
