extends GutTest
## The HUD only reads `Events`: bar, numbers, attack name, enemies left.

const HUD_SCENE_PATH := "res://scenes/ui/hud.tscn"
const RUSTED_BLADE_PATH := "res://data/rusted_blade.tres"
const ENEMY_COUNT := 3

var _hud: Hud


func before_each() -> void:
	_hud = add_child_autofree((load(HUD_SCENE_PATH) as PackedScene).instantiate())


func _spawn_enemies(count: int) -> Array[Node3D]:
	var enemies: Array[Node3D] = []
	for i in count:
		var enemy: Node3D = add_child_autofree(Node3D.new())
		enemy.add_to_group(Groups.ENEMIES)
		enemies.append(enemy)
	return enemies


func test_health_bar_and_numbers_follow_player_health_changed() -> void:
	Events.player_health_changed.emit(70, 100)
	var bar := _hud.get_node("%HealthBar") as ProgressBar
	assert_eq(bar.max_value, 100.0)
	assert_eq(bar.value, 70.0)
	assert_eq((_hud.get_node("%HealthLabel") as Label).text, "70 / 100")


func test_health_bar_tracks_a_changed_maximum() -> void:
	Events.player_health_changed.emit(40, 40)
	var bar := _hud.get_node("%HealthBar") as ProgressBar
	assert_eq(bar.max_value, 40.0)
	assert_eq(bar.value, 40.0)


func test_attack_name_follows_attack_changed() -> void:
	Events.attack_changed.emit(load(RUSTED_BLADE_PATH) as AttackData)
	assert_eq((_hud.get_node("%AttackLabel") as Label).text, "Rusted Blade")


func test_enemy_count_is_read_one_frame_after_ready() -> void:
	var enemies := _spawn_enemies(ENEMY_COUNT)
	assert_eq((_hud.get_node("%EnemiesLabel") as Label).text, "Enemies: 0", "not read yet")
	await get_tree().process_frame
	assert_eq((_hud.get_node("%EnemiesLabel") as Label).text, "Enemies: %d" % enemies.size())


func test_enemy_died_counts_down_and_stops_at_zero() -> void:
	var enemies := _spawn_enemies(1)
	await get_tree().process_frame
	var label := _hud.get_node("%EnemiesLabel") as Label
	Events.enemy_died.emit(enemies[0])
	assert_eq(label.text, "Enemies: 0")
	Events.enemy_died.emit(enemies[0])
	assert_eq(label.text, "Enemies: 0", "never negative")


func test_hud_does_not_block_the_mouse() -> void:
	assert_eq(_hud.mouse_filter, Control.MOUSE_FILTER_IGNORE)
