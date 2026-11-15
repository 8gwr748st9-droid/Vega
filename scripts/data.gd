extends Node
# All unit, building and faction definitions live here so balancing is done in one place.
#
# Common keys
#   faction     : which faction can build it ("any" = every faction with a base)
#   cost        : spice credits
#   build_time  : seconds at full power
#   tech        : campaign tech level needed (skirmish uses tech 3)
#   requires    : buildings that must exist before this can be built
#   hp, radius  : toughness and size
#   weapon keys : range, damage, reload, weapon ("bullet"|"shell"|"missile"|"tesla"), splash, anti_air

const CELL = 64

const FACTIONS = {
	"arthem": {
		"name": "Arthems",
		"color": Color(0.22, 0.56, 0.95),
		"dark": Color(0.10, 0.26, 0.52),
		"sand_speed": 1.0,
		"blurb": "Adaptable. Helicopters, drones and stealth. Strong defences.",
	},
	"klingos": {
		"name": "Klingos",
		"color": Color(0.86, 0.20, 0.18),
		"dark": Color(0.45, 0.08, 0.07),
		"sand_speed": 0.72,
		"blurb": "Emissaries of King Khan. Heavy firepower, Tesla technology, slow on sand.",
	},
	"freedom": {
		"name": "Freedom Fighters",
		"color": Color(0.96, 0.76, 0.22),
		"dark": Color(0.55, 0.38, 0.06),
		"sand_speed": 1.3,
		"no_tracks": true,
		"worm_safe": true,
		"blurb": "People of Vega. Fast on sand, leave no tracks, ride the sandworms.",
	},
	"khan": {
		"name": "King Khan",
		"color": Color(0.62, 0.22, 0.80),
		"dark": Color(0.28, 0.06, 0.40),
		"sand_speed": 0.85,
		"blurb": "The tyrant of Vega. Best technology on the planet. (Missions 9-10)",
	},
}

const UNITS = {
	# ---------------- Arthems ----------------
	"arthem_ranger": {
		"name": "Ranger", "faction": "arthem", "shape": "infantry",
		"cost": 100, "build_time": 4.0, "tech": 1, "built_at": "barracks",
		"hp": 90, "radius": 8, "speed": 72, "sight": 230,
		"range": 160, "damage": 9, "reload": 0.6, "weapon": "bullet", "anti_air": true,
	},
	"arthem_scout": {
		"name": "Dune Buggy", "faction": "arthem", "shape": "buggy",
		"cost": 300, "build_time": 6.0, "tech": 1, "built_at": "factory",
		"hp": 170, "radius": 13, "speed": 150, "sight": 280,
		"range": 150, "damage": 11, "reload": 0.45, "weapon": "bullet", "anti_air": true,
	},
	"arthem_harvester": {
		"name": "Harvester", "faction": "arthem", "shape": "harvester", "harvester": true,
		"cost": 1000, "build_time": 10.0, "tech": 1, "built_at": "factory",
		"hp": 650, "radius": 18, "speed": 58, "sight": 200, "capacity": 500,
	},
	"arthem_drone": {
		"name": "Strike Drone", "faction": "arthem", "shape": "drone", "air": true,
		"cost": 450, "build_time": 7.0, "tech": 2, "built_at": "factory",
		"hp": 90, "radius": 10, "speed": 175, "sight": 260,
		"range": 140, "damage": 18, "reload": 0.9, "weapon": "missile", "splash": 18, "anti_air": true,
	},
	"arthem_gunship": {
		"name": "Gunship", "faction": "arthem", "shape": "heli", "air": true,
		"cost": 900, "build_time": 11.0, "tech": 2, "built_at": "helipad",
		"hp": 320, "radius": 18, "speed": 120, "sight": 300,
		"range": 200, "damage": 38, "reload": 1.4, "weapon": "missile", "splash": 34, "anti_air": false,
	},
	# ---------------- Klingos ----------------
	"klingos_trooper": {
		"name": "Heavy Trooper", "faction": "klingos", "shape": "infantry_heavy",
		"cost": 150, "build_time": 5.0, "tech": 1, "built_at": "barracks",
		"hp": 150, "radius": 9, "speed": 52, "sight": 220,
		"range": 150, "damage": 22, "reload": 1.3, "weapon": "bullet", "anti_air": true,
	},
	"klingos_rocketeer": {
		"name": "Rocketeer", "faction": "klingos", "shape": "infantry_heavy",
		"cost": 250, "build_time": 6.0, "tech": 2, "built_at": "barracks",
		"hp": 120, "radius": 9, "speed": 48, "sight": 240,
		"range": 190, "damage": 45, "reload": 2.4, "weapon": "missile", "splash": 30, "anti_air": true,
	},
	"klingos_harvester": {
		"name": "Harvester", "faction": "klingos", "shape": "harvester", "harvester": true,
		"cost": 1000, "build_time": 10.0, "tech": 1, "built_at": "factory",
		"hp": 800, "radius": 19, "speed": 52, "sight": 200, "capacity": 500,
	},
	"klingos_tesla_tank": {
		"name": "Tesla Tank", "faction": "klingos", "shape": "tank_tesla",
		"cost": 1100, "build_time": 12.0, "tech": 1, "built_at": "factory",
		"hp": 750, "radius": 18, "speed": 48, "sight": 260,
		"range": 175, "damage": 95, "reload": 2.6, "weapon": "tesla", "anti_air": false,
	},
	"klingos_siege": {
		"name": "Siege Crawler", "faction": "klingos", "shape": "tank_siege",
		"cost": 1400, "build_time": 15.0, "tech": 2, "built_at": "factory",
		"hp": 900, "radius": 21, "speed": 38, "sight": 300,
		"range": 280, "damage": 120, "reload": 3.8, "weapon": "shell", "splash": 60, "anti_air": false,
	},
	# ---------------- Freedom fighters (no base, appear through events) ----------------
	"freedom_warrior": {
		"name": "Desert Warrior", "faction": "freedom", "shape": "infantry_cloak",
		"cost": 0, "build_time": 0.0, "tech": 99, "built_at": "",
		"hp": 110, "radius": 8, "speed": 90, "sight": 260,
		"range": 150, "damage": 13, "reload": 0.7, "weapon": "bullet", "anti_air": true,
	},
	"freedom_hijacker": {
		"name": "Hijacker", "faction": "freedom", "shape": "infantry_cloak",
		"cost": 0, "build_time": 0.0, "tech": 99, "built_at": "", "hijacker": true, "max_alive": 2,
		"hp": 90, "radius": 8, "speed": 100, "sight": 260,
		"range": 0, "damage": 0, "reload": 1.0, "weapon": "", "anti_air": false,
	},
}

