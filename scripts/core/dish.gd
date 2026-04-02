class_name Dish
extends Resource

## 菜品 Resource 类

@export var id: String = ""
@export var dish_name: String = ""
@export var category: String = "meat"
@export var taste_tag: String = "spicy"
@export var base_cost: float = 3.0
@export var quality_level: int = 3
@export var quality_score: float = 60.0
@export var available_for: Array[String] = []
@export var is_halal: bool = false

func to_dict() -> Dictionary:
	return {
		"id": id,
		"dish_name": dish_name,
		"category": category,
		"taste_tag": taste_tag,
		"base_cost": base_cost,
		"quality_level": quality_level,
		"quality_score": quality_score,
		"available_for": available_for,
		"is_halal": is_halal,
	}

static func from_dict(data: Dictionary) -> Dish:
	var d := Dish.new()
	d.id = data.get("id", "")
	d.dish_name = data.get("name", "")
	d.category = data.get("category", "meat")
	d.taste_tag = data.get("taste_tag", "spicy")
	d.base_cost = float(data.get("base_cost", 3.0))
	d.quality_level = int(data.get("quality_level", 3))
	d.quality_score = float(data.get("quality_score", 60.0))
	d.available_for = data.get("available_for", [])
	d.is_halal = data.get("is_halal", false)
	return d
