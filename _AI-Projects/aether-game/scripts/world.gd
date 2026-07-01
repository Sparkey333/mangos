extends Node2D
## Project Aether — vertical-slice arena.
## Greybox room + the M2 goal: walk right past the gate to trigger the first
## boss, a 3-phase escalating fight with a musical arc. Player has real combat
## (attack/HP/respawn) and hit-stop on every connecting blow.

const PlayerScript := preload("res://scripts/player.gd")
const BossScript := preload("res://scripts/boss.gd")
const MusicScript := preload("res://scripts/music_manager.gd")

const SPAWN := Vector2(160, 520)

var music
var _player
var _boss
var _fight_started := false
var _hud: Label
var _banner: Label

func _ready() -> void:
	_setup_input()
	_build_level()

	music = MusicScript.new()
	add_child(music)

	_player = PlayerScript.new()
	_player.position = SPAWN
	_player.respawn_point = SPAWN
	_player.music = music
	add_child(_player)
	_player.died.connect(_on_player_died)
	_add_camera(_player)

	_add_boss_gate(Rect2(600, 280, 36, 380))
	_build_hud()

# --- input (registered in code; no fragile bindings to break) ---
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
		Rect2(700, 470, 150, 26),    # mid platform (dash the gap)
		Rect2(980, 380, 160, 26),    # high platform
	]
	for r in solids:
		_add_solid(r, Color(0.13, 0.16, 0.25))

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

# --- boss fight flow ---
func _add_boss_gate(rect: Rect2) -> void:
	var area := Area2D.new()
	area.position = rect.position + rect.size * 0.5
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	col.shape = shape
	area.add_child(col)
	area.add_child(_rect_visual(rect.size, Color(0.70, 0.40, 0.20, 0.22)))
	area.body_entered.connect(func(b):
		if b.is_in_group("player"):
			_start_fight()
	)
	add_child(area)

func _start_fight() -> void:
	if _fight_started:
		return
	_fight_started = true
	_boss = BossScript.new()
	_boss.position = Vector2(1060, 470)
	_boss.music = music
	_boss.player = _player
	_boss.defeated.connect(_on_boss_defeated)
	add_child(_boss)
	_boss.activate()
	_flash_banner("THE FIRST WARDEN")

func _on_boss_defeated() -> void:
	_boss = null
	_flash_banner("THE WAY OPENS")

func _on_player_died() -> void:
	if is_instance_valid(_boss):
		_boss.queue_free()
	_boss = null
	_fight_started = false
	if music:
		music.set_state("explore")

# --- HUD ---
func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(20, 16)
	_hud.add_theme_color_override("font_color", Color(0.82, 0.90, 1.0))
	_hud.add_theme_font_size_override("font_size", 18)
	layer.add_child(_hud)

	_banner = Label.new()
	_banner.position = Vector2(0, 250)
	_banner.size = Vector2(1280, 60)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_color_override("font_color", Color(0.95, 0.85, 0.7))
	_banner.add_theme_font_size_override("font_size", 40)
	_banner.modulate = Color(1, 1, 1, 0)
	layer.add_child(_banner)

func _flash_banner(text: String) -> void:
	_banner.text = text
	_banner.modulate = Color(1, 1, 1, 1)
	var t := create_tween()
	t.tween_interval(1.4)
	t.tween_property(_banner, "modulate", Color(1, 1, 1, 0), 1.0)

func _process(_delta: float) -> void:
	if not _hud or not is_instance_valid(_player):
		return
	var hearts := ""
	for i in _player.MAX_HP:
		hearts += "♥ " if i < _player.hp else "· "
	var boss_line := ""
	if is_instance_valid(_boss):
		boss_line = "\nWARDEN  P%d  [%s]" % [_boss.phase, _boss_bar()]
	_hud.text = "PROJECT AETHER — vertical slice\nMove A/D · Jump Space · Dash Shift · Attack K\nHP %s   Dash %s%s" % [
		hearts,
		"on" if _player.has_dash else "off",
		boss_line
	]

func _boss_bar() -> String:
	var frac: float = clampf(float(_boss.hp) / float(_boss.MAX_HP), 0.0, 1.0)
	var filled := int(round(frac * 20.0))
	return "#".repeat(filled) + "-".repeat(20 - filled)
