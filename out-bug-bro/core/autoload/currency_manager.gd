## 货币管理器 [Autoload]
## 全局货币（金币），售卖物品获得，购买消耗
extends Node

signal changed  ## 货币变化时触发

var currency: int = 0:
	set(v):
		currency = v
		changed.emit()


## 增加货币
func add(amount: int) -> void:
	if amount <= 0:
		return
	currency += amount


## 花费货币，成功返回 true
func spend(amount: int) -> bool:
	if amount <= 0 or currency < amount:
		return false
	currency -= amount
	return true


## 是否足够
func has_enough(amount: int) -> bool:
	return currency >= amount
