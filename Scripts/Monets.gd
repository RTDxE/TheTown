extends Spatial

func fire(c=4):
	if  c == 0:
		queue_free()
	else:
		$Particles.amount = c
		$Particles.emitting = true
		$Coins.pitch_scale = 1.0 + randf() * 0.1
