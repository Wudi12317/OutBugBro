## 开场动画 — 游戏名 → 开发者 → 主菜单
## 黑底白字，缓入缓出，全程可跳过（任意键/鼠标）
extends Control

const GAME_TITLE := "逃离虫哥"
const DEV_NAME := "Castorice_rz"

const FADE_IN := 0.8    ## 文字缓入时长
const FADE_OUT := 0.8    ## 文字缓出时长
const HOLD_TITLE := 1.5  ## 游戏名停留
const HOLD_DEV := 1.2    ## 开发者名停留
const DEV_FADE_IN := 0.6
const DEV_FADE_OUT := 0.6

var _bg: ColorRect
var _title_label: Label
var _dev_label: Label
var _active_tweens: Array[Tween] = []
var _skipped: bool = false
var _sequence_done: bool = false


func _ready() -> void:
	# 全屏
	get_window().mode = Window.MODE_FULLSCREEN
	# 构建 UI
	_build_ui()
	# 启动动画序列
	_play_sequence()


func _input(event: InputEvent) -> void:
	if _sequence_done:
		return
	# 任意键/鼠标跳过
	if (event is InputEventKey and event.pressed) or \
	   (event is InputEventMouseButton and event.pressed):
		_skip()


func _build_ui() -> void:
	# 全屏黑底
	_bg = ColorRect.new()
	_bg.color = Color.BLACK
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	# 居中容器
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)

	# 游戏名
	_title_label = Label.new()
	_title_label.text = GAME_TITLE
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 72)
	_title_label.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0, 0.0))
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_title_label)

	# 间隔
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)

	# 开发者名
	_dev_label = Label.new()
	_dev_label.text = DEV_NAME
	_dev_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dev_label.add_theme_font_size_override("font_size", 32)
	_dev_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7, 0.0))
	_dev_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_dev_label)


func _play_sequence() -> void:
	# —— 游戏名缓入 ——
	if _skipped:
		return
	var tw1 := create_tween()
	_active_tweens.append(tw1)
	tw1.set_ease(Tween.EASE_OUT)
	tw1.set_trans(Tween.TRANS_SINE)
	tw1.tween_property(_title_label, "theme_override_colors/font_color:a", 1.0, FADE_IN)
	await tw1.finished

	# —— 游戏名停留 ——
	if _skipped:
		return
	await get_tree().create_timer(HOLD_TITLE).timeout

	# —— 游戏名缓出 ——
	if _skipped:
		return
	var tw2 := create_tween()
	_active_tweens.append(tw2)
	tw2.set_ease(Tween.EASE_IN)
	tw2.set_trans(Tween.TRANS_SINE)
	tw2.tween_property(_title_label, "theme_override_colors/font_color:a", 0.0, FADE_OUT)
	await tw2.finished

	# —— 短暂黑屏过渡 ——
	if _skipped:
		return
	await get_tree().create_timer(0.3).timeout

	# —— 开发者名缓入 ——
	if _skipped:
		return
	var tw3 := create_tween()
	_active_tweens.append(tw3)
	tw3.set_ease(Tween.EASE_OUT)
	tw3.set_trans(Tween.TRANS_SINE)
	tw3.tween_property(_dev_label, "theme_override_colors/font_color:a", 1.0, DEV_FADE_IN)
	await tw3.finished

	# —— 开发者名停留 ——
	if _skipped:
		return
	await get_tree().create_timer(HOLD_DEV).timeout

	# —— 开发者名缓出 ——
	if _skipped:
		return
	var tw4 := create_tween()
	_active_tweens.append(tw4)
	tw4.set_ease(Tween.EASE_IN)
	tw4.set_trans(Tween.TRANS_SINE)
	tw4.tween_property(_dev_label, "theme_override_colors/font_color:a", 0.0, DEV_FADE_OUT)
	await tw4.finished

	# —— 进主菜单 ——
	_go_to_menu()


func _skip() -> void:
	_skipped = true
	for tw in _active_tweens:
		if tw.is_valid():
			tw.kill()
	_active_tweens.clear()
	_go_to_menu()


func _go_to_menu() -> void:
	if _sequence_done:
		return
	_sequence_done = true
	GameManager.change_scene("res://scenes/main_menu.tscn")
