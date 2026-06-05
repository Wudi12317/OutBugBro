## 怪物基类 — 支持 .tscn 复用已有视觉节点，或程序化构建
## 子类覆写 _visual_params() 自定义外观
## 精英怪: HP×3, 体型1.5倍, 金色边框, 保证稀有以上掉落
class_name Enemy
extends CharacterBody2D

signal died(enemy: Enemy)

@export var drop_table: DropTable

var level: int = 1
var wave_config: WaveConfig
var is_elite: bool = false

var _health: HealthComponent
var _move: MoveComponent
var _attack: AttackComponent
var _body: Sprite2D
var _hp_bar: ProgressBar
var _level_label: Label


## 子类覆写：返回 { collision_r, body_scale, body_modulate, label_color, hp_fill_color, label_text }
func _visual_params() -> Dictionary:
	return {
		"collision_r": 23.0,
		"body_scale": Vector2(0.17, 0.16),
		"body_modulate": Color(0.85, 0.15, 0.15),
		"label_color": Color(1, 0.85, 0.3),
		"hp_fill_color": Color(0.85, 0.15, 0.15),
	}


func _ready() -> void:
	add_to_group("enemies")
	if not wave_config:
		wave_config = load("res://data/wave_config.tres")
	if not drop_table:
		drop_table = _build_default_drop_table()
	# 导弹即死
	if SkillManager.is_active("missile"):
		_on_died()
		return
	# 构建视觉节点（.tscn 已有时复用，否则程序化创建）
	_setup_visual()
	# 计算属性
	var hp := wave_config.get_enemy_hp(level)
	var atk := wave_config.get_enemy_atk(level)
	var spd := wave_config.get_enemy_speed(level)
	var interval := wave_config.get_enemy_attack_interval(level)
	if _level_label:
		_level_label.text = "Lv.%d" % level
	# 精英增强
	if is_elite:
		hp = hp * 3
		scale = Vector2(1.5, 1.5)
		if _body:
			_body.modulate = Color(1.0, 0.85, 0.0)
		if _level_label:
			_level_label.text = "★Lv.%d" % level
	# 挂载组件
	_health = HealthComponent.new()
	_health.entity = self
	_health.max_hp = hp
	_health.name = "HealthComponent"
	add_child(_health)
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)

	_move = MoveComponent.new()
	_move.entity = self
	_move.move_speed = spd
	_move.stop_distance = 50.0
	_move.name = "MoveComponent"
	add_child(_move)

	_attack = AttackComponent.new()
	_attack.entity = self
	_attack.attack_damage = atk
	_attack.attack_rate = interval
	_attack.name = "AttackComponent"
	add_child(_attack)

	# 拖尾
	var trail := TrailComponent.new()
	trail.entity = self
	trail.name = "TrailComponent"
	trail.trail_color = Color(1.0, 0.25, 0.15, 0.7) if not is_elite else Color(1.0, 0.85, 0.0, 0.75)
	trail.trail_radius = 6.0 if not is_elite else 9.0
	trail.fade_time = 0.45
	trail.spawn_interval = 0.03
	add_child(trail)
	# 查找目标
	var targets := get_tree().get_nodes_in_group("targets")
	if targets.size() > 0:
		_move.target_node = targets[0]


## 初始化视觉节点：优先复用 .tscn 已有节点，否则程序化构建
func _setup_visual() -> void:
	if has_node("LevelLabel"):
		# .tscn 已提供视觉节点，直接引用
		_level_label = $LevelLabel
		_hp_bar = get_node_or_null("HpBar")
		_body = get_node_or_null("Body")
	else:
		_build_visual()


