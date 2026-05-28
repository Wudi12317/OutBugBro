## 掉落条目 — 物品 + 权重，用于 DropTable
class_name DropEntry
extends Resource

@export var item: ItemData        ## 物品数据
@export var weight: float = 10.0   ## 权重（越大越容易掉落，支持小数）