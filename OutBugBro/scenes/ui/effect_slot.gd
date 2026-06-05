## 效果格子 — 右上角状态栏的小图标，点击查看详情
class_name EffectSlot
extends Control

signal effect_clicked(slot: EffectSlot)

var effect_data: EffectData = null
var remaining: float = -1.0  ## 剩余时间，-1=永久

@onready var _icon: TextureRect = $Icon
@onready var _timer_label: Label = $TimerLabel
var _style: StyleBoxFlat


func _ready() -> void:
	_style = StyleBoxFlat.new()
	_style.bg_color = Color(0.15, 0.15, 0.18, 0.85)
	_style.set_border_width_all(1)
	_style.set_corner_radius_all(0)
	$Panel.add_theme_stylebox_override("panel", _style)
	_timer_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_timer_label.add_theme_constant_override("shadow_offset_x", 1)
	_timer_label.add_theme_constant_override("shadow_offset_y", 1)
	_timer_label.add_theme_font_size_override("font_size", 10)


## 设置效果
func setup(data: EffectData, time: float = -1.0) -> void:
	effect_data = data
	remaining = time
	_icon.texture = data.icon if data else null
	_icon.visible = data != null
	_update_timer()


## 更新倒计时显示（每帧从 EffectManager 取真实 remaining）
func _process(_delta: float) -> void:
	if not effect_data:
		return
	# 从 EffectManager 同步真实剩余时间
	for entry in EffectManager.get_active():
		if entry.effect.id == effect_data.id:
			remaining = entry.remaining
			break
	_update_timer()


func _update_timer() -> void:
	if remaining < 0 or not effect_data:
		_timer_label.visible = false
		return
	_timer_label.visible = true
	_timer_label.text = "%.0fs" % remaining
	# 边框变红 + 闪烁提示即将消失
	if remaining < 3.0:
		_style.border_color = Color.RED
		modulate.a = 0.4 + 0.6 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005))
	else:
		_style.border_color = Color(0.4, 0.4, 0.45)
		modulate.a = 1.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		effect_clicked.emit(self)
