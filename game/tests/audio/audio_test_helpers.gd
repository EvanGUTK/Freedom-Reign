class_name AudioTestHelpers
extends RefCounted
## Finds the pooled players of an AudioManager instance that were given a stream,
## so tests can observe which path a sound took. With no audio device the manager
## configures a player but never calls play(), so "configured" is what is asserted.

const SFX_BUSES: Array[StringName] = [&"SFX", &"UI"]
const MUSIC_BUSES: Array[StringName] = [&"Music"]


static func configured_flat_sfx(manager: Node) -> Array[Node]:
	return _players(manager, "AudioStreamPlayer", SFX_BUSES, true)


static func configured_spatial_sfx(manager: Node) -> Array[Node]:
	return _players(manager, "AudioStreamPlayer3D", SFX_BUSES, true)


static func music_players(manager: Node) -> Array[Node]:
	return _players(manager, "AudioStreamPlayer", MUSIC_BUSES, false)


static func _players(manager: Node, type_name: String, buses: Array[StringName], only_configured: bool) -> Array[Node]:
	var found: Array[Node] = []
	for child in manager.get_children():
		if child.is_class(type_name) and child.bus in buses and (child.stream != null or not only_configured):
			found.append(child)
	return found
