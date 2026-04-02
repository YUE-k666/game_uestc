extends CanvasLayer

## HUD 控制器 — 更新顶部信息栏

@onready var date_label: Label = $TopBar/DateLabel
@onready var satisfaction_label: Label = $MiniBar/SatisfactionLabel
@onready var budget_label: Label = $MiniBar/BudgetLabel
@onready var week_label: Label = $MiniBar/WeekLabel
@onready var sidebar: PanelContainer = $Sidebar
@onready var sidebar_toggle: Button = $SidebarToggle

var _sidebar_open := false

func _ready() -> void:
	GameEvents.time_period_changed.connect(_on_time_changed)
	GameEvents.time_speed_changed.connect(_on_speed_changed)
	GameEvents.satisfaction_overall_changed.connect(_on_satisfaction_changed)
	GameEvents.budget_balance_changed.connect(_on_budget_changed)
	sidebar_toggle.pressed.connect(_toggle_sidebar)
	_update_date_display()

func _on_time_changed(_period: int, _day: int, _dow: int) -> void:
	_update_date_display()

func _on_speed_changed(_speed: int) -> void:
	_update_date_display()

func _update_date_display() -> void:
	if date_label:
		date_label.text = TimeManager.get_date_description()

func _on_satisfaction_changed(value: float) -> void:
	if satisfaction_label:
		var color := ">60%" if value > 60.0 else "<60%"
		satisfaction_label.text = "满意度: %.1f" % value
		if value < 60.0:
			satisfaction_label.add_theme_color_override("font_color", Color.RED)
		elif value < 65.0:
			satisfaction_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			satisfaction_label.add_theme_color_override("font_color", Color.WHITE)

func _on_budget_changed(balance: float, _delta: float) -> void:
	if budget_label:
		budget_label.text = "预算: %.0f元" % balance

func _toggle_sidebar() -> void:
	_sidebar_open = not _sidebar_open
	sidebar.visible = _sidebar_open
	sidebar_toggle.text = "◀" if _sidebar_open else "▶"
