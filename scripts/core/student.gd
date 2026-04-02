class_name Student
extends Resource

## 学生 Resource 类

@export var id: int = 0
@export var student_name: String = ""
@export var student_type: String = "undergraduate"  # undergraduate / graduate
@export var assigned_group: int = 0
@export var assigned_building: int = 0
@export var wallet_balance: float = 1500.0
@export var taste_preference: String = "spicy"  # spicy / mild / sweet / salty
@export var personality_tag: String = "foodie"  # foodie / scholar / frugal / athlete
@export var satisfaction: float = 75.0
@export var satisfaction_cafeteria: float = 70.0
@export var satisfaction_dormitory: float = 80.0
@export var grid_position: Vector2i = Vector2i.ZERO
@export var target_building: String = ""
@export var state: String = "idle"
@export var meals_today: int = 0
@export var curfew_violated: bool = false

## 序列化为字典（用于存档）
func to_dict() -> Dictionary:
	return {
		"id": id,
		"student_name": student_name,
		"student_type": student_type,
		"assigned_group": assigned_group,
		"assigned_building": assigned_building,
		"wallet_balance": wallet_balance,
		"taste_preference": taste_preference,
		"personality_tag": personality_tag,
		"satisfaction": satisfaction,
		"satisfaction_cafeteria": satisfaction_cafeteria,
		"satisfaction_dormitory": satisfaction_dormitory,
		"grid_position": {"x": grid_position.x, "y": grid_position.y},
		"target_building": target_building,
		"state": state,
		"meals_today": meals_today,
		"curfew_violated": curfew_violated,
	}

## 从字典反序列化
static func from_dict(data: Dictionary) -> Student:
	var s := Student.new()
	s.id = data.get("id", 0)
	s.student_name = data.get("student_name", "")
	s.student_type = data.get("student_type", "undergraduate")
	s.assigned_group = data.get("assigned_group", 0)
	s.assigned_building = data.get("assigned_building", 0)
	s.wallet_balance = data.get("wallet_balance", 1500.0)
	s.taste_preference = data.get("taste_preference", "spicy")
	s.personality_tag = data.get("personality_tag", "foodie")
	s.satisfaction = data.get("satisfaction", 75.0)
	s.satisfaction_cafeteria = data.get("satisfaction_cafeteria", 70.0)
	s.satisfaction_dormitory = data.get("satisfaction_dormitory", 80.0)
	var pos := data.get("grid_position", {"x": 0, "y": 0})
	s.grid_position = Vector2i(pos.get("x", 0), pos.get("y", 0))
	s.target_building = data.get("target_building", "")
	s.state = data.get("state", "idle")
	s.meals_today = data.get("meals_today", 0)
	s.curfew_violated = data.get("curfew_violated", false)
	return s
