## 存档管理器 [Autoload] — 自动存档、读档、最高评分
extends Node

const SAVE_PATH := "user://save_data.json"

signal loaded  ## 读档完成

## 存档数据
var _data: Dictionary = {}

## 击杀数（本次运行）
var run_kills: int = 0

## 待加载存档标志（主菜单设，main场景读）
var _pending_load: bool = false


func _ready() -> void:
	_load()


# ============ 存档操作 ============

func has_save() -> bool:
	return _data.has("run")


## 保存当前运行状态
func save_run() -> void:
	# 收集本次运行数据
	var spawners := get_tree().get_nodes_in_group("spawners")
	var wave: int = 1
	if not spawners.is_empty():
		wave = spawners[0].wave
	_data["run"] = {
		"currency": CurrencyManager.currency,
		"wave": wave,
		"kills": run_kills,
		"upgrades": _collect_upgrades(),
		"skills_purchased": _collect_skills(),
		"consumable_bindings": _collect_bindings(),
		"items": _collect_items(),
	}
	_write_file()


## 读档并恢复状态
func load_run() -> void:
	if not _data.has("run"):
		return
	var run: Dictionary = _data["run"]
	CurrencyManager.currency = int(run.get("currency", 0))
	run_kills = int(run.get("kills", 0))
	_restore_upgrades(run.get("upgrades", {}))
	_restore_skills(run.get("skills_purchased", []))
	_restore_bindings(run.get("consumable_bindings", []))
	_restore_items(run.get("items", []))
	loaded.emit()


## 获取存档中的波次
func get_saved_wave() -> int:
	if not _data.has("run"):
		return 1
	return int(_data["run"].get("wave", 1))


## 重置本次运行（保留最高记录）
func reset_run() -> void:
	clear_runtime()
	_data.erase("run")
	_write_file()


## 完全重置（包括最高记录）
func full_reset() -> void:
	clear_runtime()
	_data = {}
	_write_file()


## 清除所有运行时状态（Autoload 单例在场景重载后不重置，需手动清）
func clear_runtime() -> void:
	run_kills = 0
	_pending_load = false
	# 背包清空
	InventoryManager.clear_all()
	InventoryManager.consumable_bindings = PackedStringArray(["", "", "", "", ""])
	InventoryManager.bindings_changed.emit()
	# 金币清零
	CurrencyManager.currency = 0
	# 技能清空
	SkillManager._purchased.clear()
	SkillManager._active.clear()
	SkillManager._cooldowns.clear()
	SkillManager.changed.emit()
	# 效果清空
	EffectManager.clear_all()
	# 连击清空
	ComboManager.combo = 0
	ComboManager._timer = 0.0


# ============ 最高评分 ============

## 更新最高评分（死亡时调用）
func update_high_score(waves: int, kills: int) -> void:
	var best: int = _data.get("high_score", {}).get("waves", 0)
	if waves > best:
		var grade_info := calculate_grade(waves)
		_data["high_score"] = {
			"grade": grade_info.grade,
			"waves": waves,
			"kills": kills,
			"stars": grade_info.stars,
		}
	_write_file()


## 获取最高评分信息
func get_high_score() -> Dictionary:
	return _data.get("high_score", {})


## 获取最高评分显示文本
func get_high_score_text() -> String:
	var hs := get_high_score()
	if hs.is_empty():
		return "最高评分: -"
	var grade: String = hs.get("grade", "?")
	var stars: int = hs.get("stars", 0)
	if stars > 0:
		return "最高评分: %s ⭐x%d" % [grade, stars]
	return "最高评分: %s" % grade


## 评分等级计算（波次阈值延后3波）
func calculate_grade(waves: int) -> Dictionary:
	var grade: String
	var color: Color
	var stars: int = 0

	if waves < 6:
		grade = "C"
		color = Color(0.3, 0.9, 0.3)  # 绿
	elif waves < 7:
		grade = "B"
		color = Color(0.3, 0.6, 1.0)  # 蓝
	elif waves < 9:
		grade = "A"
		color = Color(0.6, 0.2, 1.0)  # 紫
	elif waves < 12:
		grade = "S"
		color = Color(1.0, 0.85, 0.0)  # 金
	elif waves < 13:
		grade = "SS"
		color = Color(1.0, 0.85, 0.0)
	elif waves < 14:
		grade = "SSS"
		color = Color(1.0, 0.15, 0.15)  # 红
	elif waves < 15:
		grade = "SSS+"
		color = Color(1.0, 0.15, 0.15)
	else:
		stars = waves - 15
		grade = "SSS+"
		color = Color.WHITE  # 炫彩由调用方处理

	return { "grade": grade, "color": color, "stars": stars, "waves": waves }


# ============ 内部方法 ============

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
	else:
		_data = {}


func _write_file() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()


## 收集升级等级
func _collect_upgrades() -> Dictionary:
	var targets := get_tree().get_nodes_in_group("player")
	if targets.is_empty():
		return {}
	var stats: PlayerStats = targets[0].get_node_or_null("PlayerStats")
	if not stats:
		return {}
	return stats.upgrade_levels.duplicate()


## 收集已购买技能
func _collect_skills() -> PackedStringArray:
	var result: PackedStringArray = []
	for s in SkillManager.get_skills():
		if SkillManager.is_unlocked(s.id):
			result.append(s.id)
	return result


## 收集消耗品绑定
func _collect_bindings() -> PackedStringArray:
	return InventoryManager.consumable_bindings


## 收集背包物品
func _collect_items() -> Array:
	var result: Array = []
	for entry in InventoryManager.get_items():
		result.append({ "id": entry.data.id, "count": entry.count })
	return result


## 恢复升级等级
func _restore_upgrades(data: Dictionary) -> void:
	var targets := get_tree().get_nodes_in_group("player")
	if targets.is_empty():
		return
	var stats: PlayerStats = targets[0].get_node_or_null("PlayerStats")
	if not stats:
		return
	for key in data:
		if stats.upgrade_levels.has(key):
			stats.upgrade_levels[key] = int(data[key])
	stats.stats_changed.emit()


## 恢复已购买技能
func _restore_skills(ids: Array) -> void:
	for id in ids:
		var sid: String = str(id)
		if not SkillManager.is_unlocked(sid):
			SkillManager._purchased[sid] = true
	SkillManager.changed.emit()


## 恢复消耗品绑定
func _restore_bindings(data: Array) -> void:
	for i in range(mini(data.size(), 5)):
		InventoryManager.consumable_bindings[i] = str(data[i])
	InventoryManager.bindings_changed.emit()


## 恢复背包物品
func _restore_items(data: Array) -> void:
	InventoryManager.clear_all()
	for entry in data:
		var item_id: String = str(entry.get("id", ""))
		var count: int = int(entry.get("count", 1))
		# 在 data/items/ 中查找
		var item: ItemData = _find_item_by_id(item_id)
		if item:
			InventoryManager.add_item(item, count)


func _find_item_by_id(item_id: String) -> ItemData:
	# 从 DataRegistry 读取物品路径（开发+导出通用，加新物品无需改代码）
	var registry: DataRegistry = load("res://data/data_registry.tres")
	var paths: Array = registry.item_paths if registry else []
	for path in paths:
		var res: Resource = load(path)
		if res is ItemData and res.id == item_id:
			return res
	push_warning("[SaveManager] 未找到物品 id=%s" % item_id)
	return null
