extends KinematicBody2D

export var movement_speed := 200.0
export var drag_factor := 0.13

var _velocity := Vector2.ZERO


func _physics_process(_delta: float) -> void:
	var direction := _get_direction()
	var desired_velocity := direction * movement_speed
	var steering_vector := desired_velocity - _velocity
	
	_velocity += steering_vector * drag_factor
	move_and_slide(_velocity)


func _get_direction() -> Vector2:
	return Vector2(
		(Input.get_action_strength("right") - Input.get_action_strength("left")) * 2.0, Input.get_action_strength("down") - Input.get_action_strength("up")
	).normalized()
