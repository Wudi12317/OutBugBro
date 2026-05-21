## 连击管理器 [Autoload] — 2秒窗口内连续击杀累计连击
## 连击越高，掉率加成越大（combo × 5%）
extends Node

signal combo_changed(combo: int)  ## 连击数变化
signal combo_expired              ## 连击中断

const COMBO_WINDOW := 2.0   ## 连击窗口（秒）
const COMBO_BONUS := 0.05   ## 每级掉率加成

var combo: int = 0
var _timer: float = 0.0


func _process(delta: float) -> void:
	if combo <= 0:
		return
	_timer -= delta
	if _timer <= 0:
		_expire()


## 击杀时调用
func on_kill() -> void:
	combo += 1
	_timer = COMBO_WINDOW
	combo_changed.emit(combo)


## 获取当前连击掉率加成（0.0~0.5）
func get_drop_bonus() -> float:
	return minf(0.5, float(combo) * COMBO_BONUS)


## 连击中断
func _expire() -> void:
	var old := combo
	combo = 0
	_timer = 0.0
	if old > 0:
		combo_expired.emit()
