## 游戏结束画面
class_name GameOver
extends Control


func _ready() -> void:
	visible = false
	# 暂停时仍需接收输入
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.listen("game_over", _on_game_over)


func _on_game_over(_data: Variant = null) -> void:
	visible = true
	get_tree().paused = true


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().paused = false
		get_tree().reload_current_scene()
