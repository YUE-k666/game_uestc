extends Node

## 按需提示系统 — 维护提示队列和已读标记

var _shown_hints: Dictionary = {}
var _hint_queue: Array[String] = []
var _is_showing_hint := false

var _hint_definitions := {
	"first_building_click": {
		"title": "建筑交互",
		"message": "点击食堂或宿舍建筑可以打开配置面板，调整运营参数。",
	},
	"first_param_change": {
		"title": "参数调整",
		"message": "修改菜品价格、宿舍参数后，效果会在下个时段生效。",
	},
	"first_event": {
		"title": "突发事件",
		"message": "随机事件会影响满意度和财务，及时做出正确决策很重要。",
	},
	"first_dashboard": {
		"title": "数据看板",
		"message": "右侧面板可以查看满意度、营收等关键指标的详细信息。",
	},
	"first_upgrade": {
		"title": "建筑升级",
		"message": "升级食堂窗口或宿舍组团可以提升服务质量，但需要花费资金和时间。",
	},
	"satisfaction_warning": {
		"title": "满意度警告",
		"message": "综合满意度低于65！如果不及时改善，游戏将结束。",
	},
	"budget_low": {
		"title": "预算紧张",
		"message": "预算余额不足5万元，请注意控制支出。",
	},
}

func _ready() -> void:
	GameEvents.building_clicked.connect(_on_building_clicked)
	GameEvents.building_config_changed.connect(_on_config_changed)
	GameEvents.event_triggered.connect(_on_event_triggered)
	GameEvents.satisfaction_below_threshold.connect(_on_satisfaction_low)

func _on_building_clicked(_bid: String, _btype: String) -> void:
	trigger_hint("first_building_click")

func _on_config_changed(_bid: String) -> void:
	trigger_hint("first_param_change")

func _on_event_triggered(_eid: String, _data: Dictionary) -> void:
	trigger_hint("first_event")

func _on_satisfaction_low(value: float) -> void:
	if value < 60.0:
		trigger_hint("satisfaction_warning")

func trigger_hint(hint_id: String) -> void:
	if _shown_hints.get(hint_id, false):
		return
	_shown_hints[hint_id] = true
	_hint_queue.append(hint_id)
	if not _is_showing_hint:
		_show_next_hint()

func _show_next_hint() -> void:
	if _hint_queue.is_empty():
		_is_showing_hint = false
		return

	_is_showing_hint = true
	var hint_id := _hint_queue.pop_front()
	var hint: Dictionary = _hint_definitions.get(hint_id, {})
	if hint.is_empty():
		_show_next_hint()
		return

	# 这里可以发出信号让 UI 层显示提示
	# 简化版：直接打印
	print("[提示] %s: %s" % [hint.get("title", ""), hint.get("message", "")])

func dismiss_hint() -> void:
	_show_next_hint()

func reset() -> void:
	_shown_hints.clear()
	_hint_queue.clear()
	_is_showing_hint = false
