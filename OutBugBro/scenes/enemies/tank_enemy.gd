## 坦克怪 — 巡逻行为：在随机点之间移动，发现玩家后追击
extends Enemy
class_name TankEnemy

func _visual_params() -> Dictionary:
	return {
		"collision_r": 32.0,
		"body_scale": Vector2(0.22, 0.2),
		"body_modulate": Color(0.6, 0.2, 0.8),
		"label_color": Color(0.7, 0.4, 1),
		"hp_fill_color": Color(0.6, 0.3, 0.8),
	}

var _patrol_points: Array[Vector2] = []
var _patrol_index: int = 0
var _patrol_timer: float = 0.0
var _state: int = 0  ## 0=巡逻, 1=追击

func _ready() -> void:
	scale = Vector2(1.4, 1.4) if not is_elite else Vector2(2.1, 2.1)
	super._ready()
	if _move:
		_move.move_speed *= 0.5
		_move.stop_distance = 55.0
	if _attack:
		_attack.attack_damage *= 2
	if has_node("TrailComponent"):
		var trail: TrailComponent = $TrailComponent
		trail.trail_color = Color(0.6, 0.2, 0.8, 0.35) if not is_elite else Color(1.0, 0.85, 0.0, 0.35)
		trail.trail_radius = 6.0
	## 生成巡逻点（以出生点为中心，半径200-400）
	var center := global_position
	for i in range(4):
		var angle := randf() * TAU
		var dist := randf_range(200.0, 400.0)
		_patrol_points.append(center + Vector2(cos(angle), sin(angle)) * dist)

func _physics_process(delta: float) -> void:
	if _state == 0:
		_process_patrol(delta)
	else:
		_process_chase(delta)

func _process_patrol(delta: float) -> void:
	if _patrol_points.is_empty() or not _move:
		return
	var target := _patrol_points[_patrol_index] as Vector2
	var dist := global_position.distance_to(target)
	if dist < 20.0:
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()
		_patrol_timer = randf_range(0.5, 1.5)
		return
	## 向巡逻点移动
	var dir := (target - global_position).normalized()
	_move.target_node = null
	velocity = dir * (_move.move_speed * 0.6)
	move_and_slide()
	## 检测玩家
	if _move.target_node or _detect_player():
		_state = 1

func _process_chase(delta: float) -> void:
	if not _move or not _move.target_node:
		## 丢失目标，回到巡逻
		_state = 0
		return
	if _move.is_in_range:
		_attack.try_attack(_move.target_node)
	else:
		## 追击
		var dir := (_move.target_node.global_position - global_position).normalized()
		velocity = dir * _move.move_speed
		move_and_slide()

func _detect_player() -> bool:
	var targets := get_tree().get_nodes_in_group("targets")
	if targets.is_empty():
		return false
	var target := targets[0] as Node2D
	if not target:
		return false
	var dist := global_position.distance_to(target.global_position)
	if dist < 300.0:
		if _move:
			_move.target_node = target
		return true
	return false
