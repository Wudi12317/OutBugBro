# 元进度系统 [Autoload] — 死后永久升级（Roguelike）
extends Node

signal upgraded(id: String)  ## 某一项升级时触发

const SAVE_PATH := "user://meta_save.json"

## 永久升级定义（ID / 名称 / 描述 / 基础费用 / 每级增量 / 最大值 / 当前等级）
## 效果值由 PlayerStats 读取 meta 数据计算
var upgrades: Dictionary = {
	"hp_boost":  { "name": "生命强化", "desc": "基础HP +50/级", "base_cost": 50,  "cost_mult": 1.3, "max_lv": 20, "lv": 0, "icon": "❤️" },
	"atk_boost": { "name": "力量强化", "desc": "基础ATK +5/级", "base_cost": 60,  "cost_mult": 1.35, "max_lv": 20, "lv": 0, "icon": "⚔️" },
	"def_boost": { "name": "防御强化", "desc": "基础DEF +5/级", "base_cost": 50,  "cost_mult": 1.3, "max_lv": 20, "lv": 0, "icon": "🛡️" },
	"spd_boost": { "name": "敏捷强化", "desc": "基础移速 +10/级", "base_cost": 40,  "cost_mult": 1.25, "max_lv": 15, "lv": 0, "icon": "💨" },
	"drop_boost":{ "name": "幸运强化", "desc": "掉落率 +5%/级", "base_cost": 80,  "cost_mult": 1.4, "max_lv": 10, "lv": 0, "icon": "🍀" },
	"gold_boost":{ "name": "财运强化", "desc": "金币获取 +15%/级", "base_cost": 60,  "cost_mult": 1.35, "max_lv": 10, "lv": 0, "icon": "💰" },
	"dmg_boost": { "name": "伤害强化", "desc": "伤害倍率 +5%/级", "base_cost": 100, "cost_mult": 1.45, "max_lv": 10, "lv": 0, "icon": "🔥" },
	"crit_boost":{ "name": "精准强化", "desc": "暴击率 +3%/级", "base_cost": 90,  "cost_mult": 1.4, "max_lv": 10, "lv": 0, "icon": "🎯" },
	"hp_regen":  { "name": "生命回复", "desc": "每秒回复 +1HP/级", "base_cost": 100, "cost_mult": 1.5, "max_lv": 10, "lv": 0, "icon": "💚" },
}

var _data: Dictionary = {}


# ============ 生命周期 ============

func _ready() -> void:
	_load()


# ============ 外部接口 ============

## 获取某升级的当前等级
func get_level(id: String) -> int:
	return upgrades.get(id, {}).get("lv", 0)

## 获取某升级的当前费用
func get_cost(id: String) -> int:
	var u: Dictionary = upgrades.get(id)
	if not u:
		return 999999
	var lv: int = u.get("lv", 0)
	var base: int = u.get("base_cost", 100)
	var mult: float = u.get("cost_mult", 1.4)
	return int(base * pow(mult, lv))

## 是否可以升级
func can_upgrade(id: String) -> bool:
	var u: Dictionary = upgrades.get(id)
	if not u:
		return false
	if u.get("lv", 0) >= u.get("max_lv", 99):
		return false
	return CurrencyManager.currency >= get_cost(id)

## 执行升级，成功返回 true
func upgrade(id: String) -> bool:
	if not can_upgrade(id):
		return false
	var cost: int = get_cost(id)
	if not CurrencyManager.spend(cost):
		return false
	upgrades[id]["lv"] += 1
	_write_file()
	upgraded.emit(id)
	return true

## 总升级等级（用于显示）
func total_levels() -> int:
	var t: int = 0
	for u in upgrades.values():
		t += u.get("lv", 0)
	return t

## 获取元进度加成值（供 PlayerStats 调用）
func get_hp_bonus() -> int:
	return get_level("hp_boost") * 50

func get_atk_bonus() -> int:
	return get_level("atk_boost") * 5

func get_def_bonus() -> int:
	return get_level("def_boost") * 5

func get_spd_bonus() -> float:
	return get_level("spd_boost") * 10.0

func get_drop_rate_bonus() -> float:
	return get_level("drop_boost") * 0.05

func get_gold_mult_bonus() -> float:
	return 1.0 + get_level("gold_boost") * 0.15

func get_dmg_mult_bonus() -> float:
	return 1.0 + get_level("dmg_boost") * 0.05

func get_crit_bonus() -> float:
	return get_level("crit_boost") * 0.03

func get_hp_regen() -> float:
	return get_level("hp_regen") * 1.0


# ============ 存档 ============

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_data = {}
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		_data = {}
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err == OK and json.data is Dictionary:
		_data = json.data
		# 恢复等级到 upgrades 字典
		for id in _data.get("upgrades", {}):
			if upgrades.has(id):
				upgrades[id]["lv"] = int(_data["upgrades"][id])
	else:
		_data = {}

func _write_file() -> void:
	# 只保存等级
	var save_data := { "upgrades": {} }
	for id in upgrades:
		var lv: int = upgrades[id].get("lv", 0)
		if lv > 0:
			save_data["upgrades"][id] = lv
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	_data = save_data
