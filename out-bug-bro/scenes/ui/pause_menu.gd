## 暂停菜单 — ESC 触发，暗化背景 + 毛玻璃弹窗
extends Control

@onready var _overlay: ColorRect = $Overlay
@onready var _panel: PanelContainer = $Panel
@onready var _resume_btn: Button = $Panel/VBox/ResumeBtn
@onready var _menu_btn: Button = $Panel/VBox/MenuBtn


func _ready() -> void:
	visible = false
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	# 毛玻璃暗色样式
	_apply_style()
	_resume_btn.pressed.connect(_on_resume)
	_menu_btn.pressed.connect(_on_menu)
	# 按钮动效
	for btn: Button in [_resume_btn, _menu_btn]:
		btn.mouse_entered.connect(_on_hover.bind(btn, true))
		btn.mouse_exited.connect(_on_hover.bind(btn, false))


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if GameManager.state == GameManager.State.PLAYING:
			_pause()
		elif GameManager.state == GameManager.State.PAUSED:
			_resume()


func _pause() -> void:
	GameManager.pause()
	visible = true


func _resume() -> void:
	GameManager.play()
	visible = false


func _on_resume() -> void:
	_resume()


func _on_menu() -> void:
	# 保存当前游戏
	SaveManager.save_run()
	GameManager.play()
	GameManager.change_scene("res://scenes/main_menu.tscn")


func _on_hover(btn: Button, entering: bool) -> void:
	var target := Vector2(1.08, 1.08) if entering else Vector2.ONE
	var dur := 0.2 if entering else 0.15
	var tw := create_tween()
	tw.tween_property(btn, "scale", target, dur).set_ease(Tween.EASE_OUT if entering else Tween.EASE_IN)


func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.15, 0.92)
	style.border_color = Color(0.3, 0.3, 0.5, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_offset = Vector2(0, 4)
	style.shadow_size = 8
	_panel.add_theme_stylebox_override("panel", style)
