## 连击显示 — 屏幕中偏右显示连击数字 + 掉率加成
extends Control

@onready var _combo_label: Label = %ComboLabel
@onready var _bonus_label: Label = %BonusLabel

var _tween: Tween = null


func _ready() -> void:
	visible = false
	ComboManager.combo_changed.connect(_on_combo_changed)
	ComboManager.combo_expired.connect(_on_combo_expired)


func _on_combo_changed(combo: int) -> void:
	visible = true
	_combo_label.text = "%d 连击!" % combo
	var bonus_pct := ComboManager.get_drop_bonus() * 100.0
	_bonus_label.text = "📦+%d%%" % int(bonus_pct)
	# 颜色随连击数变化
	var color := Color.GREEN
	if combo >= 10:
		color = Color.GOLD
	elif combo >= 5:
		color = Color.CYAN
	elif combo >= 3:
		color = Color.GREEN
	_combo_label.add_theme_color_override("font_color", color)
	# 弹跳动画
	if _tween and _tween.is_valid():
		_tween.kill()
	scale = Vector2(1.3, 1.3)
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)


func _on_combo_expired() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	_tween.tween_callback(func():
		visible = false
		modulate.a = 1.0
	)
