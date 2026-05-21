## Boss — 压迫感出场 + 3种技能 + 闪避 + 粒子光环
class_name Boss
extends Enemy

const SKILL_SEQUENCE: Array[int] = [1, 2, 0, 2, 1, 0, 3, 0]
const SKILL_INTERVAL: float = 5.0
const ULTIMATE_WARN_TIME: float = 2.0
const DODGE_CHANCE: float = 0.02
const SHOOT_CHANCE: float = 0.35
## 濒死阈值：血量低于此比例触发
const ENRAGE_HP_RATIO: float = 0.08

var _skill_index: int = 0
var _skill_timer: float = 2.0
var _move_timer: float = 0.0
var _move_target: Vector2 = Vector2.ZERO
var _shoot_timer: float = 0.0
var _shoot_interval: float = 1.2
var _ultimate_active: bool = false
var _vulnerable: bool = false
var _particles: Array[ColorRect] = []
var _particle_time: float = 0.0
## 濒死相关
var _enrage_triggered: bool = false  ## 是否已触发濒死大招
var _death_locked: bool = false       ## 血量锁死中（等大招释放后才死亡）
static var _has_shown_tip: bool = false


func _visual_params() -> Dictionary:
	return {
		"collision_r": 35.0,
		"body_scale": Vector2(0.3, 0.28),
		"body_modulate": Color(0.9, 0.1, 0.1),
		"label_color": Color(1, 0.3, 0.3),
		"hp_fill_color": Color(0.85, 0.1, 0.1),
	}


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	if not wave_config:
		wave_config = preload("res://data/wave_config.tres")
	if not drop_table:
		drop_table = _build_default_drop_table()
	_build_visual()
	# Boss HP（进一步加强：×50）
	var hp := int(wave_config.get_enemy_hp(level) * 35.0)
	if is_elite:
		hp = hp * 3
	var _atk := wave_config.get_enemy_atk(level) * 3
	if _level_label:
		_level_label.text = "★大虫 Lv.%d" % level
	# 血量组件
	_health = HealthComponent.new()
	_health.entity = self
	_health.max_hp = hp
	_health.name = "HealthComponent"
	add_child(_health)
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	_move = null
	_attack = null
	# 拖尾
	var trail := TrailComponent.new()
	trail.entity = self
	trail.name = "TrailComponent"
	trail.trail_color = Color(1.0, 0.15, 0.15, 0.4)
	trail.trail_radius = 10.0
	trail.fade_time = 0.4
	add_child(trail)
	# 粒子光环
	_init_particles()
	# 出场：清小怪 + 屏幕震动 + 闪红
	_spawn_entrance()


func _physics_process(delta: float) -> void:
	_skill_timer -= delta
	_move_timer -= delta
	if _move_timer <= 0:
		_pick_move_target()
	var dir := (_move_target - global_position).normalized()
	velocity = dir * 100.0
	move_and_slide()
	_shoot_timer -= delta
	if _shoot_timer <= 0:
		_try_shoot()
		_shoot_timer = _shoot_interval
	if _skill_timer <= 0 and not _ultimate_active:
		_execute_next_skill()
	_update_particles(delta)


## ============ 出场效果 ============

func _spawn_entrance() -> void:
	# 清除场上所有小怪
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e == self:
			continue
		if is_instance_valid(e) and not e.is_in_group("bosses"):
			if e.has_method("_play_death_effect"):
				e._play_death_effect()
			e.queue_free()
	# 屏幕震动
	_screen_shake(12.0, 0.8)
	# 全屏闪红
	_flash_screen(Color(1, 0, 0, 0.3), 0.6)
	# 出场文字
	_show_boss_text("⚠ 大虫降临!", 28, Color.RED)
	EventBus.dispatch("boss_spawned", { "hp": _health.hp, "max_hp": _health.max_hp })
	# 首次提示手动模式
	if not _has_shown_tip:
		_has_shown_tip = true
		_show_manual_mode_tip()
	# 暂停1.5秒（压迫感）
	var tree := get_tree()
	tree.paused = true
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(1.5)
	tw.tween_callback(func(): tree.paused = false)


## ============ 粒子光环 ============

func _init_particles() -> void:
	for i in range(8):
		var p := ColorRect.new()
		p.name = "BossParticle%d" % i
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.z_index = 6
		p.size = Vector2(5, 5)
		p.color = Color(1.0, 0.2, 0.2, 0.6)
		add_child(p)
		_particles.append(p)


