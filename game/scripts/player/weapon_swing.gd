class_name WeaponSwing
extends Node3D
## Makes a swing readable: a blade as long as the attack's reach sweeps through
## exactly the arc the attack hits. Purely visual; hits are decided by AttackController.

const SWING_SECONDS := 0.18

var _tween: Tween

@onready var _blade: MeshInstance3D = $Blade


func _ready() -> void:
	_blade.visible = false
	Events.player_attacked.connect(play)


## Sweeps left to right across the attack's arc.
func play(attack: AttackData) -> void:
	if _tween != null:
		_tween.kill()
	var half_arc := deg_to_rad(attack.arc_degrees) / 2.0
	_blade.scale.z = attack.reach_meters
	_blade.position.z = -attack.reach_meters / 2.0
	_blade.visible = true
	rotation.y = half_arc
	_tween = create_tween()
	_tween.tween_property(self, "rotation:y", -half_arc, SWING_SECONDS)
	_tween.tween_callback(_blade.hide)
