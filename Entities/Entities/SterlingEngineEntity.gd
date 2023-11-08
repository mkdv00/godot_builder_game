# SterlingEngine consumes fuel and acts as a power source
extends Entity

# used in tween animation (unit: time)
const BOOTUP_TIME : float = 6.0
const SHUTDOWN_TIME : float = 3.0

onready var anim_player := $AnimationPlayer
onready var tween := $Tween
onready var shaft := $PistonShaft
onready var power := $PowerSource

func _ready() -> void:
	anim_player.play("Work")
	
	# tween controls speed of animation over time
	tween.interpolate_property(anim_player, "playback_speed", 0, 1, BOOTUP_TIME)
	tween.interpolate_property(shaft, "modulate", Color.white, Color(0.5, 1, 0.5), BOOTUP_TIME)
	tween.interpolate_property(power, "efficiency", 0, 1, BOOTUP_TIME)
	tween.start()
