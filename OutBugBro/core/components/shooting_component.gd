## 射击组件 — 瞄准(AUTO/MOUSE) + 射击逻辑
class_name ShootingComponent
extends Node

enum AimMode { AUTO, MOUSE }

@export var aim_mode: AimMode = AimMode.AUTO
@export var fire_rate: float = 0.5       ## 每次射击间隔
@export var rotate_speed: float = 5.0   ## 炮塔旋转速度
@export var bullet_scene: PackedScene   ## 子弹场景

var entity: Node2D                      ## 宿主引用
var stats: PlayerStats                  ## 属性引用（用于计算伤害）

## 蓄力系统
var _is_charging: bool = false
var _charge_time: float = 0.0
var _charge_max: float = 1.5            ## 普通蓄力上限
var _charge_max_heavy: float = 5.0      ## 重蓄力上限(W7+)
var _charge_min: float = 0.3            ## 最短蓄力

var _fire_timer: float = 0.0
var _target: Node2D = null

## 蓄力方向（用于磁力偏移计算）
var _charge_aim_dir: Vector2 = Vector2.RIGHT


func _physics_process(delta: float) -> void:
	if not entity:
		return
	# 找最近敌人
	_find_target()
	# 旋转炮塔朝向
	_rotate_turret(delta)
	# 蓄力计时
	if _is_charging:
		var max_t := _get_charge_max()
		_charge_time = minf(_charge_time + delta, max_t)


## 找最近敌人
func _find_target() -> void:
	_target = null
	var best_dist: float = 999999.0
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var dist := entity.global_position.distance_to(e.global_position)
		if dist < best_dist:
			best_dist = dist
			_target = e


## 旋转朝向目标/鼠标
func _rotate_turret(delta: float) -> void:
	var target_angle: float = 0.0
	if aim_mode == AimMode.AUTO and _target:
		target_angle = entity.global_position.angle_to_point(_target.global_position)
		entity.rotation = lerp_angle(entity.rotation, target_angle, rotate_speed * delta)
	elif aim_mode == AimMode.MOUSE:
		target_angle = entity.global_position.angle_to_point(entity.get_global_mouse_position())
		entity.rotation = target_angle  # 手动模式瞬间对准，不受转速限制
		_charge_aim_dir = Vector2.RIGHT.rotated(target_angle)
	else:
		return


## 自动射击
func _shoot() -> void:
	if not bullet_scene:
		return
	var bullet: Node2D = bullet_scene.instantiate()
	bullet.global_position = entity.global_position
	bullet.rotation = entity.rotation
	# 计算伤害（含暴击）
	if stats:
		bullet.damage = stats.calc_damage_dealt()
		bullet.is_crit = stats.last_attack_was_crit
	_setup_bullet(bullet, 1.0, 1)
	get_tree().current_scene.add_child(bullet)


## 开始蓄力
func start_charge() -> void:
	_is_charging = true
	_charge_time = 0.0
	_charge_aim_dir = Vector2.RIGHT.rotated(entity.rotation)


## 释放蓄力
func release_charge() -> void:
	if not _is_charging:
		return
	_is_charging = false
	if _charge_time < _charge_min:
		# 蓄力不够，普通射击
		_shoot()
		return
	# 计算蓄力等级
	var charge_level := _get_charge_level()
	var damage_mult: float = 1.0
	var pierce: int = 3
	var is_heavy: bool = false
	match charge_level:
		0:  # 普通蓄力 (0.3-1.5s)
			damage_mult = lerpf(2.0, 3.0, _charge_time / _charge_max)
			pierce = 3
		1:  # 重蓄力 (1.5-5.0s, W7+)
			damage_mult = lerpf(3.0, 7.0, (_charge_time - _charge_max) / (_charge_max_heavy - _charge_max))
			damage_mult = clampf(damage_mult, 5.0, 7.0)
			pierce = 5
			is_heavy = true
	# 是否双发
	var shot_count := 2 if SkillManager.is_active("double_shot") else 1
	# 磁力偏移：蓄力方向±10度
	var spread := deg_to_rad(10.0) if SkillManager.is_active("magnet") else 0.0
	# 磁力技能：蓄力时间缩短
	# 已在 _get_charge_max 中处理
	for i in range(shot_count):
		var angle_offset: float = 0.0
		if shot_count > 1:
			angle_offset = deg_to_rad(8.0) * (1 if i == 0 else -1)
		var dir := Vector2.RIGHT.rotated(entity.rotation + angle_offset)
		_fire_charged_bullet(dir, damage_mult, pierce, is_heavy)
	# 磁力吸引：让附近敌人朝射击方向偏移
	if SkillManager.is_active("magnet"):
		_apply_magnet_pull()
	# 重蓄力屏幕抖动
	if is_heavy:
		_screen_shake(3.0, 0.15)


