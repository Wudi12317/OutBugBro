## 技能栏 — 底部中央，5技能槽 + 分隔 + 5消耗品槽
## CD用自定义扇形遮罩覆盖，右键打开详情/购买/使用 窗口
extends HBoxContainer

const SLOT_SIZE := 64.0

var _skill_slots: Array[Control] = []
var _item_slots: Array[Control] = []

## 详情弹窗
var _popup: Control = null


func _ready() -> void:
	SkillManager.changed.connect(_refresh)
	InventoryManager.changed.connect(_refresh_items)
	InventoryManager.bindings_changed.connect(_refresh_items)
	_build_ui()
	_build_popup()
	UITheme.apply_iOS_style(self)


func _process(_delta: float) -> void:
	_update_cd_display()


func _build_ui() -> void:
	var skills := SkillManager.get_skills()
	var skill_count := maxi(skills.size(), 5)
	for i in range(skill_count):
		var slot := _create_slot(i, true)
		add_child(slot)
		_skill_slots.append(slot)
	var sep := VSeparator.new()
	sep.custom_minimum_size = Vector2(10, 48)
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sep.add_theme_color_override("separator", Color(0.4, 0.4, 0.5, 0.5))
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep)
	for i in range(5):
		var slot := _create_slot(i, false)
		add_child(slot)
		_item_slots.append(slot)
	_refresh()
	_refresh_items()


## ============ 详情弹窗（统一风格） ============

func _build_popup() -> void:
	_popup = Control.new()
	_popup.name = "SkillPopup"
	_popup.visible = false
	_popup.process_mode = Node.PROCESS_MODE_ALWAYS
	_popup.z_index = 200
	var panel := Panel.new()
	panel.name = "PopupPanel"
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.08, 0.08, 0.12, 0.97)
	sty.border_color = Color(0.5, 0.5, 0.65)
	sty.set_border_width_all(2)
	sty.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sty)
	panel.name = "PopupBg"
	_popup.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.name = "PopupVBox"
	vbox.add_theme_constant_override("separation", 8)
	_popup.add_child(vbox)
	## 标题
	var title := Label.new()
	title.name = "PopupTitle"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	vbox.add_child(title)
	## 描述
	var desc := Label.new()
	desc.name = "PopupDesc"
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	## 状态行
	var status := Label.new()
	status.name = "PopupStatus"
	status.add_theme_font_size_override("font_size", 12)
	status.add_theme_color_override("font_color", Color.CYAN)
	vbox.add_child(status)
	## 操作按钮
	var btn := Button.new()
	btn.name = "PopupBtn"
	btn.custom_minimum_size = Vector2(140, 32)
	btn.add_theme_font_size_override("font_size", 13)
	btn.focus_mode = Control.FOCUS_NONE
	vbox.add_child(btn)
	## 关闭按钮
	var close_btn := Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = "✕"
	close_btn.flat = true
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left = -24.0
	close_btn.offset_right = 0.0
	close_btn.offset_bottom = 22.0
	close_btn.pressed.connect(func(): _popup.visible = false)
	_popup.add_child(close_btn)
	## 加到 CanvasLayer
	var ui_layer := _get_ui_layer()
	if ui_layer:
		ui_layer.add_child.call_deferred(_popup)
	else:
		get_parent().add_child.call_deferred(_popup)


func _get_ui_layer() -> Node:
	var node: Node = self
	while node:
		if node is CanvasLayer:
			return node
		node = node.get_parent()
	return null


