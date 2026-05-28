## 暂停菜单 — ESC 触发，暗化背景 + iOS 弹窗
extends Control

@onready var _overlay: ColorRect = $Overlay
@onready var _panel: PanelContainer = $Panel
@onready var _resume_btn: Button = $Panel/VBox/ResumeBtn
@onready var _menu_btn: Button = $Panel/VBox/MenuBtn

func _ready() -> void:
	visible = false
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	_apply_style()
	_resume_btn.pressed.connect(_on_resume)
	_menu_btn.pressed.connect(_on_menu)
	# 按钮动效
	for btn: Button in [_resume_btn, _menu_btn]:
		btn.mouse_entered.connect(_on_hover.bind(btn, true))
		btn.mouse_exited.connect(_on_hover.bind(btn, false))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		# 背包打开时 ESC 只关背包，不触发暂停菜单
		var inv_nodes := get_tree().get_nodes_in_group("inventory_ui")
		for inv in inv_nodes:
			if inv.visible:
				return
		if visible:
			_on_resume()
		else:
			_show()

func _show() -> void:
	visible = true
	get_tree().paused = true
	UITheme.apply_iOS_style(_panel)

func _on_resume() -> void:
	visible = false
	get_tree().paused = false

func _on_menu() -> void:
	visible = false
	get_tree().paused = false
	SaveManager.reset_run()
	CurrencyManager.currency = 0
	GameManager.change_scene("res://scenes/main_menu.tscn")

func _on_hover(btn: Button, entering: bool) -> void:
	var target := Vector2(1.08, 1.08) if entering else Vector2.ONE
	var dur := 0.2 if entering else 0.15
	var tw := create_tween()
	tw.tween_property(btn, "scale", target, dur).set_ease(Tween.EASE_OUT)

func _apply_style() -> void:
	## 半透明暗化遮罩
	_overlay.color = Color(0, 0, 0, 0.85)
	## 面板 iOS 暗色 + 赛博朋克边框
	UITheme.apply_iOS_style(_panel)
	## 标题 label 赛博朋克色
	var title: Label = _panel.get_node_or_null("TitleLabel")
	if title:
		title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.85))
	## 按钮风格
	for btn in [_resume_btn, _menu_btn]:
		UITheme._apply_button_style(btn)
