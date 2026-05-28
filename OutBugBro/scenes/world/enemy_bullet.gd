## 敌人子弹 — 三角+长方形外形，碰到玩家扣血，碰到玩家子弹互相抵消
## 使用 enemy_bullet.tscn 场景，不再程序化创建碰撞体
class_name EnemyBullet
extends Area2D

var damage: int = 10
var direction: Vector2 = Vector2.RIGHT
var speed: float = 180.0
var lifetime: float = 4.0

## 场景引用（由 _ready 自动加载或外部注入）
static var _scene: PackedScene


## 工厂方法：创建一颗敌人子弹（优先用 .tscn 场景）
static func create(pos: Vector2, dir: Vector2, dmg: int = 10) -> EnemyBullet:
	if not _scene:
		_scene = load("res://scenes/world/enemy_bullet.tscn")
	var b: EnemyBullet
	if _scene:
		b = _scene.instantiate()
	else:
		# 回退：程序化创建
		b = EnemyBullet.new()
		b.collision_layer = 8
		b.collision_mask = 5
		var col := CircleShape2D.new()
		col.radius = 6.0
		var cs := CollisionShape2D.new()
		cs.shape = col
		b.add_child(cs)
	b.position = pos
	b.direction = dir
	b.damage = dmg
	b.rotation = dir.angle()
	b.add_to_group("enemy_bullets")
	return b


func _draw() -> void:
	# 红色三角+长方形
	var hw := 2.5
	var tip := Vector2(7.0, 0.0)
	var tri := PackedVector2Array([
		tip,
		Vector2(-2.0, -hw),
		Vector2(-2.0, hw),
	])
	draw_colored_polygon(tri, Color(1.0, 0.25, 0.2, 1.0))
	draw_rect(Rect2(-7.0, -hw * 0.6, 5.0, hw * 1.2), Color(1.0, 0.25, 0.2, 1.0))


func _ready() -> void:
	direction = Vector2.RIGHT.rotated(rotation)
	monitoring = false
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	call_deferred("set", "monitoring", true)


func _process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("targets") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
		return
	if not body.is_in_group("player_bullets"):
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_bullets"):
		queue_free()