func _open_skill_popup(idx: int) -> void:
	if idx < 0 or idx >= _skill_slots.size():
		return
	if not _popup or not is_instance_valid(_popup):
		return
	var slot: Control = _skill_slots[idx]
	var data: SkillData = slot.get_meta("skill_data")
	if not data:
		return
	var title: Label = _popup.get_node("PopupVBox/PopupTitle")
	var desc_lbl: Label = _popup.get_node("PopupVBox/PopupDesc")
	var status: Label = _popup.get_node("PopupVBox/PopupStatus")
	var btn: Button = _popup.get_node("PopupVBox/PopupBtn")
	var bg: Panel = _popup.get_node("PopupBg")
	## 断开旧连接
	if btn.pressed.get_connections().size() > 0:
		for c in btn.pressed.get_connections():
			btn.pressed.disconnect(c["callable"])
	title.text = "%s (Slot %d)" % [data.skill_name, idx + 1]
	desc_lbl.text = data.desc
	var id := data.id
	var wave := _get_current_wave()
	if not SkillManager.is_unlocked(id):
		if wave < data.unlock_wave:
			status.text = "🔒 第%d波解锁" % data.unlock_wave
			btn.text = "未解锁"
			btn.disabled = true
		else:
			var cost_str := "免费" if data.cost <= 0 else "💰%d" % data.cost
			status.text = "✅ 可购买 | 费用: %s" % cost_str
			var can := data.cost <= 0 or CurrencyManager.has_enough(data.cost)
			btn.text = "购买 %s" % cost_str
			btn.disabled = not can
			btn.pressed.connect(func():
				if SkillManager.purchase(id):
					_popup.visible = false
					_refresh()
			)
	elif SkillManager.is_active(id):
		status.text = "✨ 激活中: %.1fs" % SkillManager.get_active_remaining(id)
		btn.text = "冷却中…"
		btn.disabled = true
	elif SkillManager.is_on_cooldown(id):
		status.text = "⏳ 冷却: %.0fs" % SkillManager.get_cooldown_remaining(id)
		btn.text = "冷却中…"
		btn.disabled = true
	else:
		status.text = "✅ 可使用 | CD: %.0fs" % data.cooldown
		btn.text = "▶ 使用技能"
		btn.disabled = false
		btn.pressed.connect(func():
			SkillManager.activate(id)
			_popup.visible = false
		)
	## 颜色边框
	var sty: StyleBoxFlat = bg.get_theme_stylebox("panel").duplicate()
	sty.border_color = Color(0.5, 0.5, 0.65)
	bg.add_theme_stylebox_override("panel", sty)
	## 定位并调整大小
	var vbox: VBoxContainer = _popup.get_node("PopupVBox")
	var popup_w := 200.0
	var popup_h := 160.0
	_popup.custom_minimum_size = Vector2(popup_w, popup_h)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10.0
	vbox.offset_top = 8.0
	vbox.offset_right = -10.0
	vbox.offset_bottom = -8.0
	_popup.size = Vector2(popup_w, popup_h)
	## 位置：在格子上方
	var slot_gp: Vector2 = slot.get_global_rect().position
	_popup.global_position = Vector2(slot_gp.x - 70.0, slot_gp.y - popup_h - 8.0)
	_popup.visible = true


func _open_item_popup(idx: int) -> void:
	if idx < 0 or idx >= _item_slots.size():
		return
	if not _popup or not is_instance_valid(_popup):
		return
	var slot: Control = _item_slots[idx]
	var data: ItemData = slot.get_meta("item_data", null)
	if not data:
		return
	var title: Label = _popup.get_node("PopupVBox/PopupTitle")
	var desc_lbl: Label = _popup.get_node("PopupVBox/PopupDesc")
	var status: Label = _popup.get_node("PopupVBox/PopupStatus")
	var btn: Button = _popup.get_node("PopupVBox/PopupBtn")
	var bg: Panel = _popup.get_node("PopupBg")
	if btn.pressed.get_connections().size() > 0:
		for c in btn.pressed.get_connections():
			btn.pressed.disconnect(c["callable"])
	var count := InventoryManager.get_consumable_count_at_slot(idx)
	var rc := data.get_rarity_color()
	title.text = data.name
	title.add_theme_color_override("font_color", rc)
	desc_lbl.text = data.desc
	var item_keys := ["8", "9", "0", "F1", "F2"]
	var key_str: String = item_keys[idx] if idx < item_keys.size() else "?"
	status.text = "数量: %d | 快捷键: %s" % [count, key_str]
	btn.text = "▶ 使用"
	btn.disabled = count <= 0
	btn.pressed.connect(func():
		InventoryManager.use_item(data)
		_popup.visible = false
	)
	var sty: StyleBoxFlat = bg.get_theme_stylebox("panel").duplicate()
	sty.border_color = rc
	bg.add_theme_stylebox_override("panel", sty)
	var vbox: VBoxContainer = _popup.get_node("PopupVBox")
	var popup_w := 200.0
	var popup_h := 140.0
	_popup.custom_minimum_size = Vector2(popup_w, popup_h)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10.0
	vbox.offset_top = 8.0
	vbox.offset_right = -10.0
	vbox.offset_bottom = -8.0
	_popup.size = Vector2(popup_w, popup_h)
	var slot_gp: Vector2 = slot.get_global_rect().position
	_popup.global_position = Vector2(slot_gp.x - 70.0, slot_gp.y - popup_h - 8.0)
	_popup.visible = true