## 程序化创建视觉节点（LevelLabel + HpBar + Collision + Body）
func _build_visual() -> void:
	var p := _visual_params()
	# 等级标签
	_level_label = Label.new()
	_level_label.name = "LevelLabel"
	_level_label.offset_left = -16.0
	_level_label.offset_top = -42.0
	_level_label.offset_right = 16.0
	_level_label.offset_bottom = -28.0
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.add_theme_font_size_override("font_size", 10)
	_level_label.add_theme_color_override("font_color", p.label_color)
	add_child(_level_label)
	# 血条
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.25, 0.8)
	bg_style.set_corner_radius_all(0)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = p.hp_fill_color
	fill_style.set_corner_radius_all(0)
	_hp_bar = ProgressBar.new()
	_hp_bar.name = "HpBar"
	_hp_bar.unique_name_in_owner = true
	_hp_bar.offset_left = -16.0
	_hp_bar.offset_top = -26.0
	_hp_bar.offset_right = 16.0
	_hp_bar.offset_bottom = -18.0
	_hp_bar.value = 100.0
	_hp_bar.show_percentage = false
	_hp_bar.add_theme_stylebox_override("background", bg_style)
	_hp_bar.add_theme_stylebox_override("fill", fill_style)
	add_child(_hp_bar)
	# 碰撞
	var col_shape := CircleShape2D.new()
	col_shape.radius = p.collision_r
	var collision := CollisionShape2D.new()
	collision.name = "Collision"
	collision.position = Vector2(0, 3)
	collision.shape = col_shape
	add_child(collision)
	# 贴图
	_body = Sprite2D.new()
	_body.name = "Body"
	_body.position = Vector2(0, -1)
	_body.scale = p.body_scale
	_body.texture = load("res://assets/sprites/items/xwp.png")
	_body.modulate = p.body_modulate
	add_child(_body)
	collision_layer = 2


func _physics_process(_delta: float) -> void:
	if _move and _move.is_in_range and _move.target_node:
		_attack.try_attack(_move.target_node)
	# 限制在方框内
	global_position = ArenaBounds.clamp_position(global_position)


func take_damage(amount: int, _attacker: Node = null, is_crit: bool = false) -> void:
	_health.take_damage(amount)
	if _body:
		var tw := create_tween()
		_body.modulate = Color.WHITE
		tw.tween_property(_body, "modulate", Color(0.85, 0.15, 0.15), 0.15).set_ease(Tween.EASE_IN_OUT)
	_show_damage_number(amount, is_crit)


func _on_health_changed(current: int, maximum: int) -> void:
	if _hp_bar:
		_hp_bar.max_value = maximum
		_hp_bar.value = current


func _on_died() -> void:
	if has_meta("dead"):
		return
	set_meta("dead", true)
	died.emit(self)
	SaveManager.run_kills += 1
	ComboManager.on_kill()
	EventBus.dispatch("enemy_killed")
	var gold := int(wave_config.gold_per_level * level * MetaProgression.get_gold_mult_bonus())
	CurrencyManager.add(gold)
	var drop_chance := wave_config.get_drop_chance(level) + ComboManager.get_drop_bonus()
	var dropped_item: ItemData = null
	if is_elite:
		dropped_item = _drop_rare_item()
	elif randf() < drop_chance:
		dropped_item = _drop_random_item()
	DropIndicator.spawn(get_parent(), global_position, gold, dropped_item)
	_play_death_effect()


func _drop_random_item() -> ItemData:
	if not drop_table:
		return null
	var item_data := drop_table.roll()
	if item_data:
		InventoryManager.add_item(item_data)
	return item_data


func _drop_rare_item() -> ItemData:
	if not drop_table:
		return null
	var rare_items: Array[ItemData] = []
	var weights: Array[float] = []
	for entry in drop_table.entries:
		if entry.item and entry.item.rarity >= 2:
			rare_items.append(entry.item)
			weights.append(entry.weight)
	if rare_items.is_empty():
		return _drop_random_item()
	var total := 0.0
	for w in weights:
		total += w
	if total <= 0:
		return _drop_random_item()
	var roll := randf() * total
	var cumulative := 0.0
	for i in range(rare_items.size()):
		cumulative += weights[i]
		if roll < cumulative:
			InventoryManager.add_item(rare_items[i])
			return rare_items[i]
	InventoryManager.add_item(rare_items[-1])
	return rare_items[-1]


