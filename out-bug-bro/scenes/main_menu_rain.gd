## 雨层 — 仅负责绘制粒子雨（由 MainMenu 驱动数据）
extends Control

func _draw() -> void:
	var parent: Node = get_parent()
	if parent and parent.has_method("_draw_rain"):
		parent._draw_rain()
