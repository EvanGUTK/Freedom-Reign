class_name ItemData
extends Resource
## A loot item. Picking it up switches the player to `grants_attack`.

@export var id: StringName
@export var display_name: String
@export var grants_attack: AttackData
