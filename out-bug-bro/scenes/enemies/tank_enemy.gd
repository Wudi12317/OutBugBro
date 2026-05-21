## 坦克怪 — HP×3, 速度×0.5, 体型1.4, 紫色, 攻击力×2
class_name TankEnemy
extends Enemy


func _visual_params() -> Dictionary:
	return {
		"collision_r": 32.0,
		"body_scale": Vector2(0.22, 0.2),
		"body_modulate": Color(0.6, 0.2, 0.8),
		"label_color": Color(0.7, 0.4, 1),
		"hp_fill_color": Color(0.6, 0.3, 0.8),
	}


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
