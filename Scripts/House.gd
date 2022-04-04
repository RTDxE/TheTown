extends StaticBody
class_name House
tool

export (int) var level = 1
signal build
signal built
enum STATE{
	UP,
	DOWN,
	BUILT,
	PREPARE
}
var colors : Array = [0,0,0,0]
var rays : Array = []
var can_build = false
var field = {}
const base_y = 0
var state = STATE.DOWN
onready var tween = $Tween
export (bool) var decor = true setget set_decor

func set_decor(b):
	decor = b
	if has_node("Visual"):
		if b:
			colors = [99,99,99,99]
			state = STATE.BUILT
			$Visual.translation.y = 0
			translation.y = 0
		else:
			colors = [1,2,3,4]
			state = STATE.DOWN
			translation.y = 1
		# print(colors)
		for blds in $Visual.get_children():
			for bld in  blds.get_children():
				if bld is MeshInstance:
					if b:
						bld.material_override = preload("res://Models/gray_texture.material")
					else:
						bld.material_override = null

func _ready() -> void:
	rays = $Rays.get_children()
	$AnimationPlayer.connect("animation_finished", self, "anim_end")
	if decor:
		$Visual.translation.y = 0
		translation.y = 0
	else:
		translation.y = 1

func prepare():
	state = STATE.PREPARE
	$AnimationPlayer.play("Prepare")

func anim_end(anim):
	# print("Anim end, ", anim)
	match anim:
		"Start", "Down":
			state = STATE.DOWN
		"Up":
			state = STATE.UP
		"Prepare":
			emit_signal("build")

func get_collisions():
	var result = []
	for r in rays:
#		r.force_raycast_update()
#		if r.is_colliding():
#			result.append(r.get_collision_point())
		var pos = r.global_transform.origin
		pos.y = 0
		result.append(pos)


	return result

func set_colors(arr):
	colors = arr
	for c in $Visual.get_children():
		Helper.set_mats(c, arr)

func stop():
	$Visual.translation = Vector3(0,base_y,0)
	if $AnimationPlayer.is_playing() and $AnimationPlayer.current_animation == "Prepare":
		$AnimationPlayer.stop()
		
	$Visual.rotation = Vector3(0,0,0)
	state = STATE.UP if not can_build else STATE.DOWN

func start():
	translation.y = 1
	$AnimationPlayer.play("Start")

func build():
	collision_layer= 0
	if not decor:
		if ($AnimationPlayer.is_playing()):
			$AnimationPlayer.playback_speed = 3
			yield($AnimationPlayer, "animation_finished")
			$AnimationPlayer.playback_speed = 1
		$AnimationPlayer.play("Build")
		state = STATE.BUILT
		var t = get_tree().create_timer(0.3)
		t.connect("timeout", self, "emit_signal", ["built"])

func update_markers(markers):
	for i in $Rays.get_child_count():
		markers[i].translation = $Rays.get_child(i).global_transform.origin
		markers[i].translation.y = 0

func markers_count():
	 return $Rays.get_child_count()

func up():
	tween.stop_all()
	if int(floor(translation.y)) != 4:
		tween.interpolate_property(self, "translation:y", translation.y, 4, 0.15, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		tween.start()
		state = STATE.UP
#	if not $AnimationPlayer.current_animation == "Up" and not can_build and state != STATE.UP:
#		$AnimationPlayer.play("Up")

func down():
	tween.stop_all()
	if int(floor(translation.y)) != 1:
		tween.interpolate_property(self, "translation:y", translation.y, 1, 0.15, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		tween.start()
		state = STATE.DOWN


func tween_complete() -> void:
	pass
#	state = STATE.UP if not can_build else STATE.DOWN
