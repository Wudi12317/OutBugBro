# 位移组件 — 免费位移技能，Q 键触发
# 方向：鼠标方向 | CD: dash_cooldown | 击杀减 CD: kill_cd_reduction
class_name DashComponent
extends Node

@export var dash_speed: float = 800.0       ## 位移速度
@export var dash_duration: float = 0.15     ## 位移持续时间（秒）
@export var dash_cooldown: float = 10.0     ## 冷却时间（秒）
@export var kill_cd_reduction: float = 1.0  ## 击杀减 CD（秒）

var _entity: CharacterBody2D
var _cooldown_remaining: float = 0.0
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO

signal dash_started
signal dash_ended

func _ready() -> void:
	# 监听击杀事件来减 CD
	EventBus.listen("enemy_killed", _on_enemy_killed)

func _process(delta: float) -> void:
	# 冷却倒计时
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)

	# 位移中
	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_is_dashing = false
			_entity.set_physics_process(true)
			dash_ended.emit()
		elif _entity:
			_entity.velocity = _dash_dir * dash_speed
			_entity.move_and_slide()

	# Q 键触发
	if Input.is_action_just_pressed("dash") and can_dash():
		_start_dash()

## 是否可位移
func can_dash() -> bool:
	return not _is_dashing and _cooldown_remaining <= 0.0 and _entity != null

## 获取 CD 进度 0~1（1=可用）
func get_cd_ratio() -> float:
	if dash_cooldown <= 0.0:
		return 1.0
	return 1.0 - (_cooldown_remaining / dash_cooldown)

## 获取 CD 剩余
func get_cd_remaining() -> float:
	return _cooldown_remaining

## 外部触发位移（可选）
func trigger_dash() -> void:
	if can_dash():
		_start_dash()

func _start_dash() -> void:
	if not _entity:
		return
	# 方向：鼠标位置 - 玩家位置
	var mouse_pos := _entity.get_global_mouse_position()
	_dash_dir = (mouse_pos - _entity.global_position).normalized()
	if _dash_dir.length_squared() < 0.01:
		_dash_dir = Vector2.RIGHT  # 默认右方
	_is_dashing = true
	_dash_timer = dash_duration
	_cooldown_remaining = dash_cooldown
	dash_started.emit()
	# 位移特效
	_spawn_dash_fx()

func _on_enemy_killed(_data: Variant = null) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(0.0, _cooldown_remaining - kill_cd_reduction)

func _spawn_dash_fx() -> void:
	if not _entity or not _entity.get_parent():
		return
	# 残影效果：3 个半透明方块沿位移方向散开
	for i in range(3):
		var ghost := ColorRect.new()
		ghost.size = Vector2(24, 24)
		ghost.color = Color(0.3, 0.8, 1.0, 0.4)
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost.z_index = 5
		ghost.position = _entity.global_position - Vector2(12, 12)
		_entity.get_parent().add_child(ghost)
		var offset := -_dash_dir * (i + 1) * 20.0
		var tw := _entity.get_parent().create_tween()
		tw.tween_property(ghost, "position", ghost.position + offset, 0.3)
		tw.parallel().tween_property(ghost, "modulate:a", 0.0, 0.3)
		tw.tween_callback(ghost.queue_free)
