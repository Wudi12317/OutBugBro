## 效果基类 — 定义一个效果对角色属性的改变
## 所有值默认 0，表示无改变；正为加，负为扣
class_name EffectData
extends Resource

@export var id: String = ""              ## 效果编号（唯一标识）
@export var icon: Texture2D              ## 效果贴图
@export var heal_amount: float = 0.0     ## 即时回血（使用消耗品时立刻回复）
@export var hp_change: float = 0.0       ## 改变最大生命上限（持续效果）
@export var fire_rate_change: float = 0.0  ## 改变射速
## item_prob_change 已移除 — 暂无对应属性消费
@export var damage_change: float = 0.0     ## 改变伤害
@export var damage_mult_change: float = 0.0  ## 改变伤害倍率
@export var crit_rate_change: float = 0.0    ## 改变暴击率
@export var crit_damage_change: float = 0.0  ## 改变暴击伤害
@export var defense_change: float = 0.0     ## 改变防御力
@export var move_speed_change: float = 0.0  ## 改变移动速度
## hp_regen_change 已移除 — 暂无自动回血逻辑


## 获取所有非零效果，返回字典 { 属性名: 值 }
func get_active_effects() -> Dictionary:
	var result := {}
	if heal_amount != 0.0: result["heal_amount"] = heal_amount
	if hp_change != 0.0: result["hp_change"] = hp_change
	if fire_rate_change != 0.0: result["fire_rate_change"] = fire_rate_change
	if damage_change != 0.0: result["damage_change"] = damage_change
	if damage_mult_change != 0.0: result["damage_mult_change"] = damage_mult_change
	if crit_rate_change != 0.0: result["crit_rate_change"] = crit_rate_change
	if crit_damage_change != 0.0: result["crit_damage_change"] = crit_damage_change
	if defense_change != 0.0: result["defense_change"] = defense_change
	if move_speed_change != 0.0: result["move_speed_change"] = move_speed_change
	return result
