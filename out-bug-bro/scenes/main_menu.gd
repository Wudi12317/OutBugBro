## 主菜单 — iOS 暗色风 + 粒子雨 + 呼吸标题
extends Control

@onready var _title: Label = %Title
@onready var _high_score: Label = %HighScore
@onready var _start_btn: Button = %StartBtn
@onready var _continue_btn: Button = %ContinueBtn
@onready var _intro_btn: Button = %IntroBtn
@onready var _about_btn: Button = %AboutBtn
@onready var _quit_btn: Button = %QuitBtn
@onready var _dialog: PanelContainer = %OverwriteDialog
@onready var _overlay: ColorRect = %Overlay
@onready var _overwrite_btn: Button = %OverwriteBtn
@onready var _new_game_btn: Button = %NewGameBtn
@onready var _cancel_btn: Button = %CancelBtn
@onready var _intro_panel: PanelContainer = %IntroPanel
@onready var _about_panel: PanelContainer = %AboutPanel
@onready var _rain_layer: Control = %RainLayer

var _title_time: float = 0.0
var _rain_particles: Array[Dictionary] = []
var _lightning_timer: float = 0.0
var _lightning_flash: float = 0.0
var _current_popup: String = ""  # "intro" / "about" / "dialog" / ""


func _ready() -> void:
	# 高评分显示
	_high_score.text = SaveManager.get_high_score_text()
	# 继续游戏按钮（无存档时禁用）
	_continue_btn.disabled = not SaveManager.has_save()
	_continue_btn.visible = SaveManager.has_save()
	# 按钮动效
	for btn: Button in [_start_btn, _continue_btn, _intro_btn, _about_btn, _quit_btn]:
		btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
		btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))
		_apply_main_btn_style(btn)
	# 弹窗毛玻璃暗色样式
	_apply_dialog_style(_dialog)
	_apply_dialog_style(_intro_panel)
	_apply_dialog_style(_about_panel)
	# 粒子雨初始化
	_init_rain()


func _process(delta: float) -> void:
	# 标题呼吸效果
	_title_time += delta
	var breath := 0.6 + 0.4 * (0.5 + 0.5 * sin(_title_time * 2.5))
	_title.modulate.a = breath
	_title.scale = Vector2(0.98 + 0.02 * sin(_title_time * 2.5),
		0.98 + 0.02 * sin(_title_time * 2.5))
	# 粒子雨更新
	_update_rain(delta)
	# 闪电
	_lightning_timer -= delta
	if _lightning_timer <= 0.0:
		_lightning_timer = randf_range(5.0, 12.0)
		_lightning_flash = 0.6
	if _lightning_flash > 0.0:
		_lightning_flash -= delta * 3.0
	_rain_layer.queue_redraw()


## ============ 粒子雨绘制（在 RainLayer 上） ============

func _init_rain() -> void:
	_rain_particles.clear()
	var w := _rain_layer.size.x if _rain_layer.size.x > 0 else 1152.0
	var h := _rain_layer.size.y if _rain_layer.size.y > 0 else 648.0
	for i in range(60):
		_rain_particles.append({
			"x": randf() * w,
			"y": randf() * h,
			"speed": randf_range(200.0, 500.0),
			"alpha": randf_range(0.15, 0.55),
		})


func _update_rain(delta: float) -> void:
	var w := _rain_layer.size.x if _rain_layer.size.x > 0 else 1152.0
	var h := _rain_layer.size.y if _rain_layer.size.y > 0 else 648.0
	for p in _rain_particles:
		p.y += p.speed * delta
		if p.y > h + 20.0:
			p.y = -10.0
			p.x = randf() * w
			p.speed = randf_range(200.0, 500.0)
			p.alpha = randf_range(0.15, 0.55)


