extends Node2D
## Project Aether — vertical-slice blockout.
## Builds a greybox room in code, registers input, spawns the player + camera,
## a training-dummy enemy, a boss zone, the adaptive music manager, and a HUD.
## Everything is intentionally simple greyboxing — replace blockboxes with real
## tilesets/art and the Polygon2D visuals with sprites as you build out the GDD.

const PlayerScript := preload("res://scripts/player.gd")
const EnemyScript := preload("res://scripts/enemy.gd")
const MusicScript := preload("res://scripts/music_manager.gd")

var music
var _player
var _hud: Label

func _ready() -> void:
	_setup_input()
	_build_level()

	music = MusicScript.new()
	add_child(music)

	_player = PlayerScript.new()
	_player.position = Vector2(160, 520)
	_player.music = music
	add_child(_player)
	_add_camera(_player)

	_spawn_enemy(Vector2(840, 560))
	_add_boss_zone(Rect2(1090, 470, 150, 170))
	_build_hud()

# --- input (registered in code so the project needs no fragile input map) ---
func _setup_input() -> void:
	_ensure("move_left", [KEY_A, KEY_LEFT])
	_ensure("move_right", [KEY_D, KEY_RIGHT])
	_ensure("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_ensure("dash", [KEY_SHIFT, KEY_J])
	_ensure("attack", [KEY_K, KEY_X])

func _ensure(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

# --- greybox level ---
func _build_level() -> void:
	var solids := [
		Rect2(0, 660, 1280, 60),     # floor
		Rect2(0, 0, 32, 720),        # left wall
		Rect2(1248, 0, 32, 720),     # right wall
		Rect2(360, 540, 200, 26),    # low platform
		Rect2(660, 430, 180, 26),    # mid platform (dash the gap to reach it)
		Rect2(960, 330, 180, 26),    # high platform
	]
	for r in solids:
		_add_solid(r, Color(0.13, 0.16, 0.25))
	# an orange marker block = a future "dash gate" hint
	_add_solid(Rect2(596, 560, 24, 100), Color(0.86, 0.49, 0.30))

func _add_solid(rect: Rect2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	col.shape = shape
	body.add_child(col)
	body.add_child(_rect_visual(rect.size, color))
	add_child(body)

func _rect_visual(size: Vector2, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	var hs := size * 0.5
	poly.polygon = PackedVector2Array([-hs, Vector2(hs.x, -hs.y), hs, Vector2(-hs.x, hs.y)])
	poly.color = color
	return poly

func _add_camera(target: Node2D) -> void:
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	target.add_child(cam)
	cam.make_current()

func _spawn_enemy(pos: Vector2) -> void:
	var e := EnemyScript.new()
	e.position = pos
	e.player = _player
	e.music = music
	add_child(e)

func _add_boss_zone(rect: Rect2) -> void:
	var area := Area2D.new()
	area.position = rect.position + rect.size * 0.5
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	col.shape = shape
	area.add_child(col)
	area.add_child(_rect_visual(rect.size, Color(0.70, 0.40, 0.20, 0.25)))
	area.body_entered.connect(func(_b): if music: music.set_state("boss"))
	area.body_exited.connect(func(_b): if music: music.set_state("explore"))
	add_child(area)

# --- HUD ---
func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(20, 16)
	_hud.add_theme_color_override("font_color", Color(0.82, 0.90, 1.0))
	_hud.add_theme_font_size_override("font_size", 18)
	layer.add_child(_hud)

func _process(_delta: float) -> void:
	if _hud and is_instance_valid(_player):
		_hud.text = "PROJECT AETHER — vertical slice\nMove A/D · Jump Space/W · Dash Shift/J · Attack K/X\nDash: %s   |   Music layer: %s   (walk to the dummy / orange zone to hear it shift)" % [
			"unlocked" if _player.has_dash else "locked",
			music.state if music else "-"
		]
