## 新手引导 — 首次运行触发，F1 可重看
extends Control

signal tutorial_done

const STEPS := [
	{ "text": "逃离虫哥", "icon": "😡" },
	{ "text": "WASD 或方向键移动角色", "icon": "🎮" },
	{ "text": "鼠标左键射击，按住蓄力", "icon": "🖱️" },
	{ "text": "Q 键位移（鼠标方向），击杀减CD", "icon": "💨" },
	{ "text": "B 键打开/关闭背包", "icon": "🎒" },
	{ "text": "1-5 键使用技能，Shift 切换瞄准", "icon": "⚡" },
	{ "text": "击杀敌人，坚持更多波次！", "icon": "💀" },
]

var _current: int = 0
var _shown: bool = false

@onready var _text_label: Label = $CenterContainer/Panel/VBox/TextLabel
@onready var _icon_label: Label = $CenterContainer/Panel/VBox/IconLabel
@onready var _step_label: Label = $CenterContainer/Panel/VBox/BottomHBox/StepLabel
@onready var _panel: PanelContainer = $CenterContainer/Panel

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	## 首次运行检测：元进度总等级为 0 且未看过教程
	if not _has_seen():
		call_deferred("_start_tutorial")

func _input(event: InputEvent) -> void:
	if not _shown:
		return
	if event is InputEventKey and event.pressed:
		_next_step()
	elif event is InputEventMouseButton and event.pressed:
		_next_step()

func _start_tutorial() -> void:
	_current = 0
	_shown = true
	visible = true
	_show_step()
	get_tree().paused = false  ## 教程中不暂停

func _show_step() -> void:
	if _current >= STEPS.size():
		_end_tutorial()
		return
	var step: Dictionary = STEPS[_current]
	_icon_label.text = step.get("icon", "💡")
	_text_label.text = step.get("text", "")
	_step_label.text = "%d/%d" % [_current + 1, STEPS.size()]
	## 动画：面板弹出
	if _panel:
		_panel.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)

func _next_step() -> void:
	_current += 1
	_show_step()

func _end_tutorial() -> void:
	_shown = false
	visible = false
	_save_seen()
	tutorial_done.emit()

func _has_seen() -> bool:
	return FileAccess.file_exists("user://tutorial_seen.cfg")

func _save_seen() -> void:
	var file := FileAccess.open("user://tutorial_seen.cfg", FileAccess.WRITE)
	if file:
		file.store_string("1")
		file.close()

## 外部调用：F1 重看教程
func show_tutorial() -> void:
	if _shown:
		return
	_start_tutorial()
