extends Node

## 全局信号总线 — 所有跨子系统通信通过此单例

# 时间信号
signal time_speed_changed(speed: int)
signal time_period_changed(period: int, day: int, day_of_week: int)
signal day_started(day: int, day_of_week: int)
signal week_started(week: int)
signal semester_started(semester: int)
signal semester_ended(semester: int, rating: String)

# 满意度信号
signal satisfaction_category_changed(category: String, value: float)
signal satisfaction_overall_changed(value: float)
signal satisfaction_below_threshold(value: float)

# 经济信号
signal budget_balance_changed(balance: float, delta: float)
signal daily_revenue_updated(restaurant_id: String, revenue: float)

# 事件信号
signal event_triggered(event_id: String, event_data: Dictionary)
signal event_resolved(event_id: String, choice_index: int)

# 建筑交互信号
signal building_clicked(building_id: String, building_type: String)
signal building_config_changed(building_id: String)
signal upgrade_started(building_id: String, duration_days: int)
signal upgrade_completed(building_id: String)

# 学生信号
signal student_state_changed(student_id: int, new_state: String)
signal student_queue_joined(window_id: String, student_id: int)
signal student_queue_left(window_id: String, student_id: int)
