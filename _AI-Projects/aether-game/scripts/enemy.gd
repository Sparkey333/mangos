extends Node2D
## Training dummy. No combat yet — its job in the slice is to DEMONSTRATE the
## adaptive music: when the player gets close, the combat layer fades in.

const RANGE := 280.0

var player                 # set by world
var music                  # set by world
var _engaged := false

func _ready() -> void:
	var v := Polygon2D.new()
	var hs := Vector2(20, 24)
	v.polygon = PackedVector2Array([-hs, Vector2(hs.x, -hs.y), hs, Vector2(-hs.x, hs.y)])
	v.color = Color(0.85, 0.40, 0.45)
	add_child(v)

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var d := global_position.distance_to(player.global_position)
	if d < RANGE and not _engaged:
		_engaged = true
		if music: music.set_state("combat")
	elif d >= RANGE and _engaged:
		_engaged = false
		if music: music.set_state("explore")
