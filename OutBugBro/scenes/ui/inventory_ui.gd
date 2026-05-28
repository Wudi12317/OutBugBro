## 背包 UI — 居中窗口式，左侧格子 + 右侧物品信息 + 货币 + 售卖
## 打开时暂停游戏，关闭时恢复
class_name InventoryUi
extends Control

const SLOT_SCENE := preload("res://scenes/ui/inventory_slot.tscn")

var _slots: Array[InventorySlot] = []
var _selected_slot: InventorySlot = null
var _prev_item_ids: PackedStringArray = []
var _is_pausing: bool = false  ## 背包是否导致了暂停

@onready var _grid: GridContainer = %Grid
@onready var _item_icon: TextureRect = %ItemIcon
@onready var _item_name: Label = %ItemName
@onready var _item_type: Label = %ItemType
@onready var _item_rarity: Label = %ItemRarity
@onready var _item_value: Label = %ItemValue
@onready var _item_desc: Label = %ItemDesc
@onready var _extra_title: Label = %ExtraTitle
@onready var _extra_info: Label = %ExtraInfo
@onready var _currency_label: Label = %CurrencyLabel
@onready var _close_btn: Button = %CloseBtn
@onready var _sell_section: VBoxContainer = %SellSection
@onready var _sell_count_label: Label = %SellCountLabel
@onready var _sell_max_label: Label = %SellMaxLabel
@onready var _sell_slider: HSlider = %SellSlider
@onready var _sell_price_label: Label = %SellPriceLabel
@onready var _sell_btn: Button = %SellBtn
@onready var _sell_sep: HSeparator = %HSep2
@onready var _use_btn: Button = %UseBtn
@onready var _bind_section: HBoxContainer = null  ## 动态创建


func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS  ## 暂停时仍接收输入
	add_to_group("inventory_ui")
	InventoryManager.changed.connect(_refresh)
	CurrencyManager.changed.connect(_update_currency)
	_ensureSlots(35)
	_close_btn.pressed.connect(_close)
	_sell_slider.value_changed.connect(_on_slider_changed)
	_sell_btn.pressed.connect(_on_sell)
	_use_btn.pressed.connect(_on_use)
	_update_currency()
	## iOS 暗色风
	_apply_iOS_style()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_B:
				if visible:
					_close()
				else:
					_open()
			KEY_ESCAPE:
				if visible:
					_close()


func _open() -> void:
	visible = true
	move_to_front()
	_refresh()
	# 仅在游戏进行中暂停（避免覆盖暂停菜单/死亡界面的暂停）
	if GameManager.state == GameManager.State.PLAYING:
		GameManager.pause()
		_is_pausing = true


func _close() -> void:
	visible = false
	if _is_pausing:
		GameManager.play()
		_is_pausing = false


## ============ 货币 ============

func _update_currency() -> void:
	if _currency_label:
		_currency_label.text = "💰 %d" % CurrencyManager.currency


## ============ 售卖区域 ============

func _update_sell_section() -> void:
	if not _selected_slot or not _selected_slot.item_data or _selected_slot.item_data.value <= 0:
		_sell_section.visible = false
		_sell_sep.visible = false
		return
	_sell_section.visible = true
	_sell_sep.visible = true
	var max_count := _get_count_for(_selected_slot.item_data)
	_sell_slider.min_value = 1.0
	_sell_slider.max_value = float(maxi(1, max_count))
	if _sell_slider.value > _sell_slider.max_value:
		_sell_slider.value = _sell_slider.max_value
	_sell_max_label.text = "/ %d" % max_count
	_refresh_sell_count()


func _on_slider_changed(_value: float) -> void:
	_refresh_sell_count()


func _refresh_sell_count() -> void:
	var amount: int = int(_sell_slider.value)
	_sell_count_label.text = "数量: %d" % amount
	if _selected_slot and _selected_slot.item_data:
		var total := _selected_slot.item_data.value * amount
		_sell_price_label.text = "💰 %d" % total


