## 玩家配置 — 外部可调 Resource，策划在编辑器中调整初始属性和升级曲线
## 挂载到 PlayerStats 或由 Target 加载
class_name PlayerConfig
extends Resource

@export_group("基础属性")
@export var max_hp: float = 500.0
@export var damage: float = 15.0
@export var defense: float = 5.0
@export var crit_rate: float = 0.10
@export var crit_damage: float = 0.30
@export var fire_rate: float = 1.0

@export_group("移动升级")
@export var move_speed: float = 0.0
@export var move_speed_per_level: float = 12.0
@export var move_speed_base_cost: int = 80

@export_group("生命升级")
@export var max_hp_per_level: float = 60.0
@export var max_hp_base_cost: int = 40

@export_group("攻击升级")
@export var damage_per_level: float = 5.0
@export var damage_base_cost: int = 50

@export_group("防御升级")
@export var defense_per_level: float = 3.0
@export var defense_base_cost: int = 60

@export_group("暴击升级")
@export var crit_rate_per_level: float = 0.03
@export var crit_rate_base_cost: int = 80

@export_group("爆伤升级")
@export var crit_damage_per_level: float = 0.12
@export var crit_damage_base_cost: int = 70

@export_group("射速升级")
@export var fire_rate_per_level: float = 0.2
@export var fire_rate_base_cost: int = 100

@export_group("升级费用")
@export var cost_multiplier: float = 1.45  ## 每级费用 × 此值的 ^当前等级