const BUILDINGS = {
	"hq": {
		"name": "Command Centre", "faction": "any", "shape": "hq",
		"cost": 0, "build_time": 0.0, "tech": 99, "size": Vector2(3, 3),
		"hp": 2200, "power": 20,
	},
	"power": {
		"name": "Power Plant", "faction": "any", "shape": "power",
		"cost": 300, "build_time": 6.0, "tech": 1, "size": Vector2(2, 2),
		"hp": 650, "power": 100, "requires": ["hq"],
	},
	"refinery": {
		"name": "Spice Refinery", "faction": "any", "shape": "refinery",
		"cost": 1400, "build_time": 10.0, "tech": 1, "size": Vector2(3, 2),
		"hp": 1100, "power": -30, "requires": ["power"], "free_unit": "harvester",
	},
	"barracks": {
		"name": "Barracks", "faction": "any", "shape": "barracks",
		"cost": 400, "build_time": 7.0, "tech": 1, "size": Vector2(2, 2),
		"hp": 750, "power": -20, "requires": ["power"],
	},
	"factory": {
		"name": "War Factory", "faction": "any", "shape": "factory",
		"cost": 1500, "build_time": 12.0, "tech": 1, "size": Vector2(3, 3),
		"hp": 1400, "power": -40, "requires": ["refinery"],
	},
	"helipad": {
		"name": "Helipad", "faction": "arthem", "shape": "helipad",
		"cost": 1000, "build_time": 9.0, "tech": 2, "size": Vector2(2, 2),
		"hp": 700, "power": -30, "requires": ["factory"],
	},
	"gun_tower": {
		"name": "Gun Tower", "faction": "arthem", "shape": "gun_tower", "defense": true,
		"cost": 600, "build_time": 7.0, "tech": 1, "size": Vector2(1, 1),
		"hp": 900, "power": -15, "requires": ["barracks"],
		"range": 230, "damage": 16, "reload": 0.4, "weapon": "bullet", "anti_air": true,
	},
	"tesla_coil": {
		"name": "Tesla Coil", "faction": "klingos", "shape": "tesla_coil", "defense": true,
		"cost": 1000, "build_time": 9.0, "tech": 1, "size": Vector2(1, 1),
		"hp": 1000, "power": -60, "requires": ["barracks"],
		"range": 240, "damage": 130, "reload": 2.5, "weapon": "tesla", "anti_air": true,
	},
}

const ENEMY_RELATIONS = {
	# Freedom fighters only fight the Klingos and Khan (the oppressors).
	"freedom": ["klingos", "khan"],
}


func get_def(kind):
	if UNITS.has(kind):
		return UNITS[kind]
	if BUILDINGS.has(kind):
		return BUILDINGS[kind]
	push_error("Unknown kind: %s" % kind)
	return {}


func is_building(kind):
	return BUILDINGS.has(kind)


func faction_color(faction):
	return FACTIONS[faction]["color"]


func faction_dark(faction):
	return FACTIONS[faction]["dark"]


func factions_hostile(a, b):
	if a == b:
		return false
	if ENEMY_RELATIONS.has(a):
		return b in ENEMY_RELATIONS[a]
	if ENEMY_RELATIONS.has(b):
		return a in ENEMY_RELATIONS[b]
	return true


func harvester_for(faction):
	return faction + "_harvester"


func buildings_for(faction, tech):
	var out = []
	for k in BUILDINGS.keys():
		var d = BUILDINGS[k]
		if d["tech"] > tech:
			continue
		if d["faction"] == "any" or d["faction"] == faction:
			out.append(k)
	return out


func units_for(faction, tech):
	var out = []
	for k in UNITS.keys():
		var d = UNITS[k]
		if d["faction"] == faction and d["tech"] <= tech and d["built_at"] != "":
			out.append(k)
	return out
