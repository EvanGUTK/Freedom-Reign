extends GutTest
## Smoke test: the main scene loads and instantiates.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"


func test_main_scene_loads_and_instantiates() -> void:
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	assert_not_null(packed, "main scene should load as a PackedScene")
	if packed == null:
		return
	var root := autofree(packed.instantiate()) as Node3D
	assert_not_null(root, "main scene root should be a Node3D")
	if root == null:
		return
	assert_eq(root.name, &"Main")
