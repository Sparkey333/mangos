extends Node
## Adaptive layered music — your live electric-guitar + drums, three synced stems
## whose VOLUMES (and pitch) cross-fade by game state and boss phase:
##   ambient.ogg -> exploration bed
##   combat.ogg  -> fades in near enemies / mid boss fight
##   boss.ogg    -> the boss theme; intensifies each phase
## Drop OGG loops in res://audio/ (see audio/README.md). With no files present it
## runs silently — the state machine still works, so gameplay is testable first.

const STEMS := {
	"ambient": "res://audio/ambient.ogg",
	"combat":  "res://audio/combat.ogg",
	"boss":    "res://audio/boss.ogg",
}
const MUTE := -40.0

var state := "explore"
var _players := {}

func _ready() -> void:
	for key in STEMS.keys():
		var p := AudioStreamPlayer.new()
		var path: String = STEMS[key]
		if ResourceLoader.exists(path):
			var stream = load(path)
			if stream is AudioStream:
				if "loop" in stream:
					stream.loop = true
				p.stream = stream
		p.volume_db = MUTE
		add_child(p)
		_players[key] = p
		if p.stream:
			p.play()
	set_state("explore")

func set_state(s: String) -> void:
	state = s
	_pitch(1.0)
	_fade("ambient", 0.0 if s == "explore" or s == "combat" else -8.0)
	_fade("combat", 0.0 if s == "combat" else MUTE)
	_fade("boss", 0.0 if s == "boss" else MUTE)

## Called by the boss on each phase: 1 = bed, 2 = + combat layer, 3 = full + pitch up.
func boss_phase(n: int) -> void:
	state = "boss"
	match n:
		1:
			_fade("ambient", MUTE); _fade("combat", MUTE); _fade("boss", 0.0); _pitch(1.0)
		2:
			_fade("ambient", MUTE); _fade("combat", -4.0); _fade("boss", 0.0); _pitch(1.0)
		_:
			_fade("ambient", -10.0); _fade("combat", 0.0); _fade("boss", 0.0); _pitch(1.05)

func _pitch(scale: float) -> void:
	for p in _players.values():
		p.pitch_scale = scale

func _fade(key: String, target_db: float, dur := 0.6) -> void:
	if not _players.has(key):
		return
	var p: AudioStreamPlayer = _players[key]
	var t := create_tween()
	t.tween_property(p, "volume_db", target_db, dur)
