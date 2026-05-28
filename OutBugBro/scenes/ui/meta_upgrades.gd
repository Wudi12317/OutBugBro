## 元进度升级面板 — 死后显示 / 游戏内 HUD 均可使用
extends Control

signal upgrade_done  ## 升级完成（刷新显示）
signal start_game     ## 开始游戏
signal panel_closed   ## 面板关闭（游戏内 HUD 模式用）

@onready var _grid: GridContainer = $CenterContainer/MainVBox/UpgradeGrid
@onready var _gold_label: Label = $CenterContainer/MainVBox/GoldLabel
@onready var _total_label: Label = $CenterContainer/MainVBox/BottomHBox/TotalLabel
@onready var _start_btn: Button = $CenterContainer/MainVBox/BottomHBox/StartBtn

var _in_game_mode: bool = false  ## 是否为游戏内 HUD 模式

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CurrencyManager.changed.connect(_refresh)
	MetaProgression.upgraded.connect(_on_upgraded)
	if _start_btn:
		_start_btn.pressed.connect(func(): start_game.emit())
	_build_ui()
	_refresh()

## 游戏内 HUD 模式：隐藏"开始游戏"按钮，仅显示升级项
func show_in_game() -> void:
	_in_game_mode = true
	if _start_btn:
		_start_btn.visible = false
	visible = true
	_refresh()

## 关闭面板（游戏内模式）
func hide_panel() -> void:
	visible = false
	panel_closed.emit()

func _build_ui() -> void:
	## 清空旧项
	for child in _grid.get_children():
		child.queue_free()
	## 按定义创建升级项
	for id in MetaProgression.upgrades:
		var u: Dictionary = MetaProgression.upgrades[id]
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(260, 90)
		panel.add_theme_stylebox_override("panel", _make_panel_style())
		_grid.add_child(panel)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		panel.add_child(vbox)

		## 标题行：图标 + 名称 + 等级
		var hbox := HBoxContainer.new()
		vbox.add_child(hbox)

		var icon := Label.new()
		icon.text = u.get("icon", "◆")
		icon.add_theme_font_size_override("font_size", 20)
		hbox.add_child(icon)

		var name_lbl := Label.new()
		name_lbl.text = u.get("name", id)
		name_lbl.add_theme_color_override("font_color", Color.CYAN)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_lbl)

		var lv_lbl := Label.new()
		lv_lbl.name = "LvLabel"
		lv_lbl.text = "Lv.%d/%d" % [u.get("lv", 0), u.get("max_lv", 99)]
		lv_lbl.add_theme_color_override("font_color", Color.GOLD)
		hbox.add_child(lv_lbl)

		## 描述
		var desc := Label.new()
		desc.text = u.get("desc", "")
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox.add_child(desc)

		## 费用按钮
		var btn := Button.new()
		btn.name = "UpgradeBtn"
		btn.custom_minimum_size = Vector2(0, 32)
		btn.pressed.connect(func(): _do_upgrade(id))
		vbox.add_child(btn)

	_refresh_buttons()

func _refresh() -> void:
	_gold_label.text = "💰 %d" % CurrencyManager.currency
	_total_label.text = "总等级：%d" % MetaProgression.total_levels()
	_refresh_buttons()

func _refresh_buttons() -> void:
	for panel in _grid.get_children():
		var vbox := panel.get_child(0) as VBoxContainer
		if not vbox:
			continue
		## 找到 UpgradeBtn 和 LvLabel
		var btn: Button = vbox.find_child("UpgradeBtn", false, false)
		var lv_lbl: Label = vbox.find_child("LvLabel", false, false)
		if not btn:
			continue
		## 找到对应 id
		var id := ""
		for key in MetaProgression.upgrades:
			var u: Dictionary = MetaProgression.upgrades[key]
			if btn.text != "" and btn.text.begins_with(u.get("name", key)):
				id = key
				break
		## 如果没找到，用索引匹配（简单粗暴）
		if id == "":
			var panels := _grid.get_children()
			for i in range(panels.size()):
				if panels[i] == panel:
					var keys := MetaProgression.upgrades.keys()
					if i < keys.size():
						id = keys[i]
					break
		if id == "":
			continue
		var u: Dictionary = MetaProgression.upgrades[id]
		var lv: int = u.get("lv", 0)
		var max_lv: int = u.get("max_lv", 99)
		if lv >= max_lv:
			btn.text = "已满"
			btn.disabled = true
		else:
			var cost: int = MetaProgression.get_cost(id)
			btn.text = "升级（-%d）" % cost
			btn.disabled = not CurrencyManager.has_enough(cost)

func _do_upgrade(id: String) -> void:
	if MetaProgression.upgrade(id):
		upgrade_done.emit()
		_refresh()

func _on_upgraded(_id: String) -> void:
	_refresh()

func _make_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.12, 0.15, 0.92)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.3, 0.6, 1.0, 0.5)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	return sb
