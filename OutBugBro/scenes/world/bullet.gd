## 子弹 — 三角+长方形外形，细长拖尾
## 手动模式专属：穿透(多目标)/爆裂弹(溅射)/蓄力弹(高伤+大溅射)
extends Area2D

var damage: int = 25       ## 最终伤害（含暴击），由 ShootingComponent 设置
var is_crit: bool = false  ## 是否暴击
var is_charged: bool = false  ## 是否蓄力弹

var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var lifetime: float = 2.0
var _trail_timer: float = 0.0

## 穿透：可命中的目标数（0=命中即消失，1=普通，3=穿透3目标）
var pierce_count: int = 1
var _hit_count: int = 0
var _hit_bodies: Array[Node2D] = []  ## 已命中的目标，避免重复

## 爆裂弹：溅射范围和比例
var splash_damage_ratio: float = 0.0  ## 0=无溅射
var splash_radius: float = 0.0

## 拖尾对象池（复用 ColorRect，避免频繁 new/free）
static var _trail_pool: Array[ColorRect] = []
const _TRAIL_POOL_MAX := 80
const _TRAIL_INTERVAL := 0.03

## 子弹外形尺寸
var _bullet_len: float = 12.0   ## 弹体总长度
var _bullet_w: float = 3.0      ## 弹体宽度
var _bullet_color: Color = Color(1.0, 0.9, 0.2, 1.0)


func _ready() -> void:
	direction = Vector2.RIGHT.rotated(rotation)
	monitoring = false
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	call_deferred("set", "monitoring", true)
	# 蓄力弹更大更红
	if is_charged:
		_bullet_len = 18.0
		_bullet_w = 5.0
		_bullet_color = Color(1.0, 0.3, 0.1, 1.0)


func _draw() -> void:
	# 三角头部（朝右）
	var hw := _bullet_w * 0.5
	var tip := Vector2(_bullet_len * 0.5, 0.0)
	var tri := PackedVector2Array([
		tip,
		Vector2(-_bullet_len * 0.15, -hw),
		Vector2(-_bullet_len * 0.15, hw),
	])
	draw_colored_polygon(tri, _bullet_color)
	# 长方形身体
	var body_left := -_bullet_len * 0.5
	var body_right := -_bullet_len * 0.15
	draw_rect(Rect2(body_left, -hw * 0.6, body_right - body_left, hw * 1.2), _bullet_color)
	# 蓄力弹额外光晕
	if is_charged:
		draw_circle(Vector2.ZERO, _bullet_len * 0.4, Color(1.0, 0.2, 0.05, 0.15))


func _process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	# 拖尾（使用对象池）
	_trail_timer += delta
	if _trail_timer >= _TRAIL_INTERVAL:
		_trail_timer = 0.0
		_spawn_trail()


func _on_body_entered(body: Node2D) -> void:
	# 不是敌人 → 销毁
	if not body is Enemy:
		queue_free()
		return
	# 已命中过 → 跳过
	if body in _hit_bodies:
		return
	_hit_bodies.append(body)
	_hit_count += 1

	# 对目标造成伤害
	body.take_damage(damage, null, is_crit)

	# 爆裂弹溅射（meta 或 splash_damage_ratio）
	if has_meta("explosive") and get_meta("explosive"):
		splash_radius = get_meta("explosive_radius")
		splash_damage_ratio = get_meta("explosive_damage_mult")
	if splash_damage_ratio > 0.0 and splash_radius > 0.0:
		_do_splash(body)

	# 穿透判定
	if _hit_count >= pierce_count:
		queue_free()
	# 否则继续飞行（不销毁）


## 爆裂弹范围溅射
func _do_splash(hit_target: Node2D) -> void:
	var splash_dmg := int(damage * splash_damage_ratio)
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if not is_instance_valid(e) or e == hit_target or e in _hit_bodies:
			continue
		var dist: float = hit_target.global_position.distance_to(e.global_position)
		if dist <= splash_radius:
			var falloff := 1.0 - (dist / splash_radius) * 0.5
			e.take_damage(int(splash_dmg * falloff), null, false)
	_spawn_explosion(hit_target.global_position)


## 爆炸视觉特效
func _spawn_explosion(pos: Vector2) -> void:
	var effect := preload("res://scenes/world/explosion_effect.tscn").instantiate()
	effect.radius = splash_radius
	effect.color = Color(1.0, 0.6, 0.2, 0.5) if not is_charged else Color(1.0, 0.3, 0.1, 0.7)
	get_parent().add_child(effect)
	effect.global_position = pos


## 外部设置伤害倍率
func set_damage_mult(mult: float) -> void:
	damage = int(float(damage) * mult)
	if mult >= 3.0:
		is_charged = true


## 外部设置穿透数
func set_pierce(count: int) -> void:
	pierce_count = count


## 碰到敌人子弹 → 互相抵消（蓄力弹摧毁敌弹但自身不消失）
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_bullets"):
		area.queue_free()
		if not is_charged:
			queue_free()


## 拖尾粒子（对象池复用，细长条形）
func _spawn_trail() -> void:
	var world := get_parent()
	if not is_instance_valid(world):
		return
	var dot: ColorRect = _get_trail_dot()
	var tw: float = 10.0 if is_charged else 6.0  ## 拖尾长度
	var th: float = 2.0 if is_charged else 1.0    ## 拖尾宽度
	dot.size = Vector2(tw, th)
	dot.color = Color(1.0, 0.3, 0.05, 0.8) if is_charged else Color(1.0, 0.9, 0.3, 0.55)
	dot.modulate.a = 1.0
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.z_index = -1
	# 朝向与子弹方向一致
	dot.rotation = rotation
	world.add_child(dot)
	dot.global_position = global_position - Vector2(tw * 0.5, th * 0.5)
	# Tween 绑定到 world
	var t_len := 0.35 if is_charged else 0.22
	var tw2 := world.create_tween()
	tw2.tween_property(dot, "modulate:a", 0.0, t_len)
	tw2.parallel().tween_property(dot, "size", Vector2(0.5, 0.5), t_len)
	tw2.tween_callback(_recycle_trail_dot.bind(dot))


static func _get_trail_dot() -> ColorRect:
	while not _trail_pool.is_empty():
		var d: ColorRect = _trail_pool.pop_back()
		if is_instance_valid(d):
			var old_parent := d.get_parent()
			if old_parent and is_instance_valid(old_parent):
				old_parent.remove_child(d)
			return d
	return ColorRect.new()


static func _recycle_trail_dot(dot: ColorRect) -> void:
	if not is_instance_valid(dot):
		return
	var p := dot.get_parent()
	if p and is_instance_valid(p):
		p.remove_child(dot)
	if _trail_pool.size() < _TRAIL_POOL_MAX:
		_trail_pool.append(dot)
	else:
		dot.queue_free()
