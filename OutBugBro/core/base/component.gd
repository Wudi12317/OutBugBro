## 组件基类
## 挂载到实体节点上实现组合模式，避免继承地狱
##
## 用法:
##   extends Component
##   func _setup() -> void: ...   # 初始化
##   func _tick(delta) -> void: ... # 每帧逻辑
class_name Component
extends Node

@export var enabled: bool = true

var entity: Node:  # 宿主节点
	get: return get_parent()


func _ready() -> void:
	_setup()


func _process(delta: float) -> void:
	if enabled:
		_tick(delta)


## 子类覆写：初始化逻辑
func _setup() -> void:
	pass


## 子类覆写：每帧逻辑
func _tick(_delta: float) -> void:
	pass
