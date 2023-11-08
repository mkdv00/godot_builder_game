class_name Entity
extends Node

#used to store an entity as an item like a requirement as a String
export var deconstruct_filter : String

#specifies number of entities to create; e.g., tree -> 5 logs
export var pickup_count : int = 1

#virtual function 
func _setup(_blueprint) -> void:
	pass