## RainLayer 的自定义绘制
func _draw_rain() -> void:
	var h := _rain_layer.size.y if _rain_layer.size.y > 0 else 648.0
	for p in _rain_particles:
		var alpha: float = p.alpha * (1.0 - float(p.y) / h * 0.5)
		var col := Color(0.5, 0.5, 0.7, alpha)
		# 拖尾线
		var tail_len: float = p.speed * 0.08 * (0.5 + p.alpha)
		_rain_layer.draw_line(Vector2(p.x, p.y), Vector2(p.x, p.y + tail_len), col, 1.5)
	# 闪电闪光
	if _lightning_flash > 0.0:
		_rain_layer.draw_rect(Rect2(Vector2.ZERO, _rain_layer.size),
			Color(0.7, 0.7, 1.0, _lightning_flash * 0.15))


# ============ 按钮动效 ============

func _on_btn_hover(btn: Button, entered: bool) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT if entered else Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK if entered else Tween.TRANS_LINEAR)
	tween.tween_property(btn, "scale", Vector2(1.08, 1.08) if entered else Vector2.ONE, 0.2)


# ============ 弹窗管理 ============

func _show_popup(popup_name: String) -> void:
	_close_all_popups()
	_current_popup = popup_name
	_overlay.visible = true
	match popup_name:
		"intro":
			_intro_panel.visible = true
		"about":
			_about_panel.visible = true
		"dialog":
			_dialog.visible = true


func _close_popup() -> void:
	_overlay.visible = false
	_intro_panel.visible = false
	_about_panel.visible = false
	_dialog.visible = false
	_current_popup = ""


func _close_all_popups() -> void:
	_overlay.visible = false
	_intro_panel.visible = false
	_about_panel.visible = false
	_dialog.visible = false


func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_popup()


# ============ 按钮事件 ============

func _on_start_btn_pressed() -> void:
	if SaveManager.has_save():
		_show_popup("dialog")
	else:
		_start_new_game()


func _on_continue_btn_pressed() -> void:
	SaveManager.clear_runtime()  # 先清空再加载存档
	SaveManager._pending_load = true
	GameManager.state = GameManager.State.PLAYING
	GameManager.change_scene("res://scenes/main.tscn")


func _on_intro_btn_pressed() -> void:
	_show_popup("intro")


func _on_about_btn_pressed() -> void:
	_show_popup("about")


func _on_quit_btn_pressed() -> void:
	get_tree().quit()


func _on_close_intro() -> void:
	_close_popup()


func _on_close_about() -> void:
	_close_popup()


# ============ 覆盖存档对话框 ============

func _on_overwrite_btn_pressed() -> void:
	_close_popup()
	# 覆盖原存档 = 继续游戏（加载存档）
	SaveManager.clear_runtime()
	SaveManager._pending_load = true
	GameManager.state = GameManager.State.PLAYING
	GameManager.change_scene("res://scenes/main.tscn")


func _on_new_game_btn_pressed() -> void:
	SaveManager.full_reset()
	_close_popup()
	_start_new_game()


func _on_cancel_btn_pressed() -> void:
	_close_popup()


func _start_new_game() -> void:
	GameManager.state = GameManager.State.PLAYING
	GameManager.change_scene("res://scenes/main.tscn")


## 按钮毛玻璃圆角样式
func _apply_btn_style(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.22, 0.8)
	style.border_color = Color(0.35, 0.35, 0.5, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	# hover
	var hover := style.duplicate()
	hover.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	hover.border_color = Color(0.5, 0.5, 0.7, 0.8)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", style)


## 主菜单按钮毛玻璃圆角样式（更宽的内边距）
func _apply_main_btn_style(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.85)
	style.border_color = Color(0.35, 0.35, 0.5, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	var hover := style.duplicate()
	hover.bg_color = Color(0.18, 0.18, 0.28, 0.95)
	hover.border_color = Color(0.5, 0.5, 0.7, 0.9)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", style)


## 弹窗毛玻璃暗色样式
func _apply_dialog_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.15, 0.92)
	style.border_color = Color(0.3, 0.3, 0.5, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_offset = Vector2(0, 4)
	style.shadow_size = 8
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	# 按钮也加圆角样式
	for child in panel.get_children():
		if child is VBoxContainer:
			for sub in child.get_children():
				if sub is Button:
					_apply_btn_style(sub)
