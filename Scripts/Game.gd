extends Spatial

signal add_money(howmuch)
signal win
signal message(s)
signal restart
signal sound(s)
var terrain : Terrain
var selected = null
var is_dragging = false
var delta = Vector3()
var camera
var markers = []
var field = {}
var viewers : HBoxContainer
var selected_house_viewer
var click = 0
var last_pos : Vector3
const particles_inst = preload("res://Scenes/Monets.tscn")
var game_started = false
var game_time = 1
var figures_count = 0
var lines = {}
var camera_zoom = 1
var time

func init():
	if has_node("DirectionalLight"):
		$DirectionalLight.shadow_enabled = !OS.has_feature('JavaScript')

	# Generate 5 markers
	for i in 5:
		var marker = preload("res://Scenes/Marker.tscn").instance()
		$Markers.add_child(marker)
#		marker.hide()
		markers.append(marker)
	# Пока берем дефолтный, потом будем подгружать
	camera = get_viewport().get_camera()
	terrain = $Terrain
	field = terrain.build_field()
	terrain.connect("tapped", self, "terrain_tapped")
	figures_count = viewers.get_child_count()

	for d in $Decor.get_children():
		d.decor = true
		build(d)
	for i in viewers.get_child_count():
		viewers.get_child(i).connect("pick_building", self, "house_built")
	house_built()
	time.text = "00:00"

func calc_places():
	var figures_count = viewers.get_child_count()

func _process(delta: float) -> void:
	if selected:
		click += delta
		# Старый код, который позволяет ДЕРЖАТЬ
#		if not selected.state == House.STATE.PREPARE and click >= 0.2 and\
#				selected.can_build and \
#				last_pos == terrain.world_to_map(selected.translation):
#			selected.prepare()
#			print("prepare")
	if game_started:
		game_time += delta
		var m = int(game_time/60)
		var s = int(game_time) % 60
		time.text = "%02d:%02d" %[m, s]

func terrain_tapped(vec : Vector3, real: Vector3):
	print("Terrain coordinates: ", vec)
	print("Global coordinates: ", real)


#func viewer_tap(h_inst: PackedScene, view) -> void:
#	if selected:
#		return
#	for c in $Houses.get_children():
#		if c.state != House.STATE.BUILT:
#			return
#	print("Viewer")
#	var house : House = h_inst.instance()
#	$Houses.add_child(house)
#	update_markers(house.markers_count())
#	view.queue_free()
#	to_grid(house, Vector3(0,0,0))
#	check(house)
#	house.connect("build", self, "build")
#	house.connect("built", self, "house_built")
#	house.start()

func pick(mask=1):
	var r = get_viewport().size / OS.window_size
	var mouse_pos = get_viewport().get_mouse_position() * r
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 10000
	var space_state = get_world().direct_space_state
	return space_state.intersect_ray(from, to, [], mask)

func house_built(idx = -1):
	if selected != null:
		selected.queue_free()
	if  $Houses.get_child_count() > 0:
		emit_signal("sound", "Build")
	if selected_house_viewer != null:
		if idx >= 0:
			selected_house_viewer.selected = false
		else:
			selected_house_viewer.queue_free()
			yield(get_tree(), "idle_frame")
			yield(get_tree(), "idle_frame")
	if viewers.get_child_count() == 0:
		print("Win!")
		return win()
	if idx < 0:
		selected_house_viewer = viewers.get_child(0)
	else: 
		selected_house_viewer = viewers.get_child(idx)
	selected_house_viewer.selected = true
	var house : House = selected_house_viewer.house.instance()
	house.decor = false
	$Houses.add_child(house)
	house.rotate_y(deg2rad(selected_house_viewer.angle))
	update_markers(house.markers_count())
	to_grid(house, Vector3(0,0,0))
	check(house)
	house.connect("build", self, "build")
	house.connect("built", self, "house_built")
	house.start()
	house.set_colors(selected_house_viewer.colors)
	selected = house

func _ready() -> void:
	camera_zoom = $Camera.size
	get_tree().connect("screen_resized", self, "resize")
	resize()

func resize():
	for i in 3:
		yield(get_tree().create_timer(0.1),"timeout")
		var s  = get_viewport().size
		if s.x > s.y * 0.7:
			$Camera.keep_aspect = Camera.KEEP_HEIGHT
			$Camera.size = camera_zoom * 1.5
		else:
			$Camera.keep_aspect =  Camera.KEEP_WIDTH
			$Camera.size = camera_zoom

func win():
	var is_win = true
	for line in lines:
		is_win = is_win and lines[line] <= count_lines(line)
	game_started = false
	if is_win:
		emit_signal("sound", "Win")
		var frases = []
		var x = 1
		var f_place_time = figures_count + 2
		if f_place_time >= game_time:
			# 1 place
			x = 4
		elif f_place_time * 1.5 >= game_time:
			x = 3
		elif f_place_time * 1.5 * 1.5 >= game_time:
			x = 2
		if x > 1:
			emit_signal("message", "%s X%d" % [tr("KEY_TIME_BONUS"), x])
		var particles_arr = []
		for cell in terrain.get_all():
			var particles = particles_inst.instance()
			add_child(particles)
			particles.translation = cell.global + Vector3(1,0,1)
			var color = field[int(cell.local.x)][int(cell.local.z)]
			var price = 1 if color <= 0 else \
				(4 if color < 99 else 0)

			particles.fire(price*x)
			emit_signal("add_money", price*x)
