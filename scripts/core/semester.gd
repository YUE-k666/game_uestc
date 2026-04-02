class_name Semester
extends Resource

## 学期 Resource

@export var semester_number: int = 1
@export var current_week: int = 1
@export var current_day: int = 1
@export var current_period: int = 0
@export var budget_allocated: float = 500000.0
@export var budget_spent: float = 0.0
@export var revenue_total: float = 0.0
@export var rating: String = "B"
@export var start_date: String = ""

func to_dict() -> Dictionary:
	return {
		"semester_number": semester_number,
		"current_week": current_week,
		"current_day": current_day,
		"current_period": current_period,
		"budget_allocated": budget_allocated,
		"budget_spent": budget_spent,
		"revenue_total": revenue_total,
		"rating": rating,
		"start_date": start_date,
	}

static func from_dict(data: Dictionary) -> Semester:
	var s := Semester.new()
	s.semester_number = int(data.get("semester_number", 1))
	s.current_week = int(data.get("current_week", 1))
	s.current_day = int(data.get("current_day", 1))
	s.current_period = int(data.get("current_period", 0))
	s.budget_allocated = float(data.get("budget_allocated", 500000.0))
	s.budget_spent = float(data.get("budget_spent", 0.0))
	s.revenue_total = float(data.get("revenue_total", 0.0))
	s.rating = data.get("rating", "B")
	s.start_date = data.get("start_date", "")
	return s