## ============ 创建格子 ============

func _create_slot(idx: int, is_skill: bool) -> Control:
	var slot := Control.new()
	slot.name = "Slot_%d_%s" % [idx, "S" if is_skill else "I"]
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var panel := Panel.new()
	panel.name = "BgPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18, 0.9)
	style.border_color = Color(0.35, 0.35, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	slot.add_child(panel)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	## 扇形CD遮罩 — 用专门绘制节点
	var cd_fan := _CdFanNode.new()
	cd_fan.name = "CdFan"
	cd_fan.set_anchors_preset(Control.PRESET_FULL_RECT)
	cd_fan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cd_fan.visible = false
	cd_fan.z_index = 2
	slot.add_child(cd_fan)
	var label := Label.new()
	label.name = "Label"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 3
	slot.add_child(label)
	var count_label := Label.new()
	count_label.name = "CountLabel"
	count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count_label.offset_left = -22.0
	count_label.offset_top = -18.0
	count_label.offset_right = -2.0
	count_label.offset_bottom = -2.0
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	count_label.add_theme_constant_override("shadow_offset_x", 1)
	count_label.add_theme_constant_override("shadow_offset_y", 1)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_label.visible = false
	count_label.z_index = 3
	slot.add_child(count_label)
	var key_label := Label.new()
	key_label.name = "KeyLabel"
	key_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	key_label.offset_left = 3.0
	key_label.offset_top = 1.0
	key_label.add_theme_font_size_override("font_size", 10)
	key_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 0.9))
	key_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	key_label.add_theme_constant_override("shadow_offset_x", 1)
	key_label.add_theme_constant_override("shadow_offset_y", 1)
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_label.z_index = 3
	if is_skill:
		key_label.text = str(idx + 1)
	else:
		var item_keys := ["8", "9", "0", "F1", "F2"]
		key_label.text = item_keys[idx] if idx < item_keys.size() else "?"
	slot.add_child(key_label)
	## 左键=快速激活/使用，右键=打开详情窗口
	var btn := Button.new()
	btn.name = "ClickBtn"
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.z_index = 5
	if is_skill:
		btn.pressed.connect(_on_skill_left_click.bind(idx))
		btn.gui_input.connect(_on_slot_gui_input.bind(idx, true))
	else:
		btn.pressed.connect(_on_item_left_click.bind(idx))
		btn.gui_input.connect(_on_slot_gui_input.bind(idx, false))
	slot.add_child(btn)
	return slot


## ============ 扇形CD节点（内嵌类） ============

class _CdFanNode extends Control:
	var ratio: float = 0.0  ## 0=满CD 1=可用

	func _draw() -> void:
		if ratio >= 1.0:
			return
		var center := size / 2.0
		var r := minf(center.x, center.y)
		## 半透明暗底
		draw_circle(center, r, Color(0, 0, 0, 0.55))
		## 用扇形"擦除"已冷却部分
		var points := PackedVector2Array()
		points.append(center)
		var start_angle := -PI / 2.0
		var covered := TAU * (1.0 - ratio)
		var steps := 40
		for i in range(steps + 1):
			var angle: float = start_angle + covered * i / steps
			points.append(center + Vector2(cos(angle), sin(angle)) * r)
		draw_polygon(points, PackedColorArray([Color(0, 0, 0, 0.6)]))


## ============ 技能槽刷新 ============

