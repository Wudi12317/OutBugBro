## 爆裂弹爆炸特效 — 扩散圆环后消失
extends Node2D

var radius: float = 50.0
var color: Color = Color(1.0, 0.6, 0.2, 0.5)
var _lifetime: float = 0.3
var _elapsed: float = 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _lifetime:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var ratio := _elapsed / _lifetime
	var r := radius * ratio
	var alpha := 1.0 - ratio
	draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, alpha * color.a))
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(color.r, color.g, color.b, alpha * 0.8), 2.0)
