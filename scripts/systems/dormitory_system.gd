extends Node

## 宿舍运营系统 — 参数管理、成本计算、满意度影响

var _groups: Dictionary = {}  # group_id -> DormitoryGroup
var _buildings: Dictionary = {}  # building_id -> DormitoryBuilding

func _ready() -> void:
	_init_groups()

func _init_groups() -> void:
	var data := GameConfig.dormitory_groups
	var groups_list: Array = data.get("组团", [])
	for gdata in groups_list:
		var g := DormitoryGroup.from_dict(gdata)
		_groups[g.group_id] = g

		# 创建楼栋
		var details: Array = gdata.get("building_details", [])
		for bdata in details:
			var db := DormitoryBuilding.new()
			db.building_id = int(bdata.get("building_id", 0))
			db.group_id = g.group_id
			db.has_ac = bdata.get("has_ac", false)
			db.has_private_bath = bdata.get("has_private_bath", false)
			db.capacity = int(bdata.get("capacity", 200))
			db.base_satisfaction_bonus = float(bdata.get("base_satisfaction_bonus", 0.0))
			db.type = "dormitory"
			_buildings[db.building_id] = db

## 获取组团
func get_group(group_id: int) -> DormitoryGroup:
	return _groups.get(group_id, null)

## 获取所有组团
func get_all_groups() -> Dictionary:
	return _groups

## 获取楼栋
func get_building(building_id: int) -> DormitoryBuilding:
	return _buildings.get(building_id, null)

## 更新热水时段
func update_hot_water(group_id: int, start_period: int, end_period: int) -> void:
	var g: DormitoryGroup = _groups.get(group_id)
	if g:
		g.hot_water_start = start_period
		g.hot_water_end = end_period
		GameEvents.building_config_changed.emit("dorm_group_%d" % group_id)

## 更新电费
func update_electricity_price(group_id: int, price: float) -> void:
	var g: DormitoryGroup = _groups.get(group_id)
	if g:
		g.electricity_price = price
		GameEvents.building_config_changed.emit("dorm_group_%d" % group_id)

## 更新维修频率
func update_maintenance(group_id: int, level: int) -> void:
	var g: DormitoryGroup = _groups.get(group_id)
	if g:
		g.maintenance_frequency = level
		GameEvents.building_config_changed.emit("dorm_group_%d" % group_id)

## 更新清洁等级
func update_cleanliness(group_id: int, level: int) -> void:
	var g: DormitoryGroup = _groups.get(group_id)
	if g:
		g.cleanliness_level = level
		GameEvents.building_config_changed.emit("dorm_group_%d" % group_id)

## 更新门禁
func update_curfew(group_id: int, period: int) -> void:
	var g: DormitoryGroup = _groups.get(group_id)
	if g:
		g.curfew_period = period
		GameEvents.building_config_changed.emit("dorm_group_%d" % group_id)

## 计算组团运营成本
func calculate_group_cost(group_id: int) -> Dictionary:
	var g: DormitoryGroup = _groups.get(group_id)
	if g:
		return g.calculate_cost()
	return {"总计": 0.0}

## 计算组团满意度影响
func calculate_satisfaction_impact(group_id: int) -> float:
	var g: DormitoryGroup = _groups.get(group_id)
	if not g:
		return 0.0

	var impact := 0.0

	# 热水可用性：可用时段越长满意度越高
	var hot_water_hours := g.hot_water_end - g.hot_water_start
	impact += (hot_water_hours - 4.0) * 1.5  # 4小时为基准

	# 维修频率：越高越好
	impact += (g.maintenance_frequency - 3) * 2.0

	# 清洁等级：越高越好
	impact += (g.cleanliness_level - 3) * 2.5

	# 门禁：越晚越宽容
	impact += (g.curfew_period - 5) * 1.0

	# 楼栋硬件加成
	var avg_bonus := 0.0
	var count := 0
	for bid in g.buildings:
		var db: DormitoryBuilding = _buildings.get(bid)
		if db:
			avg_bonus += db.base_satisfaction_bonus
			count += 1
	if count > 0:
		impact += avg_bonus / count

	return impact
