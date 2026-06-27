extends Node
## Adaptive layered music — your live electric-guitar + drums, three synced stems
## whose VOLUMES cross-fade by game state:
##   ambient.ogg -> exploration bed (always audible)
##   combat.ogg  -> fades in near enemies
##   boss.ogg    -> full theme inside boss arenas
## Drop your OGG loops in res://audio/ (see audio/README.md). With no files
## present this runs silently — the state machine still works, so you can wire
## and test gameplay before the music is recorded.

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
	_fade("ambient", 0.0 if s == "explore" or s == "combat" else -8.0)
	_fade("combat", 0.0 if s == "combat" else MUTE)
	_fade("boss", 0.0 if s == "boss" else MUTE)

func _fade(key: String, target_db: float, dur := 0.6) -> void:
	if not _players.has(key):
		return
	var p: AudioStreamPlayer = _players[key]
	var t := create_tween()
	t.tween_property(p, "volume_db", target_db, dur)
