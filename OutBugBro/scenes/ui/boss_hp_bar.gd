## Boss 血条 UI — 屏幕顶部，红底
## 使用 boss_hp_bar.tscn 场景节点，不再程序化构建
extends MarginContainer

@onready var _bar: ProgressBar = %BossHpBar if has_node("VBox/BarContainer/BossHpBar") else $VBox/BarContainer/BossHpBar
@onready var _damage_bar: ProgressBar = $VBox/BarContainer/BossDamageBar if has_node("VBox/BarContainer/BossDamageBar") else null
@onready var _label: Label = $VBox/HpLabel if has_node("VBox/HpLabel") else null
@onready var _name_label: Label = $VBox/NameLabel if has_node("VBox/NameLabel") else null

var _prev_hp: int = -1
var _damage_tween: Tween = null


func _ready() -> void:
	# 如果 .tscn 未提供节点，回退程序化构建
	if not _bar:
		_build_fallback()
	visible = false
	EventBus.listen("boss_spawned", _on_boss_spawned)
	EventBus.listen("boss_hp_changed", _on_hp_changed)
	EventBus.listen("boss_died", _on_boss_died)


## 程序化构建回退（当 .tscn 节点不存在时）
func _build_fallback() -> void:
	anchor_left = 0.2
	anchor_top = 0.0
	anchor_right = 0.8
	anchor_bottom = 0.0
	offset_top = 40.0
	offset_bottom = 96.0
	add_theme_constant_override("margin_left", 8)
	add_theme_constant_override("margin_right", 8)
	add_theme_constant_override("margin_top", 4)
	add_theme_constant_override("margin_bottom", 4)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 18)
	_name_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1))
	_name_label.text = "BOSS"
	vbox.add_child(_name_label)

	var bar_container := Control.new()
	bar_container.custom_minimum_size = Vector2(0, 28)
	bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(bar_container)

	var bg_style := _make_style(Color(0.35, 0.08, 0.08, 0.9))
	var dmg_style := _make_style(Color(0.5, 0.08, 0.08, 0.9))
	var fill_style := _make_style(Color(0.9, 0.15, 0.15, 1))

	_damage_bar = ProgressBar.new()
	_damage_bar.name = "BossDamageBar"
	_damage_bar.anchor_right = 1.0
	_damage_bar.anchor_bottom = 1.0
	_damage_bar.max_value = 1.0
	_damage_bar.show_percentage = false
	_damage_bar.add_theme_stylebox_override("background", bg_style)
	_damage_bar.add_theme_stylebox_override("fill", dmg_style)
	bar_container.add_child(_damage_bar)

	_bar = ProgressBar.new()
	_bar.name = "BossHpBar"
	_bar.anchor_right = 1.0
	_bar.anchor_bottom = 1.0
	_bar.max_value = 1.0
	_bar.show_percentage = false
	_bar.add_theme_stylebox_override("background", bg_style)
	_bar.add_theme_stylebox_override("fill", fill_style)
	bar_container.add_child(_bar)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_color_override("font_color", Color(1, 0.7, 0.7, 1))
	_label.text = "0 / 0"
	vbox.add_child(_label)


func _make_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(4)
	return s


func _on_boss_spawned(data: Variant) -> void:
	if data is Dictionary:
		visible = true
		_bar.max_value = float(data.max_hp)
		_bar.value = float(data.hp)
		_damage_bar.max_value = float(data.max_hp)
		_damage_bar.value = float(data.hp)
		_prev_hp = int(data.hp)
		_update_label(int(data.hp), int(data.max_hp))


func _on_hp_changed(data: Variant) -> void:
	if data is Dictionary:
		var hp: int = int(data.hp)
		var max_hp: int = int(data.max_hp)
		_bar.max_value = float(max_hp)
		_bar.value = float(hp)
		_update_label(hp, max_hp)
		if _prev_hp >= 0 and hp < _prev_hp:
			_on_damage(float(_prev_hp), float(max_hp))
		_prev_hp = hp


func _on_boss_died(_data: Variant = null) -> void:
	visible = false
	_prev_hp = -1


func _on_damage(old_val: float, max_val: float) -> void:
	if not _damage_bar:
		return
	_damage_bar.max_value = max_val
	_damage_bar.value = old_val
	if _damage_tween and _damage_tween.is_valid():
		_damage_tween.kill()
	_damage_tween = create_tween()
	_damage_tween.tween_property(_damage_bar, "value", _bar.value, 0.6).set_ease(Tween.EASE_IN_OUT)


func _update_label(hp: int, max_hp: int) -> void:
	_label.text = "%d / %d" % [hp, max_hp]
