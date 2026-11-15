extends Node2D
# A tiny "2.5D" painter used to pre-render units and buildings.
# Shapes are flat polygons with bevelled edges. Every face gets a 3D normal and is lit by a
# fixed sun (upper left), so parts look solid and stay correctly lit at any rotation.
#
# Local coordinates: +x = forward (unit facing), +y = right. Sizes are in game pixels;
# the painter scales by `sc` (supersampling) and rotates by `angle` around `origin`.

const SUN = Vector3(-0.55, -0.6, 0.58)

var origin = Vector2()
var angle = 0.0
var sc = 2.0
var offset = Vector2()   # shifts the drawing inside its cell (buildings leave room for height and shadow)
var job = null           # {"cells": [[origin, angle], ...], "draw": FuncRef, "args": []}
var L = SUN.normalized()
var H = (SUN.normalized() + Vector3(0, 0, 1)).normalized()


func _draw():
	if job == null:
		return
	for cell in job["cells"]:
		origin = cell[0]
		angle = cell[1]
		job["draw"].call_funcv([self] + job["args"])


# ---------------------------------------------------------------- transforms and lighting

func P(v):
	return origin + (v + offset).rotated(angle) * sc


func world_normal(n):
	var xy = Vector2(n.x, n.y).rotated(angle)
	return Vector3(xy.x, xy.y, n.z).normalized()


func lit(base, n, metal = 0.25, rough = 24.0):
	var N = world_normal(n)
	var d = max(N.dot(L), 0.0)
	var k = 0.52 + 0.78 * d
	var s = pow(max(N.dot(H), 0.0), rough) * metal
	return Color(min(base.r * k + s, 1.0), min(base.g * k + s, 1.0), min(base.b * k + s * 0.95, 1.0), base.a)


# ---------------------------------------------------------------- geometry helpers

func _area(pts):
	var a = 0.0
	for i in range(pts.size()):
		var p = pts[i]
		var q = pts[(i + 1) % pts.size()]
		a += p.x * q.y - q.x * p.y
	return a * 0.5


func _inset(pts, d):
	var n = pts.size()
	var sign_ = 1.0 if _area(pts) > 0 else -1.0
	var out = []
	for i in range(n):
		var a = pts[(i - 1 + n) % n]
		var b = pts[i]
		var c = pts[(i + 1) % n]
		var e1 = (b - a).normalized()
		var e2 = (c - b).normalized()
		# inward normals
		var n1 = Vector2(-e1.y, e1.x) * sign_
		var n2 = Vector2(-e2.y, e2.x) * sign_
		var bis = (n1 + n2)
		if bis.length() < 0.001:
			bis = n1
		bis = bis.normalized()
		var cosv = max(0.35, bis.dot(n1))
		out.append(b + bis * d / cosv)
	return out


func rect_pts(center, size):
	var h = size / 2
	return [center + Vector2(-h.x, -h.y), center + Vector2(h.x, -h.y), center + Vector2(h.x, h.y), center + Vector2(-h.x, h.y)]


func chamfer_pts(center, size, c):
	var h = size / 2
	return [
		center + Vector2(-h.x + c, -h.y), center + Vector2(h.x - c, -h.y), center + Vector2(h.x, -h.y + c),
		center + Vector2(h.x, h.y - c), center + Vector2(h.x - c, h.y), center + Vector2(-h.x + c, h.y),
		center + Vector2(-h.x, h.y - c), center + Vector2(-h.x, -h.y + c)]


func circle_pts(center, r, segs = 20):
	var out = []
	for i in range(segs):
		out.append(center + Vector2.RIGHT.rotated(i * TAU / segs) * r)
	return out


# ---------------------------------------------------------------- primitives

func _poly(pts, cols):
	# Skip degenerate pieces (they make Godot's triangulator fail).
	if pts.size() < 3 or abs(_area(Array(pts))) < 0.05:
		return
	draw_polygon(pts, cols)


