extends Node

## 寻路辅助工具 — 基于简单格子距离的路径计算

var _campus_map: Node2D = null

func setup(map: Node2D) -> void:
	_campus_map = map

## 计算从起点到建筑入口的路径（简化为直线移动）
func get_path_to_building(from: Vector2, building_id: String) -> Array[Vector2]:
	if not _campus_map:
		return []
	var target := _campus_map.get_building_entrance(building_id)
	if target == Vector2.ZERO:
		return []
	# 简化为直线（后续可接入 NavigationRegion2D）
	var steps: Array[Vector2] = []
	var distance := from.distance_to(target)
	var step_count := int(ceil(distance / 48.0))
	for i in range(1, step_count + 1):
		var t := float(i) / float(step_count)
		steps.append(from.lerp(target, t))
	return steps

## 计算两个位置之间的格子距离
func grid_distance(from: Vector2i, to: Vector2i) -> int:
	return abs(from.x - to.x) + abs(from.y - to.y)

## 计算两个世界坐标之间的距离
func world_distance(from: Vector2, to: Vector2) -> float:
	return from.distance_to(to)

## 获取最近的建筑
func find_nearest_building(from: Vector2, building_type: String) -> String:
	if not _campus_map:
		return ""
	var best_id := ""
	var best_dist := INF
	var ids: Array[String] = _campus_map.get_buildings_by_type(building_type)
	for id in ids:
		var entrance := _campus_map.get_building_entrance(id)
		var dist := from.distance_to(entrance)
		if dist < best_dist:
			best_dist = dist
			best_id = id
	return best_id
