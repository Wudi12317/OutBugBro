# GameHUD — UI 层主脚本：教程管理 + F3 重看 + 位移 CD 显示 + Tab 升级面板
extends CanvasLayer

var _dash_label: Label = null
var _upgrade_panel: Control = null
var _upgrade_overlay: ColorRect = null

func _ready() -> void:
	# 延迟一帧再检测教程（确保 MetaProgression 已加载）
	call_deferred("_try_show_tutorial")
	# 创建位移 CD 显示
	_create_dash_label()
	# 创建升级面板（无按钮，Tab 键打开）
	_create_upgrade_ui()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		# F3 重看教程
		var overlay = get_node_or_null("TutorialOverlay")
		if overlay and overlay.has_method("show_tutorial"):
			overlay.show_tutorial()
	# Tab 键切换升级面板
	if event.is_action_pressed("toggle_upgrades"):
		_toggle_upgrade_panel()

func _process(_delta: float) -> void:
	_update_dash_label()

func _try_show_tutorial() -> void:
	# 首次运行检测：元进度总等级为 0 且未看过教程
	var total := 0
	if MetaProgression.has_method("total_levels"):
		total = MetaProgression.total_levels()
	if total == 0:
		var overlay = get_node_or_null("TutorialOverlay")
		if overlay and overlay.has_method("show_tutorial"):
			overlay.show_tutorial()

func _create_dash_label() -> void:
	_dash_label = Label.new()
	_dash_label.name = "DashCD"
	_dash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dash_label.add_theme_font_size_override("font_size", 14)
	_dash_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	_dash_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_dash_label.add_theme_constant_override("shadow_offset_x", 1)
	_dash_label.add_theme_constant_override("shadow_offset_y", 1)
	# 定位：技能栏左上方
	_dash_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_dash_label.offset_left = 20.0
	_dash_label.offset_top = -110.0
	_dash_label.offset_right = 100.0
	_dash_label.offset_bottom = -90.0
	_dash_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dash_label.z_index = 10
	add_child(_dash_label)

func _update_dash_label() -> void:
	if not _dash_label:
		return
	var targets := get_tree().get_nodes_in_group("player")
	if targets.is_empty():
		_dash_label.visible = false
		return
	var player = targets[0]
	if not player.has_node("DashComponent"):
		_dash_label.visible = false
		return
	var dash: DashComponent = player.get_node("DashComponent")
	_dash_label.visible = true
	if dash._is_dashing:
		_dash_label.text = "Q 位移中"
		_dash_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	elif dash._cooldown_remaining > 0:
		_dash_label.text = "Q 位移 %.0fs" % dash._cooldown_remaining
		_dash_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	else:
		_dash_label.text = "Q 位移 就绪"
		_dash_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))

# ============ 升级面板 ============

func _create_upgrade_ui() -> void:
	# 半透明遮罩
	_upgrade_overlay = ColorRect.new()
	_upgrade_overlay.name = "UpgradeOverlay"
	_upgrade_overlay.color = Color(0, 0, 0, 0.5)
	_upgrade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_upgrade_overlay.z_index = 90
	_upgrade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_upgrade_overlay.visible = false
	_upgrade_overlay.gui_input.connect(_on_overlay_input)
	add_child(_upgrade_overlay)

	# 升级面板（从场景加载）
	var scene := load("res://scenes/ui/meta_upgrades.tscn") as PackedScene
	if scene:
		_upgrade_panel = scene.instantiate()
		_upgrade_panel.name = "InGameUpgradePanel"
		_upgrade_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		_upgrade_panel.z_index = 100
		_upgrade_panel.visible = false
		# 连接信号（面板 _ready 后才有效）
		_upgrade_panel.start_game.connect(_on_panel_start_game)
		_upgrade_panel.panel_closed.connect(_on_panel_closed)
		add_child(_upgrade_panel)

func _toggle_upgrade_panel() -> void:
	if not _upgrade_panel:
		return
	if _upgrade_panel.visible:
		_close_upgrade_panel()
	else:
		_open_upgrade_panel()

func _open_upgrade_panel() -> void:
	if not _upgrade_panel:
		return
	_upgrade_overlay.visible = true
	_upgrade_panel.show_in_game()

func _close_upgrade_panel() -> void:
	if not _upgrade_panel:
		return
	_upgrade_panel.hide_panel()
	_upgrade_overlay.visible = false

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_upgrade_panel()

func _on_panel_start_game() -> void:
	_close_upgrade_panel()

func _on_panel_closed() -> void:
	_upgrade_overlay.visible = false
