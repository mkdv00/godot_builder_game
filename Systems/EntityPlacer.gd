extends TileMap

# used to track if mouse is within game bounds
const MAX_WORK_DISTANCE := 275.0

# gives blueprint slight offset from mouse (visual only)
const POSITION_OFFSET := Vector2(0,25)

# time in seconds
const DECONSTRUCT_TIME := 0.3

# for testing purposes only
var _blueprint : BlueprintEntity

# received from Simulation.gd
var _tracker : EntityTracker

# used to track if mouse is within game bounds
var _ground : TileMap

var _player : KinematicBody2D
var _flat_entities : YSort
var _current_deconstruct_location := Vector2.ZERO

onready var Library := {
	"StirlingEngine": preload("res://Entities/Blueprints/SterlingEngineBlueprint.tscn").instance(),
	"Wire": preload("res://Entities/Blueprints/WireBlueprint.tscn").instance(),
	"Battery": preload("res://Entities/Blueprints/BatteryBlueprint.tscn").instance()
}
onready var _deconstruct_timer := $DeconstructTimer

func _ready() -> void:
	# we use the blueprint as a key to its corresponding entity
	Library[Library.StirlingEngine] = preload("res://Entities/Entities/SterlingEngineEntity.tscn")
	Library[Library.Wire] = preload("res://Entities/Entities/WireEntity.tscn")
	Library[Library.Battery] = preload("res://Entities/Entities/BatteryEntity.tscn")


# important function for setting up EntityPlacer
# only called in Simulation.gd once on game start
func setup(tracker: EntityTracker, ground: TileMap, flat_entities: YSort, player: KinematicBody2D) -> void:
	# this approach makes refactoring (moving nodes around) easier
	# because we don't rely on node paths
	_tracker = tracker
	_ground = ground
	_flat_entities = flat_entities
	_player = player

	# note: world coordinates use decimals, map coordinates are integers
	# integer values are less prone to error
	for child in get_children():
		if child is Entity:
			var map_position := world_to_map(child.global_position)
			_tracker.add_to_dictionary(child, map_position)


func _process(_delta: float) -> void:
	var has_placeable_blueprint: bool = _blueprint and _blueprint.placeable
	if has_placeable_blueprint:
		_move_blueprint_in_world(world_to_map(get_global_mouse_position()))


# entity placement calculations
func _unhandled_input(event: InputEvent) -> void:
	var global_mouse_position := get_global_mouse_position()

	# validity check boolean variables
	var has_placeable_blueprint : bool = _blueprint and _blueprint.placeable
		# can only place entities within distance of player's position
	var is_close_to_player := (
		global_mouse_position.distance_to(_player.global_position) < MAX_WORK_DISTANCE
	)
	var cellv : Vector2 = world_to_map(global_mouse_position)
	var cell_is_occupied : bool = _tracker.is_cell_occupied(cellv)
	var is_on_ground : bool = _ground.get_cellv(cellv) == 0

	if event is InputEventMouseButton:
		_abort_deconstruct()

	# validity checks
	if event.is_action_pressed("left_click"):
		if has_placeable_blueprint:
			if not cell_is_occupied and is_on_ground and is_close_to_player:
				_place_entity(cellv)
				_update_neighboring_flat_entities(cellv)

	elif event.is_action_pressed("right_click") and not has_placeable_blueprint:
		if cell_is_occupied and is_close_to_player:
			_deconstruct(global_mouse_position, cellv)

	elif event is InputEventMouseMotion:
		if cellv != _current_deconstruct_location:
			_abort_deconstruct()
		if has_placeable_blueprint:
			_move_blueprint_in_world(cellv)

	# testing only
	elif event.is_action_pressed("drop") and _blueprint:
		remove_child(_blueprint)
		_blueprint = null
	
	elif event.is_action_pressed("rotate_blueprint") and _blueprint:
		_blueprint.rotate_blueprint()
	
	elif event.is_action_pressed("quickbar_1"):
		if _blueprint:
			remove_child(_blueprint)
		_blueprint = Library.StirlingEngine
		add_child(_blueprint)
		_move_blueprint_in_world(cellv)
	
	elif event.is_action_pressed("quickbar_2"):
		if _blueprint:
			remove_child(_blueprint)
		_blueprint = Library.Wire
		add_child(_blueprint)
		_move_blueprint_in_world(cellv)
	
	elif event.is_action_pressed("quickbar_3"):
		if _blueprint:
			remove_child(_blueprint)
		
		_blueprint = Library.Battery
		add_child(_blueprint)
		_move_blueprint_in_world(cellv)


