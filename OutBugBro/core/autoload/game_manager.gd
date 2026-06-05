## 游戏管理器 [Autoload]
## 全局状态、暂停、场景切换
extends Node

enum State { MENU, PLAYING, PAUSED }

var state: State = State.MENU
var challenge_mode: bool = false  ## 挑战模式：仅允许技能1(shield)和Q(head_oil)，自动解锁


func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	_setup_tooltip_theme()


func play() -> void:
	state = State.PLAYING
	get_tree().paused = false
	EventBus.dispatch("game_state_changed", state)


func pause() -> void:
	state = State.PAUSED
	get_tree().paused = true
	EventBus.dispatch("game_state_changed", state)


func change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)


## 全局 Tooltip 毛玻璃暗色遮罩样式
func _setup_tooltip_theme() -> void:
	var default_theme := ThemeDB.get_default_theme()
	# TooltipPanel: 暗色毛玻璃圆角底
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.08, 0.08, 0.15, 0.92)
	panel.border_color = Color(0.35, 0.35, 0.5, 0.7)
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(0)
	panel.set_content_margin_all(8)
	panel.shadow_color = Color(0, 0, 0, 0.3)
	panel.shadow_offset = Vector2(2, 2)
	panel.shadow_size = 4
	default_theme.set_stylebox("panel", "TooltipPanel", panel)
	# TooltipLabel: 浅色文字
	default_theme.set_color("font_color", "TooltipLabel", Color(0.9, 0.9, 0.95, 1.0))
	default_theme.set_font_size("font_size", "TooltipLabel", 14)
