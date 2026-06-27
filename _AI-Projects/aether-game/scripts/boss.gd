extends CharacterBody2D
## "The First Warden" — the slice's first boss.
## A 3-phase escalation, each phase faster with an added attack, each phase
## raising the music a layer (see MusicManager.boss_phase):
##   Phase 1: slow — charge OR a single bolt.
##   Phase 2: faster — adds a 3-bolt spread.
##   Phase 3 (desperation): rapid charges + 5-bolt spread, music goes full.
## Story is SHOWN, not told (GDD pillar): it telegraphs every attack with a
## colour wind-up so difficulty comes from reading, not surprise.

signal defeated

const Projectile := preload("res://scripts/projectile.gd")

const MAX_HP := 120
const SIZE := Vector2(84, 96)
const PHASE_THRESHOLDS := [80, 40]   # hp entering phase 2, then phase 3

var music
var player
var hp := MAX_HP
var phase := 1
var state := "sleep"                 # sleep, idle, telegraph, charge, recover, dead
var _t := 0.0
var _phase_invuln := 0.0
var _attack := ""
var _target_x := 0.0
var _home := Vector2.ZERO
var _visual: Polygon2D
var _base_color := Color(0.62, 0.30, 0.46)

func _ready() -> void:
	_home = position
	var col := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = SIZE
	col.shape = sh
	add_child(col)

	_visual = Polygon2D.new()
	var hs := SIZE * 0.5
	_visual.polygon = PackedVector2Array([-hs, Vector2(hs.x, -hs.y), hs, Vector2(-hs.x, hs.y)])
	_visual.color = _base_color
	add_child(_visual)

	var hurt := Area2D.new()                 # player attacks land here
	hurt.add_to_group("boss_hurtbox")
	var hc := CollisionShape2D.new()
	var hsh := RectangleShape2D.new()
	hsh.size = SIZE
	hc.shape = hsh
	hurt.add_child(hc)
	add_child(hurt)

	var contact := Area2D.new()              # hurts player while charging
	var cc := CollisionShape2D.new()
	var csh := RectangleShape2D.new()
	csh.size = SIZE
	cc.shape = csh
	contact.add_child(cc)
	contact.body_entered.connect(_on_contact)
	add_child(contact)

	set_physics_process(false)               # dormant until activated

func activate() -> void:
	state = "idle"
	_t = 1.0
	set_physics_process(true)
	if music: music.boss_phase(1)

func _on_contact(body) -> void:
	if state == "charge" and body and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1, global_position)

func _physics_process(delta: float) -> void:
	_phase_invuln = max(0.0, _phase_invuln - delta)
	if state == "dead":
		return
	_t -= delta
	match state:
		"idle":
			_hover(delta, 60.0)
			if _t <= 0.0:
				_begin_attack()
		"telegraph":
			_visual.color = _base_color.lerp(Color(1, 1, 0.6), 0.5 + 0.5 * sin(_t * 40.0))
			if _t <= 0.0:
				_fire_attack()
		"charge":
			var dirx := signf(_target_x - global_position.x)
			velocity = Vector2(dirx * _charge_speed(), 0.0)
			move_and_slide()
			if absf(global_position.x - _target_x) < 24.0 or _t <= 0.0:
				_visual.color = _base_color
				state = "recover"
				_t = _recover_time()
		"recover":
			_hover(delta, 30.0)
			if _t <= 0.0:
				state = "idle"
				_t = _idle_time()

func _hover(delta: float, follow_speed: float) -> void:
	var px := global_position.x
	if is_instance_valid(player):
		px = player.global_position.x
	global_position.x = move_toward(global_position.x, clampf(px, _home.x - 360.0, _home.x + 40.0), follow_speed * delta)
	global_position.y = _home.y + sin(Time.get_ticks_msec() / 450.0) * 14.0
	velocity = Vector2.ZERO

func _begin_attack() -> void:
	if phase == 1:
		_attack = "charge" if randf() < 0.5 else "volley"
	elif phase == 2:
		_attack = ["charge", "volley", "volley"][randi() % 3]
	else:
		_attack = "charge" if randf() < 0.6 else "volley"
	state = "telegraph"
	_t = _telegraph_time()

func _fire_attack() -> void:
	if _attack == "charge":
		_target_x = player.global_position.x if is_instance_valid(player) else global_position.x
		_visual.color = Color(1, 0.85, 0.4)
		state = "charge"
		_t = 1.2
	else:
		_volley()
		_visual.color = _base_color
		state = "recover"
		_t = _recover_time()

func _volley() -> void:
	var count := 1
	if phase == 2: count = 3
	elif phase == 3: count = 5
	var to := Vector2.LEFT
	if is_instance_valid(player):
		to = (player.global_position - global_position).normalized()
	var base_ang := to.angle()
	var spread := deg_to_rad(16.0)
	for i in count:
		var off := (i - (count - 1) / 2.0) * spread
		var p := Projectile.new()
		p.global_position = global_position
		p.dir = Vector2.RIGHT.rotated(base_ang + off)
		get_parent().add_child(p)

func _idle_time() -> float: return [0.0, 1.1, 0.8, 0.5][phase]
func _telegraph_time() -> float: return [0.0, 0.6, 0.45, 0.32][phase]
func _recover_time() -> float: return [0.0, 0.8, 0.6, 0.4][phase]
func _charge_speed() -> float: return [0.0, 420.0, 520.0, 640.0][phase]

func take_damage(amount: int, from_pos: Vector2) -> void:
	if state == "dead" or _phase_invuln > 0.0:
		return
	hp -= amount
	_damage_flash()
	if phase <= 2 and hp <= PHASE_THRESHOLDS[phase - 1]:
		_advance_phase()
	elif hp <= 0:
		_die()

func _advance_phase() -> void:
	phase += 1
	_phase_invuln = 1.1
	state = "recover"
	_t = 0.9
	if music: music.boss_phase(phase)
	var t := create_tween()
	_visual.color = Color(1, 1, 1)
	t.tween_property(_visual, "color", _base_color, 0.5)

func _damage_flash() -> void:
	var t := create_tween()
	_visual.color = Color(1, 1, 1)
	t.tween_property(_visual, "color", _base_color, 0.12)

func _die() -> void:
	state = "dead"
	set_physics_process(false)
	if music: music.set_state("explore")
	defeated.emit()
	var t := create_tween()
	t.tween_property(_visual, "modulate", Color(1, 1, 1, 0), 1.2)
	t.tween_callback(queue_free)
