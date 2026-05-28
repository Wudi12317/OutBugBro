## 数据注册表 — 集中管理所有数据资源路径
## 添加新物品/效果/技能只需在 data_registry.tres 中添加路径，无需改代码
class_name DataRegistry
extends Resource

@export var item_paths: Array[String] = []
@export var effect_paths: Array[String] = []
@export var skill_paths: Array[String] = []
