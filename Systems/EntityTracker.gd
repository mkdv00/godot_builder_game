# Helper Script that Simulation.gd attaches to EntityPlacer as a Node2D child
# EntityTracker's functions are called in EntityPlacer
# Perks: Reference class is lighter than Node class (no properties)
# Gets erased when not referred to by anyone
class_name EntityTracker
extends Reference

# Entities are keyed using 'Vector2' TimeMap Coordinates
var entities : Dictionary = {}

func add_to_dictionary(entity: Entity, cellv: Vector2) -> void:
	# checks if an entity is already placed at this Vector2 position
	if entities.has(cellv):
		return

	entities[cellv] = entity
	Events.emit_signal("entity_placed", entity, cellv)

func remove_entity(cellv: Vector2) -> void:
	# prevents function from running if entity does not exist
	if not entities.has(cellv):
		return

	var entity = entities[cellv]
	var _result := entities.erase(cellv)
	Events.emit_signal("entity_removed")
	entity.queue_free()

func is_cell_occupied(cellv: Vector2) -> bool:
	return entities.has(cellv)

func get_entity_at(cellv: Vector2) -> Node2D:
	if entities.has(cellv):
		return entities[cellv]
	else:
		return null
