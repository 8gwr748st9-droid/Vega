extends Node2D
# Shared base for units and buildings: health, team, weapons and drawing helpers.

const INK = Color("#1d130c")

var game
var team = 0
var faction = ""
var kind = ""
var def = {}
var hp = 100.0
var max_hp = 100.0
var radius = 10.0
var is_building = false
var is_air = false
var selected = false
var dead = false
var reload_left = 0.0
var target = null
var flash = 0.0
var scan_timer = 0.0


func setup(g, k, t):
	game = g
	kind = k
	team = t
	def = Data.get_def(k)
	faction = def["faction"]
	if faction == "any":
		faction = game.team_faction[t]
	max_hp = float(def["hp"])
	hp = max_hp
	radius = float(def.get("radius", 10))
	is_air = def.get("air", false)
	add_to_group("entities")


func team_color():
	return Data.faction_color(faction)


func team_dark():
	return Data.faction_dark(faction)


func is_enemy_of(other):
	if other == null or not is_instance_valid(other) or other.dead:
		return false
	if other.team == team:
		return false
	return Data.factions_hostile(faction, other.faction)


func can_attack(other):
	if not is_enemy_of(other):
		return false
	if def.get("damage", 0) <= 0:
		return false
	if other.is_air and not def.get("anti_air", false):
		return false
	return true


func in_range(other):
	return global_position.distance_to(other.global_position) <= def.get("range", 0) + other.radius


func find_target(sight):
	var best = null
	var best_d = sight * sight
	for e in get_tree().get_nodes_in_group("entities"):
		if not can_attack(e):
			continue
		var d = global_position.distance_squared_to(e.global_position)
		# Prefer units over buildings when both are close.
		if e.is_building:
			d *= 1.6
		if d < best_d:
			best_d = d
			best = e
	return best


func fire_at(other):
	reload_left = def["reload"]
	var muzzle = global_position + muzzle_offset(other)
	match def.get("weapon", ""):
		"tesla":
			game.fx_tesla(muzzle, other.global_position)
			other.take_damage(def["damage"], self)
		"bullet":
			game.fx_tracer(muzzle, other.global_position)
			other.take_damage(def["damage"], self)
		_:
			game.spawn_projectile(self, other)


func muzzle_offset(other):
	var dir = (other.global_position - global_position).normalized()
	if is_air:
		return dir * radius + Vector2(0, -26)
	return dir * radius


func take_damage(amount, attacker = null):
	if dead:
		return
	hp -= amount
	flash = 0.12
	game.on_damaged(self, attacker)
	if hp <= 0:
		die()


func die():
	if dead:
		return
	dead = true
	game.on_entity_died(self)
	queue_free()


func set_selected(v):
	selected = v
	update()


func _tick_common(delta):
	if reload_left > 0:
		reload_left -= delta
	if flash > 0:
		flash -= delta
		update()


# ---------------------------------------------------------------- drawing helpers

func draw_health(width, y_offset):
	if not selected and hp >= max_hp:
		return
	var frac = clamp(hp / max_hp, 0, 1)
	var col = Color(0.35, 0.92, 0.40)
	if frac < 0.6:
		col = Color(0.98, 0.80, 0.20)
	if frac < 0.3:
		col = Color(0.98, 0.28, 0.22)
	var r = Rect2(Vector2(-width / 2, y_offset), Vector2(width, 4))
	draw_rect(r.grow(1), Color(0, 0, 0, 0.65))
	draw_rect(Rect2(r.position, Vector2(width * frac, 4)), col)
	draw_rect(Rect2(r.position, Vector2(width * frac, 1.5)), col.lightened(0.4))


func draw_selection(r):
	if not selected:
		return
	# Ground ring (slightly squashed so it sits on the floor), with corner brackets.
	var col = Color(0.45, 1.0, 0.55, 0.9)
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.8))
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(0, 0, 0, 0.35), 3.5, true)
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, col, 1.6, true)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func draw_outlined_poly(points, fill, width = 3.0):
	var pts = PoolVector2Array(points)
	draw_colored_polygon(pts, fill)
	var closed = PoolVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, INK, width)


func draw_outlined_circle(p, r, fill, width = 3.0):
	draw_circle(p, r + width * 0.5, INK)
	draw_circle(p, r - width * 0.5, fill)


func rect_points(center, size, angle = 0.0):
	var h = size / 2
	var pts = [Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)]
	var out = []
	for p in pts:
		out.append(center + p.rotated(angle))
	return out
