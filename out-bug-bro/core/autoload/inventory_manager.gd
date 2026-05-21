## 背包管理器 — 数据层，与 UI 解耦
extends Node

signal changed  ## 背包内容变化时触发
signal bindings_changed  ## 消耗品快捷栏绑定变化

## 背包数据：[{ data: ItemData, count: int }, ...]
var _items: Array[Dictionary] = []

## 消耗品快捷栏绑定：5个槽位，存 item_id 或 ""
var consumable_bindings: PackedStringArray = ["", "", "", "", ""]


## 添加物品（同类自动堆叠）
func add_item(data: ItemData, amount: int = 1) -> void:
	if not data:
		return
	# 查找已有同类物品
	for entry in _items:
		if entry.data.id == data.id:
			entry.count += amount
			changed.emit()
			return
	# 新物品
	_items.append({ data = data, count = amount })
	changed.emit()


## 移除物品（数量归零则删除条目）
func remove_item(data: ItemData, amount: int = 1) -> void:
	if not data:
		return
	for i in range(_items.size()):
		if _items[i].data.id == data.id:
			_items[i].count -= amount
			if _items[i].count <= 0:
				_items.remove_at(i)
			changed.emit()
			return


## 使用消耗品 — 解析 effect_ids，触发即时效果和持续增益
## 返回 true 表示使用成功
func use_item(data: ItemData) -> bool:
	if not data or not data is ConsumableItemData:
		return false
	var consumable: ConsumableItemData = data as ConsumableItemData
	if consumable.effect_ids.is_empty():
		return false
	# 解析每个效果
	for eff_id in consumable.effect_ids:
		var eff: EffectData = EffectManager.get_effect_by_id(eff_id)
		if not eff:
			continue
		# 即时回血
		if eff.heal_amount > 0:
			EventBus.dispatch("player_heal", eff.heal_amount)
		# 持续增益（有属性改变且非纯即时效果）
		var active := eff.get_active_effects()
		var has_buff := false
		for key in active:
			if key != "heal_amount":
				has_buff = true
				break
		if has_buff:
			EffectManager.add_effect(eff, consumable.effect_duration)
	# 消耗一个
	remove_item(data, 1)
	return true


## 获取所有物品（只读副本）
func get_items() -> Array[Dictionary]:
	return _items.duplicate()


## 获取物品总数
func get_item_count() -> int:
	return _items.size()


## 清空背包
func clear_all() -> void:
	_items.clear()
	changed.emit()


## ============ 消耗品快捷栏绑定 ============

## 设置快捷栏槽位绑定
func set_consumable_binding(slot_idx: int, item_id: String) -> void:
	if slot_idx < 0 or slot_idx >= consumable_bindings.size():
		return
	consumable_bindings[slot_idx] = item_id
	bindings_changed.emit()


## 获取快捷栏槽位绑定的物品（未绑定则按背包顺序自动填充）
func get_consumable_at_slot(slot_idx: int) -> ItemData:
	if slot_idx < 0 or slot_idx >= consumable_bindings.size():
		return null
	# 已绑定 → 直接返回
	var id := consumable_bindings[slot_idx]
	if id != "":
		for entry in _items:
			if entry.data.id == id:
				return entry.data
		return null  # 绑定了但背包里没有
	# 未绑定 → 按背包消耗品顺序填充
	var auto_list := _get_auto_consumables()
	if slot_idx < auto_list.size():
		return auto_list[slot_idx]
	return null


## 获取快捷栏槽位绑定的物品数量
func get_consumable_count_at_slot(slot_idx: int) -> int:
	var data := get_consumable_at_slot(slot_idx)
	if not data:
		return 0
	for entry in _items:
		if entry.data.id == data.id:
			return entry.count
	return 0


## 获取未绑定槽位的自动填充列表（背包消耗品顺序，排除已绑定的）
func _get_auto_consumables() -> Array[ItemData]:
	var bound_ids: PackedStringArray = []
	for b in consumable_bindings:
		if b != "":
			bound_ids.append(b)
	var result: Array[ItemData] = []
	for entry in _items:
		if entry.data is ConsumableItemData and entry.data.id not in bound_ids:
			result.append(entry.data)
	return result
