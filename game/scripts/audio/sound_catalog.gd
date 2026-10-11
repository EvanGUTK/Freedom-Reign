class_name SoundCatalog
extends RefCounted
## Sound id -> asset path for every sound the slice ships. The ids are the
## contract (docs/CONTRACTS.md, "Audio"); the paths follow the naming scheme in
## assets/audio/README.md and are written by tools/audio/generate.py.

const MUSIC_PREFIX := "music."
const UI_PREFIX := "ui."

const PATHS: Dictionary[StringName, String] = {
	&"sfx.jump": "res://assets/audio/sfx/jump.wav",
	&"sfx.land": "res://assets/audio/sfx/land.wav",
	&"sfx.attack_swing": "res://assets/audio/sfx/attack_swing.wav",
	&"sfx.attack_hit": "res://assets/audio/sfx/attack_hit.wav",
	&"sfx.player_hurt": "res://assets/audio/sfx/player_hurt.wav",
	&"sfx.player_die": "res://assets/audio/sfx/player_die.wav",
	&"sfx.enemy_die": "res://assets/audio/sfx/enemy_die.wav",
	&"sfx.loot_drop": "res://assets/audio/sfx/loot_drop.wav",
	&"sfx.loot_pickup": "res://assets/audio/sfx/loot_pickup.wav",
	&"ui.pause_open": "res://assets/audio/ui/pause_open.wav",
	&"ui.pause_close": "res://assets/audio/ui/pause_close.wav",
	&"ui.click": "res://assets/audio/ui/click.wav",
	&"music.arena": "res://assets/audio/music/arena.ogg",
}
