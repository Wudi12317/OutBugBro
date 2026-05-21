## 远程怪 — 远距离射击，不会靠近攻击，橙色
class_name RangedEnemy
extends Enemy

var _shoot_timer: float = 0.0
var _shoot_interval: float = 2.0


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
	if has_node("TrailComponent"):
		var trail: TrailComponent = $TrailComponent
		trail.trail_color = Color(1.0, 0.6, 0.2, 0.35) if not is_elite else Color(1.0, 0.85, 0.0, 0.35)


func _physics_process(_delta: float) -> void:
	if not _move or not _move.target_node:
		return
	_shoot_timer -= _delta
	if _move.is_in_range and _shoot_timer <= 0:
		_shoot_at_target()
		_shoot_timer = _shoot_interval


## 发射子弹
func _shoot_at_target() -> void:
	var bullet := EnemyBullet.create(
		global_position,
		(_move.target_node.global_position - global_position).normalized(),
		_attack.attack_damage if _attack else 5
	)
	get_parent().add_child(bullet)
