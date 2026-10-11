class_name LootPickup
extends Area3D
## A dropped item. Touching it with the player swaps the player's attack for the
## item's. Spins and bobs so it reads as something to grab.

const SPIN_RADIANS_PER_SECOND := 1.6
const BOB_HEIGHT := 0.15
const BOB_RADIANS_PER_SECOND := 2.4

@export var item: ItemData

var _collected := false
var _age := 0.0
var _visual_rest_y := 0.0

@onready var _visual: Node3D = $Visual


func _ready() -> void:
	if item == null or item.grants_attack == null:
		push_error("LootPickup needs an item that grants an attack")
		queue_free()
		return
	_visual_rest_y = _visual.position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_age += delta
	_visual.rotation.y += SPIN_RADIANS_PER_SECOND * delta
	_visual.position.y = _visual_rest_y + sin(_age * BOB_RADIANS_PER_SECOND) * BOB_HEIGHT


func collect(player: Player) -> void:
	if _collected or not player.is_alive():
		return
	_collected = true
	Events.loot_picked_up.emit(item)
	player.equip_attack(item.grants_attack)
	queue_free()


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player != null:
		collect(player)