#			emit_signal("sound", "Coins")
			var t = get_tree().create_timer(0.2)
			yield(t, "timeout")

		for p in particles_arr:
			p.queue_free()
		
		var t = get_tree().create_timer(1.0)
		yield(t, "timeout")
		emit_signal("win")
	else:
		emit_signal("message", tr("KEY_INCORRECT"))
		emit_signal("sound", "Lose")
		yield(get_tree().create_timer(1.0), "timeout")
		emit_signal("restart")

func count_lines(col):
	for f in field:
		print(field[f].values())
	var width = field.size()
	var height = field[field.keys()[0]].size()
	var lines = 0
	# Проверяем сначала  горизонтально, потом вертикально
	for i in field:
		print("Check row ", i)
		var c = 0
		for j in field[i]:
			print("Values... ", field[i][j])
			if field[i][j] != int(col):
				print("Break")
				break
			c += 1
		if c == height:
			lines += 1
			print("horizontal line")
	print("->")
	for j in field[field.keys()[0]]:
		print("Check row ", j)
		var c = 0
		for i in field:
			print("Values... ", field[i][j])
			if field[i][j] != int(col):
				print("Break")
				break
			c += 1
		if c == width:
			lines += 1
			print("vertical line")
	print("Found lines: ", lines)
	return lines

func build(force = null):
	if not force:
		force = selected
	var position = terrain.world_to_map(force.translation)
	clamp_pos(position)
	var can_build = can_build(force)
	if can_build:
		force.build()
		var i = 0
		for c in force.get_collisions():
			var w = terrain.world_to_map(c)
			field[int(w.x)][int(w.z)] = force.colors[i]
			i += 1
		update_markers(0)
		terrain.cells_left -= force.markers_count()
	if force == selected:
		selected = null

func stop(st):
	set_process_unhandled_input(!st)
	set_process(!st)
# warning-ignore:unused_argument
func _unhandled_input(event):
#	event is InputEventScreenTouch or
	if (event is InputEventMouseButton and event.button_index == BUTTON_LEFT):

		if event.pressed:
			game_started = true
			time.visible = true
			
			if selected:
				var result = pick(4) # Floor
				if result:
					is_dragging = true
					delta = selected.translation - result.position
					emit_signal("sound", "Tap")

#			var result = pick(3)
#			if result:
#				if result.collider == terrain:
#					var position = terrain.world_to_map(result.position)
#					terrain_tapped(position, result.position)
#				elif result.collider is House:
#					game_started = true
#					print(result.collider.name)
#					selected = result.collider
#					selected.stop()
#					selected.update_markers(markers)
#					click = 0
		elif is_dragging:
			#print("click")
			is_dragging = false
#			var result_house = pick(2)
			var result = pick(4)
			if selected:
				selected.stop()
#			if result_house and click <= 0.5 and result_house.collider is House and selected:
#				selected.rotate_y(deg2rad(90))
#				check()
			if result and selected:
				var position = terrain.world_to_map(result.position + delta)
				clamp_pos(position)
				var can_build = can_build()
				if can_build and selected.state != House.STATE.PREPARE:
					selected.build()
					var i = 0
					for c in selected.get_collisions():
						var w = terrain.world_to_map(c)
						field[int(w.x)][int(w.z)] = selected.colors[i]
						i+=1
					selected = null
					update_markers(0)
				else:
					check()

#	 or event is InputEventScreenDrag
	elif event is InputEventMouseMotion:
		if selected and is_dragging:
#			var result = pick(1)
			var floor_col = pick(4)
#			if result and result.collider == terrain:
#				var current_pos = to_grid(selected, result.position + delta)
#				if last_pos != current_pos:
#					last_pos =  current_pos
#					click = 0
#					check()
			if floor_col:
				var current_pos = to_grid(selected, floor_col.position + delta)
				if last_pos != current_pos:
					last_pos =  current_pos
					click = 0
					check()
					emit_signal("sound", "Tap")

func check(force=null):
	if not force:
		force = selected
	if force:
		force.can_build = can_build(force)
		force.update_markers(markers)
		for m in markers:
			var p = terrain.world_to_map((m as Spatial).translation)
			(m as Spatial).translation = terrain.map_to_world(p.x, p.y, p.z)
		force.stop()
		if force.can_build:
			force.down()
			markers[0].set_color(Marker.COLOR.BLUE)

		else:
			force.up()
			markers[0].set_color(Marker.COLOR.RED)

func can_build(force=null):
	if not force:
		force = selected
	assert(force)
	for coor in force.get_collisions():
		var w = terrain.world_to_map(coor)
		var a = int(w.x) in field
		var b = int(w.z) in field[int(w.x)] if a else false

		if not a or not b or field[int(w.x)][int(w.z)] >= 0:
			force.can_build = false
			return false
	force.can_build = true
	return true

func update_markers(count):
	for i in markers.size():
		markers[i].visible = i < count

func change_back(path):
	var back = load("res://Scenes/BackGrounds/%s.tscn" % path).instance()
	for b in $Back.get_children():
		b.queue_free()
	$Back.add_child(back)

func to_grid(obj: Spatial, pos: Vector3):
	var coor = terrain.world_to_map(pos)
	coor = clamp_pos(coor)
	var coor_span = terrain.map_to_world(coor.x, coor.y, coor.z)
	obj.translation.x = coor_span.x
	obj.translation.z = coor_span.z
	coor.y = 0
	return coor

func clamp_pos(coor):
	coor.x =  clamp(coor.x, terrain.min_x-1,  terrain.max_x+1)
	coor.z =  clamp(coor.z, terrain.min_y-1,  terrain.max_y+1)
	return coor
