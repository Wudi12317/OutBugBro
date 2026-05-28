## 效果管理器 — 管理角色身上激活的效果 + 效果注册表
extends Node

signal changed  ## 效果变化时触发

## 激活效果列表: [{ effect: EffectData, remaining: float }]
## remaining < 0 表示永久效果
var _active: Array[Dictionary] = []

## 效果注册表: { id: EffectData }，启动时扫描 data/effects/ 加载所有效果
var _registry: Dictionary = {}


func _ready() -> void:
	_scan_effects()


## 加载效果资源，建立 id → EffectData 映射（从 DataRegistry 读取路径，导出安全）
func _scan_effects() -> void:
	var registry: DataRegistry = load("res://data/data_registry.tres")
	var paths: Array = registry.effect_paths if registry else []
	if paths.is_empty():
		push_warning("[EffectManager] DataRegistry 为空，无效果加载")
	for path in paths:
		var res: Resource = load(path)
		if res is EffectData and res.id != "":
			_registry[res.id] = res
	push_warning("[EffectManager] 已加载 %d/%d 个效果" % [_registry.size(), paths.size()])


## 通过 ID 获取效果数据
func get_effect_by_id(id: String) -> EffectData:
	return _registry.get(id, null)


## 添加效果（同 id 刷新时长，不叠加）
func add_effect(effect: EffectData, duration: float = -1.0) -> void:
	if not effect:
		return
	# 同 id 已有则刷新时长
	for entry in _active:
		if entry.effect.id == effect.id:
			entry.remaining = duration
			changed.emit()
			return
	_active.append({ effect = effect, remaining = duration })
	changed.emit()


## 移除效果
func remove_effect(id: String) -> void:
	for i in range(_active.size()):
		if _active[i].effect.id == id:
			_active.remove_at(i)
			changed.emit()
			return


## 是否拥有某效果
func has_effect(id: String) -> bool:
	for entry in _active:
		if entry.effect.id == id:
			return true
	return false


## 获取所有激活效果（只读副本）
func get_active() -> Array[Dictionary]:
	return _active.duplicate()


## 清空所有效果
func clear_all() -> void:
	_active.clear()
	changed.emit()


## 倒计时（永久效果 remaining < 0 不减）
func _process(delta: float) -> void:
	var dirty := false
	for i in range(_active.size() - 1, -1, -1):
		var r: float = _active[i].remaining
		if r >= 0:
			_active[i].remaining = r - delta
			if _active[i].remaining <= 0:
				_active.remove_at(i)
				dirty = true
	if dirty:
		changed.emit()
