extends Node
## Plays sound effects and music by id. Streams are registered in `registry`
## (filled from SoundCatalog); an unknown id is reported through `error_reporter`,
## never silence. Audio owns this file (docs/CONTRACTS.md, "Audio").

signal sfx_played(id: StringName)
signal music_started(id: StringName)

const SFX_BUS := &"SFX"
const UI_BUS := &"UI"
const MUSIC_BUS := &"Music"
const NON_POSITIONAL := Vector3.INF
## Simultaneous one-shots per kind (positional / non-positional). When all are
## busy the next sound takes over the next player in round-robin order.
const POOL_SIZE := 12
const DUMMY_DRIVER_NAME := "Dummy"
const NO_DEVICE_MESSAGE := "AudioManager: no audio device (Dummy driver), playback disabled"

## False when there is no audio device (headless Godot uses the Dummy driver, which
## never mixes, so a stream started on it can never be released). Everything else
## still happens - player choice, stream, bus, position, current music, signals -
## only the final `play()` is skipped.
var playback_enabled := true

## Id of the music that is on, or &"" when none is.
var current_music_id: StringName = &""

## Sound id -> stream.
var registry: Dictionary[StringName, AudioStream] = {}

## Receives the message for an unknown id. Defaults to push_error; tests swap it
## so a deliberate failure does not print a real ERROR line into check.sh.
var error_reporter: Callable = _push_error

var _music_player: AudioStreamPlayer
var _flat_pool: Array[AudioStreamPlayer] = []
var _spatial_pool: Array[AudioStreamPlayer3D] = []
var _steal_cursor := 0

static var _no_device_announced := false


func _ready() -> void:
	playback_enabled = AudioServer.get_driver_name() != DUMMY_DRIVER_NAME
	if not playback_enabled and not _no_device_announced:
		_no_device_announced = true
		print(NO_DEVICE_MESSAGE)
	# The pause menu's cues must sound while the tree is paused, and music keeps going.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)
	for _slot in POOL_SIZE:
		var flat := AudioStreamPlayer.new()
		add_child(flat)
		_flat_pool.append(flat)
		var spatial := AudioStreamPlayer3D.new()
		add_child(spatial)
		_spatial_pool.append(spatial)
	_load_registry()
	add_child(AudioEventRouter.new())


## `world_position` of Vector3.INF means non-positional.
func play_sfx(id: StringName, world_position: Vector3 = NON_POSITIONAL) -> void:
	var stream := _lookup(id, false)
	if stream == null:
		return
	if world_position == NON_POSITIONAL:
		var flat := _pick(_flat_pool) as AudioStreamPlayer
		_play_on(flat, stream, _bus_for(id))
	else:
		var spatial := _pick(_spatial_pool) as AudioStreamPlayer3D
		spatial.global_position = world_position
		_play_on(spatial, stream, _bus_for(id))
	sfx_played.emit(id)


## Replaces whatever music is playing; the track loops until stop_music().
func play_music(id: StringName) -> void:
	var stream := _lookup(id, true)
	if stream == null:
		return
	_music_player.stream = stream
	current_music_id = id
	if playback_enabled:
		_music_player.play()
	music_started.emit(id)


func stop_music() -> void:
	_music_player.stop()
	current_music_id = &""


func is_music_active() -> bool:
	return current_music_id != &""


func _load_registry() -> void:
	for id: StringName in SoundCatalog.PATHS:
		var path: String = SoundCatalog.PATHS[id]
		var stream := load(path) as AudioStream
		if stream == null:
			error_reporter.call("AudioManager: cannot load '%s' for sound id '%s'" % [path, id])
			continue
		if _is_music(id):
			_make_looping(stream, id)
		registry[id] = stream


func _make_looping(stream: AudioStream, id: StringName) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	else:
		error_reporter.call("AudioManager: music '%s' is a %s, which cannot loop" % [id, stream.get_class()])


func _lookup(id: StringName, wants_music: bool) -> AudioStream:
	if _is_music(id) != wants_music:
		var kind := "a sound effect" if wants_music else "music"
		var right_call := "play_sfx" if wants_music else "play_music"
		error_reporter.call("AudioManager: '%s' is %s; call %s instead" % [id, kind, right_call])
		return null
	var stream: AudioStream = registry.get(id)
	if stream == null:
		error_reporter.call("AudioManager: unknown sound id '%s'" % id)
	return stream


func _is_music(id: StringName) -> bool:
	return id.begins_with(SoundCatalog.MUSIC_PREFIX)


func _bus_for(id: StringName) -> StringName:
	return UI_BUS if id.begins_with(SoundCatalog.UI_PREFIX) else SFX_BUS


# A free player if there is one, else the next in round-robin order (cutting it off).
func _pick(pool: Array) -> Node:
	for player: Node in pool:
		if not player.playing:
			return player
	_steal_cursor = (_steal_cursor + 1) % pool.size()
	return pool[_steal_cursor]


# `player` is an AudioStreamPlayer or AudioStreamPlayer3D; both share this API.
func _play_on(player: Node, stream: AudioStream, bus: StringName) -> void:
	player.stream = stream
	player.bus = bus
	if playback_enabled:
		player.play()


func _push_error(message: String) -> void:
	push_error(message)
