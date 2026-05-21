## 血量组件 — 管理生命值、受击、死亡
## 挂载到实体节点上，通过信号通知宿主
class_name HealthComponent
extends Component

signal health_changed(current: int, maximum: int)  ## 血量变化
signal died                                      ## 死亡

@export var max_hp: int = 100

var hp: int = 0


func _setup() -> void:
	hp = max_hp


## 设置最大血量，当前 HP 按差值平移（增加上限时也加血，减少上限时扣血）
func set_max_hp(new_max: int) -> void:
	if new_max == max_hp:
		return
	var diff := new_max - max_hp
	max_hp = new_max
	hp = clampi(hp + diff, 0, max_hp)
	health_changed.emit(hp, max_hp)


## 受击扣血
func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	health_changed.emit(hp, max_hp)
	if hp <= 0:
		died.emit()


## 治愈
func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)
	health_changed.emit(hp, max_hp)


## 直接设置 hp（用于修理等场景，会钳制）
func set_hp(new_hp: int) -> void:
	hp = clampi(new_hp, 0, max_hp)
	health_changed.emit(hp, max_hp)


## 血量比例 0~1
func get_ratio() -> float:
	return float(hp) / float(max_hp) if max_hp > 0 else 0.0
