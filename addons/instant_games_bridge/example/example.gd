extends Node

var _initialized_cb = JavaScript.create_callback(self, "_initialized")
var _get_data_cb = JavaScript.create_callback(self, "_apply_data")
var _set_data_cb = JavaScript.create_callback(self, "_saved")

var _adv
var _platform
var _game

func _ready() -> void:
	logger("Init SDK")

	if InstantGamesBridge.initialize():
		InstantGamesBridge.connect("initalized", self, "_initialized")
	else:
		logger("Can't initialized")
		return
	
	#or use callback
	
	logger("Try alternative init")
	
	if !InstantGamesBridge.initialize(_initialized_cb):
		logger("Already Initialized")


func _initialized() -> void:
	logger("Initialized")

	logger("\nPLATFORM:")
	_check_platform_info()
	
	logger("\nGAME:")
	_check_game()
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	logger("\nADVERTISEMENT:")
	_check_advertisement()


func _check_platform_info() -> void:
	_platform = InstantGamesBridge.platform
	
	logger("ID: " + _platform.id)
	logger("Lang: " + _platform.language)
	logger("SDK: " + str(_platform.sdk))
	logger("Payload: " + str(_platform.payload))


func _check_game() -> void:
	_game = InstantGamesBridge.game

	_game.set_data("gold", 100, _set_data_cb)
	_game.set_data("name", "John", _set_data_cb)
	
	logger("Wait 1 second")
	yield(get_tree().create_timer(1.0), "timeout")
	
	_game.get_data("gold", _get_data_cb)
	_game.get_data("name", _get_data_cb)


func _apply_data(args) -> void:
	logger("Data given: " + str(args[0]))


func _saved(args) -> void:
	logger("Data was saved")


func _check_advertisement() -> void:
	_adv = InstantGamesBridge.advertisement

	_adv.connect("interstitial_state_changed", self, "_interstitial_state_changed")
	_adv.connect("rewarded_state_changed", self, "_rewarded_state_changed")
	_adv.show_interstitial(true)


func _interstitial_state_changed(state: String):
	logger("New Inter State: " + state)
	
	if state == InterstitialState.CLOSED:
		_adv.show_rewarded()


func _rewarded_state_changed(state: String):
	logger("New Reward State: " + state)
	
	if state == RewardState.REWARDED:
		pass


func logger(text):
	$logger.add_text(str(text) + '\n')
