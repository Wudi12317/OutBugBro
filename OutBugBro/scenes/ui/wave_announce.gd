## 波次公告 — 屏幕中央大字提示波次信息 + 清波奖励
class_name WaveAnnounce
extends Control

@onready var _title: Label = %AnnounceTitle
@onready var _sub: Label = %AnnounceSub
@onready var _bonus: Label = %BonusLabel

var _spawner: EnemySpawner = null
var _tween: Tween = null


func _ready() -> void:
	# 初始隐藏
	modulate.a = 0.0
	await get_tree().process_frame
	_bind_spawner()


func _bind_spawner() -> void:
	_spawner = _find_spawner()
	if not _spawner:
		get_tree().node_added.connect(_on_node_added)
		return
	_spawner.wave_changed.connect(_on_wave_changed)
	_spawner.wave_break.connect(_on_wave_break)
	_spawner.wave_bonus.connect(_on_wave_bonus)
	# Boss 波公告
	EventBus.listen("boss_wave_announce", _on_boss_wave)


func _find_spawner() -> EnemySpawner:
	var nodes := get_tree().get_nodes_in_group("spawners")
	if nodes.size() > 0:
		return nodes[0] as EnemySpawner
	return null


func _on_node_added(node: Node) -> void:
	if node.is_in_group("spawners"):
		_spawner = node as EnemySpawner
		_spawner.wave_changed.connect(_on_wave_changed)
		_spawner.wave_break.connect(_on_wave_break)
		_spawner.wave_bonus.connect(_on_wave_bonus)
		get_tree().node_added.disconnect(_on_node_added)


## 新波次开始 → 大字公告
func _on_wave_changed(wave_num: int) -> void:
	var phase_name := _spawner.config.get_phase_name(wave_num)
	var phase_color := _spawner.config.get_phase_color(wave_num)
	_title.text = "⚔ 第 %d 波 ⚔" % wave_num
	_title.add_theme_color_override("font_color", phase_color)
	_sub.text = "— %s —" % phase_name
	_sub.add_theme_color_override("font_color", phase_color)
	_bonus.visible = false
	_animate_in()


## 休息期开始 → 倒计时提示
func _on_wave_break(secs: float) -> void:
	_title.text = "休息"
	_title.add_theme_color_override("font_color", Color.GREEN)
	_sub.text = "%.0f 秒后下一波" % secs
	_sub.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5, 1))
	_bonus.visible = false
	_animate_in()


## 清波奖励
func _on_wave_bonus(gold: int) -> void:
	_bonus.visible = true
	_bonus.text = "💰 +%d 清波奖励!" % gold


## 公告动画：淡入 → 停留 → 淡出
func _animate_in() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.3)
	_tween.tween_interval(1.2)
	_tween.tween_property(self, "modulate:a", 0.0, 0.5)


## Boss 波公告
func _on_boss_wave(wave_num: Variant) -> void:
	var w: int = int(wave_num) if wave_num is float else wave_num
	_title.text = "💀 大虫来袭 💀"
	_title.add_theme_color_override("font_color", Color.RED)
	_sub.text = "— 第 %d 波 —" % w
	_sub.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	_bonus.visible = false
	_animate_in()
