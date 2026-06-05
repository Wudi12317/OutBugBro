# 挑战模式 — 独立 Boss 战
# 规则：独立背包 | 只能用位移 | 无法升级属性 | 99血包 | 222级Boss | 限时300s
# 对Boss造成伤害3%概率获得消耗品 | 结算评分 = 造成伤害/受到伤害(最小1)
class_name ChallengeMode
extends Node2D

const BOSS_LEVEL: int = 222
const TIME_LIMIT: float = 300.0
const HEALTH_PACK_COUNT: int = 99
const DROP_CHANCE: float = 0.03

var _time_remaining: float = TIME_LIMIT
var _damage_dealt: int = 0
var _damage_taken: int = 0
var _boss: Boss = null
var _player: CharacterBody2D = null
var _challenge_active: bool = false
var _initial_boss_hp: int = 0
var _initial_player_hp: int = 0

# UI
var _timer_label: Label
var _health_packs_label: Label
var _boss_hp_bar: ProgressBar
var _boss_name_label: Label
var _result_panel: PanelContainer


func _ready() -> void:
	_setup_arena()
	_setup_player()
	_setup_boss()
	_setup_ui()
	_challenge_active = true


func _process(delta: float) -> void:
	if not _challenge_active:
		return
	_time_remaining -= delta
	_update_timer_label()
	_update_health_packs_label()
	_update_dash_label()
	# 检测玩家死亡
	_check_player_death()
	# 超时
	if _time_remaining <= 0.0:
		_end_challenge(false)


# ============ 竞技场 ============

func _setup_arena() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var arena_size := viewport_size * 2.0
	# 黑色背景
	var bg := ColorRect.new()
	bg.name = "ArenaBg"
	bg.size = arena_size
	bg.position = -arena_size / 2.0
	bg.color = Color(0.03, 0.03, 0.06)
	bg.z_index = -10
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	# 边框线
	for side in range(4):
		var line := ColorRect.new()
		line.color = Color(0.4, 0.4, 0.6, 0.6)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.z_index = -5
		match side:
			0:
				line.position = Vector2(-arena_size.x / 2.0, -arena_size.y / 2.0)
				line.size = Vector2(arena_size.x, 3.0)
			1:
				line.position = Vector2(-arena_size.x / 2.0, arena_size.y / 2.0 - 3.0)
				line.size = Vector2(arena_size.x, 3.0)
			2:
				line.position = Vector2(-arena_size.x / 2.0, -arena_size.y / 2.0)
				line.size = Vector2(3.0, arena_size.y)
			3:
				line.position = Vector2(arena_size.x / 2.0 - 3.0, -arena_size.y / 2.0)
				line.size = Vector2(3.0, arena_size.y)
		add_child(line)


# ============ 玩家 ============

func _setup_player() -> void:
	_player = preload("res://scenes/world/target.tscn").instantiate()
	_player.position = Vector2.ZERO
	add_child(_player)
	# 添加摄像机（target.tscn 本身不带 Camera2D，正常游戏由 game_world.tscn 提供）
	var cam := Camera2D.new()
	cam.name = "Camera2D"
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	_player.add_child(cam)
	await get_tree().process_frame
	# 禁用所有技能（位移保留），然后自动解锁挑战模式允许的技能
	SkillManager._purchased.clear()
	SkillManager._active.clear()
	SkillManager._cooldowns.clear()
	SkillManager.auto_unlock_challenge_skills()
	# 清空背包，放入 99 血包
	InventoryManager.clear_all()
	var health_potion: ItemData = load("res://data/items/health_potion.tres")
	if health_potion:
		InventoryManager.add_item(health_potion, HEALTH_PACK_COUNT)
	# 记录初始 HP
	var health_comp = _player.get_node_or_null("HealthComponent")
	if health_comp:
		_initial_player_hp = health_comp.hp


