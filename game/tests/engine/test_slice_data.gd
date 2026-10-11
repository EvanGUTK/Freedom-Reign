extends GutTest
## The slice's data instances carry exactly the numbers in docs/CONTRACTS.md.

const RUSTED_BLADE_PATH := "res://data/rusted_blade.tres"
const EMBER_CLEAVER_ATTACK_PATH := "res://data/ember_cleaver_attack.tres"
const EMBER_CLEAVER_ITEM_PATH := "res://data/ember_cleaver.tres"


func _load_attack(path: String) -> AttackData:
	var attack := load(path) as AttackData
	assert_not_null(attack, "%s should load as AttackData" % path)
	return attack


func test_rusted_blade_matches_contract() -> void:
	var attack := _load_attack(RUSTED_BLADE_PATH)
	if attack == null:
		return
	assert_eq(attack.id, &"rusted_blade")
	assert_eq(attack.damage, 10)
	assert_eq(attack.cooldown_seconds, 0.6)
	assert_eq(attack.reach_meters, 1.8)
	assert_eq(attack.arc_degrees, 90.0)
	assert_ne(attack.display_name, "", "attack needs a display name for the HUD")


func test_ember_cleaver_attack_matches_contract() -> void:
	var attack := _load_attack(EMBER_CLEAVER_ATTACK_PATH)
	if attack == null:
		return
	assert_eq(attack.id, &"ember_cleaver")
	assert_eq(attack.damage, 25)
	assert_eq(attack.cooldown_seconds, 1.0)
	assert_eq(attack.reach_meters, 2.2)
	assert_eq(attack.arc_degrees, 120.0)
	assert_ne(attack.display_name, "", "attack needs a display name for the HUD")


func test_ember_cleaver_item_grants_the_ember_cleaver_attack() -> void:
	var item := load(EMBER_CLEAVER_ITEM_PATH) as ItemData
	assert_not_null(item, "ember_cleaver.tres should load as ItemData")
	if item == null:
		return
	assert_eq(item.id, &"ember_cleaver")
	assert_ne(item.display_name, "", "item needs a display name")
	assert_not_null(item.grants_attack, "item should grant an attack")
	if item.grants_attack == null:
		return
	assert_eq(item.grants_attack.id, &"ember_cleaver")
	assert_eq(item.grants_attack.damage, 25)
