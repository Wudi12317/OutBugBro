## 开发者模式面板 — 密码 castorice 解锁
## 功能：调整波次 / 任意属性 / 加金币 / 清怪 / 无敌
## 挂到 UILayer 下，代码构建 UI
extends Control

const DEVPASS := "castorice"

var _unlocked: bool = false
var _input_text: String = ""

## 面板节点引用
var _lock_panel: Control = null
var _dev_panel: Control = null
var _pass_input: LineEdit = null
var _wave_label: Label = null
var _gold_label: Label = null
var _god_btn: Button = null
var _god_mode: bool = false

## 目标引用
var _spawner: EnemySpawner = null
var _stats: PlayerStats = null
var _health: HealthComponent = null


func _ready() -> void:
	z_index = 400
	## 根节点保持可见，否则🛠按钮也一起隐藏
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	await get_tree().process_frame
	_bind_nodes()


func _bind_nodes() -> void:
	var spawners := get_tree().get_nodes_in_group("spawners")
	if not spawners.is_empty():
		_spawner = spawners[0]
	var targets := get_tree().get_nodes_in_group("targets")
	if not targets.is_empty():
		var t := targets[0]
		if t.has_node("PlayerStats"):
			_stats = t.get_node("PlayerStats")
		if t.has_node("HealthComponent"):
			_health = t.get_node("HealthComponent")
	CurrencyManager.changed.connect(_refresh_info)
	_refresh_info()


## ============ UI 构建 ============

func _build_ui() -> void:
	## 触发按钮（右上角小图标）
	var trigger := Button.new()
	trigger.text = "🛠"
	trigger.flat = false
	trigger.add_theme_font_size_override("font_size", 16)
	trigger.custom_minimum_size = Vector2(36, 36)
	trigger.focus_mode = Control.FOCUS_NONE
	trigger.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	trigger.offset_left = -44.0
	trigger.offset_right = -8.0
	trigger.offset_top = 8.0
	trigger.offset_bottom = 44.0
	trigger.tooltip_text = "开发者模式"
	trigger.pressed.connect(_on_trigger)
	add_child(trigger)

	## 密码解锁面板
	_lock_panel = _create_lock_panel()
	_lock_panel.visible = false
	add_child(_lock_panel)

	## 开发者面板（解锁后显示）
	_dev_panel = _create_dev_panel()
	_dev_panel.visible = false
	add_child(_dev_panel)


func _create_lock_panel() -> Control:
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(240, 120)
	panel.offset_left = -120.0
	panel.offset_top = -60.0
	panel.offset_right = 120.0
	panel.offset_bottom = 60.0
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.07, 0.07, 0.1, 0.97)
	sty.border_color = Color(0.6, 0.5, 0.2)
	sty.set_border_width_all(2)
	sty.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sty)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 12.0
	vbox.offset_top = 10.0
	vbox.offset_right = -12.0
	vbox.offset_bottom = -10.0
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "🔒 输入开发者密码"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	_pass_input = LineEdit.new()
	_pass_input.placeholder_text = "密码..."
	_pass_input.secret = true
	_pass_input.add_theme_font_size_override("font_size", 13)
	_pass_input.text_submitted.connect(_on_password_submit)
	vbox.add_child(_pass_input)
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)
	var ok_btn := Button.new()
	ok_btn.text = "确认"
	ok_btn.custom_minimum_size = Vector2(80, 28)
	ok_btn.focus_mode = Control.FOCUS_NONE
	ok_btn.pressed.connect(func(): _on_password_submit(_pass_input.text))
	btn_row.add_child(ok_btn)
	var cancel_btn := Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(80, 28)
	cancel_btn.focus_mode = Control.FOCUS_NONE
	cancel_btn.pressed.connect(func(): _lock_panel.visible = false)
	btn_row.add_child(cancel_btn)
	return panel