func _check_player_death() -> void:
	if not _player or not is_instance_valid(_player):
		_end_challenge(false)
		return
	var health_comp = _player.get_node_or_null("HealthComponent")
	if health_comp and health_comp.hp <= 0:
		_end_challenge(false)


# ============ Boss ============

func _setup_boss() -> void:
	var boss_scene: PackedScene = load("res://scenes/enemies/boss.tscn")
	if boss_scene:
		_boss = boss_scene.instantiate()
	else:
		_boss = Boss.new()
	var viewport_size := get_viewport().get_visible_rect().size
	_boss.position = Vector2(300.0, 0.0)
	_boss.level = BOSS_LEVEL
	_boss.wave_config = preload("res://data/wave_config.tres")
	add_child(_boss)
	await get_tree().process_frame
	# 监听 Boss 血量变化
	if _boss.has_node("HealthComponent"):
		var boss_health: HealthComponent = _boss.get_node("HealthComponent")
		_initial_boss_hp = boss_health.hp
		boss_health.health_changed.connect(_on_boss_health_changed)
	# 监听 Boss 死亡
	_boss.died.connect(_on_boss_died)


func _on_boss_health_changed(current: int, maximum: int) -> void:
	if _boss_hp_bar:
		_boss_hp_bar.max_value = maximum
		_boss_hp_bar.value = current
	# 3% 概率掉消耗品
	if randf() < DROP_CHANCE:
		_spawn_random_consumable()


func _on_boss_died(_b: Boss) -> void:
	_end_challenge(true)


func _spawn_random_consumable() -> void:
	var paths := [
		"res://data/items/health_potion.tres",
		"res://data/items/speed_potion.tres",
		"res://data/items/power_potion.tres",
		"res://data/items/iron_wall_potion.tres",
	]
	var path: String = paths[randi() % paths.size()]
	var item: ItemData = load(path)
	if item:
		InventoryManager.add_item(item, 1)
		# 提示
		EventBus.dispatch("challenge_item_drop", item.name)


# ============ 限时 & UI 更新 ============

func _update_timer_label() -> void:
	if not _timer_label:
		return
	var mins := int(maxf(0, _time_remaining)) / 60
	var secs := int(maxf(0, _time_remaining)) % 60
	_timer_label.text = "%d:%02d" % [mins, secs]
	if _time_remaining < 30.0:
		_timer_label.add_theme_color_override("font_color", Color.RED)
	else:
		_timer_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))


func _update_health_packs_label() -> void:
	if not _health_packs_label:
		return
	# 计算血包数量
	var packs := 0
	for entry in InventoryManager.get_items():
		if entry.data and entry.data.id == "health_potion":
			packs = entry.count
	_health_packs_label.text = "血包: %d" % packs


func _update_dash_label() -> void:
	var dash_node: Label = get_node_or_null("ChallengeUI/DashCD")
	if not dash_node:
		return
	if not _player or not is_instance_valid(_player) or not _player.has_node("DashComponent"):
		dash_node.visible = false
		return
	var dash: DashComponent = _player.get_node("DashComponent")
	dash_node.visible = true
	if dash._is_dashing:
		dash_node.text = "Q 位移中"
		dash_node.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	elif dash._cooldown_remaining > 0:
		dash_node.text = "Q 位移 %.0fs" % dash._cooldown_remaining
		dash_node.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	else:
		dash_node.text = "Q 位移 就绪"
		dash_node.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))


# ============ 结算 ============

func _end_challenge(boss_killed: bool) -> void:
	if not _challenge_active:
		return  # 防止重复调用
	_challenge_active = false
	# 计算伤害
	_calc_damage()
	# 计算评分
	var dmg_taken_safe := maxi(1, _damage_taken)
	var score := snappedf(float(_damage_dealt) / float(dmg_taken_safe), 0.1)
	if boss_killed:
		score *= 2.0
	# 保存评分
	_save_challenge_score(score, boss_killed)
	# 暂停并显示结算
	get_tree().paused = true
	_show_result(boss_killed, score)


