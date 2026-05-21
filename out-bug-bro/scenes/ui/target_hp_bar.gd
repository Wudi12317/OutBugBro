## 左下角目标血条 — 灰底白条，扣血暗红过渡，加血淡灰过渡+绿色边框
extends MarginContainer

var _bar: ProgressBar
var _label: Label
var _damage_bar: ProgressBar
var _heal_bar: ProgressBar
var _heal_border: PanelContainer
var _prev_hp: int = -1
var _damage_tween: Tween = null
var _heal_tween: Tween = null
var _border_tween: Tween = null


func _ready() -> void:
	# 定位：技能栏正上方，居中
	anchor_left = 0.5
	anchor_top = 1.0
	anchor_right = 0.5
	anchor_bottom = 1.0
	offset_left = -140.0
	offset_top = -130.0
	offset_right = 140.0
	offset_bottom = -76.0

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)

	_label = Label.new()
	_label.name = "HpLabel"
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1, 1))
	vbox.add_child(_label)

	var bar_container := Control.new()
	bar_container.custom_minimum_size = Vector2(0, 22)
	bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(bar_container)

	# 绿色边框
	var border_style := StyleBoxFlat.new()
	border_style.bg_color = Color(0, 0, 0, 0)
	border_style.border_color = Color(0.3, 1.0, 0.4, 1)
	border_style.set_border_width_all(2)
	border_style.set_corner_radius_all(5)
	_heal_border = PanelContainer.new()
	_heal_border.name = "HealBorder"
	_heal_border.anchor_left = 0.0
	_heal_border.anchor_top = 0.0
	_heal_border.anchor_right = 1.0
	_heal_border.anchor_bottom = 1.0
	_heal_border.offset_left = 0.0
	_heal_border.offset_top = 0.0
	_heal_border.offset_right = 0.0
	_heal_border.offset_bottom = 0.0
	_heal_border.add_theme_stylebox_override("panel", border_style)
	_heal_border.modulate.a = 0.0
	bar_container.add_child(_heal_border)

	var bg_style := _make_style(Color(0.22, 0.22, 0.26, 0.9))

	# 暗红扣血条
	_damage_bar = ProgressBar.new()
	_damage_bar.name = "DamageBar"
	_damage_bar.anchor_left = 0.0
	_damage_bar.anchor_top = 0.0
	_damage_bar.anchor_right = 1.0
	_damage_bar.anchor_bottom = 1.0
	_damage_bar.offset_left = 0.0
	_damage_bar.offset_top = 0.0
	_damage_bar.offset_right = 0.0
	_damage_bar.offset_bottom = 0.0
	_damage_bar.max_value = 1.0
	_damage_bar.show_percentage = false
	_damage_bar.add_theme_stylebox_override("background", bg_style)
	_damage_bar.add_theme_stylebox_override("fill", _make_style(Color(0.55, 0.12, 0.12, 0.85)))
	bar_container.add_child(_damage_bar)

	# 淡灰加血条
	_heal_bar = ProgressBar.new()
	_heal_bar.name = "HealBar"
	_heal_bar.anchor_left = 0.0
	_heal_bar.anchor_top = 0.0
	_heal_bar.anchor_right = 1.0
	_heal_bar.anchor_bottom = 1.0
	_heal_bar.offset_left = 0.0
	_heal_bar.offset_top = 0.0
	_heal_bar.offset_right = 0.0
	_heal_bar.offset_bottom = 0.0
	_heal_bar.max_value = 1.0
	_heal_bar.show_percentage = false
	_heal_bar.add_theme_stylebox_override("background", bg_style)
	_heal_bar.add_theme_stylebox_override("fill", _make_style(Color(0.65, 0.65, 0.68, 0.7)))
	bar_container.add_child(_heal_bar)

	# 白色主血条
	_bar = ProgressBar.new()
	_bar.name = "HpBar"
	_bar.anchor_left = 0.0
	_bar.anchor_top = 0.0
	_bar.anchor_right = 1.0
	_bar.anchor_bottom = 1.0
	_bar.offset_left = 0.0
	_bar.offset_top = 0.0
	_bar.offset_right = 0.0
	_bar.offset_bottom = 0.0
	_bar.max_value = 1.0
	_bar.show_percentage = false
	_bar.add_theme_stylebox_override("background", bg_style)
	_bar.add_theme_stylebox_override("fill", _make_style(Color(0.92, 0.92, 0.96, 1)))
	bar_container.add_child(_bar)

	_bar.visible = false
	_label.visible = false
	EventBus.listen("target_hp_changed", _on_hp_changed)


func _make_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(4)
	return s


func _on_hp_changed(data: Variant) -> void:
	if data is Dictionary:
		var hp: int = int(data.hp)
		var max_hp: int = int(data.max_hp)
		_bar.visible = true
		_label.visible = true
		_bar.max_value = float(max_hp)
		_bar.value = float(hp)
		_update_label(hp, max_hp)
		if _prev_hp >= 0:
			if hp < _prev_hp:
				_on_damage(float(_prev_hp), float(max_hp))
			elif hp > _prev_hp:
				_on_heal(float(hp), float(max_hp))
		_prev_hp = hp


func _on_damage(old_val: float, max_val: float) -> void:
	if not _damage_bar:
		return
	_damage_bar.max_value = max_val
	_damage_bar.value = old_val
	if _damage_tween and _damage_tween.is_valid():
		_damage_tween.kill()
	_damage_tween = create_tween()
	_damage_tween.tween_property(_damage_bar, "value", _bar.value, 0.6).set_ease(Tween.EASE_IN_OUT)


func _on_heal(new_val: float, max_val: float) -> void:
	if _heal_bar:
		_heal_bar.max_value = max_val
		_heal_bar.value = _bar.value
		if _heal_tween and _heal_tween.is_valid():
			_heal_tween.kill()
		_heal_tween = create_tween()
		_heal_tween.tween_property(_heal_bar, "value", new_val, 0.4).set_ease(Tween.EASE_IN_OUT)
	if _heal_border:
		if _border_tween and _border_tween.is_valid():
			_border_tween.kill()
		_heal_border.modulate.a = 1.0
		_border_tween = create_tween()
		_border_tween.tween_property(_heal_border, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN_OUT)


func _update_label(hp: int, max_hp: int) -> void:
	_label.text = "%d / %d" % [hp, max_hp]