func _refresh() -> void:
	var skills := SkillManager.get_skills()
	for i in range(_skill_slots.size()):
		var slot: Control = _skill_slots[i]
		if i >= skills.size():
			slot.visible = false
			continue
		var data: SkillData = skills[i]
		slot.visible = true
		slot.set_meta("skill_data", data)
		var icon: TextureRect = slot.get_node("Icon")
		var label: Label = slot.get_node("Label")
		var panel: Panel = slot.get_node("BgPanel")
		var cd_fan: Control = slot.get_node("CdFan")
		var btn: Button = slot.get_node("ClickBtn")
		var id := data.id
		var unlocked := SkillManager.is_unlocked(id)
		icon.texture = data.icon
		icon.visible = data.icon != null
		var has_icon: bool = data.icon != null
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
		if not unlocked:
			var wave := _get_current_wave()
			icon.modulate = Color(0.4, 0.4, 0.45, 1.0) if has_icon else Color.WHITE
			if wave >= data.unlock_wave:
				label.text = "💰%d" % data.cost if data.cost > 0 else "免费"
			else:
				label.text = "W%d" % data.unlock_wave
			label.visible = true
			cd_fan.visible = false
			style.bg_color = Color(0.1, 0.1, 0.13, 0.9)
			style.border_color = Color(0.3, 0.3, 0.35, 0.7)
			btn.disabled = false
			btn.tooltip_text = "%s — 波次%d解锁, 💰%d" % [data.skill_name, data.unlock_wave, data.cost]
		else:
			icon.modulate = Color.WHITE
			label.visible = not has_icon
			cd_fan.visible = false
			style.bg_color = Color(0.12, 0.12, 0.16, 0.9)
			style.border_color = Color(0.55, 0.55, 0.65)
			btn.disabled = false
			btn.tooltip_text = "%s (按%d)" % [data.skill_name, i + 1]
		panel.add_theme_stylebox_override("panel", style)


## ============ 每帧更新CD/激活显示 ============

func _update_cd_display() -> void:
	var skills := SkillManager.get_skills()
	for i in range(mini(_skill_slots.size(), skills.size())):
		var slot: Control = _skill_slots[i]
		var data: SkillData = skills[i]
		var id := data.id
		if not SkillManager.is_unlocked(id):
			continue
		var label: Label = slot.get_node("Label")
		var icon: TextureRect = slot.get_node("Icon")
		var panel: Panel = slot.get_node("BgPanel")
		var cd_fan: Control = slot.get_node("CdFan")
		var btn: Button = slot.get_node("ClickBtn")
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
		var has_icon: bool = data.icon != null

		if SkillManager.is_active(id):
			var rem := SkillManager.get_active_remaining(id)
			icon.modulate = Color(0.5, 1.0, 1.0, 1.0)
			label.text = "%.1fs" % rem
			label.add_theme_color_override("font_color", Color.CYAN)
			label.visible = true
			cd_fan.visible = false
			style.bg_color = Color(0.0, 0.18, 0.28, 0.9)
			style.border_color = Color.CYAN
			btn.disabled = true
		elif SkillManager.is_on_cooldown(id):
			var rem := SkillManager.get_cooldown_remaining(id)
			var total := SkillManager.get_cooldown_total(id)
			var ratio := 1.0 - (rem / total if total > 0 else 0.0)
			icon.modulate = Color(0.5, 0.5, 0.55, 1.0)
			label.text = "%.0f" % rem
			label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
			label.visible = true
			## 扇形遮罩
			cd_fan.visible = true
			cd_fan.ratio = ratio
			cd_fan.queue_redraw()
			style.bg_color = Color(0.1, 0.1, 0.13, 0.9)
			style.border_color = Color(0.25, 0.25, 0.3, 0.5)
			btn.disabled = true
		else:
			icon.modulate = Color.WHITE
			label.text = data.skill_name.left(2) if not has_icon else ""
			label.add_theme_color_override("font_color", Color.WHITE)
			label.visible = not has_icon
			cd_fan.visible = false
			style.bg_color = Color(0.12, 0.12, 0.16, 0.9)
			style.border_color = Color(0.55, 0.55, 0.65)
			btn.disabled = false
		panel.add_theme_stylebox_override("panel", style)