func _calc_damage() -> void:
	# 对 Boss 造成的伤害
	if _boss and is_instance_valid(_boss) and _boss.has_node("HealthComponent"):
		var boss_health: HealthComponent = _boss.get_node("HealthComponent")
		_damage_dealt = _initial_boss_hp - boss_health.hp
	elif _boss and _boss.has_meta("dead"):
		_damage_dealt = _initial_boss_hp  # Boss 已死，全伤害
	# 受到的伤害
	if _player and is_instance_valid(_player):
		_damage_taken = _player.total_damage_taken


func _save_challenge_score(score: float, boss_killed: bool) -> void:
	var save_path := "user://challenge_score.json"
	var data: Dictionary = {}
	if FileAccess.file_exists(save_path):
		var f := FileAccess.open(save_path, FileAccess.READ)
		if f:
			var json := JSON.new()
			if json.parse(f.get_as_text()) == OK:
				data = json.data
			f.close()
	var best: float = data.get("best_score", 0.0)
	if score > best:
		data["best_score"] = score
	data["last_score"] = score
	data["last_damage_dealt"] = _damage_dealt
	data["last_damage_taken"] = _damage_taken
	data["last_boss_killed"] = boss_killed
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()


func _show_result(boss_killed: bool, score: float) -> void:
	_result_panel = PanelContainer.new()
	_result_panel.name = "ChallengeResult"
	_result_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	# 居中
	_result_panel.set_anchors_preset(Control.PRESET_CENTER)
	_result_panel.offset_left = -180.0
	_result_panel.offset_top = -180.0
	_result_panel.offset_right = 180.0
	_result_panel.offset_bottom = 180.0
	# iOS 暗色风格
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.12, 0.95)
	style.border_color = Color(0.4, 0.4, 0.6, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	style.set_content_margin_all(24)
	_result_panel.add_theme_stylebox_override("panel", style)
	# 添加到 UILayer
	var ui_layer = get_tree().root.find_child("UILayer", true, false)
	if not ui_layer:
		# 创建一个 CanvasLayer
		var canvas := CanvasLayer.new()
		canvas.layer = 100
		canvas.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(canvas)
		canvas.add_child(_result_panel)
	else:
		ui_layer.add_child(_result_panel)
	# 内容
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_result_panel.add_child(vbox)
	# 标题
	var title := Label.new()
	title.text = "🏆 挑战成功!" if boss_killed else "⏰ 挑战结束"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5) if boss_killed else Color(1.0, 0.3, 0.3))
	vbox.add_child(title)
	# 评分
	var score_label := Label.new()
	score_label.text = "评分: %.1f" % score
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 36)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	vbox.add_child(score_label)
	# 统计
	var stats_text := "造成伤害: %d\n受到伤害: %d\n剩余时间: %ds" % [_damage_dealt, _damage_taken, int(maxf(0, _time_remaining))]
	if boss_killed:
		stats_text += "\nBoss 已击杀 ✓"
	var stats_label := Label.new()
	stats_label.text = stats_text
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	vbox.add_child(stats_label)
	# 公式
	var formula := Label.new()
	formula.text = "评分 = 造成伤害 / 受到伤害(最小1)  击杀Boss×2"
	formula.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	formula.add_theme_font_size_override("font_size", 12)
	formula.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(formula)
	# 返回按钮
	var back_btn := Button.new()
	back_btn.text = "返回主菜单"
	back_btn.custom_minimum_size = Vector2(200, 44)
	back_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	if UITheme:
		UITheme.apply_iOS_style(back_btn)
	back_btn.pressed.connect(_on_back_to_menu)
	vbox.add_child(back_btn)


func _on_back_to_menu() -> void:
	get_tree().paused = false
	SaveManager.clear_runtime()
	GameManager.challenge_mode = false
	GameManager.state = GameManager.State.MENU
	GameManager.change_scene("res://scenes/main_menu.tscn")


# ============ UI ============

