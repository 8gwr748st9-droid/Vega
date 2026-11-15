extends SceneTree
# Diagnostic: follow the AI's harvesters for a few minutes.
var game
var frames = 0
func _initialize():
	root.get_node("GameState").map_seed = 12345
	game = load("res://scenes/Game.tscn").instance()
	root.add_child(game)
	Engine.time_scale = 4.0
func _idle(_d):
	frames += 1
	if frames % 150 == 0:
		var line = "t=%ds ai credits %d harvested %d |" % [int(game.elapsed), game.credits[1], game.harvested[1]]
		for h in get_nodes_in_group("harvesters"):
			if h.team == 1:
				line += " [%s cargo %d pos %s cell %s]" % [h.state, h.cargo, str(h.position.round()), str(h.harvest_cell)]
		print(line)
	if frames >= 1200:
		quit()
	return false