## ============ 消耗品槽刷新 ============

func _refresh_items() -> void:
	for i in range(5):
		var slot: Control = _item_slots[i]
		var icon: TextureRect = slot.get_node("Icon")
		var label: Label = slot.get_node("Label")
		var count_label: Label = slot.get_node("CountLabel")
		var panel: Panel = slot.get_node("BgPanel")
		var btn: Button = slot.get_node("ClickBtn")
		var data: ItemData = InventoryManager.get_consumable_at_slot(i)
		var count := InventoryManager.get_consumable_count_at_slot(i)
		var item_keys: Array = ["8", "9", "0", "F1", "F2"]
		var key_str: String = item_keys[i] if i < item_keys.size() else "?"
		if data:
			var rc: Color = data.get_rarity_color()
			var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
			style.bg_color = Color(rc.r, rc.g, rc.b, 0.35)
			style.border_color = rc
			panel.add_theme_stylebox_override("panel", style)
			icon.texture = data.icon
			icon.visible = data.icon != null
			label.text = data.name.left(1)
			label.add_theme_color_override("font_color", Color.WHITE)
			label.visible = data.icon == null
			count_label.text = str(count) if count > 1 else ""
			count_label.visible = count > 1
			slot.set_meta("item_data", data)
			btn.disabled = false
			btn.tooltip_text = "%s ×%d (按%s使用)" % [data.name, count, key_str]
		else:
			icon.texture = null
			icon.visible = false
			label.text = ""
			label.visible = false
			count_label.text = ""
			count_label.visible = false
			slot.set_meta("item_data", null)
			btn.disabled = false
			btn.tooltip_text = "快捷键: %s" % key_str
			var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
			style.bg_color = Color(0.15, 0.15, 0.18, 0.7)
			style.border_color = Color(0.3, 0.3, 0.35, 0.5)
			panel.add_theme_stylebox_override("panel", style)


## ============ 点击处理 ============

func _on_skill_left_click(idx: int) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	var data: SkillData = _skill_slots[idx].get_meta("skill_data")
	if not data:
		return
	var id := data.id
	if not SkillManager.is_unlocked(id):
		## 左键直接购买（有钱且波次够就静默购买，否则打开弹窗）
		if SkillManager.can_purchase(id) and CurrencyManager.has_enough(data.cost):
			SkillManager.purchase(id)
		else:
			_open_skill_popup(idx)
		return
	if not SkillManager.is_on_cooldown(id) and not SkillManager.is_active(id):
		SkillManager.activate(id)


func _on_item_left_click(idx: int) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	_use_consumable_at(idx)


func _on_slot_gui_input(event: InputEvent, idx: int, is_skill: bool) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if is_skill:
			_open_skill_popup(idx)
		else:
			_open_item_popup(idx)
		get_viewport().set_input_as_handled()


func _use_consumable_at(idx: int) -> void:
	var data: ItemData = InventoryManager.get_consumable_at_slot(idx)
	if data and data is ConsumableItemData:
		InventoryManager.use_item(data)


## 全局按键处理
func _input(event: InputEvent) -> void:
	## 按 Esc 关闭弹窗
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _popup and _popup.visible:
			_popup.visible = false
			get_viewport().set_input_as_handled()
			return
	if GameManager.state != GameManager.State.PLAYING:
		return
	if event is InputEventKey and event.pressed:
		var skill_count := _skill_slots.size()
		for i in range(skill_count):
			if event.keycode == KEY_1 + i:
				_on_skill_left_click(i)
				return
		if event.keycode == KEY_8:
			_use_consumable_at(0)
			return
		if event.keycode == KEY_9:
			_use_consumable_at(1)
			return
		if event.keycode == KEY_0:
			_use_consumable_at(2)
			return
		if event.keycode == KEY_F1:
			_use_consumable_at(3)
			return
		if event.keycode == KEY_F2:
			_use_consumable_at(4)
			return


func _get_current_wave() -> int:
	var spawners := get_tree().get_nodes_in_group("spawners")
	if spawners.is_empty():
		return 1
	return spawners[0].wave
