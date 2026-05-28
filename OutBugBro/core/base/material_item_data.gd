## 材料 — 记录获得途径
class_name MaterialItemData
extends ItemData

@export var sources: PackedStringArray = []  ## 获得途径列表

func _init() -> void:
	type = ItemType.MATERIAL
