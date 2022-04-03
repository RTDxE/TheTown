class_name InstantGamesBridgePlatform
extends Reference

var _interface: JavaScriptObject

func _init(interface: JavaScriptObject) -> void:
	_interface = interface


var id: String setget , _id_getter
func _id_getter() -> String:
	if _interface != null:
		return _interface.id
	return "mock"

var sdk: JavaScriptObject setget , _sdk_getter
func _sdk_getter() -> JavaScriptObject:
	if _interface != null:
		return _interface.sdk
	return null

var language: String setget , _language_getter
func _language_getter() -> String:
	if _interface != null:
		return _interface.language
	return "en"

var payload: String setget , _payload_getter
func _payload_getter() -> String:
	if _interface != null:
		return _interface.payload
	return ""
