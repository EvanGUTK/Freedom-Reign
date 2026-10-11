extends GutTest
## One Theme resource styles every UI control; scenes never override it per control.

const THEME_PATH := "res://scenes/ui/theme.tres"
const UI_ROOT_PATH := "res://scenes/ui/ui_root.tscn"
const UI_SCENES_DIR := "res://scenes/ui"
const OVERRIDE_MARKER := "theme_override"


func _scene_files() -> Array[String]:
	var files: Array[String] = []
	for file_name in DirAccess.get_files_at(UI_SCENES_DIR):
		if file_name.ends_with(".tscn"):
			files.append("%s/%s" % [UI_SCENES_DIR, file_name])
	return files


func test_ui_root_applies_the_theme_to_its_control_tree() -> void:
	var ui: Node = add_child_autofree((load(UI_ROOT_PATH) as PackedScene).instantiate())
	var root := ui.get_node("Root") as Control
	assert_eq(root.theme, load(THEME_PATH))


func test_theme_styles_the_controls_the_ui_uses() -> void:
	var theme := load(THEME_PATH) as Theme
	assert_true(theme.has_stylebox("normal", "Button"), "button")
	assert_true(theme.has_stylebox("focus", "Button"), "button focus for gamepad")
	assert_true(theme.has_stylebox("panel", "Panel"), "panel")
	assert_true(theme.has_stylebox("fill", "ProgressBar"), "bar fill")
	assert_true(theme.has_stylebox("background", "ProgressBar"), "bar background")
	assert_eq(theme.get_type_variation_base("HealthBar"), &"ProgressBar")
	assert_eq(theme.get_type_variation_base("EnemyCountLabel"), &"Label")


func test_player_and_enemy_accents_differ() -> void:
	var theme := load(THEME_PATH) as Theme
	var player := theme.get_color("font_color", "AttackLabel")
	var hostile := theme.get_color("font_color", "EnemyCountLabel")
	assert_ne(player, hostile)


func test_no_ui_scene_overrides_the_theme_per_control() -> void:
	var scenes := _scene_files()
	assert_gt(scenes.size(), 0, "found ui scenes")
	for path in scenes:
		var text := FileAccess.get_file_as_string(path)
		assert_false(text.contains(OVERRIDE_MARKER), "%s has no theme overrides" % path)
