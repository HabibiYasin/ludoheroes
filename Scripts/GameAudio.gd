extends Node

const MAIN_MUSIC = preload("res://Sounds/Music/Main Music.mp3")
const DICE_ROLL = preload("res://Sounds/SFX/dice_roll.wav")
const ATTACK = preload("res://Sounds/SFX/attack.wav")

var music: AudioStreamPlayer
var dice_sound: AudioStreamPlayer
var attack_sound: AudioStreamPlayer
const CHANNELS := ["Music", "SFX"]
var levels := {"Music": 4, "SFX": 4}
var muted := {"Music": false, "SFX": false}
signal settings_changed

func _ready() -> void:
	var settings := ConfigFile.new()
	settings.load("user://settings.cfg")
	var volume := clampf(float(settings.get_value("audio", "volume", 80)), 0.0, 100.0)
	AudioServer.set_bus_volume_db(0, 0.0)
	AudioServer.set_bus_mute(0, false)
	for channel in CHANNELS:
		if AudioServer.get_bus_index(channel) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, channel)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
		levels[channel] = clampi(int(settings.get_value("audio", channel + "_level", roundi(volume / 20.0))), 1, 5)
		muted[channel] = bool(settings.get_value("audio", channel + "_muted", volume == 0))
		_apply_channel(channel)
	music = _player(-12.0)
	music.bus = "Music"
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	var looped_music := MAIN_MUSIC.duplicate() as AudioStreamMP3
	looped_music.loop = true
	music.stream = looped_music
	dice_sound = _player(-3.0)
	dice_sound.bus = "SFX"
	dice_sound.stream = DICE_ROLL
	attack_sound = _player(-3.0)
	attack_sound.bus = "SFX"
	attack_sound.stream = ATTACK

func _apply_channel(channel: String) -> void:
	var index := AudioServer.get_bus_index(channel)
	AudioServer.set_bus_volume_db(index, linear_to_db(float(levels[channel]) / 5.0))
	AudioServer.set_bus_mute(index, muted[channel])

func set_level(channel: String, value: int) -> void:
	if not CHANNELS.has(channel):
		return
	levels[channel] = clampi(value, 1, 5)
	_apply_channel(channel)
	save_settings()
	settings_changed.emit()

func set_muted(channel: String, value: bool) -> void:
	if not CHANNELS.has(channel):
		return
	muted[channel] = value
	_apply_channel(channel)
	save_settings()
	settings_changed.emit()

func save_settings() -> void:
	# Merge into the latest file so display settings are preserved.
	var settings := ConfigFile.new()
	settings.load("user://settings.cfg")
	for channel in CHANNELS:
		settings.set_value("audio", channel + "_level", levels[channel])
		settings.set_value("audio", channel + "_muted", muted[channel])
	var error := settings.save("user://settings.cfg")
	if error != OK:
		push_warning("Pengaturan audio tidak dapat disimpan: %s" % error_string(error))

func _player(volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.volume_db = volume_db
	add_child(player)
	return player

func play_main_music() -> void:
	# Keep the same track playing through the menu-to-game transition.
	if not music.playing:
		music.play()

func stop_for_results() -> void:
	music.stop()
	dice_sound.stop()
	attack_sound.stop()

func play_dice_roll() -> void:
	dice_sound.play()

func play_attack() -> void:
	attack_sound.play()
