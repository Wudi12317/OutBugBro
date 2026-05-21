## 掉落指示器 — 在怪物死亡位置显示浮动文字（金币 + 物品品质色）
## 品质视觉反馈: 传说→金色光柱, 史诗→紫色脉冲, 稀有→青色闪烁, 精良→绿色小字
## 场景方式创建，符合项目规则
class_name DropIndicator
extends Node2D

const FLOAT_DURATION := 1.5
const FLOAT_DISTANCE := 50.0

@onready var _gold_label: Label = $GoldLabel
@onready var _item_label: Label = $ItemLabel


## 在指定位置生成掉落信息
static func spawn(parent: Node, pos: Vector2, gold: int, item: ItemData = null) -> void:
	if not parent or not is_instance_valid(parent):
		return
	var scene := preload("res://scenes/world/drop_indicator.tscn")
	var node: Node2D = scene.instantiate()
	node.global_position = pos
	node.z_index = 10
	# 直接赋值（add_child 立即触发 _ready，不能用 deferred）
	node._gold_text = "💰+%d" % gold if gold > 0 else ""
	node._item_data = item
	parent.add_child(node)


var _gold_text: String = ""
var _item_data: ItemData = null


func _ready() -> void:
	# 金币标签
	if _gold_text != "":
		_gold_label.text = _gold_text
		_gold_label.add_theme_font_size_override("font_size", 14)
		_gold_label.add_theme_color_override("font_color", Color.GOLD)
	else:
		_gold_label.visible = false
	# 物品标签 + 品质视觉反馈
	if _item_data:
		_item_label.visible = true
		_item_label.text = "·%s" % _item_data.name
		_item_label.add_theme_font_size_override("font_size", 12)
		_item_label.add_theme_color_override("font_color", _item_data.get_rarity_color())
		_show_rarity_effect(_item_data.rarity)
	else:
		_item_label.visible = false
	# 浮动 + 淡出
	var tw := create_tween()
	tw.tween_property(self, "position:y", position.y - FLOAT_DISTANCE, FLOAT_DURATION)
	tw.parallel().tween_property(self, "modulate:a", 0.0, FLOAT_DURATION * 0.6).set_delay(FLOAT_DURATION * 0.4)
	tw.tween_callback(queue_free)


## 品质视觉特效
func _show_rarity_effect(rarity: int) -> void:
	match rarity:
		5:  # 神话 — 红色光柱+脉冲+大字
			_add_beam(Color.CRIMSON, 100.0)
			_add_pulse(Color.CRIMSON)
			_gold_label.add_theme_font_size_override("font_size", 20)
			_item_label.add_theme_font_size_override("font_size", 18)
		4:  # 传说 — 金色光柱 + 大字
			_add_beam(Color.GOLD, 80.0)
			_gold_label.add_theme_font_size_override("font_size", 18)
			_item_label.add_theme_font_size_override("font_size", 16)
		3:  # 史诗 — 紫色脉冲
			_add_pulse(Color.MEDIUM_PURPLE)
		2:  # 稀有 — 青色闪烁
			_add_flash(Color.CYAN)
		1:  # 精良 — 绿色小字（默认大小即可）
			pass


## 光柱特效（传说级）
func _add_beam(color: Color, height: float) -> void:
	var rect := ColorRect.new()
	rect.size = Vector2(4, height)
	rect.position = Vector2(-2, -height)
	rect.color = Color(color.r, color.g, color.b, 0.6)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	var tw := create_tween()
	tw.tween_property(rect, "modulate:a", 0.0, FLOAT_DURATION)


## 脉冲特效（史诗级）
func _add_pulse(color: Color) -> void:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(24, 24)
	panel.position = Vector2(-12, -12)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.3)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var tw := create_tween()
	tw.tween_property(panel, "scale", Vector2(2.0, 2.0), 0.6).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(style, "bg_color", Color(color.r, color.g, color.b, 0.0), 0.6)
	tw.tween_callback(panel.queue_free)


## 闪烁特效（稀有级）
func _add_flash(color: Color) -> void:
	var tw := create_tween()
	_item_label.add_theme_color_override("font_color", Color.WHITE)
	tw.tween_callback(func(): _item_label.add_theme_color_override("font_color", color)).set_delay(0.1)
	tw.tween_callback(func(): _item_label.add_theme_color_override("font_color", Color.WHITE)).set_delay(0.2)
	tw.tween_callback(func(): _item_label.add_theme_color_override("font_color", color)).set_delay(0.3)
