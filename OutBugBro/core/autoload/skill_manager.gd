## 技能管理器 — 管理技能解锁、购买、激活、冷却
## 技能效果由 Target / Enemy 等节点通过 is_active() 查询
extends Node

signal changed                                      ## 任何状态变化
signal skill_activated(skill_id: String)            ## 技能激活
signal skill_expired(skill_id: String)              ## 效果到期
signal skill_purchased(skill_id: String)            ## 购买成功

## 挑战模式允许的技能ID
const CHALLENGE_ALLOWED := ["shield", "head_oil"]

var _skills: Array[SkillData] = []
var _purchased: Dictionary = {}    ## id -> true
var _cooldowns: Dictionary = {}    ## id -> remaining
var _active: Dictionary = {}       ## id -> remaining


func _ready() -> void:
	_scan_skills()


## 加载技能数据（从 DataRegistry 读取路径，导出安全）
func _scan_skills() -> void:
	var registry: DataRegistry = load("res://data/data_registry.tres")
	var paths: Array = registry.skill_paths if registry else []
	for path in paths:
		var res: Resource = load(path)
		if res is SkillData and res.id != "":
			_skills.append(res)
	# 按 key_index 排序
	_skills.sort_custom(func(a, b): return a.key_index < b.key_index)
	push_warning("[SkillManager] 已加载 %d/%d 个技能" % [_skills.size(), paths.size()])


func _process(delta: float) -> void:
	var expired_ids: PackedStringArray = []
	# 更新冷却
	for id in _cooldowns:
		_cooldowns[id] -= delta
		if _cooldowns[id] <= 0:
			_cooldowns[id] = 0
	# 更新激活效果
	for id in _active:
		_active[id] -= delta
		if _active[id] <= 0:
			expired_ids.append(id)
	# 清理到期效果
	for id in expired_ids:
		_active.erase(id)
		skill_expired.emit(id)
	if not expired_ids.is_empty():
		changed.emit()


## 获取所有技能
func get_skills() -> Array[SkillData]:
	return _skills


## 挑战模式可见技能（仅允许的2个）
func get_visible_skills() -> Array[SkillData]:
	if GameManager.challenge_mode:
		var result: Array[SkillData] = []
		for s in _skills:
			if s.id in CHALLENGE_ALLOWED:
				result.append(s)
		return result
	return _skills


## 挑战模式自动解锁允许的技能
func auto_unlock_challenge_skills() -> void:
	if not GameManager.challenge_mode:
		return
	for id in CHALLENGE_ALLOWED:
		if not _purchased.has(id):
			_purchased[id] = true
	changed.emit()


## 按ID激活（供Q键等快捷调用）
func activate_by_id(id: String) -> bool:
	return activate(id)


## 当前波次
func _get_current_wave() -> int:
	var spawners := get_tree().get_nodes_in_group("spawners")
	if spawners.is_empty():
		return 1
	return spawners[0].wave


## 是否已购买
func is_unlocked(id: String) -> bool:
	return _purchased.has(id)


## 挑战模式下是否允许使用该技能
func is_allowed_in_challenge(id: String) -> bool:
	if not GameManager.challenge_mode:
		return true
	return id in CHALLENGE_ALLOWED


## 是否可购买
func can_purchase(id: String) -> bool:
	var skill := _get_skill(id)
	if not skill: return false
	if is_unlocked(id): return false
	if GameManager.challenge_mode and id not in CHALLENGE_ALLOWED:
		return false
	return _get_current_wave() >= skill.unlock_wave


## 购买技能
func purchase(id: String) -> bool:
	var skill := _get_skill(id)
	if not skill: return false
	if is_unlocked(id): return false
	if GameManager.challenge_mode and id not in CHALLENGE_ALLOWED:
		return false
	if not CurrencyManager.has_enough(skill.cost): return false
	CurrencyManager.spend(skill.cost)
	_purchased[id] = true
	skill_purchased.emit(id)
	changed.emit()
	return true


## 激活技能
func activate(id: String) -> bool:
	# 挑战模式允许的技能免解锁直接可用
	if GameManager.challenge_mode and id in CHALLENGE_ALLOWED:
		if not is_unlocked(id):
			_purchased[id] = true
	elif not is_unlocked(id):
		return false
	if GameManager.challenge_mode and id not in CHALLENGE_ALLOWED:
		return false
	if is_on_cooldown(id): return false
	if is_active(id): return false
	var skill := _get_skill(id)
	if not skill: return false
	_active[id] = skill.duration
	_cooldowns[id] = skill.cooldown
	skill_activated.emit(id)
	changed.emit()
	return true


## 效果是否激活中
func is_active(id: String) -> bool:
	return _active.get(id, 0.0) > 0


## 是否在冷却中
func is_on_cooldown(id: String) -> bool:
	return _cooldowns.get(id, 0.0) > 0


## 获取冷却剩余
func get_cooldown_remaining(id: String) -> float:
	return _cooldowns.get(id, 0.0)


## 获取冷却总时长
func get_cooldown_total(id: String) -> float:
	var skill := _get_skill(id)
	return skill.cooldown if skill else 0.0


## 获取效果剩余
func get_active_remaining(id: String) -> float:
	return _active.get(id, 0.0)


## 获取技能数据
func _get_skill(id: String) -> SkillData:
	for s in _skills:
		if s.id == id: return s
	return null


## 按索引激活（1-5键）
func activate_by_index(idx: int) -> bool:
	if idx < 0 or idx >= _skills.size(): return false
	return activate(_skills[idx].id)


## 按索引购买
func purchase_by_index(idx: int) -> bool:
	if idx < 0 or idx >= _skills.size(): return false
	return purchase(_skills[idx].id)
