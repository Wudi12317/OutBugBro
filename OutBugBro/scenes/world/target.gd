## 目标物体 — 组件化：血量 + 射击 + 属性 + 技能效果 + 移动
## 技能特效：护盾光环 / 反伤紫盾 / 修理金光 / 导弹爆炸 / 磁力场
## WASD / 方向键移动，速度由 PlayerStats 驱动
extends CharacterBody2D

var _health: HealthComponent
var _shooting: ShootingComponent
var _stats: PlayerStats
var _dead: bool = false
var _dash: DashComponent

## 技能特效节点
var _shield_ring: ColorRect
var _fx_timer: float = 0.0
## 蓄力特效节点
var _charge_ring: ColorRect
var _charge_particles: Array[ColorRect] = []
var _charge_glow: ColorRect

@onready var _mode_label: Label = %ModeLabel
@onready var _body: ColorRect = $Body


func _ready() -> void:
	add_to_group("targets")
	add_to_group("player")
	# 挂载属性组件
	_stats = PlayerStats.new()
	_stats.config = preload("res://data/player_config.tres")
	_stats.name = "PlayerStats"
	add_child(_stats)

	# 挂载血量组件（先设 max_hp 再 add_child，避免 _setup 用默认值初始化 hp）
	_health = HealthComponent.new()
	_health.entity = self
	_health.name = "HealthComponent"
	_health.max_hp = _stats.get_max_hp()
	add_child(_health)
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)

	# 挂载射击组件
	_shooting = ShootingComponent.new()
	_shooting.entity = self
	_shooting.stats = _stats
	_shooting.fire_rate = _stats.get_fire_rate()
	_shooting.rotate_speed = 3.0
	_shooting.bullet_scene = preload("res://scenes/world/bullet.tscn")
	_shooting.name = "ShootingComponent"
	add_child(_shooting)

	# 属性变化时同步组件
	_stats.stats_changed.connect(_on_stats_changed)

	# 监听回血事件（消耗品使用）
	EventBus.listen("player_heal", _on_player_heal)

	# 监听复活
	EventBus.listen("player_revive", _on_player_revive)

	# 监听技能激活
	SkillManager.skill_activated.connect(_on_skill_activated)

	# 挂载位移组件
	_dash = DashComponent.new()
	_dash._entity = self
	_dash.name = "DashComponent"
	add_child(_dash)

	# 创建护盾光环节点（默认隐藏）
	_shield_ring = ColorRect.new()
	_shield_ring.name = "ShieldRing"
	_shield_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shield_ring.z_index = 5
	_shield_ring.color = Color.CYAN
	_shield_ring.visible = false
	add_child(_shield_ring)

	# 创建蓄力特效节点（默认隐藏）
	_init_charge_fx()

	# 通知初始血量
	EventBus.dispatch("target_hp_changed", { "hp": _health.hp, "max_hp": _health.max_hp })


func _process(delta: float) -> void:
	if _dead:
		return
	_mode_label.rotation = -rotation
	# WASD / 方向键移动
	_process_movement(delta)
	# HP 回复（元进度）
	_process_hp_regen(delta)
	# 更新护盾光环
	_update_shield_ring(delta)
	# 手动模式蓄力输入
	_process_charge_input()
	# 更新蓄力动效
	_update_charge_fx(delta)

## =========== HP 回复 ===========

var _regen_timer: float = 0.0

func _process_hp_regen(delta: float) -> void:
	var regen: float = _stats.get_hp_regen()
	if regen <= 0.0:
		return
	_regen_timer += delta
	if _regen_timer >= 1.0:
		_regen_timer = 0.0
		_health.heal(int(regen))


## ============ 玩家移动 ============

var _move_speed: float = 200.0  ## 由 PlayerStats 驱动

func _process_movement(_delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_S):
		input_dir.y += 1.0
	if Input.is_action_pressed("move_up") or Input.is_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if input_dir.length_squared() > 0.0:
		input_dir = input_dir.normalized()
	_move_speed = 200.0 + _stats.get_move_speed()
	velocity = input_dir * _move_speed
	move_and_slide()
	# 限制在方框内
	global_position = ArenaBounds.clamp_position(global_position)


## ============ 蓄力输入 ============

func _process_charge_input() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if not _shooting._is_charging:
			_shooting.start_charge()
	else:
		if _shooting._is_charging:
			_shooting.release_charge()


## ============ 蓄力高级动效 ============

func _init_charge_fx() -> void:
	# 外圈发光环
	_charge_glow = ColorRect.new()
	_charge_glow.name = "ChargeGlow"
	_charge_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_charge_glow.z_index = 4
	_charge_glow.color = Color(0.3, 0.8, 1.0, 0.0)
	_charge_glow.visible = false
	add_child(_charge_glow)
	# 内圈进度环
	_charge_ring = ColorRect.new()
	_charge_ring.name = "ChargeRing"
	_charge_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_charge_ring.z_index = 4
	_charge_ring.color = Color(0.0, 0.9, 1.0, 0.4)
	_charge_ring.visible = false
	add_child(_charge_ring)
	# 轨道粒子（6个绕行光点）
	for i in range(6):
		var p := ColorRect.new()
		p.name = "ChargeParticle%d" % i
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.z_index = 4
		p.size = Vector2(4, 4)
		p.color = Color(0.3, 0.9, 1.0, 0.0)
		p.visible = false
		add_child(p)
		_charge_particles.append(p)


