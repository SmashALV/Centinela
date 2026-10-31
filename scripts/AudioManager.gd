extends Node

const TRACKS := {
	"explore": "res://assets/audio/explore_loop.wav",
	"arena": "res://assets/audio/arena_loop.wav"
}
const EFFECTS := {
	"school_bell": "res://assets/audio/school_bell.wav",
	"confirm": "res://assets/audio/confirm.wav",
	"interact": "res://assets/audio/interact.wav",
	"ability": "res://assets/audio/ability.wav",
	"result": "res://assets/audio/result.wav",
	"pickup": "res://assets/audio/pickup.wav",
	"door": "res://assets/audio/door.wav",
	"notification": "res://assets/audio/notification.wav",
	"sleep": "res://assets/audio/sleep.wav"
}
const LEVELS := [0, 25, 50, 75, 100]

var music: AudioStreamPlayer
var effects: Array[AudioStreamPlayer] = []
var context := ""
var _next_effect := 0
var _settings_busy := false

func _ready() -> void:
	music = AudioStreamPlayer.new()
	music.name = "Music"
	add_child(music)
	for i in 3:
		var player := AudioStreamPlayer.new()
		player.name = "Effect%d" % i
		add_child(player)
		effects.append(player)
	apply_preferences()

func apply_preferences() -> void:
	music.volume_db = _volume_db(GameState.music_volume)
	for player in effects:
		player.volume_db = _volume_db(GameState.effects_volume)

func _volume_db(level: int) -> float:
	return -80.0 if level == 0 else linear_to_db(float(level) / 100.0)

func enter_context(next_context: String) -> void:
	if context == next_context:
		return
	context = next_context
	music.stop()
	music.stream = null
	if DisplayServer.get_name() == "headless" or not TRACKS.has(next_context):
		return
	var stream: AudioStream = load(TRACKS[next_context])
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.stream = stream
	music.stream_paused = false
	music.play()

func set_music_paused(value: bool) -> void:
	music.stream_paused = value

func play_effect(key: String) -> void:
	if DisplayServer.get_name() == "headless" or GameState.effects_volume == 0 or not EFFECTS.has(key):
		return
	var player := effects[_next_effect]
	_next_effect = (_next_effect + 1) % effects.size()
	player.stream = load(EFFECTS[key])
	player.play()

func stop_all() -> void:
	music.stop()
	music.stream = null
	context = ""
	for player in effects:
		player.stop()
		player.stream = null

func cycle_level(which: String) -> bool:
	if _settings_busy or which not in ["music", "effects"]:
		return false
	_settings_busy = true
	var previous: int = GameState.music_volume if which == "music" else GameState.effects_volume
	var next: int = LEVELS[(LEVELS.find(previous) + 1) % LEVELS.size()]
	if which == "music":
		GameState.music_volume = next
	else:
		GameState.effects_volume = next
	if await SaveManager.save_slot_async():
		apply_preferences()
		_settings_busy = false
		return true
	if which == "music":
		GameState.music_volume = previous
	else:
		GameState.effects_volume = previous
	_settings_busy = false
	return false
