extends Node
## Signal bus. Gameplay emits; UI and audio connect. Nobody calls into a UI or
## audio node from gameplay, and UI/audio never call gameplay nodes.
## Adding a signal is a contract change (docs/CONTRACTS.md) via the chief.

@warning_ignore_start("unused_signal")
signal player_health_changed(current: int, maximum: int)
signal player_jumped()
signal player_landed()
## The swing started.
signal player_attacked(attack: AttackData)
signal player_hit_enemy(enemy: Node3D, damage: int)
signal player_hurt(damage: int)
signal player_died()
## Emitted once at spawn and on every loot pickup.
signal attack_changed(attack: AttackData)
signal enemy_died(enemy: Node3D)
signal loot_dropped(item: ItemData, world_position: Vector3)
signal loot_picked_up(item: ItemData)
## The last enemy died.
signal arena_cleared()
## Emitted by the pause menu. Gameplay honours get_tree().paused through
## process_mode and never polls this signal.
signal game_paused(is_paused: bool)
@warning_ignore_restore("unused_signal")