func _update_particles(delta: float) -> void:
	_particle_time += delta
	var orbit_r := 40.0
	for i in range(_particles.size()):
		var p := _particles[i]
		var angle: float = _particle_time * 2.0 + i * (TAU / _particles.size())
		var px: float = cos(angle) * orbit_r
		var py: float = sin(angle) * orbit_r
		p.position = Vector2(px - p.size.x / 2.0, py - p.size.y / 2.0)
		p.color = Color(1.0, 0.15 + 0.1 * sin(_particle_time * 3.0 + i), 0.1, 0.5 + 0.3 * sin(_particle_time * 4.0 + i))


## ============ 移动 ============

func _pick_move_target() -> void:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return
	var rect := cam.get_viewport_rect()
	var cam_pos: Vector2 = cam.global_position
	var half := rect.size / 2.0
	var margin := 80.0
	_move_target = Vector2(
		cam_pos.x + randf_range(-half.x + margin, half.x - margin),
		cam_pos.y + randf_range(-half.y + margin, half.y - margin)
	)
	_move_timer = randf_range(2.0, 4.0)


## ============ 射击 ============

func _try_shoot() -> void:
	if randf() > SHOOT_CHANCE:
		return
	var targets := get_tree().get_nodes_in_group("targets")
	if targets.is_empty():
		return
	var target: Node2D = targets[0]
	var dir := (target.global_position - global_position).normalized()
	# 三发散射
	for offset in [-0.15, 0.0, 0.15]:
		var bdir := dir.rotated(offset)
		var bullet := EnemyBullet.create(global_position, bdir, wave_config.get_enemy_atk(level) * 3)
		get_parent().add_child(bullet)


## ============ 技能 ============

func _execute_next_skill() -> void:
	var skill_id: int = SKILL_SEQUENCE[_skill_index % SKILL_SEQUENCE.size()]
	_skill_index += 1
	_skill_timer = SKILL_INTERVAL
	match skill_id:
		1: _cast_debuff()
		2: _cast_summon()
		3: _cast_ultimate()


func _cast_debuff() -> void:
	var debuff := EffectData.new()
	debuff.id = "boss_debuff"
	debuff.damage_change = -40.0
	debuff.crit_rate_change = -0.25
	debuff.move_speed_change = -30.0
	EffectManager.add_effect(debuff, 10.0)
	_flash_body(Color.DARK_RED)
	_show_boss_text("⚠ DEBUFF!", 20, Color.RED)
	_screen_shake(4.0, 0.3)


func _cast_summon() -> void:
	var count := 3 + (randi() % 2)
	for i in range(count):
		var enemy: CharacterBody2D = FastEnemy.new() if randf() < 0.4 else RangedEnemy.new()
		enemy.global_position = global_position + Vector2(randf_range(-80, 80), randf_range(-80, 80))
		enemy.level = level
		enemy.wave_config = wave_config
		get_parent().add_child(enemy)
	_show_boss_text("⚔ 召唤!", 20, Color(1, 0.5, 0.5))


func _cast_ultimate() -> void:
	_ultimate_active = true
	_show_boss_text("💀 大招蓄力中...", 24, Color.RED)
	# 蓄力时身体持续闪烁
	var warn_tw := create_tween()
	for i in range(6):
		warn_tw.tween_callback(func(): _flash_body(Color.RED))
		warn_tw.tween_interval(0.4)
	warn_tw.tween_callback(_release_ultimate)


func _release_ultimate() -> void:
	_ultimate_active = false
	var targets := get_tree().get_nodes_in_group("targets")
	for t in targets:
		if is_instance_valid(t) and t.has_method("take_damage"):
			t.take_damage(wave_config.get_enemy_atk(level) * 12)
	var debuff := EffectData.new()
	debuff.id = "boss_ult_debuff"
	debuff.damage_change = -60.0
	debuff.crit_rate_change = -0.35
	debuff.defense_change = -15.0
	debuff.move_speed_change = -40.0
	EffectManager.add_effect(debuff, 12.0)
	_vulnerable = true
	get_tree().create_timer(8.0).timeout.connect(func(): _vulnerable = false)
	_screen_shake(12.0, 0.6)
	_flash_screen(Color(1, 0, 0, 0.4), 0.8)
	_show_boss_text("💥 大招!", 28, Color(1, 0.2, 0.2))


