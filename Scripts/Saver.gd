extends Node

signal loaded

var _web = false
var _l_counter = 0
var _default_background = "Back0"

var _money = 0
var _current_background = "Back0"
var _level = 1
var _backgrounds: PoolStringArray = ["Back0"]
var _sound: bool = true

var money: int setget _money_setter, _money_getter
func _money_setter(value):
	_money = value
	save()
func _money_getter():
	return _money
	
var current_background: String setget _current_back_setter, _current_back_getter
func _current_back_setter(value):
	_current_background = value
	save()
func _current_back_getter():
	return _current_background


var level: int setget _level_setter, _level_getter
func _level_setter(value):
	_level = value
	save()
func _level_getter():
	return _level

var backgrounds: PoolStringArray setget _backgrounds_setter, _backgrounds_getter
func _backgrounds_setter(value):
	_backgrounds = value
	save()
func _backgrounds_getter():
	return _backgrounds


var sound: bool setget _sound_setter, _sound_getter
func _sound_setter(value):
	_sound = value
	save()
func _sound_getter():
	return _sound


func load_data():
	if OS.has_feature("JavaScript"):
		_web = true
		
		if not InstantGamesBridge.isInitialized:
			InstantGamesBridge.connect("initalized", self, "_load_web")
			InstantGamesBridge.initialize()
		else:
			_load_web()
	else:
		_load_standalone()

var _m_cb = JavaScript.create_callback(self, "_load_data_money")
var _l_cb = JavaScript.create_callback(self, "_load_data_level")
var _s_cb = JavaScript.create_callback(self, "_load_data_sound")
var _b_cb = JavaScript.create_callback(self, "_load_data_backgrounds")
var _c_cb = JavaScript.create_callback(self, "_load_data_current_back")

func _load_web() -> void:
	InstantGamesBridge.game.get_data("money", _m_cb)
	InstantGamesBridge.game.get_data("level", _l_cb)
	InstantGamesBridge.game.get_data("sound", _s_cb)
	InstantGamesBridge.game.get_data("backgrounds", _b_cb)
	
	_l_pus(4)

func _load_data_money(args):
	if args[0] == null:
		_money = 0
	else:
		_money = int(args[0])
	
	_l_rel()

func _load_data_level(args):
	if args[0] == null:
		_level = 1
	else:
		var l = int(args[0])
		if l <= 0:
			_level = 1
		else:
			_level = l
	
	_l_rel()

func _load_data_sound(args):
	if args[0] == null:
		_sound = true
	else:
		_sound = bool(args[0])
	
	_l_rel()

func _load_data_backgrounds(args):
	if args[0] == null:
		_backgrounds = PoolStringArray(["Back0"])
	else:
		var raw_backs = str(args[0])
		if raw_backs != "":
			var backs = raw_backs.split(",", false)
			_backgrounds = PoolStringArray(backs)
	
	_l_pus()
	InstantGamesBridge.game.get_data("current_background", _c_cb)
	
	_l_rel()

func _load_data_current_back(args):
	if args[0] == null:
		_current_background = _default_background
	else:
		_current_background = _default_background
	
		var back = str(args[0])
		if not back.empty():
			for b in _backgrounds:
				if b == back:
					_current_background = back
					break
	
	_l_rel()

func _l_pus(count = 1):
	_l_counter += count

func _l_rel(count = 1):
	_l_counter -= count
	if _l_counter <= 0:
		emit_signal("loaded")

func _load_standalone() -> void:
	var config = ConfigFile.new()
	if config.load("user://data.save") != OK:
		print("No save. Load default")
	
	_money = config.get_value("Data", "money", 0)
	_level = config.get_value("Data", "level", 1)
	_backgrounds = PoolStringArray(config.get_value("Data", "backgrounds", _default_background).split(","))
	_sound = bool(config.get_value("Data", "sound", 1))
	var back = config.get_value("Data", "current_background", _default_background)
	
	_current_background = _default_background
	if not back.empty():
		for b in _backgrounds:
			if b == back:
				_current_background = back
				break
	
	emit_signal("loaded")


func save():
	if _web:
		InstantGamesBridge.game.set_data("money", _money)
		InstantGamesBridge.game.set_data("level", _level)
		InstantGamesBridge.game.set_data("backgrounds", _backgrounds.join(","))
		InstantGamesBridge.game.set_data("current_background", _current_background)
		InstantGamesBridge.game.set_data("sound", int(_sound))
	
	else:
		var config = ConfigFile.new()
		
		config.set_value("Data", "money", _money)
		config.set_value("Data", "level", _level)
		config.set_value("Data", "backgrounds", _backgrounds.join(","))
		config.set_value("Data", "current_background", _current_background)
		config.set_value("Data", "sound", int(_sound))
		
		config.save("user://data.save")