func _build_default_drop_table() -> DropTable:
	var table := DropTable.new()
	var items_and_weights: Array[Dictionary] = [
		{ "path": "res://data/items/iron_ore.tres", "weight": 35.0 },
		{ "path": "res://data/items/health_potion.tres", "weight": 40.0 },
		{ "path": "res://data/items/coin.tres", "weight": 30.0 },
		{ "path": "res://data/items/speed_potion.tres", "weight": 15.0 },
		{ "path": "res://data/items/power_potion.tres", "weight": 8.0 },
		{ "path": "res://data/items/iron_wall_potion.tres", "weight": 6.0 },
		{ "path": "res://data/items/magic_shard.tres", "weight": 5.0 },
		{ "path": "res://data/items/lucky_charm.tres", "weight": 3.0 },
		{ "path": "res://data/items/dragon_heart.tres", "weight": 1.0 },
		{ "path": "res://data/items/phoenix_feather.tres", "weight": 2.0 },
		{ "path": "res://data/items/meteor_core.tres", "weight": 2.0 },
		{ "path": "res://data/items/castorice.tres", "weight": 0.5 },
	]
	for iw in items_and_weights:
		var item: ItemData = load(iw.path)
		if not item:
			continue
		var entry := DropEntry.new()
		entry.item = item
		entry.weight = iw.weight
		table.entries.append(entry)
	return table


## 浮动伤害数字
var _dmg_labels: Array[Label] = []
static var _label_pool: Array[Label] = []
const _LABEL_POOL_MAX := 20

func _show_damage_number(amount: int, is_crit: bool) -> void:
	_dmg_labels = _dmg_labels.filter(func(l): return is_instance_valid(l))
	if _dmg_labels.size() >= 3:
		var old: Label = _dmg_labels.pop_front()
		if is_instance_valid(old):
			_recycle_label(old)
	var label: Label = _get_label()
	label.text = str(amount) + ("!" if is_crit else "")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 20
	label.modulate.a = 1.0
	if is_crit:
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color.WHITE)
	var world := get_parent()
	var spawn_pos := global_position + Vector2(randf_range(-16, 16), -30.0)
	world.add_child(label)
	label.global_position = spawn_pos
	_dmg_labels.append(label)
	var tw := world.create_tween()
	tw.tween_property(label, "global_position:y", spawn_pos.y - 30.0, 0.8)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.3)
	tw.tween_callback(func(): _recycle_label(label))


static func _get_label() -> Label:
	while not _label_pool.is_empty():
		var l = _label_pool.pop_back()
		if is_instance_valid(l):
			var old_parent = l.get_parent()
			if old_parent and is_instance_valid(old_parent):
				old_parent.remove_child(l)
			return l
	return Label.new()


static func _recycle_label(label: Label) -> void:
	if not is_instance_valid(label):
		return
	var p = label.get_parent()
	if p and is_instance_valid(p):
		p.remove_child(label)
	if _label_pool.size() < _LABEL_POOL_MAX:
		_label_pool.append(label)
	else:
		label.free()


## 死亡动效
func _play_death_effect() -> void:
	for child in get_children():
		if child is AttackComponent or child is MoveComponent or child is TrailComponent:
			child.set_physics_process(false)
			child.set_process(false)
	if has_node("Collision"):
		$Collision.set_deferred("disabled", true)
	remove_from_group("enemies")
	var world := get_parent()
	var base_color := Color(0.85, 0.15, 0.15) if not is_elite else Color(1.0, 0.85, 0.0)
	var fragment_count := 3 + (randi() % 3)
	for i in range(fragment_count):
		var frag := ColorRect.new()
		var s := randf_range(3.0, 7.0)
		frag.size = Vector2(s, s)
		frag.color = base_color
		frag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frag.z_index = 10
		world.add_child(frag)
		frag.global_position = global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		var tw := world.create_tween()
		var dir := Vector2(randf_range(-80, 80), randf_range(-100, -20))
		tw.tween_property(frag, "global_position", frag.global_position + dir, 0.4).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(frag, "modulate:a", 0.0, 0.4)
		tw.tween_callback(frag.queue_free)
	var tw := create_tween()
	tw.tween_property(self, "scale", scale * 0.3, 0.35).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.35)
	tw.tween_callback(queue_free)
