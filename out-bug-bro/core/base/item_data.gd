## 物品基类 — 所有物品数据的父类
## 子类: ConsumableItemData / MaterialItemData / CollectibleItemData
class_name ItemData
extends Resource

enum ItemType { CONSUMABLE, MATERIAL, COLLECTIBLE }

@export var id: String = ""             ## 唯一标识符
@export var name: String = ""
@export var icon: Texture2D
@export var desc: String = ""
@export var rarity: int = 0          ## 品质等级 0=普通 1=精良 2=稀有 3=史诗 4=传说 5=神话
@export var value: int = 0           ## 出售价值
@export var type: ItemType = ItemType.CONSUMABLE

## 获取品质颜色
func get_rarity_color() -> Color:
	match rarity:
		0: return Color.WHITE
		1: return Color.GREEN
		2: return Color.CYAN
		3: return Color.MEDIUM_PURPLE
		4: return Color.GOLD
		5: return Color.CRIMSON
		_: return Color.WHITE