func _max_bevel(pts, bevel):
	var c = Vector2()
	for p in pts:
		c += p
	c /= pts.size()
	var dmin = INF
	for i in range(pts.size()):
		var a = pts[i]
		var b = pts[(i + 1) % pts.size()]
		var ab = b - a
		var t = clamp((c - a).dot(ab) / max(0.0001, ab.length_squared()), 0.0, 1.0)
		dmin = min(dmin, c.distance_to(a + ab * t))
	return min(bevel, dmin * 0.7)


# A bevelled solid: flat top plus sloped rim. `slope` = how steep the rim looks (1 = 45 degrees).
func prism(pts, bevel, col, metal = 0.25, slope = 1.0, outline = true):
	bevel = _max_bevel(pts, bevel)
	var inner = _inset(pts, bevel)
	var n = pts.size()
	var sign_ = 1.0 if _area(pts) > 0 else -1.0
	for i in range(n):
		var j = (i + 1) % n
		var e = (pts[j] - pts[i]).normalized()
		var outward = -Vector2(-e.y, e.x) * sign_
		var nn = Vector3(outward.x * slope, outward.y * slope, 1.0)
		var c = lit(col, nn, metal)
		_poly(PoolVector2Array([P(pts[i]), P(pts[j]), P(inner[j]), P(inner[i])]), PoolColorArray([c, c, c, c]))
	# Top face with a faint gradient (slightly convex) so large flat areas are not dead.
	var centre = Vector2()
	for p in inner:
		centre += p
	centre /= inner.size()
	var tp = PoolVector2Array()
	var tc = PoolColorArray()
	var span = 1.0
	for p in inner:
		span = max(span, (p - centre).length())
	for p in inner:
		var d = (p - centre) / span
		tp.append(P(p))
		tc.append(lit(col, Vector3(d.x * 0.18, d.y * 0.18, 1.0), metal))
	_poly(tp, tc)
	if outline:
		var ol = PoolVector2Array()
		for p in pts:
			ol.append(P(p))
		ol.append(P(pts[0]))
		draw_polyline(ol, Color(0.05, 0.04, 0.03, 0.55), 1.2 * sc, true)


func box(center, size, bevel, col, metal = 0.25, slope = 1.0):
	prism(rect_pts(center, size), bevel, col, metal, slope)


func cbox(center, size, chamfer, bevel, col, metal = 0.25, slope = 1.0):
	prism(chamfer_pts(center, size, chamfer), bevel, col, metal, slope)


func cyl(center, r, bevel, col, metal = 0.3, segs = 20):
	prism(circle_pts(center, r, segs), bevel, col, metal)


# Hemisphere: rings with increasingly tilted normals.
func dome(center, r, col, metal = 0.35, rings = 6, segs = 24):
	for k in range(rings):
		var r0 = r * (1.0 - float(k) / rings)
		var r1 = r * (1.0 - float(k + 1) / rings)
		var tilt = cos(asin(clamp(r0 / r, 0.0, 1.0)))
		for i in range(segs):
			var a0 = i * TAU / segs
			var a1 = (i + 1) * TAU / segs
			var am = (a0 + a1) * 0.5
			var dir = Vector2.RIGHT.rotated(am)
			var sin_t = r0 / r
			var nrm = Vector3(dir.x * sin_t, dir.y * sin_t, max(0.15, tilt))
			var c = lit(col, nrm, metal, 30.0)
			var pts = [center + Vector2.RIGHT.rotated(a0) * r0, center + Vector2.RIGHT.rotated(a1) * r0]
			if r1 > 0.01:
				pts.append(center + Vector2.RIGHT.rotated(a1) * r1)
				pts.append(center + Vector2.RIGHT.rotated(a0) * r1)
			else:
				pts.append(center)
			var pp = PoolVector2Array()
			var cc = PoolColorArray()
			for p in pts:
				pp.append(P(p))
				cc.append(c)
			_poly(pp, cc)


# A rounded rod (barrel, pipe, antenna) from a to b.
func rod(a, b, w, col, metal = 0.45):
	var d = (b - a).normalized()
	var s = Vector2(-d.y, d.x) * w * 0.5
	var bands = 4
	for k in range(bands):
		var t0 = -1.0 + 2.0 * k / bands
		var t1 = -1.0 + 2.0 * (k + 1) / bands
		var tm = (t0 + t1) * 0.5
		var nn = Vector3(s.normalized().x * tm, s.normalized().y * tm, sqrt(max(0.05, 1.0 - tm * tm)))
		var c = lit(col, nn, metal, 30.0)
		_poly(PoolVector2Array([P(a + s * t0), P(b + s * t0), P(b + s * t1), P(a + s * t1)]), PoolColorArray([c, c, c, c]))


