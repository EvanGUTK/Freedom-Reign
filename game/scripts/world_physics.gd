class_name WorldPhysics
extends RefCounted
## Physics numbers shared by everything that falls.

const GRAVITY := 24.0
## Bit values of the named 3D physics layers in project.godot (layer N is bit 2^(N-1)).
const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_ENEMY := 4
const LAYER_PICKUP := 8
