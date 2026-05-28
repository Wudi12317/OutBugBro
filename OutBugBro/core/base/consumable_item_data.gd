## 消耗品 — 使用后触发效果（即时回血 + 持续增益）
class_name ConsumableItemData
extends ItemData

@export var effect_ids: PackedStringArray = []  ## 效果编号列表（对应 EffectData.id）
@export var effect_duration: float = 10.0       ## 增益效果持续时间（秒），即时效果忽略此值

func _init() -> void:
	type = ItemType.CONSUMABLE
