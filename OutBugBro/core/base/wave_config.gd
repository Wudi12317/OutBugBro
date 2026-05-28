## 波次配置 — 外部可调 Resource，所有数值在编辑器中调整
## 三阶段难度曲线: 轻松(1-3) → 普通(4-10) → 困难(11+)
class_name WaveConfig
extends Resource

@export_group("波次节奏")
@export var wave_duration: float = 25.0
@export var break_duration: float = 5.0    ## 波次间休息时间（秒）
@export var max_enemies: int = 30
@export var spawn_margin: float = 50.0
@export var wave_bonus_mult: int = 100     ## 清波奖励 = wave × 此值

@export_group("生成间隔")
@export var spawn_interval_base: float = 2.5
@export var spawn_interval_min: float = 0.3
@export var spawn_easy_reduction: float = 0.15
@export var spawn_mid_reduction: float = 0.3
@export var spawn_hard_reduction: float = 0.5

@export_group("难度阶段")
@export var easy_wave_max: int = 3
@export var hard_wave_start: int = 11
@export var extreme_wave_start: int = 15

@export_group("怪物属性")
@export var enemy_hp_base: int = 50
@export var enemy_hp_level_mult: float = 1.1
@export var enemy_atk_base: int = 2
@export var enemy_atk_easy: float = 0.5
@export var enemy_atk_mid: float = 1.0
@export var enemy_atk_hard: float = 1.5
@export var enemy_speed_base: float = 60.0
@export var enemy_speed_easy: float = 5.0
@export var enemy_speed_mid: float = 6.0
@export var enemy_speed_hard: float = 8.0
@export var enemy_interval_base: float = 3.0
@export var enemy_interval_min: float = 0.5
@export var enemy_interval_easy: float = 0.06
@export var enemy_interval_mid: float = 0.15
@export var enemy_interval_hard: float = 0.18
@export var enemy_hp_extreme_mult: float = 1.0   ## 极端阶段HP倍率(每波额外×此值)
@export var enemy_atk_extreme: float = 2.0
@export var enemy_speed_extreme: float = 5.0
@export var enemy_interval_extreme: float = 0.06
@export var spawn_extreme_reduction: float = 0.1
@export var enemy_speed_cap: float = 150.0  ## 怪物速度上限

@export_group("掉落")
@export var drop_base_chance: float = 0.50
@export var drop_per_wave: float = 0.03
@export var drop_cap: float = 0.85
@export var gold_per_level: int = 15


## 难度阶段名
func get_phase_name(wave: int) -> String:
	if wave <= easy_wave_max:
		return "轻松"
	elif wave < hard_wave_start:
		return "普通"
	elif wave < extreme_wave_start:
		return "困难"
	return "地狱"


## 阶段标识颜色
func get_phase_color(wave: int) -> Color:
	if wave <= easy_wave_max:
		return Color.GREEN
	elif wave < hard_wave_start:
		return Color.YELLOW
	elif wave < extreme_wave_start:
		return Color.RED
	return Color.DARK_RED


## 生成间隔（逐波递减）
func get_spawn_interval(wave: int) -> float:
	var interval := spawn_interval_base
	for w in range(1, wave):
		if w <= easy_wave_max:
			interval -= spawn_easy_reduction
		elif w < hard_wave_start:
			interval -= spawn_mid_reduction
		elif w < extreme_wave_start:
			interval -= spawn_hard_reduction
		else:
			interval -= spawn_extreme_reduction
	return maxf(spawn_interval_min, interval)


## 怪物 HP: base * sqrt(level) * mult (对数增长，后期不会爆炸)
func get_enemy_hp(level: int) -> int:
	return int(enemy_hp_base * sqrt(float(level)) * enemy_hp_level_mult)


## 怪物 ATK（逐波累加，极端阶段增长放缓）
func get_enemy_atk(level: int) -> int:
	var atk := float(enemy_atk_base)
	for w in range(1, level + 1):
		if w <= easy_wave_max:
			atk += enemy_atk_easy
		elif w < hard_wave_start:
			atk += enemy_atk_mid
		elif w < extreme_wave_start:
			atk += enemy_atk_hard
		else:
			atk += enemy_atk_extreme
	return maxi(1, int(atk))


## 怪物速度（逐波累加，有上限）
func get_enemy_speed(level: int) -> float:
	var spd := enemy_speed_base
	for w in range(1, level + 1):
		if w <= easy_wave_max:
			spd += enemy_speed_easy
		elif w < hard_wave_start:
			spd += enemy_speed_mid
		elif w < extreme_wave_start:
			spd += enemy_speed_hard
		else:
			spd += enemy_speed_extreme
	return minf(spd, enemy_speed_cap)


## 怪物攻击间隔（逐波递减，极端阶段放缓）
func get_enemy_attack_interval(level: int) -> float:
	var interval := enemy_interval_base
	for w in range(1, level + 1):
		if w <= easy_wave_max:
			interval -= enemy_interval_easy
		elif w < hard_wave_start:
			interval -= enemy_interval_mid
		elif w < extreme_wave_start:
			interval -= enemy_interval_hard
		else:
			interval -= enemy_interval_extreme
	return maxf(enemy_interval_min, interval)


## 掉落概率
func get_drop_chance(wave: int) -> float:
	return minf(drop_cap, drop_base_chance + float(wave) * drop_per_wave)