func _update_charge_fx(delta: float) -> void:
	var charging: bool = _shooting._is_charging
	var progress: float = _shooting.get_charge_progress()  # 0~1 普通, 1~2 重蓄力

	_charge_ring.visible = charging
	_charge_glow.visible = charging

	if not charging:
		for p in _charge_particles:
			p.visible = false
		return

	# 颜色阶段：0-1 青→橙, 1-2 橙→红
	var color: Color
	var glow_color: Color
	if progress <= 1.0:
		color = Color(0.0, 0.9, 1.0).lerp(Color(1.0, 0.7, 0.2), progress)
		glow_color = Color(0.1, 0.4, 0.8, 0.15).lerp(Color(0.5, 0.3, 0.1, 0.3), progress)
	else:
		var t: float = (progress - 1.0)
		color = Color(1.0, 0.7, 0.2).lerp(Color(1.0, 0.2, 0.1), t)
		glow_color = Color(0.5, 0.3, 0.1, 0.3).lerp(Color(0.8, 0.1, 0.0, 0.5), t)

	# 进度环：从中心扩展
	var ring_size: float = 20.0 + progress * 25.0
	_charge_ring.color = Color(color.r, color.g, color.b, 0.3 + progress * 0.2)
	_charge_ring.position = Vector2(-ring_size / 2.0, -ring_size / 2.0)
	_charge_ring.size = Vector2(ring_size, ring_size)

	# 发光外圈
	var glow_size: float = ring_size + 12.0
	_charge_glow.color = glow_color
	_charge_glow.position = Vector2(-glow_size / 2.0, -glow_size / 2.0)
	_charge_glow.size = Vector2(glow_size, glow_size)

	# 轨道粒子：绕目标旋转
	var time := Time.get_ticks_msec() / 1000.0
	var orbit_r: float = ring_size * 0.6
	for i in range(_charge_particles.size()):
		var p := _charge_particles[i]
		p.visible = true
		p.color = Color(color.r, color.g, color.b, 0.6 + 0.3 * sin(time * 3.0 + i))
		p.size = Vector2(3 + progress * 2, 3 + progress * 2)
		var angle: float = time * (2.5 + progress * 1.5) + i * (TAU / _charge_particles.size())
		var px: float = cos(angle) * orbit_r
		var py: float = sin(angle) * orbit_r
		p.position = Vector2(px - p.size.x / 2.0, py - p.size.y / 2.0)


## ============ 受击 ============

var total_damage_taken: int = 0  ## 挑战模式追踪

func take_damage(amount: int, attacker: Node = null) -> void:
	if _dead:
		return
	# 护盾：免疫所有伤害
	if SkillManager.is_active("shield"):
		_flash_shield()
		return
	# 主动防御：80%减伤 + 75%反伤
	if SkillManager.is_active("reflect"):
		var reflected := int(amount * 0.75)
		var reduced := int(amount * 0.2)
		if attacker and is_instance_valid(attacker) and attacker.has_method("take_damage"):
			attacker.take_damage(reflected)
		var actual := _stats.calc_damage_taken(reduced)
		total_damage_taken += actual
		_health.take_damage(actual)
		_flash_reflect()
		return
	# 普通受击
	var actual := _stats.calc_damage_taken(amount)
	total_damage_taken += actual
	_health.take_damage(actual)
	var tw := create_tween()
	_body.color = Color.RED
	tw.tween_property(_body, "color", Color(0.2, 0.6, 1.0), 0.2).set_ease(Tween.EASE_IN_OUT)


## ============ 回调 ============

func _on_health_changed(current: int, maximum: int) -> void:
	EventBus.dispatch("target_hp_changed", { "hp": current, "max_hp": maximum })


func _on_died() -> void:
	_dead = true
	_shooting.set_physics_process(false)
	EventBus.dispatch("game_over")


func _on_player_heal(data: Variant) -> void:
	if _dead:
		return
	var amount: int = int(data) if data is float or data is int else 0
	if amount > 0:
		_health.heal(amount)


func _on_player_revive(_data: Variant = null) -> void:
	_dead = false
	_health.set_hp(int(_health.max_hp * 0.5))
	_shooting.set_physics_process(true)
	# 复活闪光
	_spawn_burst(Color(0.2, 1.0, 0.5), 1.5, 0.5)
	var tw := create_tween()
	_body.color = Color(0.2, 1.0, 0.5)
	tw.tween_property(_body, "color", Color(0.2, 0.6, 1.0), 0.5)


