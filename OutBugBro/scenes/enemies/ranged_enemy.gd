## 远程怪 — 环绕玩家 + 保持距离射击，橙色
extends Enemy
class_name RangedEnemy

var _shoot_timer: float = 0.0
var _shoot_interval: float = 2.0
var _angle: float = 0.0  ## 环绕角度

func _visual_params() -> Dictionary:
	return {
		"collision_r": 20.0,
		"body_scale": Vector2(0.14, 0.13),
		"body_modulate": Color(1.0, 0.6, 0.2),
		"label_color": Color(1, 0.7, 0.3),
		"hp_fill_color": Color(1.0, 0.6, 0.2),
	}

func _ready() -> void:
	super._ready()
	if _move:
		_move.stop_distance = 180.0
		_move.move_speed *= 0.8
	## 随机初始环绕角度
	_angle = randf() * TAU
	if has_node("TrailComponent"):
		var trail: TrailComponent = $TrailComponent
		trail.trail_color = Color(1.0, 0.6, 0.2, 0.35) if not is_elite else Color(1.0, 0.85, 0.0, 0.35)
		trail.trail_radius = 4.0

func _physics_process(delta: float) -> void:
	if not _move or not _move.target_node:
		return
	var target: Node2D = _move.target_node
	var dist := global_position.distance_to(target.global_position)
	## 保持距离 150-250
	var ideal_dist: float = 200.0
	if dist > ideal_dist + 30.0:
		## 太远，靠近
		var dir := (target.global_position - global_position).normalized()
		velocity = dir * (_move.move_speed * 0.6)
		move_and_slide()
	elif dist < ideal_dist - 30.0:
		## 太近，远离
		var dir := (global_position - target.global_position).normalized()
		velocity = dir * (_move.move_speed * 0.4)
		move_and_slide()
	else:
		## 环绕：切线方向移动
		_angle += delta * 1.2
		var offset := Vector2(cos(_angle), sin(_angle)) * ideal_dist
		var desired := target.global_position + offset
		var dir := (desired - global_position).normalized()
		velocity = dir * (_move.move_speed * 0.5)
		move_and_slide()
	## 射击
	_shoot_timer -= delta
	if dist <= 300.0 and _shoot_timer <= 0.0:
		_shoot()
		_shoot_timer = _shoot_interval

## 远程射击：朝目标发射子弹
func _shoot() -> void:
	if not _move or not _move.target_node:
		return
	var b := EnemyBullet.create(global_position, (_move.target_node.global_position - global_position).normalized(), _attack.attack_damage if _attack else 15)
	var world := get_parent()
	if world:
		world.add_child(b)
