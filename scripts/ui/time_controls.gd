extends HBoxContainer

## 时间速度控制按钮

var _buttons: Array[Button] = []
var _speed_names := ["⏸", "▶", "⏩", "⏩⏩"]
var _speed_values := [0, 1, 2, 3]

func _ready() -> void:
	for i in range(4):
		var btn := Button.new()
		btn.text = _speed_names[i]
		btn.custom_minimum_size = Vector2(36, 28)
		btn.pressed.connect(_on_speed_button.bind(_speed_values[i]))
		_buttons.append(btn)
		add_child(btn)

	GameEvents.time_speed_changed.connect(_on_speed_changed)
	# 初始化高亮
	_update_highlight(TimeManager.current_speed)

func _on_speed_button(speed: int) -> void:
	TimeManager.set_speed(speed)

func _on_speed_changed(speed: int) -> void:
	_update_highlight(speed)

func _update_highlight(speed: int) -> void:
	for i in range(_buttons.size()):
		if _speed_values[i] == speed:
			_buttons[i].modulate = Color(1, 1, 0.5)
		else:
			_buttons[i].modulate = Color.WHITE
