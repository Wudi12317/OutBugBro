## 背包格子 — 物品贴图居中，下方数字，背景=品质颜色
class_name InventorySlot
extends Control

signal slot_clicked(slot: InventorySlot)

var item_data: ItemData = null  ## 当前物品数据
var count: int = 0              ## 物品数量

@onready var _panel: Panel = $Panel
@onready var _icon: TextureRect = $Icon
@onready var _count_label: Label = $CountLabel
var _style: StyleBoxFlat


func _ready() -> void:
	# 初始化背景样式（每实例独立副本）
	_style = StyleBoxFlat.new()
	_style.bg_color = Color(0.15, 0.15, 0.18, 0.9)
	_style.border_color = Color(0.35, 0.35, 0.4)
	_style.set_border_width_all(2)
	_style.set_corner_radius_all(4)
	_panel.add_theme_stylebox_override("panel", _style)
	# 数量文字样式
	_count_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_count_label.add_theme_constant_override("shadow_offset_x", 1)
	_count_label.add_theme_constant_override("shadow_offset_y", 1)
	_count_label.add_theme_font_size_override("font_size", 12)
	_count_label.visible = false


## 设置物品（flash=true 时播放白色缓入缓出动效）
func set_item(data: ItemData, amount: int = 1, flash: bool = false) -> void:
	item_data = data
	count = amount
	_icon.texture = data.icon if data else null
	_icon.visible = data != null
	_count_label.text = str(amount) if amount > 1 else ""
	_count_label.visible = amount > 1
	# 悬停提示物品名
	tooltip_text = data.name if data else ""
	# 背景染品质色（半透明底 + 实色边框）
	var rc: Color = data.get_rarity_color() if data else Color(0.15, 0.15, 0.18, 0.9)
	_style.bg_color = Color(rc.r, rc.g, rc.b, 0.35)
	_style.border_color = rc
	# 白色缓入缓出闪动
	if flash and data:
		var tw := create_tween()
		_style.bg_color = Color.WHITE
		tw.tween_property(_style, "bg_color", Color(rc.r, rc.g, rc.b, 0.35), 0.4).set_ease(Tween.EASE_IN_OUT)


## 清空格子
func clear() -> void:
	item_data = null
	count = 0
	_icon.visible = false
	_count_label.visible = false
	tooltip_text = ""
	_style.bg_color = Color(0.15, 0.15, 0.18, 0.9)
	_style.border_color = Color(0.35, 0.35, 0.4)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_clicked.emit(self)
