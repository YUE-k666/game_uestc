class_name GameEventResource
extends Resource

## 事件 Resource 类

@export var event_id: String = ""
@export var event_type: String = "breakdown"
@export var event_name: String = ""
@export var description: String = ""
@export var trigger_conditions: Dictionary = {}
@export var effects: Array[Dictionary] = []
@export var choices: Array[Dictionary] = []
@export var is_periodic: bool = false
@export var period_trigger: Dictionary = {}

func to_dict() -> Dictionary:
	return {
		"event_id": event_id,
		"event_type": event_type,
		"event_name": event_name,
		"description": description,
		"trigger_conditions": trigger_conditions,
		"effects": effects,
		"choices": choices,
		"is_periodic": is_periodic,
		"period_trigger": period_trigger,
	}

static func from_dict(data: Dictionary) -> GameEventResource:
	var e := GameEventResource.new()
	e.event_id = data.get("event_id", "")
	e.event_type = data.get("event_type", "breakdown")
	e.event_name = data.get("name", "")
	e.description = data.get("description", "")
	e.trigger_conditions = data.get("trigger_conditions", {})
	e.effects = data.get("effects", [])
	e.choices = data.get("choices", [])
	e.is_periodic = data.get("is_periodic", false)
	e.period_trigger = data.get("period_trigger", {})
	return e
