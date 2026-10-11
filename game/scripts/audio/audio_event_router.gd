class_name AudioEventRouter
extends Node
## Listens to the Events bus and asks its parent, the AudioManager, to play the
## matching cue. It only connects; it never emits (docs/CONTRACTS.md, "Events").
##
## Music: arena music starts on the first `player_health_changed` while nothing
## is on. UI is readied before the player, and AudioManager is an autoload
## that outlives scene reloads, so this fires on every fresh run, including after
## Restart. Later health changes find the music already on and do nothing.
## A change to 0 health never starts music, so a stray update after death cannot
## bring it back; the run-ending signals stop it.

const ARENA_MUSIC := &"music.arena"

var _audio: Node


func _ready() -> void:
	_audio = get_parent()
	Events.player_jumped.connect(_cue.bind(&"sfx.jump"))
	Events.player_landed.connect(_cue.bind(&"sfx.land"))
	Events.player_attacked.connect(_cue.bind(&"sfx.attack_swing").unbind(1))
	Events.player_hit_enemy.connect(_on_player_hit_enemy)
	Events.player_hurt.connect(_cue.bind(&"sfx.player_hurt").unbind(1))
	Events.player_died.connect(_on_player_died)
	Events.enemy_died.connect(_on_enemy_died)
	Events.loot_dropped.connect(_on_loot_dropped)
	Events.loot_picked_up.connect(_cue.bind(&"sfx.loot_pickup").unbind(1))
	Events.game_paused.connect(_on_game_paused)
	Events.arena_cleared.connect(_audio.stop_music)
	Events.player_health_changed.connect(_on_player_health_changed)


func _cue(id: StringName) -> void:
	_audio.play_sfx(id)


# At the node's position, or non-positionally if it is gone or off the tree.
func _cue_at(id: StringName, source: Node3D) -> void:
	if is_instance_valid(source) and source.is_inside_tree():
		_audio.play_sfx(id, source.global_position)
	else:
		_audio.play_sfx(id)


func _on_player_hit_enemy(enemy: Node3D, _damage: int) -> void:
	_cue_at(&"sfx.attack_hit", enemy)


func _on_player_died() -> void:
	_audio.stop_music()
	_cue(&"sfx.player_die")


func _on_enemy_died(enemy: Node3D) -> void:
	_cue_at(&"sfx.enemy_die", enemy)


func _on_loot_dropped(_item: ItemData, world_position: Vector3) -> void:
	_audio.play_sfx(&"sfx.loot_drop", world_position)


func _on_game_paused(is_paused: bool) -> void:
	_cue(&"ui.pause_open" if is_paused else &"ui.pause_close")


func _on_player_health_changed(current: int, _maximum: int) -> void:
	if current > 0 and not _audio.is_music_active():
		_audio.play_music(ARENA_MUSIC)
