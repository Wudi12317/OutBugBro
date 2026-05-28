## 状态效果栏 — 右上角显示激活效果，点击查看详情
class_name StatusEffectBar
extends Control

const SLOT_SCENE := preload("res://scenes/ui/effect_slot.tscn")

var _slots: Array[EffectSlot] = []
var _selected_slot: EffectSlot = null

@onready var _effect_container: HFlowContainer = %EffectContainer
@onready var _detail_panel: PanelContainer = %DetailPanel
@onready var _eff_name: Label = %EffName
@onready var _eff_attrs: Label = %EffAttrs
@onready var _eff_time: Label = %EffTime


func _ready() -> void:
	EffectManager.changed.connect(_refresh)


## 刷新效果栏
func _refresh() -> void:
	var effects := EffectManager.get_active()
	# 动态增减格子
	while _slots.size() > effects.size():
		var s: EffectSlot = _slots.pop_back()
		s.queue_free()
	while _slots.size() < effects.size():
		var s: EffectSlot = SLOT_SCENE.instantiate()
		s.effect_clicked.connect(_on_effect_clicked)
		_effect_container.add_child(s)
		_slots.append(s)
	# 填充数据
	for i in range(effects.size()):
		_slots[i].setup(effects[i].effect, effects[i].remaining)
	# 刷新详情
	if _selected_slot and EffectManager.has_effect(_selected_slot.effect_data.id):
		_show_detail(_selected_slot.effect_data, _selected_slot.remaining)
	else:
		_hide_detail()


## 点击效果图标
func _on_effect_clicked(slot: EffectSlot) -> void:
	_selected_slot = slot
	_show_detail(slot.effect_data, slot.remaining)


## 显示详情
func _show_detail(data: EffectData, time: float) -> void:
	_detail_panel.visible = true
	_eff_name.text = data.id
	# 属性改变
	var active := data.get_active_effects()
	var lines: PackedStringArray = []
	for key in active:
		lines.append("%s: %s%.1f" % [_attr_name(key), "+" if active[key] > 0 else "", active[key]])
	_eff_attrs.text = "\n".join(lines)
	# 剩余时间
	_eff_time.text = "永久" if time < 0 else "剩余: %.0fs" % time


## 隐藏详情
func _hide_detail() -> void:
	_detail_panel.visible = false
	_selected_slot = null


## 属性名中文映射
func _attr_name(key: String) -> String:
	match key:
		"hp_change": return "血量"
		"fire_rate_change": return "射速"
		"damage_change": return "伤害"
		"damage_mult_change": return "伤害倍率"
		"crit_rate_change": return "暴击率"
		"crit_damage_change": return "暴击伤害"
		"defense_change": return "防御力"
		"move_speed_change": return "移动速度"
		_: return key