# Flat painted shape (decals, stripes, glass panes) lit as a flat top.
func paint(pts, col, metal = 0.1):
	var c = lit(col, Vector3(0, 0, 1), metal)
	var pp = PoolVector2Array()
	for p in pts:
		pp.append(P(p))
	if pp.size() >= 3 and abs(_area(Array(pp))) > 0.05:
		draw_colored_polygon(pp, c)


func glass(pts, metal = 0.9):
	# Dark tinted glass with a sky reflection gradient.
	var pp = PoolVector2Array()
	var cc = PoolColorArray()
	var centre = Vector2()
	for p in pts:
		centre += p
	centre /= pts.size()
	for p in pts:
		var d = (p - centre)
		var c = lit(Color(0.12, 0.17, 0.22), Vector3(d.x * 0.08, d.y * 0.08, 1.0), metal, 12.0)
		pp.append(P(p))
		cc.append(c)
	_poly(pp, cc)


func line(a, b, col, w = 1.0):
	draw_line(P(a), P(b), col, w * sc, true)


func grille(center, size, n, col):
	var h = size / 2
	for i in range(n):
		var x = -h.x + (i + 0.5) * size.x / n
		line(center + Vector2(x, -h.y), center + Vector2(x, h.y), col, 1.0)


func lamp(center, r, col):
	draw_circle(P(center), r * sc * 1.8, Color(col.r, col.g, col.b, 0.25))
	draw_circle(P(center), r * sc, col)


func tread(center, size, col):
	# Track/tyre with tread lines across it.
	box(center, size, 1.5, col, 0.15)
	var h = size / 2
	var n = int(size.x / 3.0)
	for i in range(n):
		var x = -h.x + (i + 0.5) * size.x / n
		line(center + Vector2(x, -h.y + 1), center + Vector2(x, h.y - 1), Color(0.02, 0.02, 0.02, 0.6), 0.8)


# Dirt and blown sand so surfaces look used, not factory-new.
func weather(size, strength = 1.0, seed_value = 1):
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	var h = size / 2
	var n = int(size.x * size.y / 260.0 * strength)
	for i in range(n):
		var pos = Vector2(rng.randf_range(-h.x, h.x), rng.randf_range(-h.y, h.y))
		var r = rng.randf_range(1.0, 3.5)
		var col = Color(0.20, 0.14, 0.09, 0.05 * strength) if rng.randf() < 0.6 else Color(0.86, 0.70, 0.48, 0.07 * strength)
		draw_circle(P(pos), r * sc, col)
	# sand drifted against the lower-right edges (wind side)
	for i in range(int(n / 3)):
		var t = rng.randf()
		var edge = Vector2(lerp(-h.x, h.x, t), h.y - rng.randf_range(0, 6)) if rng.randf() < 0.5 else Vector2(h.x - rng.randf_range(0, 6), lerp(-h.y, h.y, t))
		draw_circle(P(edge), rng.randf_range(2.0, 5.0) * sc, Color(0.84, 0.68, 0.46, 0.10 * strength))



# ======================================================================== 3/4 view (buildings)
# Buildings are drawn in an oblique view: height z moves things up the screen by z * OBL,
# so you see roofs AND south-facing walls. The sun is in the north-west, so shadows fall south-east.

const OBL = 0.75
const SHADOW_DIR = Vector2(0.75, 0.5)


func Q(v, z):
	return P(v + Vector2(0, -z * OBL))


func cast_shadow(footprint, h, alpha = 0.32):
	var pts = PoolVector2Array()
	for v in footprint:
		pts.append(v)
		pts.append(v + SHADOW_DIR * h)
	var hull = Geometry.convex_hull_2d(pts)
	var out = PoolVector2Array()
	for v in hull:
		out.append(P(v))
	if out.size() >= 3:
		draw_colored_polygon(out, Color(0.10, 0.06, 0.03, alpha))


