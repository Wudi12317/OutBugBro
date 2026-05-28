## 方框限制区域 — 基于摄像机视口大小计算（2倍摄像机视角）
## 作为 Autoload 全局访问，所有实体限制在方框内
## 注意：不声明 class_name，避免与 Autoload 单例名称冲突
extends Node

signal bounds_initialized(size: Vector2)

var _bounds_size: Vector2 = Vector2.ZERO
var _bounds_center: Vector2 = Vector2.ZERO
var _initialized: bool = false


func _ready() -> void:
	# 等一帧让摄像机就绪
	await get_tree().process_frame
	_init_bounds()


func _init_bounds() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_bounds_size = viewport_size * 2.0
	# 方框中心 = 玩家初始位置
	var targets := get_tree().get_nodes_in_group("targets")
	if targets.size() > 0:
		_bounds_center = targets[0].global_position
	else:
		_bounds_center = Vector2.ZERO
	_initialized = true
	bounds_initialized.emit(_bounds_size)


## 将位置限制在方框内
func clamp_position(pos: Vector2) -> Vector2:
	if not _initialized:
		return pos
	var half := _bounds_size / 2.0
	var min_pos := _bounds_center - half
	var max_pos := _bounds_center + half
	return Vector2(
		clampf(pos.x, min_pos.x, max_pos.x),
		clampf(pos.y, min_pos.y, max_pos.y)
	)


## 在方框内随机位置
func random_position_in_bounds() -> Vector2:
	var half := _bounds_size / 2.0
	var min_pos := _bounds_center - half
	return Vector2(
		randf_range(min_pos.x, min_pos.x + _bounds_size.x),
		randf_range(min_pos.y, min_pos.y + _bounds_size.y)
	)


## 在方框内、玩家视野外的随机位置（用于敌人生成）
func random_position_offscreen() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return random_position_in_bounds()
	var cam_pos: Vector2 = cam.global_position
	var viewport_size := get_viewport().get_visible_rect().size
	var half_view := viewport_size / 2.0
	var half_bounds := _bounds_size / 2.0
	var margin := 50.0

	# 尝试多次找到视野外的位置
	for _attempt in range(20):
		var pos := random_position_in_bounds()
		# 检查是否在摄像机视野外
		if pos.x < cam_pos.x - half_view.x - margin or pos.x > cam_pos.x + half_view.x + margin \
			or pos.y < cam_pos.y - half_view.y - margin or pos.y > cam_pos.y + half_view.y + margin:
			return pos

	# 回退：在方框边缘区域生成
	var side := randi() % 4
	var min_pos := _bounds_center - half_bounds
	var max_pos := _bounds_center + half_bounds
	match side:
		0: return Vector2(randf_range(min_pos.x, max_pos.x), min_pos.y + margin)    # 上边
		1: return Vector2(randf_range(min_pos.x, max_pos.x), max_pos.y - margin)    # 下边
		2: return Vector2(min_pos.x + margin, randf_range(min_pos.y, max_pos.y))    # 左边
		_: return Vector2(max_pos.x - margin, randf_range(min_pos.y, max_pos.y))    # 右边


func get_bounds_size() -> Vector2:
	return _bounds_size


func get_bounds_center() -> Vector2:
	return _bounds_center
