## 掉落表 — 定义物品掉落池与权重，支持不同怪物使用不同掉落表
## 在编辑器中创建 .tres，挂载到 Enemy 子类或 WaveConfig
class_name DropTable
extends Resource

## 掉落条目：物品 + 权重
@export var entries: Array[DropEntry] = []


## 加权随机掉落，返回物品数据（可能为 null）
func roll() -> ItemData:
	if entries.is_empty():
		return null
	var total_weight := 0.0
	for e in entries:
		total_weight += e.weight
	if total_weight <= 0:
		return null
	var roll_val := randf() * total_weight
	var cumulative := 0.0
	for e in entries:
		cumulative += e.weight
		if roll_val < cumulative:
			return e.item
	return entries[-1].item


## 获取某物品的掉落概率（0.0~1.0）
func get_chance_for(item_id: String) -> float:
	var total_weight := 0.0
	var item_weight := 0.0
	for e in entries:
		total_weight += e.weight
		if e.item and e.item.id == item_id:
			item_weight += e.weight
	if total_weight <= 0:
		return 0.0
	return float(item_weight) / float(total_weight)


## 获取所有条目的概率信息，返回 [{id, name, weight, chance}]
func get_all_chances() -> Array[Dictionary]:
	var total_weight := 0.0
	for e in entries:
		total_weight += e.weight
	var result: Array[Dictionary] = []
	for e in entries:
		if e.item:
			result.append({
				"id": e.item.id,
				"name": e.item.name,
				"rarity": e.item.rarity,
				"weight": e.weight,
				"chance": float(e.weight) / float(total_weight) if total_weight > 0 else 0.0
			})
	return result
