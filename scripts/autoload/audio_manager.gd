extends Node
## Owns saved audio settings and cached mechanical battle accents.
## Original ambient score and clock SFX honor their individual volume controls.

signal settings_changed(settings: Dictionary)

var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var fast_mode: bool = false
var text_size: String = "normal"
var reduced_motion: bool = false
var _clock_sounds: Dictionary = {}
var _music_player: AudioStreamPlayer


## Short synthesized mechanical accents, cached and governed by existing settings.
func play_clock_sound(cue: String) -> void:
	if master_volume * sfx_volume <= 0.001:
		return
	if not _clock_sounds.has(cue):
		var duration := 0.16 if cue == "tick" else 0.32
		var rate := 22050
		var bytes := PackedByteArray()
		bytes.resize(int(duration * rate) * 2)
		var rng := RandomNumberGenerator.new()
		rng.seed = 713
		for i in range(int(duration * rate)):
			var t := float(i) / float(rate)
			var envelope := exp(-t * (34.0 if cue == "tick" else 15.0)) * minf(t * 800.0, 1.0)
			var frequency := 170.0 if cue == "impact" else (820.0 if cue == "tick" else 420.0)
			var tone := sin(TAU * frequency * t) * 0.45 + sin(TAU * frequency * 2.73 * t) * 0.2
			var noise := rng.randf_range(-1.0, 1.0) * (0.5 if cue == "impact" else 0.18)
			bytes.encode_s16(i * 2, int(clampf((tone + noise) * envelope * 0.45, -1.0, 1.0) * 32767.0))
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = rate
		stream.data = bytes
		_clock_sounds[cue] = stream
	var voice := AudioStreamPlayer.new()
	voice.stream = _clock_sounds[cue]
	voice.volume_db = linear_to_db(clampf(master_volume * sfx_volume, 0.001, 1.0)) - 5.0
	add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()


func _ready() -> void:
	load_settings()
	var score_path := "res://assets/audio/clockwork_nocturne.wav"
	if ResourceLoader.exists(score_path):
		_music_player = AudioStreamPlayer.new()
		var score: AudioStreamWAV = load(score_path).duplicate()
		score.loop_mode = AudioStreamWAV.LOOP_FORWARD
		score.loop_end = int(score.get_length() * score.mix_rate)
		_music_player.stream = score
		add_child(_music_player)
		_update_music_volume()
		_music_player.play()


func _exit_tree() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	_clock_sounds.clear()


func _update_music_volume() -> void:
	if is_instance_valid(_music_player):
		_music_player.volume_db = linear_to_db(maxf(0.00001, master_volume * music_volume)) - 7.0


func load_settings() -> void:
	var data := SaveManager.load_meta()
	var settings: Dictionary = data.get("settings", {})
	master_volume = settings.get("master_volume", 1.0)
	music_volume = settings.get("music_volume", 1.0)
	sfx_volume = settings.get("sfx_volume", 1.0)
	fast_mode = settings.get("fast_mode", false)
	text_size = settings.get("text_size", "normal")
	reduced_motion = settings.get("reduced_motion", false)


func save_settings() -> void:
	var settings := {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"fast_mode": fast_mode,
		"text_size": text_size,
		"reduced_motion": reduced_motion,
	}
	SaveManager.save_meta(settings)
	settings_changed.emit(settings)


func set_master_volume(value: float) -> void:
	master_volume = value
	_update_music_volume()
	save_settings()


func set_music_volume(value: float) -> void:
	music_volume = value
	_update_music_volume()
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = value
	save_settings()


func set_fast_mode(value: bool) -> void:
	fast_mode = value
	save_settings()


func set_text_size(value: String) -> void:
	text_size = value
	save_settings()


## Fast-mode global multiplier on animation/tween durations (pause/settings
## doc Part 3) - screens with tweened feedback should scale their durations
## by this rather than hiding information, per the doc's explicit rule.
func animation_speed_scale() -> float:
	return 2.0 if fast_mode else 1.0
