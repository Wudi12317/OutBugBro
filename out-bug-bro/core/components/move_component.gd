## 移动组件 — 向目标点或节点移动
## 支持击退（knockback）和减速（slow）
class_name MoveComponent
extends Component

@export var move_speed: float = 80.0    ## 移动速度
@export var stop_distance: float = 50.0 ## 到达此距离停止（需大于双方碰撞半径之和）

var target_node: Node2D = null  ## 追踪目标
var is_in_range: bool = false   ## 是否在攻击范围内

## 击退速度
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 300.0

## 减速
var slow_multiplier: float = 1.0   ## 1.0=正常, 0.85=减速15%
var slow_timer: float = 0.0


func _tick(delta: float) -> void:
	# 更新减速计时
	if slow_timer > 0:
		slow_timer -= delta
		if slow_timer <= 0:
			slow_multiplier = 1.0
	# 击退优先
	if knockback_velocity.length_squared() > 1.0:
		entity.velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
		entity.move_and_slide()
		return
	# 正常移动
	if not target_node or not is_instance_valid(target_node):
		return
	var pos: Vector2 = entity.global_position
	var target_pos: Vector2 = target_node.global_position
	var dist: float = pos.distance_to(target_pos)
	if dist <= stop_distance:
		entity.velocity = Vector2.ZERO
		is_in_range = true
	else:
		var direction: Vector2 = (target_pos - pos).normalized()
		entity.velocity = direction * move_speed * slow_multiplier
		is_in_range = false
	entity.move_and_slide()


## 施加击退
func apply_knockback(vel: Vector2) -> void:
	knockback_velocity = vel


## 施加减速
func apply_slow(mult: float, duration: float) -> void:
	slow_multiplier = mult
	slow_timer = duration