## 发射蓄力弹
func _fire_charged_bullet(dir: Vector2, damage_mult: float, pierce: int, is_heavy: bool) -> void:
	if not bullet_scene:
		return
	var bullet: Node2D = bullet_scene.instantiate()
	bullet.global_position = entity.global_position
	bullet.rotation = dir.angle()
	bullet.scale = Vector2(1.3, 1.3) if is_heavy else Vector2(1.1, 1.1)
	# 计算基础伤害（含暴击）
	if stats:
		bullet.damage = stats.calc_damage_dealt()
		bullet.is_crit = stats.last_attack_was_crit
	_setup_bullet(bullet, damage_mult, pierce)
	if is_heavy:
		bullet.modulate = Color(1.0, 0.5, 0.2)  # 橙红色
	# 爆裂弹效果
	if aim_mode == AimMode.MOUSE:
		var wave := _get_wave()
		if wave >= 5:
			bullet.set_meta("explosive", true)
			bullet.set_meta("explosive_radius", 60.0 if is_heavy else 50.0)
			bullet.set_meta("explosive_damage_mult", 0.6 if is_heavy else 0.5)
	get_tree().current_scene.add_child(bullet)


## 设置子弹参数
func _setup_bullet(bullet: Node2D, damage_mult: float, pierce: int) -> void:
	if bullet.has_method("set_damage_mult"):
		bullet.set_damage_mult(damage_mult)
	if bullet.has_method("set_pierce"):
		bullet.set_pierce(pierce)
	# 穿透：手动模式默认3，蓄力5
	if aim_mode == AimMode.MOUSE and not bullet.has_method("set_pierce"):
		bullet.set_meta("pierce", pierce)


## 磁力吸引：让附近敌人朝射击方向偏移
func _apply_magnet_pull() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var aim_dir := _charge_aim_dir
	var pull_range: float = 300.0
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var dist := entity.global_position.distance_to(e.global_position)
		if dist > pull_range:
			continue
		# 偏移方向：朝射击方向±10度
		var offset_angle := deg_to_rad(randf_range(-10.0, 10.0))
		var pull_dir := aim_dir.rotated(offset_angle)
		var strength := 80.0 * (1.0 - dist / pull_range)
		if e.has_node("MoveComponent"):
			var move: Node = e.get_node("MoveComponent")
			if move.has_method("apply_knockback"):
				move.apply_knockback(pull_dir * strength)


## 蓄力等级：0=普通, 1=重蓄力(W7+)
func _get_charge_level() -> int:
	if _charge_time > _charge_max and _get_wave() >= 7:
		return 1
	if _charge_time >= _charge_min:
		return 0
	return -1  # 未达到最低蓄力


## 蓄力上限（磁力减半）
func _get_charge_max() -> float:
	var base := _charge_max
	if SkillManager.is_active("magnet"):
		base *= 0.5
	return base


## 获取当前波次
func _get_wave() -> int:
	var spawners := get_tree().get_nodes_in_group("spawners")
	if spawners.is_empty():
		return 1
	return spawners[0].wave


## 屏幕抖动
func _screen_shake(intensity: float, duration: float) -> void:
	var camera := get_tree().get_first_node_in_group("cameras")
	if not camera:
		# 尝试从场景找
		camera = get_tree().root.find_child("Camera2D", true, false)
	if camera:
		var tw := camera.create_tween()
		var orig: Vector2 = camera.position
		for i in range(3):
			var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
			tw.tween_property(camera, "position", orig + offset, duration / 3.0)
		tw.tween_property(camera, "position", orig, duration / 3.0)


## 蓄力进度(0-1, 1-2为重蓄力)
func get_charge_progress() -> float:
	if not _is_charging:
		return 0.0
	var max_t := _get_charge_max()
	if _charge_time <= max_t:
		return _charge_time / max_t
	# 重蓄力阶段
	return 1.0 + (_charge_time - max_t) / (_charge_max_heavy - max_t)
