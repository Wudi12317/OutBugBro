## 右下角属性面板 — 显示属性 + 升级按钮
extends PanelContainer

## 按钮名 → 统计键名
const BTN_MAP := {
	"HpBtn": "max_hp",
	"AtkBtn": "damage",
	"DefBtn": "defense",
	"CritBtn": "crit_rate",
	"CdBtn": "crit_damage",
	"SpdBtn": "fire_rate",
}

var _stats: PlayerStats

@onready var _currency_label: Label = %CurrencyLabel
@onready var _hp: Label = $MarginContainer/VBox/HpRow/HpLabel
@onready var _atk: Label = $MarginContainer/VBox/AtkRow/AtkLabel
@onready var _def: Label = $MarginContainer/VBox/DefRow/DefLabel
@onready var _crit: Label = $MarginContainer/VBox/CritRow/CritLabel
@onready var _crit_dmg: Label = $MarginContainer/VBox/CdRow/CdLabel
@onready var _speed: Label = $MarginContainer/VBox/SpdRow/SpdLabel

@onready var _hp_btn: Button = %HpBtn
@onready var _atk_btn: Button = %AtkBtn
@onready var _def_btn: Button = %DefBtn
@onready var _crit_btn: Button = %CritBtn
@onready var _cd_btn: Button = %CdBtn
@onready var _spd_btn: Button = %SpdBtn


func _ready() -> void:
	# 绑定升级按钮
	_hp_btn.pressed.connect(func(): _try_upgrade("max_hp"))
	_atk_btn.pressed.connect(func(): _try_upgrade("damage"))
	_def_btn.pressed.connect(func(): _try_upgrade("defense"))
	_crit_btn.pressed.connect(func(): _try_upgrade("crit_rate"))
	_cd_btn.pressed.connect(func(): _try_upgrade("crit_damage"))
	_spd_btn.pressed.connect(func(): _try_upgrade("fire_rate"))
	# 货币变化时刷新按钮状态
	CurrencyManager.changed.connect(_refresh_btns)
	# 等待 Target 出现
	await get_tree().process_frame
	_bind_target()


func _bind_target() -> void:
	var target := get_tree().get_first_node_in_group("targets")
	if not target:
		get_tree().node_added.connect(_on_node_added)
		return
	_stats = target.get_node("PlayerStats")
	_stats.stats_changed.connect(_refresh)
	var health: HealthComponent = target.get_node("HealthComponent")
	health.health_changed.connect(func(_c, _m): _refresh())
	EffectManager.changed.connect(_refresh)
	_refresh()


func _on_node_added(node: Node) -> void:
	if node.is_in_group("targets") and node.has_node("PlayerStats"):
		_stats = node.get_node("PlayerStats")
		_stats.stats_changed.connect(_refresh)
		var health: HealthComponent = node.get_node("HealthComponent")
		health.health_changed.connect(func(_c, _m): _refresh())
		EffectManager.changed.connect(_refresh)
		_refresh()
		get_tree().node_added.disconnect(_on_node_added)


func _try_upgrade(stat: String) -> void:
	if _stats:
		_stats.upgrade(stat)


func _refresh() -> void:
	if not _stats or not is_instance_valid(_stats):
		return
	var health: HealthComponent = _stats.get_parent().get_node("HealthComponent")
	# 应急修理 buff 时属性字体变金色
	var is_golden := EffectManager.has_effect("emergency_buff")
	var font_color := Color.GOLD if is_golden else Color.WHITE
	_hp.text = "❤ HP: %d/%d" % [health.hp, _stats.get_max_hp()]
	_hp.add_theme_color_override("font_color", font_color)
	_atk.text = "⚔ ATK: %d" % _stats.get_damage()
	_atk.add_theme_color_override("font_color", font_color)
	_def.text = "🛡 DEF: %d (-%d伤)" % [_stats.get_defense(), _stats.get_defense() / 8]
	_def.add_theme_color_override("font_color", font_color)
	_crit.text = "💥 CRIT: %.0f%%" % (_stats.get_crit_rate() * 100.0)
	_crit.add_theme_color_override("font_color", font_color)
	_crit_dmg.text = "💥 CD: %.0f%%" % (_stats.get_crit_damage() * 100.0)
	_crit_dmg.add_theme_color_override("font_color", font_color)
	_speed.text = "🔥 射速: %.1f/s" % _stats.get_fire_rate()
	_speed.add_theme_color_override("font_color", font_color)
	_refresh_btns()


func _refresh_btns() -> void:
	if not _stats or not is_instance_valid(_stats):
		return
	_currency_label.text = "💰 %d" % CurrencyManager.currency
	_hp_btn.text = "💰%d" % _stats.get_upgrade_cost("max_hp")
	_atk_btn.text = "💰%d" % _stats.get_upgrade_cost("damage")
	_def_btn.text = "💰%d" % _stats.get_upgrade_cost("defense")
	_crit_btn.text = "💰%d" % _stats.get_upgrade_cost("crit_rate")
	_cd_btn.text = "💰%d" % _stats.get_upgrade_cost("crit_damage")
	_spd_btn.text = "💰%d" % _stats.get_upgrade_cost("fire_rate")
	# 金币不足时禁用按钮
	_hp_btn.disabled = not CurrencyManager.has_enough(_stats.get_upgrade_cost("max_hp"))
	_atk_btn.disabled = not CurrencyManager.has_enough(_stats.get_upgrade_cost("damage"))
	_def_btn.disabled = not CurrencyManager.has_enough(_stats.get_upgrade_cost("defense"))
	_crit_btn.disabled = not CurrencyManager.has_enough(_stats.get_upgrade_cost("crit_rate"))
	_cd_btn.disabled = not CurrencyManager.has_enough(_stats.get_upgrade_cost("crit_damage"))
	_spd_btn.disabled = not CurrencyManager.has_enough(_stats.get_upgrade_cost("fire_rate"))