func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ChallengeUI"
	canvas.layer = 10
	add_child(canvas)
	# ---- 倒计时 ----
	_timer_label = Label.new()
	_timer_label.name = "TimerLabel"
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override("font_size", 32)
	_timer_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	_timer_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_timer_label.offset_left = -60.0
	_timer_label.offset_top = 20.0
	_timer_label.offset_right = 60.0
	_timer_label.offset_bottom = 60.0
	_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_timer_label)
	# ---- 血包计数 ----
	_health_packs_label = Label.new()
	_health_packs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_packs_label.add_theme_font_size_override("font_size", 16)
	_health_packs_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	_health_packs_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_health_packs_label.offset_left = -60.0
	_health_packs_label.offset_top = 55.0
	_health_packs_label.offset_right = 60.0
	_health_packs_label.offset_bottom = 75.0
	_health_packs_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_health_packs_label)
	# ---- Boss 血条 ----
	var boss_bar_vbox := VBoxContainer.new()
	boss_bar_vbox.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_bar_vbox.offset_left = -200.0
	boss_bar_vbox.offset_top = 80.0
	boss_bar_vbox.offset_right = 200.0
	boss_bar_vbox.offset_bottom = 110.0
	boss_bar_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(boss_bar_vbox)
	_boss_name_label = Label.new()
	_boss_name_label.text = "★大虫 Lv.222"
	_boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name_label.add_theme_font_size_override("font_size", 14)
	_boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	boss_bar_vbox.add_child(_boss_name_label)
	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.max_value = 100.0
	_boss_hp_bar.value = 100.0
	_boss_hp_bar.show_percentage = false
	_boss_hp_bar.custom_minimum_size = Vector2(400, 12)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.05, 0.05, 0.8)
	bg_style.set_corner_radius_all(0)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.85, 0.1, 0.1)
	fill_style.set_corner_radius_all(0)
	_boss_hp_bar.add_theme_stylebox_override("background", bg_style)
	_boss_hp_bar.add_theme_stylebox_override("fill", fill_style)
	boss_bar_vbox.add_child(_boss_hp_bar)
	# ---- 位移 CD 显示 ----
	var dash_label := Label.new()
	dash_label.name = "DashCD"
	dash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dash_label.add_theme_font_size_override("font_size", 14)
	dash_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	dash_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	dash_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	dash_label.offset_left = 20.0
	dash_label.offset_top = -80.0
	dash_label.offset_right = 120.0
	dash_label.offset_bottom = -58.0
	dash_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(dash_label)
	# ---- 玩家血条（实例化 target_hp_bar.tscn） ----
	var hp_bar_scene: PackedScene = load("res://scenes/ui/target_hp_bar.tscn")
	if hp_bar_scene:
		var hp_bar := hp_bar_scene.instantiate()
		canvas.add_child(hp_bar)
	# ---- 技能栏（实例化 skill_bar.tscn） ----
	var skill_bar_scene: PackedScene = load("res://scenes/ui/skill_bar.tscn")
	if skill_bar_scene:
		var skill_bar := skill_bar_scene.instantiate()
		skill_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		skill_bar.offset_left = -8.0
		skill_bar.offset_top = -80.0
		skill_bar.offset_right = -8.0
		skill_bar.offset_bottom = -20.0
		canvas.add_child(skill_bar)
	# ---- 背包 UI（实例化 inventory_ui.tscn） ----
	var inv_scene: PackedScene = load("res://scenes/ui/inventory_ui.tscn")
	if inv_scene:
		var inv := inv_scene.instantiate()
		inv.set_anchors_preset(Control.PRESET_FULL_RECT)
		inv.visible = false  # 默认隐藏，按 B 打开
		canvas.add_child(inv)
	# ---- 暂停菜单（实例化 pause_menu.tscn） ----
	var pause_scene: PackedScene = load("res://scenes/ui/pause_menu.tscn")
	if pause_scene:
		var pause_menu := pause_scene.instantiate()
		pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
		canvas.add_child(pause_menu)
