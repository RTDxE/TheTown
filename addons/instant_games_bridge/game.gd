class_name InstantGamesBridgeGame
extends Reference

var _interface: JavaScriptObject

func _init(interface: JavaScriptObject) -> void:
	_interface = interface

func get_data(key: String, callback: JavaScriptObject, catch_callback: JavaScriptObject = null) -> void:
	if _interface != null:
		_interface.getData(key) \
		.then(callback) \
		.catch(catch_callback)

func set_data(key: String, value, callback: JavaScriptObject = null, catch_callback: JavaScriptObject = null) -> void:
	if _interface != null:
		_interface.setData(key, value) \
		.then(callback) \
		.catch(catch_callback)
