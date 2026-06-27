extends CharacterBody2D
## Project Aether — player controller + combat.
## Game feel (GDD): run accel/friction, heavier fall gravity, variable jump
## height, coyote time, jump buffering, dash with i-frames. Combat: a short
## melee hitbox, HP, knockback + hit-stun on damage, and instant respawn.

signal died

# --- movement tunables (game feel lives here) ---
const RUN_SPEED      := 240.0
const ACCEL          := 2200.0
const FRICTION       := 2600.0
const GRAVITY_UP     := 1800.0
const GRAVITY_DOWN   := 2500.0
const JUMP_VELOCITY  := -640.0
const JUMP_CUT       := 0.45
const COYOTE_TIME    := 0.10
const JUMP_BUFFER    := 0.10
const DASH_SPEED     := 640.0
const DASH_TIME      := 0.16
const DASH_COOLDOWN  := 0.45
const DASH_IFRAMES   := 0.22

# --- combat tunables ---
const MAX_HP         := 5
const ATK_COOLDOWN   := 0.30
const ATK_DAMAGE     := 6
const ATK_DURATION   := 0.12
const HIT_IFRAMES    := 0.70
const HIT_STUN       := 0.25
const KNOCKBACK      := Vector2(320, -260)

var has_dash := true
var hp := MAX_HP
var music
var respawn_point := Vector2(160, 520)

var _coyote := 0.0
var _buffer := 0.0
var _dash_t := 0.0
var _dash_cd := 0.0
var _iframes := 0.0
var _hitstun := 0.0
var _atk_cd := 0.0
var _facing := 1.0
var _visual: Polygon2D

func _ready() -> void:
	add_to_group("player")
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
	_hitstun = max(0.0, _hitstun - delta)
	_atk_cd = max(0.0, _atk_cd - delta)

	if is_on_floor():
		_coyote = COYOTE_TIME
	else:
		_coyote = max(0.0, _coyote - delta)
	_buffer = max(0.0, _buffer - delta)
	if _hitstun <= 0.0 and Input.is_action_just_pressed("jump"):
		_buffer = JUMP_BUFFER

	# dash overrides everything
	if _dash_t > 0.0:
		_dash_t -= delta
		velocity = Vector2(_facing * DASH_SPEED, 0.0)
		move_and_slide()
		return

	# during hit-stun: no control, just physics
	if _hitstun > 0.0:
		velocity.y += GRAVITY_DOWN * delta
		move_and_slide()
		return

	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		_facing = signf(dir)
		velocity.x = move_toward(velocity.x, dir * RUN_SPEED, ACCEL * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	var g := GRAVITY_UP if velocity.y < 0.0 else GRAVITY_DOWN
	velocity.y += g * delta

	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_buffer = 0.0
		_coyote = 0.0
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	if Input.is_action_just_pressed("dash") and has_dash and _dash_cd <= 0.0:
		_dash_t = DASH_TIME
		_dash_cd = DASH_COOLDOWN
		_iframes = DASH_IFRAMES
		_dash_flash()

	if Input.is_action_just_pressed("attack") and _atk_cd <= 0.0:
		_attack()

	move_and_slide()

func is_invincible() -> bool:
	return _iframes > 0.0

func _attack() -> void:
	_atk_cd = ATK_COOLDOWN
	var hb := Area2D.new()
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(48, 48)
	cs.shape = sh
	cs.position = Vector2(_facing * 36, 0)
	hb.add_child(cs)
	var vis := Polygon2D.new()
	var hs := Vector2(24, 24)
	vis.position = Vector2(_facing * 36, 0)
	vis.polygon = PackedVector2Array([-hs, Vector2(hs.x, -hs.y), hs, Vector2(-hs.x, hs.y)])
	vis.color = Color(0.95, 0.97, 1.0, 0.5)
	hb.add_child(vis)
	hb.area_entered.connect(func(a):
		if a.is_in_group("boss_hurtbox"):
			var boss := a.get_parent()
			if boss and boss.has_method("take_damage"):
				boss.take_damage(ATK_DAMAGE, global_position)
				HitStop.hit(0.06)
	)
	add_child(hb)
	get_tree().create_timer(ATK_DURATION).timeout.connect(hb.queue_free)

func take_damage(amount: int, from_pos: Vector2) -> void:
	if _iframes > 0.0:
		return
	hp -= amount
	_iframes = HIT_IFRAMES
	_hitstun = HIT_STUN
	var away := signf(global_position.x - from_pos.x)
	if away == 0.0:
		away = -_facing
	velocity = Vector2(away * KNOCKBACK.x, KNOCKBACK.y)
	HitStop.hit(0.09)
	_damage_flash()
	if hp <= 0:
		_die()

func _die() -> void:
	hp = MAX_HP
	global_position = respawn_point
	velocity = Vector2.ZERO
	_iframes = 1.0
	_hitstun = 0.0
	died.emit()

func _dash_flash() -> void:
	_visual.modulate = Color(1, 1, 1, 0.35)
	var t := create_tween()
	t.tween_property(_visual, "modulate", Color(1, 1, 1, 1), 0.18)

func _damage_flash() -> void:
	_visual.color = Color(1, 0.5, 0.5)
	var t := create_tween()
	t.tween_property(_visual, "color", Color(0.5, 0.82, 0.95), 0.35)
