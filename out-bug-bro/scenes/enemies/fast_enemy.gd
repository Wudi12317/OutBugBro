## 快速怪 — 速度×2, HP×0.5, 体型0.7, 绿色, 会击退玩家
class_name FastEnemy
extends Enemy


func _visual_params() -> Dictionary:
	return {
		"collision_r": 16.0,
		"body_scale": Vector2(0.12, 0.11),
		"body_modulate": Color(0.3, 1.0, 0.3),
		"label_color": Color(0.3, 1, 0.3),
		"hp_fill_color": Color(0.3, 0.8, 0.3),
	}


func _ready() -> void:
	# 先缩小体型（在 super._ready 构建视觉之前）
	scale = Vector2(0.7, 0.7) if not is_elite else Vector2(1.05, 1.05)
	super._ready()
	# 覆盖移动参数
	if _move:
		_move.move_speed *= 2.0
		_move.stop_distance = 35.0
	# 拖尾变绿
	if has_node("TrailComponent"):
		var trail: TrailComponent = $TrailComponent
		trail.trail_color = Color(0.3, 1.0, 0.3, 0.4) if not is_elite else Color(1.0, 0.85, 0.0, 0.35)
		trail.trail_radius = 3.0


## 快速怪近距离攻击时击退玩家
func _physics_process(_delta: float) -> void:
	if _move and _move.is_in_range and _move.target_node:
		_attack.try_attack(_move.target_node)
		if _move.target_node.has_node("MoveComponent"):
			var dir := (_move.target_node.global_position - global_position).normalized()
			_move.target_node.get_node("MoveComponent").apply_knockback(dir * 200.0)
