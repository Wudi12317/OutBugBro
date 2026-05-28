## 死亡界面 — 评分 + 统计 + 复活/重开/主菜单
extends Control

const REVIVE_COST: int = 1000

@onready var _grade_label: Label = $Center/VBox/GradeLabel
@onready var _kills_label: Label = $Center/VBox/StatsBox/KillsLabel
@onready var _waves_label: Label = $Center/VBox/StatsBox/WavesLabel
@onready var _stars_label: Label = $Center/VBox/StarsLabel
@onready var _revive_btn: Button = $Center/VBox/BtnVBox/ReviveBtn

var _grade_color: Color = Color.WHITE
var _is_rainbow: bool = false
var _rainbow_time: float = 0.0
var _meta_panel: Control = null
var _meta_go_menu: bool = false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.listen("game_over", _on_game_over)
	UITheme.apply_iOS_style(self)


func _process(delta: float) -> void:
	if not visible:
		return
	# 炫彩效果
	if _is_rainbow:
		_rainbow_time += delta
		var hue := fmod(_rainbow_time * 0.3, 1.0)
		_grade_label.add_theme_color_override("font_color", Color.from_hsv(hue, 0.8, 1.0))
		if _stars_label.text != "":
			_stars_label.add_theme_color_override("font_color", Color.from_hsv(fmod(hue + 0.3, 1.0), 0.8, 1.0))
	# 更新复活按钮状态
	if _revive_btn:
		var can_afford: bool = CurrencyManager.currency >= REVIVE_COST
		_revive_btn.disabled = not can_afford
		_revive_btn.text = "💎 复活 (%d金)" % REVIVE_COST
		if can_afford:
			_revive_btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5, 1))
		else:
			_revive_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.5))


func _on_game_over(_data: Variant = null) -> void:
	# 关闭背包
	var inv := get_tree().get_nodes_in_group("inventory_ui")
	if not inv.is_empty():
		inv[0].visible = false
	# 置顶：确保覆盖所有UI
	z_index = 500
	get_parent().move_child(self, get_parent().get_child_count() - 1)

	var spawners := get_tree().get_nodes_in_group("spawners")
	var waves: int = 1
	if not spawners.is_empty():
		waves = spawners[0].wave
	var kills: int = SaveManager.run_kills

	SaveManager.update_high_score(waves, kills)
	## 不在 game_over 时 reset_run()，否则金币清零无法复活
	## reset_run 移到 _on_restart_pressed / _on_menu_pressed

	var grade_info := SaveManager.calculate_grade(waves)
	_grade_color = grade_info.color
	_is_rainbow = grade_info.stars > 0

	_grade_label.text = grade_info.grade
	if not _is_rainbow:
		_grade_label.add_theme_color_override("font_color", _grade_color)
	_kills_label.text = "击败怪物: %d" % kills
	_waves_label.text = "坚持波次: %d" % waves
	if grade_info.stars > 0:
		_stars_label.text = "⭐x%d" % grade_info.stars
		if not _is_rainbow:
			_stars_label.add_theme_color_override("font_color", _grade_color)
	else:
		_stars_label.text = ""

	visible = true
	get_tree().paused = true

	## 先只显示死亡界面，元进度面板延迟到用户操作后显示


func _on_revive_pressed() -> void:
	if not CurrencyManager.spend(REVIVE_COST):
		return
	get_tree().paused = false
	visible = false
	# 复活玩家
	EventBus.dispatch("player_revive")


func _on_restart_pressed() -> void:
	## 隐藏死亡界面，显示元进度升级面板
	visible = false
	_show_meta_panel()


func _on_menu_pressed() -> void:
	## 返回主菜单也先走元进度升级
	visible = false
	_meta_go_menu = true
	_show_meta_panel()

## 显示元进度面板
func _show_meta_panel() -> void:
	if _meta_panel:
		return
	var scene := load("res://scenes/ui/meta_upgrades.tscn") as PackedScene
	if not scene:
		push_warning("[DeathScreen] 未找到 meta_upgrades.tscn")
		return
	_meta_panel = scene.instantiate()
	_meta_panel.start_game.connect(_on_meta_start_game)
	_meta_panel.upgrade_done.connect(_on_meta_upgrade_done)
	get_parent().add_child(_meta_panel)
	_meta_panel.visible = true

func _on_meta_start_game() -> void:
	## 隐藏所有面板，重新开始或返回主菜单
	if _meta_panel:
		_meta_panel.queue_free()
		_meta_panel = null
	visible = false
	get_tree().paused = false
	SaveManager.reset_run()
	if _meta_go_menu:
		_meta_go_menu = false
		CurrencyManager.currency = 0
		GameManager.change_scene("res://scenes/main_menu.tscn")
	else:
		## 保留金币（用于下次升级）
		get_tree().reload_current_scene()

func _on_meta_upgrade_done() -> void:
	## 升级后刷新复活按钮状态
	pass
