class_name InstantGamesBridgeAdvertisement
extends Reference

signal interstitial_state_changed(state)
signal rewarded_state_changed(state)

var _interface: JavaScriptObject

var _interstitial_state_changed_cb = JavaScript.create_callback(self, "_interstitial_state_changed")
var _rewarded_state_changed_cb = JavaScript.create_callback(self, "_rewarded_state_changed")

func _init(interface: JavaScriptObject) -> void:
	_interface = interface
	
	_interface.on('interstitial_state_changed', _interstitial_state_changed_cb)
	_interface.on('rewarded_state_changed', _rewarded_state_changed_cb)

func _interstitial_state_changed(args) -> void:
	emit_signal("interstitial_state_changed", str(args[0]))

func _rewarded_state_changed(args) -> void:
	emit_signal("rewarded_state_changed", str(args[0]))

func set_minimum_delay_between_interstitial(delay: int) -> void:
	if _interface != null:
		_interface.setMinimumDelayBetweenInterstitial(delay)

func show_interstitial(ignore_delay = false, callback: JavaScriptObject = null, catch_callback: JavaScriptObject = null) -> void:
	if _interface != null:
		var options = JavaScript.create_object("Object")
		options.ignoreDelay = ignore_delay
		_interface.showInterstitial(options) \
			.then(callback) \
			.catch(catch_callback)

func show_rewarded(callback: JavaScriptObject = null, catch_callback: JavaScriptObject = null) -> void:
	if _interface != null:
		_interface.showRewarded() \
			.then(callback) \
			.catch(catch_callback)
