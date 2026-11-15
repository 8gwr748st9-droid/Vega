extends Node2D
# The match: owns the map, entities, economy, power, player input and win/lose rules.

const MapScript = preload("res://scripts/map.gd")
const UnitScript = preload("res://scripts/unit.gd")
const HarvesterScript = preload("res://scripts/harvester.gd")
const BuildingScript = preload("res://scripts/building.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")
const EffectScript = preload("res://scripts/effect.gd")
const TracksScript = preload("res://scripts/tracks.gd")
const BloomsScript = preload("res://scripts/blooms.gd")
const SandeaterScript = preload("res://scripts/sandeater.gd")
const OrbitalScript = preload("res://scripts/orbital.gd")
const CritterScript = preload("res://scripts/critter.gd")
const DustScript = preload("res://scripts/dust.gd")
const OverlayScript = preload("res://scripts/overlay.gd")
const AIScript = preload("res://scripts/ai.gd")
const HudScript = preload("res://scripts/hud.gd")
const CutsceneScript = preload("res://scripts/cutscene.gd")
const Missions = preload("res://scripts/missions.gd")

const CELL = 64
const BUILD_RADIUS = 6 * 64

var player_team = 0
var enemy_team = 1
var freedom_team = 2
var team_faction = ["arthem", "klingos", "freedom"]
var credits = [0.0, 0.0, 0.0]
var harvested = [0.0, 0.0, 0.0]
var power_made = [0, 0, 0]
var power_used = [0, 0, 0]
var offline = [0.0, 0.0, 0.0]          # seconds a team's technology is knocked out (mission 10)
var struct_build = []                  # per team: {"kind", "progress", "ready"}
var tech = 3
var mission = null

var map
var tracks
var blooms
var world
var air_layer
var fx_layer
var weather
var overlay
var camera
var hud
var ai
var cutscene
var font

var selected = []
var placing = ""
var drag_start = null
var drag_now = Vector2()
var order_marker = null                # [position, age, colour]
var game_over = false
var elapsed = 0.0
var power_timer = 0.0
var rules_timer = 0.0
var dust_timer = 8.0
var raid_timer = 300.0
var attack_notice = 0.0
var eater_notice = 0.0
var orbital_charge = [0.0, 0.0, 0.0]   # seconds charged on the Orbital Uplink
var targeting = ""                     # "orbital" while the player picks a strike target
var sandeaters
var power_warned = false
var outro_playing = false


func _ready():
	randomize()
	var tmp = Label.new()
	font = tmp.get_font("font")
	tmp.free()

	team_faction = [GameState.player_faction, GameState.enemy_faction, "freedom"]
	for t in range(3):
		struct_build.append({"kind": "", "progress": 0.0, "ready": false})
	if GameState.mode == "campaign":
		mission = Missions.get_mission(GameState.mission)
		tech = mission["tech"]
	credits = [2500.0, 2500.0 + 500.0 * GameState.difficulty, 0.0]

	map = MapScript.new()
	map.z_index = -10
	add_child(map)
	map.generate(GameState.map_seed if GameState.map_seed != 0 else randi())

	tracks = TracksScript.new()
	tracks.z_index = -9
	add_child(tracks)

	blooms = BloomsScript.new()
	blooms.z_index = -8
	add_child(blooms)
	blooms.setup(self)

	sandeaters = Node2D.new()
	sandeaters.name = "Sandeaters"
	sandeaters.z_index = -7
	add_child(sandeaters)

	world = YSort.new()
	world.name = "World"
	add_child(world)

	air_layer = Node2D.new()
	air_layer.z_index = 5
	add_child(air_layer)

	fx_layer = Node2D.new()
	fx_layer.z_index = 6
	add_child(fx_layer)

	weather = Node2D.new()
	weather.z_index = 8
	add_child(weather)

	overlay = OverlayScript.new()
	overlay.z_index = 20
	overlay.game = self
	add_child(overlay)

	camera = Camera2D.new()
	camera.current = true
	camera.pause_mode = Node.PAUSE_MODE_PROCESS   # lets cutscenes pan while the game is paused
	camera.limit_left = -40
	camera.limit_top = -40
	camera.limit_right = int(map.world_size().x + 270)
	camera.limit_bottom = int(map.world_size().y + 40)
	add_child(camera)

	_spawn_start()

	# Each sandeater guards a Uralium feeding ground away from the bases.
	for i in range(3):
		var w = SandeaterScript.new()
		w.setup(self, _feeding_ground())
		sandeaters.add_child(w)
	for i in range(26):
		var c = CritterScript.new()
		var k = ["lizard", "hopper", "hopper", "lizard", "bird"][i % 5]
		c.setup(self, k, _random_sand_pos(6))
		world.add_child(c)

	ai = AIScript.new()
	ai.setup(self, enemy_team)
	add_child(ai)

	hud = HudScript.new()
	hud.game = self
	add_child(hud)

	cutscene = CutsceneScript.new()
	cutscene.game = self
	add_child(cutscene)

	_recompute_power()
	camera.position = map.center_of(map.bases[0]) + Vector2(120, 60)

	if mission != null:
		cutscene.connect("finished", self, "_on_intro_done")
		cutscene.play(mission["intro"])
	else:
		notify("Skirmish: destroy every %s structure." % Data.FACTIONS[team_faction[enemy_team]]["name"])


