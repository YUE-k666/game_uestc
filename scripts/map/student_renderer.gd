extends Node2D

## 学生精灵管理器 — 对象池管理学生 Sprite2D

const STUDENT_SIZE := 16
const MOVE_SPEED := 120.0  # 像素/秒

var _pool: Array[Sprite2D] = []
var _active: Dictionary = {}  # student_id -> Sprite2D
var _movement_targets: Dictionary = {}  # student_id -> {"target": Vector2, "speed": float}

func get_or_create_sprite(student_id: int) -> Sprite2D:
	if _active.has(student_id):
		return _active[student_id]

	var sprite: Sprite2D
	if _pool.size() > 0:
		sprite = _pool.pop_back()
	else:
		sprite = _create_sprite()

	sprite.visible = true
	_active[student_id] = sprite
	add_child(sprite)
	return sprite

func _create_sprite() -> Sprite2D:
	var sprite := Sprite2D.new()
	# 使用纯色纹理占位
	var img := Image.create(STUDENT_SIZE, STUDENT_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.9, 0.9, 0.2, 1.0))  # 黄色小方块
	var tex := ImageTexture.create_from_image(img)
	sprite.texture = tex
	return sprite

func release_sprite(student_id: int) -> void:
	if _active.has(student_id):
		var sprite: Sprite2D = _active[student_id]
		sprite.visible = false
		_movement_targets.erase(student_id)
		_active.erase(student_id)
		if get_children().has(sprite):
			remove_child(sprite)
		_pool.append(sprite)

func update_position(student_id: int, position: Vector2) -> void:
	var sprite := get_or_create_sprite(student_id)
	sprite.position = position

func move_student(student_id: int, target: Vector2) -> void:
	_movement_targets[student_id] = {"target": target, "speed": MOVE_SPEED}

func _process(delta: float) -> void:
	var to_remove: Array[int] = []
	for sid in _movement_targets:
		if not _active.has(sid):
			to_remove.append(sid)
			continue
		var sprite: Sprite2D = _active[sid]
		var info: Dictionary = _movement_targets[sid]
		var target: Vector2 = info["target"]
		var speed: float = info["speed"]

		var direction := target - sprite.position
		var dist := direction.length()
		if dist < 2.0:
			sprite.position = target
			to_remove.append(sid)
		else:
			sprite.position += direction.normalized() * speed * delta

	for sid in to_remove:
		_movement_targets.erase(sid)
