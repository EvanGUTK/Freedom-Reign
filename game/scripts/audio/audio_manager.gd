extends Node
## Plays sound effects and music by id. Streams are registered in `registry`;
## an unknown id is a push_error, never silence. Audio owns this file after the
## milestone 2 foundation (docs/CONTRACTS.md, "Audio").

const SFX_BUS := &"SFX"
const MUSIC_BUS := &"Music"
const NON_POSITIONAL := Vector3.INF

## Sound id -> stream. Filled by the audio role as assets land.
var registry: Dictionary[StringName, AudioStream] = {}

## Receives the message for an unknown id. Defaults to push_error; tests swap it
## so a deliberate failure does not print a real ERROR line into check.sh.
var error_reporter: Callable = _push_error

var _music_player: AudioStreamPlayer


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)


## `world_position` of Vector3.INF means non-positional.
func play_sfx(id: StringName, world_position: Vector3 = NON_POSITIONAL) -> void:
	var stream := _lookup(id)
	if stream == null:
		return
	if world_position == NON_POSITIONAL:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		_start_one_shot(player, stream)
	else:
		var player_3d := AudioStreamPlayer3D.new()
		player_3d.bus = SFX_BUS
		_start_one_shot(player_3d, stream)
		player_3d.global_position = world_position


func play_music(id: StringName) -> void:
	var stream := _lookup(id)
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func _lookup(id: StringName) -> AudioStream:
	var stream: AudioStream = registry.get(id)
	if stream == null:
		error_reporter.call("AudioManager: unknown sound id '%s'" % id)
	return stream


func _push_error(message: String) -> void:
	push_error(message)


# Adds the player to the tree, plays it, and frees it when it finishes.
func _start_one_shot(player: Node, stream: AudioStream) -> void:
	player.stream = stream
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()
