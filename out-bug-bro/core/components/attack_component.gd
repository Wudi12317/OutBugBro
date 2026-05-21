## 攻击组件 — 定时对目标造成伤害
## 挂载到敌人等实体上，需配合 MoveComponent 使用
class_name AttackComponent
extends Component

@export var attack_damage: int = 10    ## 每次攻击伤害
@export var attack_rate: float = 1.0   ## 攻击间隔（秒）

var _attack_timer: float = 0.0


func _tick(delta: float) -> void:
	_attack_timer -= delta


## 尝试攻击，在冷却中则返回 false
## 攻击时将宿主（entity）作为攻击者传入，支持反伤等机制
func try_attack(target: Node) -> bool:
	if _attack_timer > 0:
		return false
	_attack_timer = attack_rate
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(attack_damage, entity)
		return true
	return false