func _on_intro_done():
	cutscene.disconnect("finished", self, "_on_intro_done")
	notify("Mission %d: %s" % [mission["id"], mission["title"]])


func _spawn_start():
	for t in [player_team, enemy_team]:
		var b = map.bases[t]
		var f = team_faction[t]
		spawn_building("hq", t, b - Vector2(1, 1))
		spawn_building("power", t, b + Vector2(-4, -1))
		spawn_building("refinery", t, b + Vector2(2, -1))
		if t == enemy_team:
			spawn_building("barracks", t, b + Vector2(-1, 3))
		var front = map.center_of(b) + (map.world_size() / 2 - map.center_of(b)).normalized() * 230
		var infantry = Data.units_for(f, 1)
		for k in infantry:
			if Data.UNITS[k]["shape"].begins_with("infantry"):
				for i in range(3):
					spawn_unit(k, t, front + Vector2(i * 26 - 26, 0))
				break
		if f == "arthem":
			spawn_unit("arthem_scout", t, front + Vector2(0, 40))


func _feeding_ground():
	var cells = map.uralium.keys()
	cells.shuffle()
	for c in cells:
		if not map._near_base(c, 18):
			return map.center_of(c)
	return _random_sand_pos(20)


func _random_sand_pos(min_base_dist):
	for i in range(500):
		var c = Vector2(randi() % map.W, randi() % map.H)
		if map.get_type(c) == map.SAND and not map._near_base(c, min_base_dist):
			return map.center_of(c)
	return map.world_size() / 2


# ---------------------------------------------------------------- spawning

func spawn_unit(kind, team, pos, from_building = null):
	var d = Data.get_def(kind)
	var u = HarvesterScript.new() if d.get("harvester", false) else UnitScript.new()
	u.setup(self, kind, team)
	u.position = map.clamp_to_map(pos)
	if d.get("air", false):
		air_layer.add_child(u)
	else:
		world.add_child(u)
	if d.get("harvester", false):
		u.add_to_group("harvesters")
		u.start_harvesting()
	elif from_building != null:
		u.order_move(pos + Vector2(rand_range(-30, 30), 50))
	if team == player_team and from_building != null:
		notify("%s ready." % d["name"])
	return u


func spawn_building(kind, team, cell):
	var b = BuildingScript.new()
	b.setup_building(self, kind, team, cell)
	world.add_child(b)
	for c in b.cells():
		map.occupied[c] = b
	var free_unit = b.def.get("free_unit", "")
	if free_unit == "harvester":
		spawn_unit(Data.harvester_for(b.faction), team, b.dock_point())
	_recompute_power()
	return b


func spawn_projectile(shooter, target):
	var p = ProjectileScript.new()
	p.launch(self, shooter, target)
	fx_layer.add_child(p)


# ---------------------------------------------------------------- effects

func _fx(kind, pos, life):
	var e = EffectScript.new()
	e.kind = kind
	e.position = pos
	e.life = life
	fx_layer.add_child(e)
	return e


func fx_explosion(pos, size = 1.0):
	var e = _fx("explosion", pos, 0.45 + 0.2 * size)
	e.size = size
	if size >= 1.0:
		loud_noise(pos, 300 * size)
		if randf() < 0.5:
			fx_text(pos + Vector2(0, -30), ["BOOM!", "KRAK!", "BLAM!", "WHAM!"][randi() % 4], Color(1, 0.8, 0.2))


func fx_tracer(a, b):
	var e = _fx("tracer", a, 0.08)
	e.a = a
	e.b = b


