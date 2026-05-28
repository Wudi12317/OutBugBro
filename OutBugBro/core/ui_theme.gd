# UI 风格工具 — iOS 暗色 + 赛博朋克，统一调用
extends Node

# 给任意 Control 节点应用 iOS 暗色风格
static func apply_iOS_style(node: Control, extra_radius: int = 12) -> void:
	if not node:
		return
	# PanelContainer / Panel
	if node is PanelContainer or node is Panel:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.08, 0.12, 0.96)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.3, 0.6, 1.0, 0.45)
		sb.corner_radius_top_left = extra_radius
		sb.corner_radius_top_right = extra_radius
		sb.corner_radius_bottom_left = extra_radius
		sb.corner_radius_bottom_right = extra_radius
		node.add_theme_stylebox_override("panel", sb)
	# 让子 Control 也递归应用（可选）
	for child in node.get_children():
		if child is Control:
			_apply_to_child(child)

# 递归处理子节点
static func _apply_to_child(child: Control) -> void:
	if child is Button:
		_apply_button_style(child)
	elif child is Label:
		_apply_label_style(child)
	elif child is ProgressBar:
		_apply_progress_style(child)
	elif child is HSeparator or child is VSeparator:
		_apply_separator_style(child)

static func _apply_button_style(btn: Button) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.12, 0.18, 0.9)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.3, 0.6, 1.0, 0.35)
	sb.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", sb)
	var hover := sb.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.2, 0.2, 0.3, 0.95)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color.CYAN)

static func _apply_label_style(lbl: Label) -> void:
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1.0))

static func _apply_progress_style(pb: ProgressBar) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	bg.set_corner_radius_all(4)
	pb.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.2, 0.8, 0.4, 1.0)
	fill.set_corner_radius_all(4)
	pb.add_theme_stylebox_override("fill", fill)

static func _apply_separator_style(sep: Control) -> void:
	sep.add_theme_color_override("separator", Color(0.3, 0.6, 1.0, 0.3))