func _quad(a, b, c, d, ca, cb):
	_poly(PoolVector2Array([a, b, c, d]), PoolColorArray([ca, ca, cb, cb]))


# A building block: south wall + roof. roof_bevel/roof_slope make flat, hipped or pitched roofs.
func block(center, size, h, wall, roof, roof_bevel = 3.0, roof_slope = 1.0, metal = 0.15):
	var hx = size.x / 2
	var hy = size.y / 2
	var bl = center + Vector2(-hx, hy)
	var br = center + Vector2(hx, hy)
	# South walls face away from the sun: evenly lit by the sky, a little darker near the ground.
	var wc = Color(wall.r * 0.80, wall.g * 0.81, wall.b * 0.84, wall.a)
	_quad(Q(bl, 0), Q(br, 0), Q(br, h), Q(bl, h), wc.darkened(0.16), wc)
	draw_line(Q(bl, 0), Q(br, 0), Color(0.05, 0.04, 0.03, 0.5), 1.0 * sc, true)
	prism(rect_pts(center + Vector2(0, -h * OBL), size), roof_bevel, roof, metal, roof_slope)


func wall_band(center, size, z0, z1, col):
	# A horizontal band on the south wall of a block (window strip, stripe, door...).
	var y = center.y + size.y / 2
	var a = Vector2(center.x - size.x / 2, y)
	var b = Vector2(center.x + size.x / 2, y)
	_quad(Q(a, z0), Q(b, z0), Q(b, z1), Q(a, z1), col, col)


func windows(center, size, z0, z1, count, lit_frac = 0.3):
	var y = center.y + size.y / 2
	var w = size.x / count
	for i in range(count):
		var x0 = center.x - size.x / 2 + i * w + w * 0.2
		var x1 = x0 + w * 0.6
		var col = Color(0.95, 0.80, 0.45) if fmod(i * 0.618, 1.0) < lit_frac else Color(0.16, 0.22, 0.28)
		_quad(Q(Vector2(x0, y), z0), Q(Vector2(x1, y), z0), Q(Vector2(x1, y), z1), Q(Vector2(x0, y), z1), col, col.lightened(0.15))


func cylinder(center, r, h, col, top_col = null, metal = 0.3, segs = 24):
	if top_col == null:
		top_col = col
	var half = int(segs / 2)
	for i in range(half):
		var a0 = i * PI / half
		var a1 = (i + 1) * PI / half
		var am = (a0 + a1) * 0.5
		var p0 = center + Vector2(cos(a0), sin(a0)) * r
		var p1 = center + Vector2(cos(a1), sin(a1)) * r
		# Lit from the left (west), falling into shade on the right: reads as a round wall.
		var c = lit(col, Vector3(cos(am) * 0.75, -0.25, 0.62), metal, 20.0)
		_quad(Q(p0, 0), Q(p1, 0), Q(p1, h), Q(p0, h), c.darkened(0.14), c)
	prism(circle_pts(center + Vector2(0, -h * OBL), r, segs), max(1.0, r * 0.12), top_col, metal)


func rings(center, r, z0, z1, n, col):
	# Bands around a cylinder (ladders, stripes).
	for k in range(n):
		var z = lerp(z0, z1, (k + 0.5) / n)
		var pts = PoolVector2Array()
		for i in range(13):
			var a = i * PI / 12
			pts.append(Q(center + Vector2(cos(a), sin(a)) * r * 1.02, z))
		draw_polyline(pts, col, 1.6 * sc, true)


func pipe3(a, b, z, w, col):
	rod(a + Vector2(0, -z * OBL), b + Vector2(0, -z * OBL), w, col)


func sphere(center, z, r, col, metal = 0.5):
	dome(center + Vector2(0, -z * OBL), r, col, metal, 6, 24)


func hole(center, z, r, col = Color(0.07, 0.07, 0.08)):
	# A dark opening in a roof (chimney mouth, cooling tower throat).
	var pts = PoolVector2Array()
	for v in circle_pts(center + Vector2(0, -z * OBL), r, 24):
		pts.append(P(v))
	draw_colored_polygon(pts, col)