func fx_tesla(a, b):
	var e = _fx("tesla", a, 0.25)
	e.a = a
	e.b = b
	var pts = [a]
	for i in range(1, 7):
		var p = a.linear_interpolate(b, i / 7.0)
		pts.append(p + Vector2(rand_range(-10, 10), rand_range(-10, 10)))
	pts.append(b)
	e.points = pts
	if randf() < 0.35:
		fx_text(b + Vector2(0, -24), "ZZZAP!", Color(0.6, 0.9, 1.0))


func fx_puff(pos):
	_fx("puff", pos, 0.5)


func fx_uralium_cloud(pos):
	var e = _fx("uralium_cloud", pos, 3.0)
	e.size = 1.2
	fx_explosion(pos, 2.2)


func fx_text(pos, text, color):
	var e = _fx("text", pos, 1.1)
	e.text = text
	e.color = color
	e.font = font
	e.z_index = 10


func loud_noise(pos, radius):
	for c in world.get_children():
		if c is CritterScript and c.position.distance_to(pos) < radius:
			c.scare(pos, 1.5)


# ---------------------------------------------------------------- economy and power

func add_credits(team, amount):
	harvested[team] += amount
	if team == enemy_team:
		amount *= [0.8, 1.0, 1.4][GameState.difficulty]
	credits[team] += amount


func build_speed(team):
	if team == enemy_team:
		return [0.8, 1.0, 1.25][GameState.difficulty]
	return 1.0


func _recompute_power():
	power_made = [0, 0, 0]
	power_used = [0, 0, 0]
	for b in get_tree().get_nodes_in_group("buildings"):
		if b.dead:
			continue
		var p = b.def.get("power", 0)
		if p > 0:
			power_made[b.team] += p
		else:
			power_used[b.team] -= p


func has_power(team):
	return offline[team] <= 0 and power_used[team] <= power_made[team]


func power_factor(team):
	if offline[team] > 0:
		return 0.0
	return 1.0 if power_used[team] <= power_made[team] else 0.5


# ---------------------------------------------------------------- queries

func team_buildings(team):
	var out = []
	for b in get_tree().get_nodes_in_group("buildings"):
		if b.team == team and not b.dead:
			out.append(b)
	return out


func has_building(team, kind):
	for b in team_buildings(team):
		if b.kind == kind:
			return true
	return false


func nearest_building(team, kind, pos):
	var best = null
	var best_d = INF
	for b in team_buildings(team):
		if kind != "" and b.kind != kind:
			continue
		var d = b.position.distance_squared_to(pos)
		if d < best_d:
			best_d = d
			best = b
	return best


func requirements_met(team, kind):
	for r in Data.get_def(kind).get("requires", []):
		if not has_building(team, r):
			return false
	return true


func producers_for(team, unit_kind):
	var at = Data.get_def(unit_kind)["built_at"]
	var out = []
	for b in team_buildings(team):
		if b.kind == at:
			out.append(b)
	return out


func queued_count(team, unit_kind):
	var n = 0
	for b in team_buildings(team):
		for q in b.queue:
			if q == unit_kind:
				n += 1
	return n


func entity_at(pos):
	var best = null
	var best_d = INF
	for e in get_tree().get_nodes_in_group("entities"):
		if e.dead:
			continue
		if e.is_building:
			if e.get_rect().has_point(pos) and best == null:
				best = e
			continue
		var p = e.global_position + (Vector2(0, -22) if e.is_air else Vector2.ZERO)
		var d = p.distance_to(pos)
		if d < e.radius + 8 and d < best_d:
			best_d = d
			best = e
	return best


# ---------------------------------------------------------------- production

func queue_unit(team, kind):
	var d = Data.get_def(kind)
	var producers = producers_for(team, kind)
	if producers.empty():
		return false
	if credits[team] < d["cost"]:
		if team == player_team:
			notify("Not enough Uralium.")
		return false
	credits[team] -= d["cost"]
	var best = producers[0]
	for p in producers:
		if p.queue.size() < best.queue.size():
			best = p
	best.enqueue(kind)
	return true


func start_structure(team, kind):
	var sb = struct_build[team]
	if sb["kind"] != "":
		return false
	var d = Data.get_def(kind)
	if not requirements_met(team, kind):
		return false
	if credits[team] < d["cost"]:
		if team == player_team:
			notify("Not enough Uralium.")
		return false
	credits[team] -= d["cost"]
	sb["kind"] = kind
	sb["progress"] = 0.0
	sb["ready"] = false
	return true