## ============ 受击 ============

func take_damage(amount: int, _attacker: Node = null, is_crit: bool = false) -> void:
	if randf() < DODGE_CHANCE:
		_show_dodge()
		return
	var final_amount := amount
	if _vulnerable:
		final_amount = int(amount * 1.5)
	## 濒死锁血：锁定期间血量不低于 1%
	if _death_locked:
		var min_hp := maxi(1, int(_health.max_hp * 0.01))
		if _health.hp - final_amount <= min_hp:
			final_amount = maxi(0, _health.hp - min_hp)
	_health.take_damage(final_amount)
	if _body:
		var tw := create_tween()
		_body.modulate = Color.WHITE
		tw.tween_property(_body, "modulate", Color(0.9, 0.1, 0.1), 0.15).set_ease(Tween.EASE_IN_OUT)
	_show_damage_number(final_amount, is_crit)


## ============ 濒死触发 ============

func _trigger_enrage() -> void:
	_enrage_triggered = true
	_death_locked = true
	## 锁血到 1%
	var lock_hp := maxi(1, int(_health.max_hp * 0.01))
	_health.set_hp(lock_hp)
	EventBus.dispatch("boss_hp_changed", { "hp": lock_hp, "max_hp": _health.max_hp })
	## 全屏警告
	_flash_screen(Color(1, 0, 0, 0.5), 0.8)
	_screen_shake(18.0, 0.8)
	_show_boss_text("💀 大虫已黑化!!!", 32, Color.RED)
	## 强制释放终极大招，大招结束后解锁死亡
	_skill_timer = 0.0
	_ultimate_active = false
	_force_ultimate_then_die()


func _force_ultimate_then_die() -> void:
	_ultimate_active = true
	_show_boss_text("☠ RAGE - 大招蓄力...", 26, Color(1.0, 0.4, 0.1))
	## 身体加速闪烁
	var warn_tw := create_tween()
	for i in range(10):
		warn_tw.tween_callback(func(): _flash_body(Color.RED))
		warn_tw.tween_interval(0.25)
	## 释放强化版大招
	warn_tw.tween_callback(_release_rage_ultimate)


func _release_rage_ultimate() -> void:
	_ultimate_active = false
	## 超强终极大招
	var targets := get_tree().get_nodes_in_group("targets")
	for t in targets:
		if is_instance_valid(t) and t.has_method("take_damage"):
			t.take_damage(wave_config.get_enemy_atk(level) * 20)
	var debuff := EffectData.new()
	debuff.id = "boss_rage_debuff"
	debuff.damage_mult_change = -0.5
	debuff.crit_rate_change = -0.3
	debuff.defense_change = -10.0
	debuff.move_speed_change = -30.0
	EffectManager.add_effect(debuff, 15.0)
	_screen_shake(20.0, 1.0)
	_flash_screen(Color(1, 0.2, 0, 0.6), 1.0)
	_show_boss_text("💀 RAGE ULTIMATE!", 32, Color(1, 0.1, 0.1))
	## 大招后解锁死亡，执行真正死亡
	_death_locked = false
	get_tree().create_timer(1.5).timeout.connect(_real_death)


func _real_death() -> void:
	if has_meta("dead"):
		return
	_health.set_hp(0)


## ============ 闪避 ============

func _show_dodge() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1, 0.3), 0.1)
	tw.tween_property(self, "modulate", Color.WHITE, 0.15)
	_show_boss_text("闪避!", 18, Color(1, 1, 0.5))


## ============ 死亡 ============

func _on_died() -> void:
	if has_meta("dead"):
		return
	set_meta("dead", true)
	died.emit(self)
	EventBus.dispatch("boss_died")
	SaveManager.run_kills += 1
	ComboManager.on_kill()
	CurrencyManager.add(level * 500)
	_drop_boss_loot()
	_play_death_effect()


func _drop_boss_loot() -> void:
	var red_count := 1 + (randi() % 2)
	var gold_count := 3 + (randi() % 2)
	var loot_items: Array[ItemData] = []
	for i in range(red_count):
		loot_items.append(_create_red_item())
	for i in range(gold_count):
		loot_items.append(_create_gold_item())
	for item in loot_items:
		InventoryManager.add_item(item)
	DropIndicator.spawn(get_parent(), global_position, level * 500, loot_items[0])
	for i in range(1, loot_items.size()):
		var offset := Vector2(randf_range(-40, 40), randf_range(-40, 40))
		DropIndicator.spawn(get_parent(), global_position + offset, 0, loot_items[i])


