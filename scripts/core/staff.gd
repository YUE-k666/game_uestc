class_name Staff
extends Resource

## 员工 Resource

@export var staff_id: int = 0
@export var staff_type: String = "chef"  # chef / maintenance / cleaning / dorm_manager
@export var skill_level: int = 2  # 1-5, MVP固定不可培训
@export var assigned_building: String = ""
@export var monthly_salary: float = 3500.0

func to_dict() -> Dictionary:
	return {
		"staff_id": staff_id,
		"staff_type": staff_type,
		"skill_level": skill_level,
		"assigned_building": assigned_building,
		"monthly_salary": monthly_salary,
	}

static func from_dict(data: Dictionary) -> Staff:
	var s := Staff.new()
	s.staff_id = int(data.get("staff_id", 0))
	s.staff_type = data.get("staff_type", "chef")
	s.skill_level = int(data.get("skill_level", 2))
	s.assigned_building = data.get("assigned_building", "")
	s.monthly_salary = float(data.get("monthly_salary", 3500.0))
	return s

## 根据岗位获取基础月薪
static func get_base_salary(staff_type: String) -> float:
	var salaries := {
		"chef": 3500.0,
		"maintenance": 3000.0,
		"cleaning": 2800.0,
		"dorm_manager": 3200.0,
	}
	return salaries.get(staff_type, 3000.0)

## 自动为建筑生成员工
static func generate_staff_for_building(building_id: String, building_type: String) -> Array[Staff]:
	var staff_list: Array[Staff] = []
	var id_counter := 10001

	match building_type:
		"cafeteria":
			for i in range(4):
				var s := Staff.new()
				s.staff_id = id_counter + i
				s.staff_type = "chef"
				s.skill_level = 2
				s.assigned_building = building_id
				s.monthly_salary = get_base_salary("chef")
				staff_list.append(s)
		"dormitory":
			var s1 := Staff.new()
			s1.staff_id = id_counter
			s1.staff_type = "dorm_manager"
			s1.skill_level = 2
			s1.assigned_building = building_id
			s1.monthly_salary = get_base_salary("dorm_manager")
			staff_list.append(s1)

			var s2 := Staff.new()
			s2.staff_id = id_counter + 1
			s2.staff_type = "cleaning"
			s2.skill_level = 2
			s2.assigned_building = building_id
			s2.monthly_salary = get_base_salary("cleaning")
			staff_list.append(s2)

	return staff_list