func cancel_structure(team):
	var sb = struct_build[team]
	if sb["kind"] == "":
		return
	credits[team] += Data.get_def(sb["kind"])["cost"]
	sb["kind"] = ""
	sb["ready"] = false
	if placing != "" and team == player_team:
		placing = ""


func can_place(team, kind, cell):
	var d = Data.get_def(kind)
	var size = d["size"]
	for y in range(int(size.y)):
		for x in range(int(size.x)):
			var c = cell + Vector2(x, y)
			if map.get_type(c) != map.ROCK or not map.in_bounds(c) or map.occupied.has(c):
				return false
	var centre = cell * CELL + size * CELL / 2.0
	for b in team_buildings(team):
		if b.position.distance_to(centre) <= BUILD_RADIUS:
			return true
	return false


func place_structure(team, cell):
	var sb = struct_build[team]
	if sb["kind"] == "" or not sb["ready"]:
		return false
	if not can_place(team, sb["kind"], cell):
		return false
	spawn_building(sb["kind"], team, cell)
	sb["kind"] = ""
	sb["ready"] = false
	return true


func begin_placement(kind):
	placing = kind


func placement_cell(world_pos):
	var size = Data.get_def(placing)["size"]
	return map.cell_of(world_pos - size * CELL / 2.0 + Vector2(CELL / 2, CELL / 2))


# ---------------------------------------------------------------- events

func notify(text):
	if hud:
		hud.show_message(text)


func on_damaged(e, attacker):
	if e.team == player_team and attack_notice <= 0 and e.is_building:
		attack_notice = 15.0
		notify("Our base is under attack!")
	if e.team == enemy_team and ai:
		ai.on_attacked(e, attacker)
	# Units under fire fight back.
	if not e.is_building and attacker != null and is_instance_valid(attacker) and e.has_method("order_attack"):
		if e.state == "idle" and e.target == null and e.can_attack(attacker):
			e.target = attacker


func on_sandeater_alert(prey):
	if prey.team == player_team and eater_notice <= 0:
		eater_notice = 20.0
		notify("Sandeater! Get off the sand!")
		fx_text(prey.position + Vector2(0, -40), "RUMBLE...", Color(0.95, 0.75, 0.4))


func on_sandeater_returned(eater):
	fx_text(eater.position + Vector2(0, -40), "SHHHRRR...", Color(0.95, 0.75, 0.4))


func swallow_unit(u):
	# Eaten units are lost for good (no wreck, no explosion).
	if u.dead:
		return
	if u.team == player_team:
		notify("A sandeater swallowed our %s!" % u.def["name"])
	selected.erase(u)
	u.dead = true
	u.queue_free()


func on_entity_died(e):
	selected.erase(e)
	if e.is_building:
		for c in e.cells():
			map.occupied.erase(c)
		call_deferred("_recompute_power")
		if e.team == player_team:
			notify("%s destroyed." % e.def["name"])
	else:
		fx_explosion(e.global_position, 0.8 if e.radius > 12 else 0.4)


# ---------------------------------------------------------------- main loop

func _process(delta):
	elapsed += delta
	attack_notice -= delta
	eater_notice -= delta
	for t in range(3):
		if offline[t] > 0:
			offline[t] -= delta
	_update_structures(delta)
	_update_camera(delta)
	power_timer -= delta
	if power_timer <= 0:
		power_timer = 0.5
		_recompute_power()
		_charge_orbital(0.5)
		if not has_power(player_team) and not power_warned:
			power_warned = true
			notify("Low power! Build more Power Plants.")
		elif has_power(player_team):
			power_warned = false
	dust_timer -= delta
	if dust_timer <= 0:
		dust_timer = rand_range(15, 35)
		var d = DustScript.new()
		var wind = Vector2(rand_range(30, 60), rand_range(-10, 20))
		d.setup(camera.position + Vector2(-900, rand_range(-350, 350)), wind)
		weather.add_child(d)
	if mission == null:
		raid_timer -= delta
		if raid_timer <= 0:
			raid_timer = rand_range(240, 360)
			_freedom_raid()
	if order_marker != null:
		order_marker[1] += delta
		if order_marker[1] > 0.6:
			order_marker = null
	rules_timer -= delta
	if rules_timer <= 0:
		rules_timer = 1.0
		_check_rules()


