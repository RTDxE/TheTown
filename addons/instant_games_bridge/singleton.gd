extends Node

signal initalized

var _instant_games_bridge_interface

var _initialized_cb = JavaScript.create_callback(self, "_on_initialized")
var _printerr_cb = JavaScript.create_callback(self, "printerr")

var isInitialized: bool setget , _is_initialized_getter
func _is_initialized_getter() -> bool:
	if _check_sdk():
		return _instant_games_bridge_interface.isInitialized
	return false

var _advertisement: InstantGamesBridgeAdvertisement
var advertisement: InstantGamesBridgeAdvertisement setget , _advertisement_getter
func _advertisement_getter() -> InstantGamesBridgeAdvertisement:
	if _advertisement != null:
		return _advertisement
	if _check_sdk():
		_advertisement = InstantGamesBridgeAdvertisement.new(_instant_games_bridge_interface.advertisement)
		return _advertisement
	return null

var _platform: InstantGamesBridgePlatform
var platform: InstantGamesBridgePlatform setget , _platform_getter
func _platform_getter() -> InstantGamesBridgePlatform:
	if _platform != null:
		return _platform
	if _check_sdk():
		_platform = InstantGamesBridgePlatform.new(_instant_games_bridge_interface.platform)
		return _platform
	return null

var _game: InstantGamesBridgeGame
var game: InstantGamesBridgeGame setget , _game_getter
func _game_getter() -> InstantGamesBridgeGame:
	if _game != null:
		return _game
	if _check_sdk():
		_game = InstantGamesBridgeGame.new(_instant_games_bridge_interface.game)
		return _game
	return null


func _check_sdk() -> bool:
	if _instant_games_bridge_interface != null:
		return true
	
	if OS.has_feature("JavaScript"):
		if JavaScript.get_interface("window").instantGamesBridge != null:
			_instant_games_bridge_interface = JavaScript.get_interface("instantGamesBridge")
			return true
	return false


func _on_initialized(args) -> void:
	emit_signal("initalized")


func initialize(callback: JavaScriptObject = null, catch_callback: JavaScriptObject = null) -> bool:
	if OS.has_feature("JavaScript"):
		if _check_sdk():
			if isInitialized:
				_check_sdk()
				return false
			
			_instant_games_bridge_interface.initialize() \
			.then(_initialized_cb if callback == null else callback) \
			.catch(_printerr_cb if catch_callback == null else catch_callback)

			return true
	else:
		pass
#		printerr("Can't initialize SDK. (Not HTML5?)")
	return false