func _create_red_item() -> ItemData:
	var roll := randi() % 3
	match roll:
		0:
			var item := MaterialItemData.new()
			item.id = "boss_heart"
			item.name = "大虫之心"
			item.icon = load("res://assets/sprites/items/meteor_core.svg")
			item.desc = "从大虫体内取出的核心，蕴含强大能量"
			item.rarity = 5
			item.value = 5000
			item.sources = ["Boss掉落"]
			return item
		1:
			var item := MaterialItemData.new()
			item.id = "boss_crystal"
			item.name = "虫哥水晶"
			item.icon = load("res://assets/sprites/items/chy.png")
			item.desc = "大虫身上析出的神秘晶体，散发不祥光辉"
			item.rarity = 5
			item.value = 8000
			item.sources = ["Boss掉落"]
			return item
		_:
			var item := ConsumableItemData.new()
			item.id = "boss_essence"
			item.name = "大虫精粹"
			item.icon = load("res://assets/icon_magnet.svg")
			item.desc = "浓缩的Boss精华，使用后获得超强增益"
			item.rarity = 5
			item.value = 10000
			item.effect_duration = 30.0
			item.effect_ids = ["boss_essence_effect"]
			return item


func _create_gold_item() -> ItemData:
	var paths: PackedStringArray = [
		"res://data/items/dragon_heart.tres",
		"res://data/items/phoenix_feather.tres",
		"res://data/items/meteor_core.tres",
	]
	var path: String = paths[randi() % paths.size()]
	var item: ItemData = load(path)
	return item


func _on_health_changed(current: int, maximum: int) -> void:
	EventBus.dispatch("boss_hp_changed", { "hp": current, "max_hp": maximum })
	## 濒死触发：低于阈值且未触发过
	if not _enrage_triggered and maximum > 0:
		var ratio: float = float(current) / float(maximum)
		if ratio <= ENRAGE_HP_RATIO:
			_trigger_enrage()


## ============ 视觉特效 ============

func _show_boss_text(text: String, font_size: int = 20, color: Color = Color.RED) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 30
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	var world := get_parent()
	world.add_child(label)
	label.global_position = global_position + Vector2(-60, -80)
	var tw := world.create_tween()
	tw.tween_property(label, "global_position:y", label.global_position.y - 50.0, 1.2)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 1.2).set_delay(0.5)
	tw.tween_callback(label.queue_free)


func _flash_body(color: Color) -> void:
	if not _body:
		return
	var tw := create_tween()
	_body.modulate = color
	tw.tween_property(_body, "modulate", Color(0.9, 0.1, 0.1), 0.3).set_ease(Tween.EASE_IN_OUT)


func _screen_shake(intensity: float, duration: float) -> void:
	var camera := get_tree().get_first_node_in_group("cameras")
	if not camera:
		camera = get_tree().root.find_child("Camera2D", true, false)
	if not camera:
		return
	var tw := camera.create_tween()
	var orig: Vector2 = camera.position
	var steps := int(duration / 0.05)
	for i in range(steps):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(camera, "position", orig + offset, 0.05)
	tw.tween_property(camera, "position", orig, 0.05)


func _flash_screen(color: Color, duration: float) -> void:
	var overlay := ColorRect.new()
	overlay.name = "ScreenFlash"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 100
	overlay.color = color
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var parent: Node = get_tree().root.find_child("UILayer", true, false)
	if not parent:
		parent = get_parent()
	parent.add_child(overlay)
	var tw := overlay.create_tween()
	tw.tween_property(overlay, "color:a", 0.0, duration)
	tw.tween_callback(overlay.queue_free)


func _show_manual_mode_tip() -> void:
	var label := Label.new()
	label.text = "💡 提示：按 Shift 切换为手动模式，可蓄力射击！"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 50
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
	var world := get_parent()
	world.add_child(label)
	label.global_position = Vector2(300, 100)
	var tw := world.create_tween()
	tw.tween_property(label, "modulate:a", 0.0, 5.0).set_delay(3.0)
	tw.tween_callback(label.queue_free)
