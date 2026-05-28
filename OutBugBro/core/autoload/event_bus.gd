## 全局事件总线 [Autoload]
## 解耦模块间通信，替代硬引用
##
## 用法:
##   EventBus.listen("item_picked", _on_item_picked)
##   EventBus.unlisten("item_picked", _on_item_picked)
##   EventBus.dispatch("item_picked", item_data)
extends Node

var _listeners: Dictionary = {}


func listen(event: StringName, callback: Callable) -> void:
	if not _listeners.has(event):
		_listeners[event] = []
	_listeners[event].append(callback)


func unlisten(event: StringName, callback: Callable) -> void:
	if _listeners.has(event):
		_listeners[event].erase(callback)


func dispatch(event: StringName, data: Variant = null) -> void:
	if not _listeners.has(event):
		return
	for cb in _listeners[event].duplicate():
		if cb.is_valid():
			if data != null:
				cb.call(data)
			else:
				cb.call()