func _on_sell() -> void:
	if not _selected_slot or not _selected_slot.item_data:
		return
	var data: ItemData = _selected_slot.item_data
	var amount := int(_sell_slider.value)
	amount = mini(amount, _get_count_for(data))
	if amount <= 0:
		return
	CurrencyManager.add(data.value * amount)
	InventoryManager.remove_item(data, amount)
	_sell_slider.value = 1.0
	_refresh()


## 使用消耗品
func _on_use() -> void:
	if not _selected_slot or not _selected_slot.item_data:
		return
	var data: ItemData = _selected_slot.item_data
	if InventoryManager.use_item(data):
		_refresh()


func _get_count_for(data: ItemData) -> int:
	for entry in InventoryManager.get_items():
		if entry.data.id == data.id:
			return entry.count
	return 0


## ============ 刷新背包 ============

func _refresh() -> void:
	var items := InventoryManager.get_items()
	_ensureSlots(items.size())
	var new_ids: PackedStringArray = []
	for entry in items:
		new_ids.append(entry.data.id)
	for i in range(items.size()):
		var is_new: bool = (i >= _prev_item_ids.size() or _prev_item_ids[i] != items[i].data.id)
		_slots[i].set_item(items[i].data, items[i].count, is_new)
	for i in range(items.size(), _slots.size()):
		_slots[i].clear()
	_prev_item_ids = new_ids
	if _selected_slot and _selected_slot.item_data:
		_show_info(_selected_slot.item_data)
	else:
		_clear_info()


func _ensureSlots(needed: int) -> void:
	var target := maxi(35, ceili(needed / 7.0) * 7)
	while _slots.size() < target:
		var slot: InventorySlot = SLOT_SCENE.instantiate()
		slot.slot_clicked.connect(_on_slot_clicked)
		_grid.add_child(slot)
		_slots.append(slot)


func _on_slot_clicked(slot: InventorySlot) -> void:
	_selected_slot = slot
	if slot.item_data:
		_show_info(slot.item_data)
	else:
		_clear_info()


## ============ 物品信息 ============

func _show_info(data: ItemData) -> void:
	_item_icon.texture = data.icon
	_item_name.text = data.name
	_item_name.add_theme_color_override("font_color", data.get_rarity_color())
	_item_type.text = "类型: %s" % _type_name(data.type)
	_item_rarity.text = "品质: %s" % _rarity_name(data.rarity)
	_item_value.text = "价值: 💰%d" % data.value
	_item_desc.text = data.desc
	# 掉落概率
	var drop_pct := _get_drop_chance(data.id)
	if drop_pct > 0:
		_item_desc.text += "\n掉落率: %.1f%%" % (drop_pct * 100)
	# 额外信息
	if data is ConsumableItemData:
		_extra_title.visible = true
		_extra_info.visible = true
		_extra_title.text = "效果:"
		_extra_info.text = _describe_effects(data.effect_ids)
		_use_btn.visible = true
		_show_bind_section(data)
	elif data is MaterialItemData:
		_extra_title.visible = true
		_extra_info.visible = true
		_extra_title.text = "获得途径:"
		_extra_info.text = ", ".join(data.sources)
		_use_btn.visible = false
	else:
		_extra_title.visible = false
		_extra_info.visible = false
		_use_btn.visible = false
	_update_sell_section()


func _clear_info() -> void:
	_item_icon.texture = null
	_item_name.text = ""
	_item_type.text = ""
	_item_rarity.text = ""
	_item_value.text = ""
	_item_desc.text = ""
	_extra_title.visible = false
	_extra_info.visible = false
	_use_btn.visible = false
	_hide_bind_section()
	_sell_section.visible = false
	_sell_sep.visible = false


func _type_name(t: ItemData.ItemType) -> String:
	match t:
		ItemData.ItemType.CONSUMABLE: return "消耗品"
		ItemData.ItemType.MATERIAL: return "材料"
		ItemData.ItemType.COLLECTIBLE: return "收藏品"
		_: return "未知"


