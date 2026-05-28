## 快速怪 — 冲锋行为：蓄力0.4s后冲刺，击退玩家
extends Enemy
class_name FastEnemy

func _visual_params() -> Dictionary:
	return {
		"collision_r": 16.0,
		"body_scale": Vector2(0.12, 0.11),
		"body_modulate": Color(0.3, 1.0, 0.3),
		"label_color": Color(0.3, 1, 0.3),
		"hp_fill_color": Color(0.3, 0.8, 0.3),
	}

var _charge_t: float = 0.0
var _is_charging: bool = false
var _charge_dir: Vector2 = Vector2.ZERO
var _cooldown: float = 0.0

func _ready() -> void:
	scale = Vector2(0.7, 0.7) if not is_elite else Vector2(1.05, 1.05)
	super._ready()
	if _move:
		_move.move_speed *= 2.0
		_move.stop_distance = 35.0
	if has_node("TrailComponent"):
		var trail: TrailComponent = $TrailComponent
		trail.trail_color = Color(0.3, 1.0, 0.3, 0.4) if not is_elite else Color(1.0, 0.85, 0.0, 0.35)
		trail.trail_radius = 3.0

func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
		return
	if _is_charging:
		_process_charge(delta)
		return
	if not _move or not _move.target_node:
		return
	var dist := global_position.distance_to(_move.target_node.global_position)
	if dist < 250.0 and dist > _move.stop_distance and not _is_charging:
		_start_charge()
	elif _move.is_in_range and _move.target_node:
		_attack.try_attack(_move.target_node)
		if _move.target_node.has_node("MoveComponent"):
			var dir := (_move.target_node.global_position - global_position).normalized()
			_move.target_node.get_node("MoveComponent").apply_knockback(dir * 200.0)

func _start_charge() -> void:
	_is_charging = true
	_charge_t = 0.0
	_charge_dir = (_move.target_node.global_position - global_position).normalized()
	if _body:
		var tw := create_tween()
		tw.tween_property(_body, "modulate:a", 0.4, 0.35).set_trans(Tween.TRANS_SINE)

func _process_charge(delta: float) -> void:
	_charge_t += delta
	if _charge_t >= 0.4:
		## 冲刺
		if _body:
			_body.modulate.a = 1.0
		velocity = _charge_dir * (_move.move_speed * 4.5)
		move_and_slide()
		_cooldown = 1.8
		_is_charging = false
	else:
		## 蓄力中减速
		velocity = Vector2.ZERO
