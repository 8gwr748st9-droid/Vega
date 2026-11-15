extends Node
# Computer opponent: builds a base, keeps harvesters busy, trains an army and attacks in waves.

var game
var team = 1
var faction = "klingos"
var think = 2.0
var wave = 0
var first_attack = 240.0
var defending = 0.0

var build_order = ["power", "barracks", "power", "factory", "DEFENSE", "power", "refinery", "refinery", "DEFENSE", "power", "helipad", "DEFENSE", "power", "orbital_uplink", "power"]


func setup(g, t):
	game = g
	team = t
	faction = game.team_faction[t]
	first_attack = [420.0, 260.0, 160.0][GameState.difficulty]


func _defense_kind():
	return "tesla_coil" if faction == "klingos" else "gun_tower"


func _process(delta):
	if game.game_over:
		return
	defending -= delta
	think -= delta
	if think > 0:
		return
	think = 1.5
	if game.team_buildings(team).empty():
		return
	_manage_structures()
	_manage_harvesters()
	_manage_army()
	_use_orbital()


func _use_orbital():
	if not game.orbital_ready(team):
		return
	var targets = game.team_buildings(game.player_team)
	if targets.empty():
		return
	var tgt = targets[randi() % targets.size()]
	game.fire_orbital(team, tgt.position)


func _manage_structures():
	var sb = game.struct_build[team]
	if sb["kind"] != "":
		if sb["ready"]:
			_auto_place(sb["kind"])
		return
	# Power first if we are short.
	if game.power_used[team] + 40 > game.power_made[team]:
		game.start_structure(team, "power")
		return
	var counts = {}
	for b in game.team_buildings(team):
		counts[b.kind] = counts.get(b.kind, 0) + 1
	var wanted = {}
	for k in build_order:
		var kind = _defense_kind() if k == "DEFENSE" else k
		wanted[kind] = wanted.get(kind, 0) + 1
		if counts.get(kind, 0) < wanted[kind]:
			var d = Data.get_def(kind)
			if d["faction"] != "any" and d["faction"] != faction:
				continue
			if d["tech"] > game.tech or not game.requirements_met(team, kind):
				continue
			if game.credits[team] >= d["cost"]:
				game.start_structure(team, kind)
			return


func _auto_place(kind):
	var hq = game.nearest_building(team, "hq", game.map.center_of(game.map.bases[team]))
	var anchor = hq.origin if hq else game.map.bases[team]
	var toward = (game.map.world_size() / 2 - anchor * Data.CELL).normalized()
	if Data.get_def(kind).get("defense", false):
		anchor += (toward * 5).round()
	var best = null
	var best_score = INF
	for y in range(-8, 9):
		for x in range(-8, 9):
			var c = anchor + Vector2(x, y)
			if not game.can_place(team, kind, c):
				continue
			# Leave a one-cell gap around buildings so units can move.
			var crowded = false
			var size = Data.get_def(kind)["size"]
			for yy in range(-1, int(size.y) + 1):
				for xx in range(-1, int(size.x) + 1):
					if game.map.occupied.has(c + Vector2(xx, yy)):
						crowded = true
			if crowded:
				continue
			var score = c.distance_to(anchor) + randf()
			if score < best_score:
				best_score = score
				best = c
	if best != null:
		game.place_structure(team, best)
	else:
		game.cancel_structure(team)


func _manage_harvesters():
	var refineries = 0
	for b in game.team_buildings(team):
		if b.kind == "refinery":
			refineries += 1
	var kind = Data.harvester_for(faction)
	var have = 0
	for h in get_tree().get_nodes_in_group("harvesters"):
		if h.team == team and not h.dead:
			have += 1
	have += game.queued_count(team, kind)
	if have < min(4, refineries * 2) and game.credits[team] >= Data.get_def(kind)["cost"]:
		game.queue_unit(team, kind)


func _army():
	var out = []
	for u in get_tree().get_nodes_in_group("units"):
		if u.team == team and not u.dead and not u.def.get("harvester", false):
			out.append(u)
	return out


func _manage_army():
	var options = []
	for k in Data.units_for(faction, game.tech):
		if not Data.UNITS[k].get("harvester", false) and not game.producers_for(team, k).empty():
			options.append(k)
	var queued = 0
	for b in game.team_buildings(team):
		queued += b.queue.size()
	if not options.empty() and queued < 3:
		var k = options[randi() % options.size()]
		var reserve = 400 if game.struct_build[team]["kind"] == "" else 0
		if game.credits[team] >= Data.get_def(k)["cost"] + reserve:
			game.queue_unit(team, k)

	var army = _army()
	var idle = []
	for u in army:
		if u.state == "idle":
			idle.append(u)
	var wave_size = min(5 + wave * 2, 16)
	if game.elapsed >= first_attack and idle.size() >= wave_size and defending <= 0:
		var tgt = game.nearest_building(game.player_team, "", idle[0].position)
		if tgt:
			wave += 1
			for u in idle:
				u.order_attack_move(tgt.position + Vector2(rand_range(-60, 60), rand_range(-60, 60)))


func on_attacked(_victim, attacker):
	if attacker == null or not is_instance_valid(attacker) or defending > 0:
		return
	defending = 8.0
	for u in _army():
		if u.state == "idle" and u.position.distance_to(attacker.global_position) < 900:
			u.order_attack_move(attacker.global_position)
