extends Area2D
## Boss bolt. Flies along `dir`, damages the player on contact, despawns on
## hit or after its lifetime. Set `dir` before adding it to the tree.

var dir := Vector2.LEFT
const SPEED := 300.0
const LIFETIME := 4.0
var _life := LIFETIME

func _ready() -> void:
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 10.0
	cs.shape = sh
	add_child(cs)
	var v := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 8:
		pts.append(Vector2.RIGHT.rotated(TAU * i / 8.0) * 10.0)
	v.polygon = pts
	v.color = Color(1.0, 0.7, 0.4)
	add_child(v)
	body_entered.connect(_on_body)

func _process(delta: float) -> void:
	global_position += dir * SPEED * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()

func _on_body(body) -> void:
	if body and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1, global_position)
		queue_free()