## 属性变化 → 同步血量上限 & 射速 & 移速 & 强制刷新血条
func _on_stats_changed() -> void:
	var new_max := _stats.get_max_hp()
	_health.set_max_hp(new_max)
	_shooting.fire_rate = _stats.get_fire_rate()
	_move_speed = 200.0 + _stats.get_move_speed()
	# 强制推送血条事件（确保UI立即更新）
	EventBus.dispatch("target_hp_changed", { "hp": _health.hp, "max_hp": _health.max_hp })


## ============ 技能特效 ============

## 技能激活回调
func _on_skill_activated(skill_id: String) -> void:
	match skill_id:
		"shield":
			# 护盾光环由 _update_shield_ring 处理
			pass
		"reflect":
			_flash_reflect()
		"repair":
			var new_hp := int(_health.max_hp * 0.9)
			_health.set_hp(new_hp)
			var buff: EffectData = EffectManager.get_effect_by_id("emergency_buff")
			if buff:
				EffectManager.add_effect(buff, 10.0)
			_spawn_burst(Color.GOLD, 1.2, 0.5)
		"missile":
			_spawn_burst(Color.ORANGE_RED, 2.0, 0.3)
			var enemies := get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e) and e.has_method("_on_died"):
					e._on_died()  # enemy._on_died 会自行 queue_free
		"head_oil":
			_spawn_burst(Color.YELLOW_GREEN, 0.8, 0.3)
			var enemies := get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if not is_instance_valid(e):
					continue
				var dist := global_position.distance_to(e.global_position)
				if dist < 200.0 and e.has_node("MoveComponent"):
					var move: MoveComponent = e.get_node("MoveComponent")
					var dir: Vector2 = (e.global_position - global_position).normalized()
					move.apply_knockback(dir * 400.0)
					move.apply_slow(0.85, 5.0)
		"double_shot":
			_spawn_burst(Color(0.3, 0.9, 1.0), 0.6, 0.2)
		"magnet":
			_spawn_burst(Color(0.5, 0.3, 0.9), 0.8, 0.3)


## 护盾/反伤光环更新
func _update_shield_ring(delta: float) -> void:
	var shield_active := SkillManager.is_active("shield")
	var reflect_active := SkillManager.is_active("reflect")

	if shield_active or reflect_active:
		_shield_ring.visible = true
		_fx_timer += delta * 4.0
		var pulse := 0.5 + 0.5 * sin(_fx_timer)
		var base_size := 52.0
		var size := base_size + pulse * 6.0
		_shield_ring.position = Vector2(-size / 2.0, -size / 2.0)
		_shield_ring.size = Vector2(size, size)
		if shield_active:
			_shield_ring.color = Color(0.0, 0.9, 1.0, 0.25 + pulse * 0.15)
		else:
			_shield_ring.color = Color(0.6, 0.2, 0.9, 0.25 + pulse * 0.15)
	else:
		_shield_ring.visible = false
		_fx_timer = 0.0


## 护盾受击闪烁
func _flash_shield() -> void:
	var tw := create_tween()
	_body.color = Color.CYAN
	tw.tween_property(_body, "color", Color(0.2, 0.6, 1.0), 0.3)


## 反伤闪烁
func _flash_reflect() -> void:
	var tw := create_tween()
	_body.color = Color.MEDIUM_PURPLE
	tw.tween_property(_body, "color", Color(0.2, 0.6, 1.0), 0.3)


## 爆发光圈特效
func _spawn_burst(color: Color, max_radius: float, duration: float) -> void:
	var circle := ColorRect.new()
	circle.name = "BurstFX"
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.z_index = 10
	circle.color = color
	circle.position = Vector2(-2, -2)
	circle.size = Vector2(4, 4)
	add_child(circle)
	var tw := create_tween()
	tw.tween_property(circle, "size", Vector2(max_radius * 2, max_radius * 2), duration)
	tw.parallel().tween_property(circle, "position", Vector2(-max_radius, -max_radius), duration)
	tw.parallel().tween_property(circle, "color:a", 0.0, duration)
	tw.tween_callback(circle.queue_free)


## 切换瞄准模式
func _unhandled_input(event: InputEvent) -> void:
	if _dead:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_SHIFT:
		_shooting.aim_mode = ShootingComponent.AimMode.MOUSE if _shooting.aim_mode == ShootingComponent.AimMode.AUTO else ShootingComponent.AimMode.AUTO
		_mode_label.text = "AUTO" if _shooting.aim_mode == ShootingComponent.AimMode.AUTO else "MOUSE"
		_mode_label.rotation = -rotation
		_show_mode_tip()


func _show_mode_tip() -> void:
	var text := "自动瞄准 (手动射击)" if _shooting.aim_mode == ShootingComponent.AimMode.AUTO else "手动瞄准 (手动射击)"
	var color := Color(0.8, 0.8, 0.8) if _shooting.aim_mode == ShootingComponent.AimMode.AUTO else Color(0.3, 0.9, 1.0)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 50
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	var world := get_parent()
	world.add_child(label)
	label.global_position = global_position + Vector2(-40, -70)
	var tw := world.create_tween()
	tw.tween_property(label, "global_position:y", label.global_position.y - 30.0, 1.5)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 1.5).set_delay(0.5)
	tw.tween_callback(label.queue_free)
