extends GutTest
## Every contract sound id has a file under assets/audio, within the size caps.

const AUDIO_ROOT := "res://assets/audio"
const MAX_FILE_BYTES := 2 * 1024 * 1024
const MAX_TOTAL_BYTES := 10 * 1024 * 1024
## docs/CONTRACTS.md, "Audio": the ids the slice must ship.
const CONTRACT_IDS: Array[StringName] = [
	&"sfx.jump", &"sfx.land", &"sfx.attack_swing", &"sfx.attack_hit", &"sfx.player_hurt",
	&"sfx.player_die", &"sfx.enemy_die", &"sfx.loot_drop", &"sfx.loot_pickup",
	&"ui.pause_open", &"ui.pause_close", &"ui.click", &"music.arena",
]


func _file_size(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return -1
	return file.get_length()


func _audio_files_under(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	for sub_dir in DirAccess.get_directories_at(dir_path):
		found.append_array(_audio_files_under(dir_path.path_join(sub_dir)))
	for file_name in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".wav") or file_name.ends_with(".ogg"):
			found.append(dir_path.path_join(file_name))
	return found


func test_catalog_covers_exactly_the_contract_ids() -> void:
	var catalog_ids: Array = SoundCatalog.PATHS.keys()
	catalog_ids.sort()
	var expected: Array = CONTRACT_IDS.duplicate()
	expected.sort()
	assert_eq(catalog_ids, expected)


func test_every_id_has_a_file() -> void:
	for id in CONTRACT_IDS:
		var path: String = SoundCatalog.PATHS.get(id, "")
		assert_gt(_file_size(path), 0, "file for '%s' (%s) should exist and be non-empty" % [id, path])


func test_every_id_loads_as_an_audio_stream() -> void:
	for id in CONTRACT_IDS:
		var stream := load(SoundCatalog.PATHS.get(id, "")) as AudioStream
		assert_not_null(stream, "'%s' should import as an AudioStream" % id)


func test_each_file_is_within_the_single_file_cap() -> void:
	for path in _audio_files_under(AUDIO_ROOT):
		assert_lte(_file_size(path), MAX_FILE_BYTES, "%s exceeds the per-file cap" % path)


func test_all_audio_is_within_the_total_cap() -> void:
	var total := 0
	for path in _audio_files_under(AUDIO_ROOT):
		total += _file_size(path)
	assert_lte(total, MAX_TOTAL_BYTES, "total audio size in bytes")


func test_no_audio_file_is_unregistered() -> void:
	var registered: Array[String] = []
	registered.assign(SoundCatalog.PATHS.values())
	for path in _audio_files_under(AUDIO_ROOT):
		assert_has(registered, path, "%s has no sound id" % path)
