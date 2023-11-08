extends Node

# the arguments allow the signal to pass the entity and its position in map coordinates
signal entity_placed(entity, cellv)
signal entity_removed(entity, cellv)

# signal emitted when the simulation triggers the systems for updates.
signal systems_ticked(delta)
