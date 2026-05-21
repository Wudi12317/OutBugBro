## 玩家属性组件 — 升级加成 + 效果加成计算
## 防御公式：每 10 点防御，受到伤害 -1（下限 0）
class_name PlayerStats
extends Component

signal stats_changed

## 外部配置（留空使用内置默认值）
@export var config: PlayerConfig

## 统计名 → 显示信息
const STAT_INFO := {
	"max_hp":      { "icon": "❤", "name": "生命", "fmt": "d" },
	"damage":      { "icon": "⚔", "name": "攻击", "fmt": "d" },
	"defense":     { "icon": "🛡", "name": "防御", "fmt": "d" },
	"crit_rate":   { "icon": "💥", "name": "暴击", "fmt": "pct" },
	"crit_damage": { "icon": "💥", "name": "爆伤", "fmt": "pct" },
	"fire_rate":   { "icon": "🔥", "name": "射速", "fmt": "f" },
	"move_speed":  { "icon": "🏃", "name": "移速", "fmt": "f" },
}

## 各属性升级等级
var upgrade_levels: Dictionary = {
	"max_hp": 0, "damage": 0, "defense": 0,
	"crit_rate": 0, "crit_damage": 0, "fire_rate": 0,
	"move_speed": 0,
}

## 上一次暴击结果（供外部查询，避免双重随机）
var last_attack_was_crit: bool = false


func _setup() -> void:
	if not config:
		config = PlayerConfig.new()


## === 配置读取（外部优先） ===

func _cfg_base(stat: String) -> float:
	if config:
		match stat:
			"max_hp": return config.max_hp
			"damage": return config.damage
			"defense": return config.defense
			"crit_rate": return config.crit_rate
			"crit_damage": return config.crit_damage
			"fire_rate": return config.fire_rate
			"move_speed": return config.move_speed
	# 内置默认值（兼容无配置）
	match stat:
		"max_hp": return 500.0
		"damage": return 15.0
		"defense": return 5.0
		"crit_rate": return 0.10
		"crit_damage": return 0.30
		"fire_rate": return 1.0
		"move_speed": return 0.0
	return 0.0


func _cfg_per_level(stat: String) -> float:
	if config:
		match stat:
			"max_hp": return config.max_hp_per_level
			"damage": return config.damage_per_level
			"defense": return config.defense_per_level
			"crit_rate": return config.crit_rate_per_level
			"crit_damage": return config.crit_damage_per_level
			"fire_rate": return config.fire_rate_per_level
			"move_speed": return config.move_speed_per_level
	match stat:
		"max_hp": return 60.0
		"damage": return 5.0
		"defense": return 3.0
		"crit_rate": return 0.03
		"crit_damage": return 0.12
		"fire_rate": return 0.2
		"move_speed": return 12.0
	return 0.0


func _cfg_base_cost(stat: String) -> int:
	if config:
		match stat:
			"max_hp": return config.max_hp_base_cost
			"damage": return config.damage_base_cost
			"defense": return config.defense_base_cost
			"crit_rate": return config.crit_rate_base_cost
			"crit_damage": return config.crit_damage_base_cost
			"fire_rate": return config.fire_rate_base_cost
			"move_speed": return config.move_speed_base_cost
	match stat:
		"max_hp": return 40
		"damage": return 50
		"defense": return 60
		"crit_rate": return 80
		"crit_damage": return 70
		"fire_rate": return 100
		"move_speed": return 80
	return 999


func _cfg_cost_mult() -> float:
	return config.cost_multiplier if config else 1.45


## 获取基础值（含升级加成，不含效果）
func _get_base(stat: String) -> float:
	return _cfg_base(stat) + _cfg_per_level(stat) * upgrade_levels[stat]


## 升级费用: base_cost × cost_mult^current_level
func get_upgrade_cost(stat: String) -> int:
	return int(_cfg_base_cost(stat) * pow(_cfg_cost_mult(), float(upgrade_levels[stat])))


## 执行升级，成功返回 true
func upgrade(stat: String) -> bool:
	var cost := get_upgrade_cost(stat)
	if not CurrencyManager.has_enough(cost):
		return false
	CurrencyManager.spend(cost)
	upgrade_levels[stat] += 1
	stats_changed.emit()
	return true


## 下一级数值预览（不含效果加成）
func get_next_value(stat: String) -> float:
	return _cfg_base(stat) + _cfg_per_level(stat) * (upgrade_levels[stat] + 1)


## === 属性获取（升级 + 效果加成）===

func get_max_hp() -> int:
	return int(_get_base("max_hp")) + int(_get_sum("hp_change"))

func get_damage() -> int:
	var flat := _get_sum("damage_change")
	var mult := _get_sum("damage_mult_change")
	return maxi(1, int((_get_base("damage") + flat) * (1.0 + mult)))

func get_crit_rate() -> float:
	return clampf(_get_base("crit_rate") + _get_sum("crit_rate_change"), 0.0, 1.0)

func get_crit_damage() -> float:
	return _get_base("crit_damage") + _get_sum("crit_damage_change")

func get_defense() -> int:
	return maxi(0, int(_get_base("defense")) + int(_get_sum("defense_change")))

func get_fire_rate() -> float:
	return maxf(0.05, _get_base("fire_rate") + _get_sum("fire_rate_change"))

func get_move_speed() -> float:
	return maxf(0.0, _get_base("move_speed") + _get_sum("move_speed_change"))


## 防御减伤：每 8 点防御 -1 伤害，下限 0
func calc_damage_taken(raw: int) -> int:
	var reduction := get_defense() / 8
	return maxi(0, raw - reduction)


## 暴击判定（单一随机源，结果缓存到 last_attack_was_crit）
func is_crit() -> bool:
	last_attack_was_crit = randf() < get_crit_rate()
	return last_attack_was_crit


## 计算最终伤害（含暴击，复用 is_crit 的判定结果）
func calc_damage_dealt() -> int:
	var dmg := get_damage()
	# 如果 is_crit 还没被调用过这一帧，先调用
	is_crit()
	if last_attack_was_crit:
		dmg = int(dmg * (1.0 + get_crit_damage()))
	return dmg


## 汇总效果加成
func _get_sum(prop: String) -> float:
	var total := 0.0
	for entry in EffectManager.get_active():
		var val: float = entry.effect.get(prop)
		total += val
	return total


func _ready() -> void:
	super._ready()
	EffectManager.changed.connect(func(): stats_changed.emit())
