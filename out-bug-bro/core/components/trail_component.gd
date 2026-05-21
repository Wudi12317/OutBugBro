## 拖尾组件 — 轻量粒子拖尾（对象池复用 ColorRect，限制同时存在数量）
class_name TrailComponent
extends Component

@export var trail_color: Color = Color(1, 1, 1, 0.4)
@export var trail_radius: float = 3.0
@export var spawn_interval: float = 0.04
@export var fade_time: float = 0.25
@export var min_speed: float = 5.0

## 全局对象池
static var _pool: Array[ColorRect] = []
const POOL_MAX := 120

var _timer: float = 0.0
var _prev_pos: Vector2 = Vector2.ZERO
var _active_count: int = 0
const ACTIVE_MAX := 20  ## 每个组件同时最多活跃拖尾数


func _tick(delta: float) -> void:
	_timer += delta
	if _timer < spawn_interval:
		return
	_timer = 0.0
	# 速度检查
	var vel: Vector2 = entity.velocity if "velocity" in entity else _prev_pos - entity.global_position
	var speed := vel.length()
	_prev_pos = entity.global_position
	if speed < min_speed:
		return
	# 限制同时存在数量
	if _active_count >= ACTIVE_MAX:
		return
	_spawn_dot()


func _spawn_dot() -> void:
	var dot: ColorRect = _get_dot()
	if not dot:
		return
	var r := trail_radius
	dot.size = Vector2(r * 2, r * 2)
	dot.color = trail_color
	dot.modulate.a = 1.0
	entity.get_parent().add_child(dot)
	dot.global_position = entity.global_position - Vector2(r, r)
	_active_count += 1
	# 渐隐+回收
	var tw := dot.create_tween()
	tw.tween_property(dot, "modulate:a", 0.0, fade_time)
	tw.tween_callback(_recycle.bind(dot))


static func _get_dot() -> ColorRect:
	# 从池中取出
	while not _pool.is_empty():
		var dot: ColorRect = _pool.pop_back()
		if is_instance_valid(dot):
			return dot
	# 新建
	var dot := ColorRect.new()
	dot.name = "TrailDot"
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.z_index = -1
	return dot


func _recycle(dot: ColorRect) -> void:
	_active_count -= 1
	if not is_instance_valid(dot):
		return
	dot.get_parent().remove_child(dot)
	if _pool.size() < POOL_MAX:
		_pool.append(dot)
	else:
		dot.queue_free()