func _update_structures(delta):
	for t in range(2):
		var sb = struct_build[t]
		if sb["kind"] == "" or sb["ready"]:
			continue
		sb["progress"] += delta * power_factor(t) * build_speed(t)
		if sb["progress"] >= Data.get_def(sb["kind"])["build_time"]:
			sb["ready"] = true
			if t == player_team:
				notify("Construction complete. Place your %s." % Data.get_def(sb["kind"])["name"])


func _freedom_raid():
	# Freedom fighters strike whichever side serves King Khan.
	var victim = -1
	for t in [player_team, enemy_team]:
		if team_faction[t] in ["klingos", "khan"]:
			victim = t
	if victim < 0:
		return
	var hq = nearest_building(victim, "", map.center_of(map.bases[victim]))
	if hq == null:
		return
	var dir = (map.world_size() / 2 - hq.position).normalized()
	var spot = hq.position + dir * 900
	for i in range(30):
		if map.is_sand_at(spot):
			break
		spot += dir.rotated(rand_range(-1, 1)) * 64
	# They arrive riding a sandeater from the map edge, leaving lines of Uralium behind.
	var start = map.clamp_to_map(spot - dir * 1400 + dir.tangent() * rand_range(-400, 400))
	var ride = SandeaterScript.new()
	ride.setup_ridden(self, start, spot, 5, hq.position)
	sandeaters.add_child(ride)
	notify("The Freedom Fighters strike the %s!" % Data.FACTIONS[team_faction[victim]]["name"])


# ---------------------------------------------------------------- orbital vaporiser (Arthem, test phase)

func orbital_time():
	return Data.BUILDINGS["orbital_uplink"]["charge_time"]


func _charge_orbital(dt):
	for t in range(2):
		if has_building(t, "orbital_uplink"):
			if has_power(t):
				var was = orbital_charge[t]
				orbital_charge[t] = min(orbital_time(), orbital_charge[t] + dt)
				if t == player_team and was < orbital_time() and orbital_charge[t] >= orbital_time():
					notify("Orbital vaporiser charged. Warning: still in test phase.")
		else:
			orbital_charge[t] = 0.0


func orbital_ready(team):
	return orbital_charge[team] >= orbital_time()


func fire_orbital(team, pos):
	if not orbital_ready(team):
		return false
	orbital_charge[team] = 0.0
	var o = OrbitalScript.new()
	o.setup(self, team, pos)
	fx_layer.add_child(o)
	if team != player_team:
		notify("Enemy orbital strike incoming!")
	return true


func _check_rules():
	if game_over:
		return
	if team_buildings(player_team).empty():
		_end(false)
		return
	var enemy_dead = team_buildings(enemy_team).empty()
	if mission != null:
		hud.set_objectives(_objective_text())
		if enemy_dead and harvested[player_team] >= mission.get("uralium_goal", 0):
			_end(true)
	elif enemy_dead:
		_end(true)


func _objective_text():
	if mission == null:
		return ""
	var goal = mission.get("uralium_goal", 0)
	var lines = []
	lines.append("[%s] Harvest %d Uralium (%d)" % ["x" if harvested[player_team] >= goal else " ", goal, int(harvested[player_team])])
	lines.append("[%s] Destroy the Klingos outpost" % ["x" if team_buildings(enemy_team).empty() else " "])
	return PoolStringArray(lines).join("\n")


func _end(won):
	game_over = true
	if won and mission != null:
		GameState.unlocked_missions = max(GameState.unlocked_missions, mission["id"] + 1)
		GameState.save_progress()
		if mission.has("outro"):
			cutscene.connect("finished", self, "_show_end", [won])
			cutscene.play(mission["outro"])
			return
	_show_end(won)


func _show_end(won):
	hud.show_game_over(won)


# ---------------------------------------------------------------- camera

func _update_camera(delta):
	var vp = get_viewport()
	var size = vp.get_visible_rect().size
	var m = vp.get_mouse_position()
	var dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or (m.x < 6 and m.x >= 0):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or (m.x > size.x - 6 and m.x <= size.x):
		dir.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or (m.y < 6 and m.y >= 0):
		dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or (m.y > size.y - 6 and m.y <= size.y):
		dir.y += 1
	if dir != Vector2.ZERO and not (cutscene and cutscene.active):
		camera.position += dir.normalized() * 900 * delta * camera.zoom.x
	var half = size * camera.zoom / 2
	camera.position.x = clamp(camera.position.x, camera.limit_left + half.x, camera.limit_right - half.x)
	camera.position.y = clamp(camera.position.y, camera.limit_top + half.y, camera.limit_bottom - half.y)