func _place_entity(cellv: Vector2) -> void:
	var new_entity: Entity = Library[_blueprint].instance()
	if _blueprint is WireBlueprint:
		var directions := _get_powered_neighbors(cellv)
		_flat_entities.add_child(new_entity)
		WireBlueprint.set_sprite_for_direction(new_entity.sprite, directions)
	else:
		add_child(new_entity)
	new_entity.global_position = map_to_world(cellv) + POSITION_OFFSET
	# this calls the _setup() method under Entity, not EntityPlacer
	new_entity._setup(_blueprint)
	_tracker.add_to_dictionary(new_entity, cellv)


func _move_blueprint_in_world(cellv: Vector2) -> void:
	_blueprint.global_position = map_to_world(cellv) + POSITION_OFFSET
	var is_close_to_player := (
		get_global_mouse_position().distance_to(_player.global_position) < MAX_WORK_DISTANCE
	)
	var cell_is_occupied : bool = _tracker.is_cell_occupied(cellv)
	var is_on_ground : bool = _ground.get_cellv(cellv) == 0
	if not cell_is_occupied and is_on_ground and is_close_to_player:
		_blueprint.modulate = Color.white
	else:
		_blueprint.modulate = Color.red
	if _blueprint is WireBlueprint:
		WireBlueprint.set_sprite_for_direction(_blueprint.sprite, _get_powered_neighbors(cellv))

func _deconstruct(event_position: Vector2, cellv: Vector2) -> void:
	_deconstruct_timer.connect("timeout", self, "_finish_deconstruct", [cellv], CONNECT_ONESHOT)
	_deconstruct_timer.start(DECONSTRUCT_TIME)
	_current_deconstruct_location = cellv


func _finish_deconstruct(cellv: Vector2) -> void:
	var entity := _tracker.get_entity_at(cellv)
	_tracker.remove_entity(cellv)
	_update_neighboring_flat_entities(cellv)


func _abort_deconstruct() -> void:
	if _deconstruct_timer.is_connected("timeout", self, "_finish_deconstruct"):
		_deconstruct_timer.disconnect("timeout", self, "_finish_deconstruct")
	_deconstruct_timer.stop()


func _get_powered_neighbors(cellv: Vector2) -> int:
	var direction := 0
	for neighbor in Types.NEIGHBORS.keys():
		var key: Vector2 = cellv + Types.NEIGHBORS[neighbor]
		if _tracker.is_cell_occupied(key):
			var entity: Node = _tracker.get_entity_at(key)
			if (
				entity.is_in_group(Types.POWER_MOVERS)
				or entity.is_in_group(Types.POWER_RECEIVERS)
				or entity.is_in_group(Types.POWER_SOURCES)
			):
				direction |= neighbor
	return direction


func _update_neighboring_flat_entities(cellv: Vector2) -> void:
	for neighbor in Types.NEIGHBORS.keys():
		var key: Vector2 = cellv + Types.NEIGHBORS[neighbor]
		var object = _tracker.get_entity_at(key)
		
		if object and object is WireEntity:
			var tile_directions := _get_powered_neighbors(key)
			WireBlueprint.set_sprite_for_direction(object.sprite, tile_directions)


# temporary function during testing
# needed to remove blueprint instances because they are not tied to a node
func _exit_tree() -> void:
	Library.StirlingEngine.queue_free()
	Library.Wire.queue_free()
	Library.Battery.queue_free()
