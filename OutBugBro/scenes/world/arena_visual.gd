## 方框背景 + 边框 — 运行时根据 ArenaBounds 大小动态调整
extends Node2D

@onready var _bg: ColorRect = $ArenaBackground
@onready var _border: Line2D = $ArenaBorder


func _ready() -> void:
	ArenaBounds.bounds_initialized.connect(_on_bounds_initialized)
	# 如果已经初始化过了（Autoload 先于场景），直接设置
	if ArenaBounds._initialized:
		_on_bounds_initialized(ArenaBounds.get_bounds_size())


func _on_bounds_initialized(size: Vector2) -> void:
	var center := ArenaBounds.get_bounds_center()
	var half := size / 2.0
	# 背景 ColorRect
	_bg.global_position = center - half
	_bg.size = size
	# 边框 Line2D（矩形四边）
	_border.clear_points()
	_border.add_point(Vector2(-half.x, -half.y))
	_border.add_point(Vector2(half.x, -half.y))
	_border.add_point(Vector2(half.x, half.y))
	_border.add_point(Vector2(-half.x, half.y))
	_border.add_point(Vector2(-half.x, -half.y))  # 闭合
	_border.global_position = center
