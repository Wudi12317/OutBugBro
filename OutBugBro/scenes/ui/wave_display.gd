## 波次显示 — 监听 EnemySpawner + 倒计时 + 难度阶段 + 掉落率 + 敌人数
extends PanelContainer

@onready var _label: Label = %WaveLabel
@onready var _timer_label: Label = %TimerLabel
@onready var _phase_label: Label = %PhaseLabel
@onready var _drop_label: Label = %DropLabel
@onready var _enemy_label: Label = %EnemyLabel

var _spawner: EnemySpawner = null


func _ready() -> void:
	await get_tree().process_frame
	_bind_spawner()


func _process(_delta: float) -> void:
	if _spawner and is_instance_valid(_spawner):
		var remaining := _spawner.get_wave_time_remaining()
		if _spawner.phase == EnemySpawner.Phase.BREAK:
			_timer_label.text = " 休整%d s" % ceili(remaining)
			_timer_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			_timer_label.text = " %ds" % ceili(remaining)
			_timer_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
		# 实时更新敌人数和掉落率
		var enemies := get_tree().get_nodes_in_group("enemies")
		_enemy_label.text = "👾%d" % enemies.size()
		if _spawner.config:
			var drop_pct := _spawner.config.get_drop_chance(_spawner.wave) * 100.0
			_drop_label.text = "📦%.0f%%" % drop_pct


func _bind_spawner() -> void:
	_spawner = _find_spawner()
	if not _spawner:
		get_tree().node_added.connect(_on_node_added)
		return
	_spawner.wave_changed.connect(_on_wave_changed)
	_on_wave_changed(_spawner.wave)


func _find_spawner() -> EnemySpawner:
	var nodes := get_tree().get_nodes_in_group("spawners")
	if nodes.size() > 0:
		return nodes[0] as EnemySpawner
	return null


func _on_node_added(node: Node) -> void:
	if node.is_in_group("spawners"):
		_spawner = node as EnemySpawner
		_spawner.wave_changed.connect(_on_wave_changed)
		_on_wave_changed(_spawner.wave)
		get_tree().node_added.disconnect(_on_node_added)


func _on_wave_changed(wave_num: int) -> void:
	if _spawner and _spawner.is_boss_wave():
		_label.text = "💀 大虫来袭 第 %d 波" % wave_num
		_phase_label.text = "大虫"
		_phase_label.add_theme_color_override("font_color", Color.RED)
	else:
		_label.text = "第 %d 波" % wave_num
		if _spawner and _spawner.config:
			_phase_label.text = _spawner.config.get_phase_name(wave_num)
			_phase_label.add_theme_color_override("font_color", _spawner.config.get_phase_color(wave_num))
	if _spawner and _spawner.config:
		var drop_pct := _spawner.config.get_drop_chance(wave_num) * 100.0
		_drop_label.text = "📦%.0f%%" % drop_pct
