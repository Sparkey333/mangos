extends CharacterBody2D
## Project Aether — player controller.
## Implements the GDD "game feel" basics: run accel/friction, heavier fall
## gravity, variable jump height, coyote time, jump buffering, and a dash with
## i-frames + cooldown. Tunables up top are where the feel lives — tweak freely.

# --- tunables (the GDD's "game feel" knobs) ---
const RUN_SPEED      := 240.0
const ACCEL          := 2200.0
const FRICTION       := 2600.0
const GRAVITY_UP     := 1800.0   # rising
const GRAVITY_DOWN   := 2500.0   # falling — heavier = snappier
const JUMP_VELOCITY  := -640.0
const JUMP_CUT       := 0.45     # tap-to-shorten jump
const COYOTE_TIME    := 0.10     # forgiveness after leaving a ledge
const JUMP_BUFFER    := 0.10     # forgiveness pressing jump early
const DASH_SPEED     := 640.0
const DASH_TIME      := 0.16
const DASH_COOLDOWN  := 0.45
const DASH_IFRAMES   := 0.22

var has_dash := true          # the slice's unlockable ability (on by default to feel it)
var music                     # MusicManager (set by world)

var _coyote := 0.0
var _buffer := 0.0
var _dash_t := 0.0
var _dash_cd := 0.0
var _iframes := 0.0
var _facing := 1.0
var _visual: Polygon2D

func _ready() -> void:
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(36, 56)
	col.shape = shape
	add_child(col)

	_visual = Polygon2D.new()
	var hs := Vector2(18, 28)
	_visual.polygon = PackedVector2Array([-hs, Vector2(hs.x, -hs.y), hs, Vector2(-hs.x, hs.y)])
	_visual.color = Color(0.5, 0.82, 0.95)
	add_child(_visual)

func _physics_process(delta: float) -> void:
	_dash_cd = max(0.0, _dash_cd - delta)
	_iframes = max(0.0, _iframes - delta)

	# coyote + jump buffer timers
	if is_on_floor():
		_coyote = COYOTE_TIME
	else:
		_coyote = max(0.0, _coyote - delta)
	_buffer = max(0.0, _buffer - delta)
	if Input.is_action_just_pressed("jump"):
		_buffer = JUMP_BUFFER

	# --- dash overrides normal motion ---
	if _dash_t > 0.0:
		_dash_t -= delta
		velocity = Vector2(_facing * DASH_SPEED, 0.0)
		move_and_slide()
		return

	# horizontal run
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		_facing = signf(dir)
		velocity.x = move_toward(velocity.x, dir * RUN_SPEED, ACCEL * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	# gravity (heavier on the way down)
	var g := GRAVITY_UP if velocity.y < 0.0 else GRAVITY_DOWN
	velocity.y += g * delta

	# jump (buffered + coyote)
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_buffer = 0.0
		_coyote = 0.0
	# variable jump height
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	# dash start
	if Input.is_action_just_pressed("dash") and has_dash and _dash_cd <= 0.0:
		_dash_t = DASH_TIME
		_dash_cd = DASH_COOLDOWN
		_iframes = DASH_IFRAMES
		_dash_flash()

	move_and_slide()

func is_invincible() -> bool:
	return _iframes > 0.0

func _dash_flash() -> void:
	_visual.modulate = Color(1, 1, 1, 0.35)
	var t := create_tween()
	t.tween_property(_visual, "modulate", Color(1, 1, 1, 1), 0.18)