func _zoom_by(f):
	camera.zoom = Vector2.ONE * clamp(camera.zoom.x * f, 0.6, 1.8)


func focus_point(name_):
	match name_:
		"player_base":
			return map.center_of(map.bases[player_team])
		"enemy_base":
			return map.center_of(map.bases[enemy_team])
		_:
			return map.world_size() / 2


# ---------------------------------------------------------------- input

func _unhandled_input(event):
	if game_over or (cutscene and cutscene.active):
		return
	var wp = get_global_mouse_position()
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP and event.pressed:
			_zoom_by(0.9)
		elif event.button_index == BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_by(1.1)
		elif event.button_index == BUTTON_LEFT:
			if event.pressed:
				if targeting == "orbital":
					fire_orbital(player_team, wp)
					targeting = ""
					return
				if placing != "":
					if place_structure(player_team, placement_cell(wp)):
						placing = ""
					else:
						notify("Can't build there - needs open rock near your base.")
					return
				drag_start = wp
				drag_now = wp
			elif drag_start != null:
				_finish_selection(wp, event.shift)
				drag_start = null
		elif event.button_index == BUTTON_RIGHT and event.pressed:
			if placing != "" or targeting != "":
				placing = ""
				targeting = ""
				return
			_command(wp, event.control or event.alt)
	elif event is InputEventMouseMotion and drag_start != null:
		drag_now = wp
	elif event is InputEventPanGesture:
		# MacBook trackpad: two-finger swipe scrolls the map.
		camera.position += event.delta * 18.0 * camera.zoom.x
	elif event is InputEventMagnifyGesture:
		# Pinch to zoom.
		_zoom_by(1.0 / event.factor)
	elif event is InputEventKey and event.pressed and not event.echo:
		var key = event.scancode
		if key == KEY_ESCAPE:
			if placing != "" or targeting != "":
				placing = ""
				targeting = ""
			else:
				_set_selection([])
		elif key == KEY_X:
			for u in selected:
				if u.has_method("order_stop"):
					u.order_stop()
		elif key == KEY_H:
			var hq = nearest_building(player_team, "hq", camera.position)
			if hq:
				camera.position = hq.position
		elif key == KEY_Q:
			var army = []
			for u in get_tree().get_nodes_in_group("units"):
				if u.team == player_team and not u.def.get("harvester", false):
					army.append(u)
			_set_selection(army)


func _finish_selection(wp, add):
	var picked = []
	if drag_start.distance_to(wp) < 8:
		var e = entity_at(wp)
		if e != null and e.team == player_team:
			picked = [e]
	else:
		var r = Rect2(drag_start, Vector2.ZERO).expand(wp)
		for u in get_tree().get_nodes_in_group("units"):
			if u.team == player_team and not u.dead and r.has_point(u.global_position):
				picked.append(u)
	if add:
		for s in selected:
			if not s in picked:
				picked.append(s)
	_set_selection(picked)


func _set_selection(list):
	for s in selected:
		if is_instance_valid(s):
			s.set_selected(false)
	selected = []
	for s in list:
		if is_instance_valid(s) and not s.dead:
			s.set_selected(true)
			selected.append(s)


func _command(wp, attack_move):
	var units = []
	for s in selected:
		if is_instance_valid(s) and not s.dead and not s.is_building:
			units.append(s)
	if units.empty():
		return
	var tgt = entity_at(wp)
	if tgt != null and tgt.team != player_team:
		for u in units:
			if u.can_attack(tgt):
				u.order_attack(tgt)
			else:
				u.order_move(wp)
		order_marker = [wp, 0.0, Color(1, 0.3, 0.2)]
		return
	var cols = int(ceil(sqrt(units.size())))
	for i in range(units.size()):
		var off = Vector2((i % cols) - (cols - 1) / 2.0, int(i / cols) - (cols - 1) / 2.0) * 34
		var dest = wp + off
		if units[i].def.get("harvester", false):
			dest = wp
		if attack_move:
			units[i].order_attack_move(dest)
		else:
			units[i].order_move(dest)
	order_marker = [wp, 0.0, Color(1, 0.6, 0.2) if attack_move else Color(0.4, 1, 0.4)]
