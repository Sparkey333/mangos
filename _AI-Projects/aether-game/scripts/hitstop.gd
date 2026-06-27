extends Node
## Global hit-stop: briefly freezes time on impact so hits feel weighty.
## Call `HitStop.hit(0.07)`. Uses an ignore-time-scale timer so it always
## un-freezes even though Engine.time_scale is 0 during the freeze.
## (Registered as an autoload singleton in project.godot.)

var _token := 0

func hit(duration := 0.07, scale := 0.0) -> void:
	_token += 1
	var mine := _token
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	if mine == _token:
		Engine.time_scale = 1.0