func _rarity_name(r: int) -> String:
	const NAMES = ["普通", "精良", "稀有", "史诗", "传说", "神话"]
	return NAMES[mini(r, NAMES.size() - 1)]


## 描述消耗品效果（中文翻译属性名）
func _describe_effects(effect_ids: PackedStringArray) -> String:
	var lines: PackedStringArray = []
	for eid in effect_ids:
		var eff: EffectData = EffectManager.get_effect_by_id(eid)
		if not eff:
			lines.append(eid)
			continue
		var parts: PackedStringArray = []
		var active := eff.get_active_effects()
		for key in active:
			var val: float = active[key]
			var sign := "+" if val > 0 else ""
			parts.append("%s%s%.1f" % [_attr_label(key), sign, val])
		if parts.is_empty():
			lines.append(eid)
		else:
			lines.append(" ".join(parts))
	return ", ".join(lines)


## 效果属性名中文映射
func _attr_label(key: String) -> String:
	match key:
		"heal_amount": return "回血"
		"hp_change": return "血量上限"
		"fire_rate_change": return "射速"
		"damage_change": return "伤害"
		"damage_mult_change": return "伤害倍率"
		"crit_rate_change": return "暴击率"
		"crit_damage_change": return "暴击伤害"
		"defense_change": return "防御"
		"move_speed_change": return "移速"
		_: return key


## 获取物品掉落概率（从掉落表查询）
func _get_drop_chance(item_id: String) -> float:
	# 尝试从场上敌人获取掉落表
	var enemies := get_tree().get_nodes_in_group("enemies")
	if not enemies.is_empty():
		var e: Node = enemies[0]
		if "drop_table" in e and e.drop_table is DropTable:
			return e.drop_table.get_chance_for(item_id)
	return 0.0


## ============ 消耗品快捷栏绑定 ============

## 显示绑定按钮区
func _show_bind_section(data: ConsumableItemData) -> void:
	_hide_bind_section()
	_bind_section = HBoxContainer.new()
	_bind_section.name = "BindSection"
	_bind_section.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl := Label.new()
	lbl.text = "快捷栏:"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bind_section.add_child(lbl)
	for i in range(5):
		var btn := Button.new()
		var item_keys := ["8", "9", "0", "F1", "F2"]
		var key_str: String = item_keys[i] if i < item_keys.size() else "?"
		var is_bound := InventoryManager.consumable_bindings[i] == data.id
		btn.text = key_str
		btn.custom_minimum_size = Vector2(36, 28)
		btn.focus_mode = Control.FOCUS_NONE
		if is_bound:
			btn.add_theme_color_override("font_color", Color.CYAN)
			btn.tooltip_text = "已绑定，点击取消"
		else:
			btn.tooltip_text = "设为快捷%s" % key_str
		btn.pressed.connect(_on_bind_slot.bind(i, data.id, is_bound))
		_bind_section.add_child(btn)
	# 插到 UseBtn 之后
	var right: VBoxContainer = _use_btn.get_parent()
	var idx := right.get_children().find(_use_btn) + 1
	right.add_child(_bind_section)
	right.move_child(_bind_section, idx)


func _hide_bind_section() -> void:
	if _bind_section and is_instance_valid(_bind_section):
		_bind_section.queue_free()
	_bind_section = null


func _on_bind_slot(slot_idx: int, item_id: String, is_bound: bool) -> void:
	if is_bound:
		InventoryManager.set_consumable_binding(slot_idx, "")
	else:
		InventoryManager.set_consumable_binding(slot_idx, item_id)
	# 刷新绑定按钮状态
	var data: ItemData = _selected_slot.item_data if _selected_slot else null
	if data and data is ConsumableItemData:
		_show_bind_section(data as ConsumableItemData)

## =========== iOS 暗色风格 ============

func _apply_iOS_style() -> void:
	UITheme.apply_iOS_style(self)
