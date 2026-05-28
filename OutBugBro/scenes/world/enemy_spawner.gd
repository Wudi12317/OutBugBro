## 怪物生成器 — 波次状态机 + Boss + 多怪物类型
## 支持编辑器拖入 .tscn 场景，未设置时回退程序化创建
class_name EnemySpawner
extends Node2D

enum Phase { FIGHTING, BREAK }

@export var config: WaveConfig
@export var elite_chance: float = 0.10
@export var boss_first_wave: int = 2
@export var boss_interval_min: int = 7
@export var boss_interval_max: int = 10
## 各类型敌人场景（编辑器拖入 .tscn，留空则程序化创建）
@export var enemy_scene: PackedScene
@export var fast_enemy_scene: PackedScene
@export var tank_enemy_scene: PackedScene
@export var ranged_enemy_scene: PackedScene
@export var boss_scene: PackedScene

var wave: int = 1
var phase: Phase = Phase.FIGHTING
var _spawn_timer: float = 0.0
var _wave_timer: float = 0.0
var _break_timer: float = 0.0
var _spawn_interval: float
var _enemies_at_wave_start: int = 0
var _enemies_alive: int = 0
var _is_boss_wave: bool = false
var _next_boss_wave: int = 0
var _boss_spawned: bool = false

signal wave_changed(wave_num: int)
signal wave_break(break_secs: float)
signal wave_bonus(gold: int)


func _ready() -> void:
	if not config:
		config = preload("res://data/wave_config.tres")
	add_to_group("spawners")
	if SaveManager._pending_load:
		SaveManager._pending_load = false
		SaveManager.load_run()
		wave = SaveManager.get_saved_wave()
	_spawn_interval = config.get_spawn_interval(wave)
	_calc_next_boss_wave()


func get_wave_time_remaining() -> float:
	if phase == Phase.BREAK:
		return maxf(0.0, _break_timer)
	return maxf(0.0, config.wave_duration - _wave_timer)


func get_enemies_alive() -> int:
	return _enemies_alive


func is_boss_wave() -> bool:
	return _is_boss_wave


func _process(delta: float) -> void:
	match phase:
		Phase.FIGHTING: _process_fighting(delta)
		Phase.BREAK: _process_break(delta)


func _process_fighting(delta: float) -> void:
	if _is_boss_wave:
		if not _boss_spawned:
			_spawn_boss()
		return
	_wave_timer += delta
	if _wave_timer >= config.wave_duration:
		_enter_break()
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0:
		_try_spawn()
		_spawn_interval = config.get_spawn_interval(wave)
		_spawn_timer = _spawn_interval


func _process_break(delta: float) -> void:
	_break_timer -= delta
	if _break_timer <= 0:
		_enter_fighting()


func _enter_break() -> void:
	phase = Phase.BREAK
	_break_timer = config.break_duration
	var gold := wave * config.wave_bonus_mult
	CurrencyManager.add(gold)
	wave_bonus.emit(gold)
	wave_break.emit(config.break_duration)
	SaveManager.save_run()


func _enter_fighting() -> void:
	wave += 1
	phase = Phase.FIGHTING
	_wave_timer = 0.0
	_spawn_interval = config.get_spawn_interval(wave)
	_is_boss_wave = (wave == _next_boss_wave)
	_boss_spawned = false
	wave_changed.emit(wave)


func _spawn_boss() -> void:
	_boss_spawned = true
	_enemies_alive = 0
	var boss: Enemy = _spawn_enemy("Boss")
	boss.global_position = _random_offscreen_pos()
	boss.level = wave
	boss.wave_config = config
	boss.died.connect(_on_boss_died)
	get_parent().add_child(boss)
	EventBus.dispatch("boss_wave_announce", wave)


func _on_boss_died(_boss: Boss) -> void:
	_calc_next_boss_wave()
	_enter_break()


func _try_spawn() -> void:
	if _enemies_alive >= config.max_enemies:
		return
	var enemy: Enemy = _pick_enemy_type()
	enemy.global_position = _random_offscreen_pos()
	enemy.level = wave
	enemy.wave_config = config
	if randf() < elite_chance:
		enemy.is_elite = true
	enemy.died.connect(_on_enemy_died)
	get_parent().add_child(enemy)
	_enemies_alive += 1


func _pick_enemy_type() -> Enemy:
	var roll := randf()
	if wave < 5:
		return _spawn_enemy("Enemy") if roll < 0.7 else _spawn_enemy("FastEnemy")
	elif wave < 10:
		if roll < 0.4: return _spawn_enemy("Enemy")
		elif roll < 0.65: return _spawn_enemy("FastEnemy")
		elif roll < 0.85: return _spawn_enemy("TankEnemy")
		else: return _spawn_enemy("RangedEnemy")
	else:
		if roll < 0.25: return _spawn_enemy("Enemy")
		elif roll < 0.5: return _spawn_enemy("FastEnemy")
		elif roll < 0.75: return _spawn_enemy("TankEnemy")
		else: return _spawn_enemy("RangedEnemy")


## 按类型创建敌人，优先使用 .tscn 场景，回退程序化创建
func _spawn_enemy(cls_name: String) -> Enemy:
	var scene_map := {
		"Enemy": enemy_scene if enemy_scene else load("res://scenes/enemies/enemy_a.tscn"),
		"FastEnemy": fast_enemy_scene if fast_enemy_scene else load("res://scenes/enemies/fast_enemy.tscn"),
		"TankEnemy": tank_enemy_scene if tank_enemy_scene else load("res://scenes/enemies/tank_enemy.tscn"),
		"RangedEnemy": ranged_enemy_scene if ranged_enemy_scene else load("res://scenes/enemies/ranged_enemy.tscn"),
		"Boss": boss_scene if boss_scene else load("res://scenes/enemies/boss.tscn"),
	}
	var scene: PackedScene = scene_map.get(cls_name)
	if scene:
		return scene.instantiate()
	# 回退：程序化创建
	match cls_name:
		"Enemy": return Enemy.new()
		"FastEnemy": return FastEnemy.new()
		"TankEnemy": return TankEnemy.new()
		"RangedEnemy": return RangedEnemy.new()
		"Boss": return Boss.new()
	return Enemy.new()


func _on_enemy_died(_enemy: Enemy) -> void:
	_enemies_alive = maxi(0, _enemies_alive - 1)


func _calc_next_boss_wave() -> void:
	var interval := boss_interval_min + randi() % (boss_interval_max - boss_interval_min + 1)
	_next_boss_wave = wave + interval
	if _next_boss_wave < boss_first_wave:
		_next_boss_wave = boss_first_wave


func _random_offscreen_pos() -> Vector2:
	return ArenaBounds.random_position_offscreen()
