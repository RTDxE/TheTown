extends Control

export (NodePath) var viewport
export (NodePath) var viewers

signal swipe(s)
var game = null


func _ready() -> void:
	Saver.connect("loaded", self, "_init_game")
	Saver.load_data()
	
	for c in get_tree().get_nodes_in_group("shop_env"):
		c.connect("pressed", self, "shop", [c])


func _init_game() -> void:
	if InstantGamesBridge.isInitialized:
		InstantGamesBridge.advertisement.connect("interstitial_state_changed", self, "_inter_changed")
	
	update_money()
	load_level()


func _inter_changed(state):
	print("Inter state: ", state)
	get_tree().paused = state == InterstitialState.OPENED


func load_level(i=-1):
	if InstantGamesBridge.isInitialized:
		InstantGamesBridge.advertisement.show_interstitial()
	
	if i < 1:
		i = Saver.level

	# Clean up
	if game and is_instance_valid(game):
		game.queue_free()
	for v in get_node(viewers).get_children():
		if is_instance_valid(v):
			v.get_parent().remove_child(v)
			v.queue_free()

	$Level.text = "Level " + str(i)
	
	var res = Levels.get_scene(i)
	for v in res.buildings:
		get_node(viewers).add_child(v)
		v.init()
	game = res.scene
	game.time = $Time
	game.time.visible = false
	get_node(viewport).add_child(game)
	game.viewers = get_node(viewers)
	if "lines" in res:
		game.lines = res.lines
	yield(get_tree().create_timer(0.15), "timeout")
	game.init()
	game.change_back(Saver.current_background)
	game.connect("win", self, "next_level")
	game.connect("restart", self, "reload")
	game.connect("add_money", self, "add_money")
	game.connect("sound", self, "sound")
	game.connect("message", self, "message")

func message(s):
	$Message.run(s)

func sound(s):
	get_node(s).stop()
	get_node(s).play()

func add_money(c):
	Saver.money += c
	update_money()

func update_money():
	$Money/Panel/Count.text = str(int(Saver.money))
	$Money/AnimationPlayer.stop(true)
	$Money/AnimationPlayer.play("Punch")


func next_level():
	Saver.level += 1
	if Saver.level > Levels.levels.size():
		print("End of game, level 1")
		Saver.level = 1
	load_level()
	
	print("next level ", Saver.level)

func reload(with_sound = false) -> void:
	if with_sound:
		sound("DoubleClick")
	game.is_dragging = false
	load_level()
	print("reload level ", Saver.level)


func settings() -> void:
	game.is_dragging = false


func toggle_sound(b) -> void:
	print("Audio")
	if game != null:
		game.is_dragging = false
		Saver.sound = b
	AudioServer.set_bus_mute(0, !b)

# Swipe realization and shop
var shop_opened = false
func show_show():
	shop_opened = not shop_opened
	if shop_opened:
		print("shop pos: ", $Shop.rect_position.y)
		print("shop size: ", $Shop.rect_size.y)
		$Shop.rect_size.x = rect_size.x
		$ShopTween.interpolate_property(
			$Shop, "rect_position:y",
			$Shop.rect_position.y,
			$Shop.rect_position.y - $Shop.rect_size.y,
			0.5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT
		)
		game.stop(true)
		$CloseController.show()
	else:

		$ShopTween.interpolate_property(
			$Shop, "rect_position:y",
			$Shop.rect_position.y,
			$Shop.rect_position.y + $Shop.rect_size.y,
			0.5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT
		)

	$ShopTween.start()

func shop_change() -> void:
	if not shop_opened:
		game.stop(false)
		$CloseController.hide()

func shop(c):
	if c.pursuased:
		Saver.current_background = c.asset
		game.change_back(Saver.current_background)
	elif c.gold <= Saver.money:
		Saver.money -= c.gold
		update_money()
		c.pursuased = true
		var a = Saver.backgrounds
		a.append(c.asset)
		Saver.backgrounds = a
	
	get_tree().call_group("shop_env", "update_status")


var touched = false
var points = []
var last_pos = Vector2()
var swipe_handled = true



func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		touched = event.pressed
		points = []
		if not touched:
			swipe_handled = true
			check_swipe()

	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if touched and swipe_handled:
			var m = get_global_mouse_position()
			if points.size() == 0 or m.distance_to(points.back()) >= 10:
				points.append(m)
				check_swipe()

func swipe(s):
	match s:
		"left":
			pass
		"right":
			pass

func check_swipe():
	var angles = []
	var prev = null
	var length = 0
	if points.size() < 2:
		return
	for p in points:
		if prev:
			length += p.distance_to(prev)
			var t_angle = rad2deg((p-prev).angle())
			var angle = int(round(t_angle/45)*45)
			if angle == -0:
				angle = 0
			elif angle == -180:
				angle = 180
			if angles.size() == 0:
				angles = [angle]
			elif angles.back() != angle:
				angles.append(angle)
		else:
			prev = p
	var s = get_viewport().size
	if length >= s.x / (2 if s.y > s.x else 6):
		points = []
		swipe_handled = false
		match(angles):
			[0]:
				emit_signal("swipe", "right")
				swipe("right")
			[180]:
				emit_signal("swipe", "left")
				swipe("left")


func resized() -> void:
	pass
#	$Shop.rect_position.y = get_viewport().size.y


func should_close(event: InputEvent) -> void:
	if event is InputEventMouseButton:

		if shop_opened:
			show_show()

