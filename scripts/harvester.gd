extends "res://scripts/unit.gd"
# Harvester: finds uralium, fills up, returns to the nearest refinery, unloads, repeats.

const HARVEST_RATE = 55.0
const UNLOAD_RATE = 180.0

var harvest_cell = null
var refinery = null
var auto = true


func order_move(p):
	# Right-clicking uralium sends the harvester to work there.
	var c = game.map.cell_of(p)
	if game.map.uralium_at(c) > 0:
		harvest_cell = c
		auto = true
		state = "to_uralium"
		return
	auto = false
	.order_move(p)


func order_stop():
	.order_stop()


func start_harvesting():
	auto = true
	state = "to_uralium"
	harvest_cell = null


func _update_state(delta):
	match state:
		"idle":
			if auto:
				state = "to_uralium"
		"move":
			if _step_to(dest, delta, true):
				state = "idle"
				guard_pos = position
		"to_uralium":
			_seek_uralium(delta)
		"harvesting":
			_harvest(delta)
		"returning":
			_return(delta)
		"unloading":
			_unload(delta)
		_:
			state = "idle"


func _seek_uralium(delta):
	if cargo >= def["capacity"]:
		state = "returning"
		return
	if harvest_cell == null or game.map.uralium_at(harvest_cell) <= 0:
		harvest_cell = game.map.find_uralium(position, _claimed_cells())
		if harvest_cell == null:
			harvest_cell = game.map.find_uralium(position)
		if harvest_cell == null:
			if cargo > 0:
				state = "returning"
			else:
				auto = false
				state = "idle"
			return
	if _step_to(game.map.center_of(harvest_cell), delta, true):
		state = "harvesting"


func _claimed_cells():
	var out = []
	for h in get_tree().get_nodes_in_group("harvesters"):
		if h != self and h.harvest_cell != null:
			out.append(h.harvest_cell)
	return out


func _harvest(delta):
	if harvest_cell == null or game.map.uralium_at(harvest_cell) <= 0:
		state = "to_uralium"
		harvest_cell = null
		return
	var got = game.map.take_uralium(harvest_cell, HARVEST_RATE * delta)
	cargo += got
	moving = true
	if randf() < delta * 6.0:
		game.fx_dust(position + Vector2(radius + 4, 0).rotated(facing), 1.2, Color(0.70, 0.36, 0.26, 0.35))
	if cargo >= def["capacity"]:
		cargo = def["capacity"]
		state = "returning"


func _return(delta):
	if refinery == null or not is_instance_valid(refinery) or refinery.dead:
		refinery = game.nearest_building(team, "refinery", position)
		if refinery == null:
			state = "idle"
			auto = false
			return
	if _step_to(refinery.dock_point(), delta, true):
		state = "unloading"


func _unload(delta):
	if refinery == null or not is_instance_valid(refinery) or refinery.dead:
		state = "returning"
		return
	var amount = min(cargo, UNLOAD_RATE * delta)
	cargo -= amount
	game.add_credits(team, amount)
	if cargo <= 0.01:
		cargo = 0
		state = "to_uralium"
