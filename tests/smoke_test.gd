extends SceneTree
# Headless smoke test: loads the menu and a skirmish, simulates a few minutes, checks the economy.
# Run:  godot --no-window --fixed-fps 30 -s res://tests/smoke_test.gd   (from the project folder)

var game
var frames = 0
var phase = 0
var start_credits = 0.0
var failures = []


func _initialize():
	var menu = load("res://scenes/Menu.tscn").instance()
	root.add_child(menu)


func _idle(delta):
	frames += 1
	if phase == 0 and frames == 5:
		root.get_child(root.get_child_count() - 1).queue_free()
		root.get_node("GameState").mode = "skirmish"
		root.get_node("GameState").map_seed = 12345
		root.get_node("GameState").difficulty = 2
		game = load("res://scenes/Game.tscn").instance()
		root.add_child(game)
		start_credits = game.credits[1]
		Engine.time_scale = 4.0
		phase = 1
		print("game started: %d entities" % get_nodes_in_group("entities").size())
	elif phase == 1:
		if frames == 40:
			# Player builds a barracks and queues units, like a person would.
			_check(game.start_structure(0, "barracks"), "start barracks")
		if frames % 30 == 0 and game.struct_build[0]["ready"]:
			var placed = false
			for y in range(-8, 9):
				for x in range(-8, 9):
					if not placed and game.can_place(0, game.struct_build[0]["kind"], game.map.bases[0] + Vector2(x, y)):
						placed = game.place_structure(0, game.map.bases[0] + Vector2(x, y))
			_check(placed, "place structure")
			if game.has_building(0, "barracks"):
				game.queue_unit(0, Data_units()[0])
		if frames == 900:
			print("after ~2 min sim: player harvested %d, ai harvested %d" % [game.harvested[0], game.harvested[1]])
			print("units: %d, buildings: %d" % [get_nodes_in_group("units").size(), get_nodes_in_group("buildings").size()])
			_check(game.harvested[0] > 0, "player harvesters delivered spice")
			_check(game.harvested[1] > 0, "AI harvesters delivered spice")
			_check(game.has_building(0, "barracks"), "player barracks built")
			_check(game.team_buildings(1).size() > 4, "AI expanded its base (has %d)" % game.team_buildings(1).size())
			# Throw armies at each other to exercise combat code.
			for u in get_nodes_in_group("units"):
				if not u.def.get("harvester", false):
					var other = 1 - u.team if u.team < 2 else 1
					var tgt = game.nearest_building(other, "", u.position)
					if tgt:
						u.order_attack_move(tgt.position)
			game._freedom_raid()
		if frames == 2400:
			print("after ~5 min sim: game_over=%s, player buildings %d, ai buildings %d" % [game.game_over, game.team_buildings(0).size(), game.team_buildings(1).size()])
			print("player harvested %d, ai harvested %d" % [game.harvested[0], game.harvested[1]])
			if failures.empty():
				print("SMOKE TEST PASSED")
			else:
				print("SMOKE TEST FAILED: %s" % str(failures))
			quit(0 if failures.empty() else 1)
	return false


func Data_units():
	return root.get_node("Data").units_for(game.team_faction[0], 3)


func _check(cond, label):
	if not cond:
		failures.append(label)
		print("FAIL: " + label)
