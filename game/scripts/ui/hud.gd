class_name Hud
extends Control
## Health, current attack and enemies remaining, driven only by `Events`.
## Sits in the screen corners so nothing covers the centre.

const HEALTH_TEXT_FORMAT := "%d / %d"
const ENEMIES_TEXT_FORMAT := "Enemies: %d"

@onready var _health_bar: ProgressBar = %HealthBar
@onready var _health_label: Label = %HealthLabel
@onready var _attack_label: Label = %AttackLabel
@onready var _enemies_label: Label = %EnemiesLabel

var _enemies_remaining := 0


func _ready() -> void:
	_show_enemies(0)
	Events.player_health_changed.connect(_on_player_health_changed)
	Events.attack_changed.connect(_on_attack_changed)
	Events.enemy_died.connect(_on_enemy_died)
	# UI is readied before the Actors node spawns the husks, so the group is
	# still empty here; count it one frame later.
	await get_tree().process_frame
	_show_enemies(get_tree().get_nodes_in_group(Groups.ENEMIES).size())


func _on_player_health_changed(current: int, maximum: int) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	_health_label.text = HEALTH_TEXT_FORMAT % [current, maximum]


func _on_attack_changed(attack: AttackData) -> void:
	_attack_label.text = attack.display_name


func _on_enemy_died(_enemy: Node3D) -> void:
	_show_enemies(maxi(_enemies_remaining - 1, 0))


func _show_enemies(count: int) -> void:
	_enemies_remaining = count
	_enemies_label.text = ENEMIES_TEXT_FORMAT % count
