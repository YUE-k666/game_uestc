class_name WindowSlot
extends Resource

## 食堂窗口 Resource 类

@export var window_id: String = ""
@export var dish_id: String = ""
@export var price: float = 10.0
@export var markup_rate: float = 0.0
@export var service_speed: float = 30.0
@export var staff_skill_level: int = 2
@export var queue_max_length: int = 20
@export var daily_customers: int = 0
@export var is_active: bool = true
@export var is_under_construction: bool = false

var queue: Array[int] = []

## 获取实际售价
func get_actual_price(dish_cost: float) -> float:
	if markup_rate > 0.0:
		return dish_cost * (1.0 + markup_rate)
	return price

## 队列是否已满
func is_queue_full() -> bool:
	return queue.size() >= queue_max_length

## 学生入队
func enqueue(student_id: int) -> bool:
	if is_queue_full() or not is_active or is_under_construction:
		return false
	queue.append(student_id)
	return true

## 学生出队（服务完成）
func dequeue() -> int:
	if queue.is_empty():
		return -1
	var sid := queue.pop_front()
	daily_customers += 1
	return sid

## 重置每日数据
func reset_daily() -> void:
	daily_customers = 0
	queue.clear()

func to_dict() -> Dictionary:
	return {
		"window_id": window_id,
		"dish_id": dish_id,
		"price": price,
		"markup_rate": markup_rate,
		"service_speed": service_speed,
		"staff_skill_level": staff_skill_level,
		"queue_max_length": queue_max_length,
		"daily_customers": daily_customers,
		"is_active": is_active,
		"is_under_construction": is_under_construction,
		"queue": queue,
	}

static func from_dict(data: Dictionary) -> WindowSlot:
	var w := WindowSlot.new()
	w.window_id = data.get("window_id", "")
	w.dish_id = data.get("dish_id", "")
	w.price = float(data.get("price", 10.0))
	w.markup_rate = float(data.get("markup_rate", 0.0))
	w.service_speed = float(data.get("service_speed", 30.0))
	w.staff_skill_level = int(data.get("staff_skill_level", 2))
	w.queue_max_length = int(data.get("queue_max_length", 20))
	w.daily_customers = int(data.get("daily_customers", 0))
	w.is_active = data.get("is_active", true)
	w.is_under_construction = data.get("is_under_construction", false)
	w.queue = data.get("queue", [])
	return w
