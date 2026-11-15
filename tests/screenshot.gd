extends SceneTree
# Renders the game and saves screenshots (needs a display; use xvfb-run on Linux).
# Usage: godot -s res://tests/screenshot.gd --fixed-fps 30 -- <out_dir> [scene]
#   scene = "game" (default) | "menu" | "battle" | "cutscene"

var frames = 0
var out_dir = "user://shots"
var scene = "game"
var game
var shots = []


func _initialize():
	var args = OS.get_cmdline_args()
	var user_args = []
	var after = false
	for a in args:
		if after:
			user_args.append(a)
		if a == "--":
			after = true
	if user_args.size() > 0:
		out_dir = user_args[0]
	if user_args.size() > 1:
		scene = user_args[1]
	var gs = root.get_node("GameState")
	gs.map_seed = 12345
	if scene == "menu":
		root.add_child(load("res://scenes/Menu.tscn").instance())
		shots = [[40, "menu"]]
	else:
		gs.mode = "campaign" if scene == "cutscene" else "skirmish"
		gs.mission = 1
		game = load("res://scenes/Game.tscn").instance()
		root.add_child(game)
		if scene == "cutscene":
			shots = [[90, "cutscene"]]
		elif scene == "battle":
			shots = [[20, "setup"], [260, "battle1"], [300, "battle2"]]
		else:
			shots = [[60, "base"], [90, "field"], [120, "zoomout"]]


func _idle(_delta):
	if not root.get_node("Art").is_ready:
		return false
	frames += 1
	if scene == "battle" and frames == 20:
		_stage_battle()
	if scene == "game" and frames == 61:
		# Close-up of the nearest Uralium field.
		var c = game.map.find_uralium(game.map.center_of(game.map.bases[0]))
		game.camera.position = game.map.center_of(c) + Vector2(150, 100)
	if scene == "game" and frames == 119:
		game.camera.zoom = Vector2(1.8, 1.8)
	for s in shots:
		if s[0] == frames:
			_save(s[1])
	if frames > shots[shots.size() - 1][0] + 1:
		quit()
	return false


func _stage_battle():
	# Put both armies together on open ground next to the player's base.
	var c = game.map.center_of(game.map.bases[0]) + Vector2(520, 380)
	game.camera.position = c
	for k in ["arthem_ranger", "arthem_ranger", "arthem_scout", "arthem_gunship", "arthem_drone"]:
		var u = game.spawn_unit(k, 0, c + Vector2(rand_range(-260, -160), rand_range(-120, 120)))
		u.order_attack_move(c + Vector2(200, 0))
	for k in ["klingos_trooper", "klingos_trooper", "klingos_tesla_tank", "klingos_siege", "klingos_rocketeer"]:
		var u2 = game.spawn_unit(k, 1, c + Vector2(rand_range(160, 260), rand_range(-120, 120)))
		u2.order_attack_move(c - Vector2(200, 0))


func _save(name):
	var img = root.get_texture().get_data()
	img.flip_y()
	var dir = Directory.new()
	dir.make_dir_recursive(out_dir)
	img.save_png(out_dir + "/" + name + ".png")
	print("saved " + out_dir + "/" + name + ".png")