func _create_dev_panel() -> Control:
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.custom_minimum_size = Vector2(260, 380)
	panel.offset_left = -268.0
	panel.offset_top = 52.0
	panel.offset_right = -8.0
	panel.offset_bottom = 432.0
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.07, 0.07, 0.1, 0.97)
	sty.border_color = Color(0.6, 0.5, 0.2)
	sty.set_border_width_all(2)
	sty.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sty)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 4.0
	scroll.offset_top = 4.0
	scroll.offset_right = -4.0
	scroll.offset_bottom = -4.0
	panel.add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.name = "DevVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)
	## 标题
	var title := Label.new()
	title.text = "🛠 开发者模式"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	_add_separator(vbox, "状态信息")
	## 信息标签
	_wave_label = Label.new()
	_wave_label.name = "WaveLabel"
	_wave_label.add_theme_font_size_override("font_size", 12)
	_wave_label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8))
	vbox.add_child(_wave_label)
	_gold_label = Label.new()
	_gold_label.name = "GoldLabel"
	_gold_label.add_theme_font_size_override("font_size", 12)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(_gold_label)
	_add_separator(vbox, "金币")
	for amount in [100, 500, 2000, 10000]:
		var btn := _make_btn("+%d 金币" % amount, func(): CurrencyManager.add(amount))
		vbox.add_child(btn)
	_add_separator(vbox, "波次控制")
	var wave_row := HBoxContainer.new()
	wave_row.add_theme_constant_override("separation", 4)
	vbox.add_child(wave_row)
	var wm1 := _make_btn("-1波", func(): _adjust_wave(-1))
	wm1.custom_minimum_size = Vector2(80, 26)
	wave_row.add_child(wm1)
	var wp1 := _make_btn("+1波", func(): _adjust_wave(1))
	wp1.custom_minimum_size = Vector2(80, 26)
	wave_row.add_child(wp1)
	var wp5 := _make_btn("+5波", func(): _adjust_wave(5))
	wp5.custom_minimum_size = Vector2(80, 26)
	wave_row.add_child(wp5)
	var boss_btn := _make_btn("💀 触发Boss波", _trigger_boss_wave)
	vbox.add_child(boss_btn)
	var kill_btn := _make_btn("🧹 清除所有怪物", _kill_all_enemies)
	vbox.add_child(kill_btn)
	_add_separator(vbox, "属性调整")
	for stat in ["max_hp", "damage", "defense", "crit_rate", "crit_damage", "fire_rate"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		vbox.add_child(row)
		var lbl := Label.new()
		lbl.text = _stat_name(stat)
		lbl.custom_minimum_size = Vector2(70, 0)
		lbl.add_theme_font_size_override("font_size", 11)
		row.add_child(lbl)
		var um := _make_btn("▲", func(): _upgrade_stat(stat, 3))
		um.custom_minimum_size = Vector2(30, 24)
		row.add_child(um)
		var dm := _make_btn("▼", func(): _downgrade_stat(stat))
		dm.custom_minimum_size = Vector2(30, 24)
		row.add_child(dm)
	_add_separator(vbox, "其他")
	var full_hp := _make_btn("💚 满血", func():
		if _health:
			_health.set_hp(_health.max_hp)
	)
	vbox.add_child(full_hp)
	_god_btn = _make_btn("😇 无敌模式 OFF", _toggle_god_mode)
	_god_btn.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	vbox.add_child(_god_btn)
	var add_item_btn := _make_btn("🎁 添加全部红色物品", _add_red_items)
	vbox.add_child(add_item_btn)
	var close_btn := _make_btn("✕ 关闭", func(): _dev_panel.visible = false)
	close_btn.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
	vbox.add_child(close_btn)
	return panel


func _add_separator(parent: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = "— %s —" % text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)


func _make_btn(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 26)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(callback)
	return btn


func _stat_name(stat: String) -> String:
	match stat:
		"max_hp": return "HP上限"
		"damage": return "攻击"
		"defense": return "防御"
		"crit_rate": return "暴击率"
		"crit_damage": return "爆伤"
		"fire_rate": return "射速"
	return stat


## ============ 逻辑处理 ============

func _on_trigger() -> void:
	if _unlocked:
		_dev_panel.visible = not _dev_panel.visible
		if _dev_panel.visible:
			_refresh_info()
	else:
		_lock_panel.visible = true
		if _pass_input:
			_pass_input.text = ""
			_pass_input.grab_focus()


func _on_password_submit(text: String) -> void:
	if text.strip_edges().to_lower() == DEVPASS:
		_unlocked = true
		_lock_panel.visible = false
		_dev_panel.visible = true
		_refresh_info()
	else:
		if _pass_input:
			_pass_input.clear()
			_pass_input.placeholder_text = "❌ 密码错误，再试"


func _refresh_info() -> void:
	if not _dev_panel or not _dev_panel.visible:
		return
	var wave_num := _spawner.wave if _spawner and is_instance_valid(_spawner) else 0
	if _wave_label:
		_wave_label.text = "🌊 当前波次: %d" % wave_num
	if _gold_label:
		_gold_label.text = "💰 金币: %d" % CurrencyManager.currency


func _adjust_wave(delta: int) -> void:
	if not _spawner or not is_instance_valid(_spawner):
		_bind_nodes()
		return
	_spawner.wave = maxi(1, _spawner.wave + delta)
	_spawner.wave_changed.emit(_spawner.wave)
	_refresh_info()


func _trigger_boss_wave() -> void:
	if not _spawner or not is_instance_valid(_spawner):
		return
	_spawner._boss_spawned = false
	_spawner._is_boss_wave = true
	_spawner.phase = EnemySpawner.Phase.FIGHTING


func _kill_all_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			e.queue_free()


func _upgrade_stat(stat: String, times: int = 1) -> void:
	if not _stats or not is_instance_valid(_stats):
		_bind_nodes()
		return
	for _i in range(times):
		_stats.upgrade_levels[stat] += 1
	_stats.stats_changed.emit()


func _downgrade_stat(stat: String) -> void:
	if not _stats or not is_instance_valid(_stats):
		return
	_stats.upgrade_levels[stat] = maxi(0, _stats.upgrade_levels[stat] - 1)
	_stats.stats_changed.emit()


func _toggle_god_mode() -> void:
	_god_mode = not _god_mode
	if _god_btn:
		_god_btn.text = "😇 无敌模式 %s" % ("ON ✓" if _god_mode else "OFF")
	## 注入一个永久护盾效果（复用现有技能逻辑）
	if _god_mode:
		SkillManager._active["shield"] = 99999.0
	else:
		SkillManager._active.erase("shield")
	SkillManager.changed.emit()


func _add_red_items() -> void:
	var items: Array[ItemData] = []
	var h := MaterialItemData.new()
	h.id = "boss_heart"
	h.name = "Boss之心"
	h.icon = load("res://assets/sprites/items/heart.png")
	h.desc = "从Boss体内取出的核心"
	h.rarity = 5
	h.value = 5000
	h.sources = ["开发者模式"]
	items.append(h)
	var c := MaterialItemData.new()
	c.id = "boss_crystal"
	c.name = "虫域水晶"
	c.icon = load("res://assets/sprites/items/chy.png")
	c.desc = "Boss身上析出的神秘晶体"
	c.rarity = 5
	c.value = 8000
	c.sources = ["开发者模式"]
	items.append(c)
	var e := ConsumableItemData.new()
	e.id = "boss_essence"
	e.name = "Boss精粹"
	e.icon = load("res://assets/sprites/items/heart.png")
	e.desc = "使用后获得超强增益30s"
	e.rarity = 5
	e.value = 10000
	e.effect_duration = 30.0
	e.effect_ids = ["boss_essence_effect"]
	items.append(e)
	for item in items:
		InventoryManager.add_item(item)


func _process(_delta: float) -> void:
	if _dev_panel and _dev_panel.visible:
		_refresh_info()
