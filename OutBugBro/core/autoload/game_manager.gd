## 游戏管理器 [Autoload]
## 全局状态、暂停、场景切换（含黑屏缓入缓出过渡）
extends Node

enum State { MENU, PLAYING, PAUSED }

var state: State = State.MENU
var challenge_mode: bool = false  ## 挑战模式：仅允许技能1(shield)和Q(head_oil)，自动解锁

## 过渡遮罩
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _fading: bool = false

const FADE_DURATION := 0.4  ## 缓入/缓出时长（秒）


func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	_setup_fade_overlay()
	_setup_tooltip_theme()


func play() -> void:
	state = State.PLAYING
	get_tree().paused = false
	EventBus.dispatch("game_state_changed", state)


func pause() -> void:
	state = State.PAUSED
	get_tree().paused = true
	EventBus.dispatch("game_state_changed", state)


## 带过渡的场景切换（黑屏缓入 → 切场景 → 黑屏缓出）
func change_scene(path: String) -> void:
	if _fading:
		return
	_fading = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(_fade_rect, "color:a", 1.0, FADE_DURATION)
	await tw.finished
	# 切场景
	get_tree().change_scene_to_file(path)
	# 等一帧让新场景渲染
	await get_tree().process_frame
	# 缓出黑屏
	var tw2 := create_tween()
	tw2.set_ease(Tween.EASE_OUT)
	tw2.set_trans(Tween.TRANS_SINE)
	tw2.tween_property(_fade_rect, "color:a", 0.0, FADE_DURATION)
	await tw2.finished
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fading = false


## 无过渡直接切场景（紧急用途）
func change_scene_instant(path: String) -> void:
	get_tree().change_scene_to_file(path)


func _setup_fade_overlay() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "FadeLayer"
	_fade_layer.layer = 9999  # 最高层
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.color = Color.BLACK
	_fade_rect.color.a = 0.0  # 初始透明
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.z_index = 9999
	_fade_layer.add_child(_fade_rect)


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
