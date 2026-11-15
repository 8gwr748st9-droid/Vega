extends Reference
# Unit and building designs, built from painter primitives (see painter.gd).
# Each function: func name(p, pal) where p = painter and pal = faction palette.
# Local space: +x forward, +y right, units are game pixels at 1x.

const PALETTES = {
	"arthem": {"body": Color(0.64, 0.66, 0.64), "dark": Color(0.30, 0.33, 0.34), "accent": Color(0.18, 0.45, 0.88), "trim": Color(0.85, 0.86, 0.82)},
	"klingos": {"body": Color(0.34, 0.32, 0.32), "dark": Color(0.17, 0.16, 0.17), "accent": Color(0.78, 0.14, 0.10), "trim": Color(0.72, 0.56, 0.26)},
	"freedom": {"body": Color(0.70, 0.60, 0.44), "dark": Color(0.42, 0.35, 0.25), "accent": Color(0.95, 0.72, 0.22), "trim": Color(0.55, 0.45, 0.32)},
	"khan": {"body": Color(0.20, 0.17, 0.24), "dark": Color(0.09, 0.08, 0.11), "accent": Color(0.55, 0.22, 0.80), "trim": Color(0.86, 0.68, 0.26)},
}

const RUBBER = Color(0.10, 0.10, 0.10)
const STEEL = Color(0.42, 0.43, 0.45)
const CONCRETE = Color(0.56, 0.52, 0.46)
const COPPER = Color(0.74, 0.46, 0.24)
const WARN = Color(0.95, 0.72, 0.12)


# ======================================================================== infantry

func soldier(p, pal):
	p.box(Vector2(-4.5, 0), Vector2(4, 7), 1.0, pal["dark"], 0.1)
	p.rod(Vector2(0, -4.5), Vector2(5, -1.5), 2.2, pal["body"], 0.1)
	p.rod(Vector2(0, 4.5), Vector2(6, 1.8), 2.2, pal["body"], 0.1)
	p.cbox(Vector2(-1, 0), Vector2(7, 11), 2.0, 1.5, pal["accent"], 0.1)
	p.rod(Vector2(1, 1.8), Vector2(12, 1.8), 1.7, Color(0.13, 0.13, 0.14), 0.5)
	p.dome(Vector2(0.5, 0), 3.6, pal["body"], 0.3, 4, 14)


func trooper(p, pal):
	p.box(Vector2(-5, 0), Vector2(5, 8), 1.0, pal["dark"], 0.1)
	p.cbox(Vector2(-1, 0), Vector2(9, 14), 2.5, 2.0, pal["body"], 0.35)
	p.cyl(Vector2(-0.5, -6.5), 2.8, 1.2, pal["accent"], 0.3, 10)
	p.cyl(Vector2(-0.5, 6.5), 2.8, 1.2, pal["accent"], 0.3, 10)
	p.rod(Vector2(1, 2.5), Vector2(13, 2.5), 2.6, Color(0.12, 0.12, 0.13), 0.5)
	p.dome(Vector2(0.5, 0), 4.0, pal["dark"], 0.5, 4, 14)
	p.lamp(Vector2(3.5, 0), 0.8, Color(1, 0.3, 0.2))


func rocketeer(p, pal):
	trooper(p, pal)
	p.rod(Vector2(-8, -4.5), Vector2(10, -4.5), 3.4, Color(0.36, 0.38, 0.30), 0.3)
	p.cyl(Vector2(10, -4.5), 2.0, 0.8, Color(0.15, 0.15, 0.15), 0.2, 8)


func warrior(p, pal):
	var cloak = []
	for i in range(14):
		var a = i * TAU / 14
		cloak.append(Vector2(cos(a) * 5.5 - 1.5, sin(a) * 6.5))
	p.prism(cloak, 2.5, pal["body"], 0.05, 0.6)
	p.paint([Vector2(1, -5), Vector2(3, -4), Vector2(3, 4), Vector2(1, 5)], pal["accent"])
	p.rod(Vector2(1, 2), Vector2(11, 2), 1.6, Color(0.20, 0.17, 0.13), 0.3)
	p.dome(Vector2(0.5, 0), 3.4, pal["dark"], 0.05, 4, 14)
	p.paint([Vector2(2.5, -1.2), Vector2(4, -1.2), Vector2(4, 1.2), Vector2(2.5, 1.2)], Color(0.1, 0.1, 0.1))


# ======================================================================== vehicles

func buggy(p, pal):
	for w in [Vector2(-8, -8), Vector2(8, -8), Vector2(-8, 8), Vector2(8, 8)]:
		p.tread(w, Vector2(8, 4), RUBBER)
	p.cbox(Vector2(0, 0), Vector2(26, 14), 3.0, 2.0, pal["body"], 0.35)
	p.box(Vector2(-8, 0), Vector2(8, 10), 1.5, pal["dark"], 0.3)
	p.grille(Vector2(-8, 0), Vector2(6, 8), 4, Color(0, 0, 0, 0.5))
	p.paint([Vector2(-12, -1), Vector2(11, -1), Vector2(11, 1), Vector2(-12, 1)], pal["accent"])
	p.glass([Vector2(3, -5), Vector2(8, -4), Vector2(8, 4), Vector2(3, 5)])
	p.rod(Vector2(-3, -5.5), Vector2(4, -5.5), 1.2, STEEL)
	p.rod(Vector2(-3, 5.5), Vector2(4, 5.5), 1.2, STEEL)
	p.lamp(Vector2(13, -5), 1.0, Color(1, 0.95, 0.75))
	p.lamp(Vector2(13, 5), 1.0, Color(1, 0.95, 0.75))

func mg_turret(p, pal):
	p.cyl(Vector2(0, 0), 3.8, 1.4, pal["dark"], 0.4, 12)
	p.rod(Vector2(1, 0), Vector2(12, 0), 1.8, Color(0.12, 0.12, 0.13), 0.6)
	p.box(Vector2(2, 0), Vector2(4, 4), 0.8, pal["body"], 0.3)


func harvester(p, pal):
	p.tread(Vector2(0, -12), Vector2(40, 6), RUBBER)
	p.tread(Vector2(0, 12), Vector2(40, 6), RUBBER)
	p.cbox(Vector2(-2, 0), Vector2(34, 20), 3.0, 2.5, Color(0.80, 0.66, 0.30), 0.3)
	p.box(Vector2(-7, 0), Vector2(18, 15), 2.0, Color(0.25, 0.22, 0.20), 0.2)
	p.paint([Vector2(-15, -6), Vector2(1, -6), Vector2(1, 6), Vector2(-15, 6)], Color(0.14, 0.12, 0.11))
	p.cbox(Vector2(11, -5), Vector2(9, 9), 2.0, 1.5, Color(0.80, 0.66, 0.30), 0.3)
	p.glass([Vector2(14, -8.5), Vector2(15.5, -8.5), Vector2(15.5, -1.5), Vector2(14, -1.5)])
	p.prism([Vector2(17, -11), Vector2(25, -13), Vector2(25, 13), Vector2(17, 11)], 2.0, STEEL, 0.6)
	for i in range(6):
		var y = -11 + i * 4.4
		p.line(Vector2(25, y), Vector2(27, y), Color(0.2, 0.2, 0.2), 1.2)
	p.paint([Vector2(-19, -9), Vector2(-17, -9), Vector2(-17, 9), Vector2(-19, 9)], pal["accent"])
	p.lamp(Vector2(10, -5), 1.2, Color(1, 0.6, 0.1))

func tank_hull(p, pal):
	p.tread(Vector2(0, -10.5), Vector2(36, 6), RUBBER)
	p.tread(Vector2(0, 10.5), Vector2(36, 6), RUBBER)
	p.cbox(Vector2(0, 0), Vector2(30, 17), 4.0, 3.0, pal["body"], 0.35)
	p.grille(Vector2(-11, 0), Vector2(6, 11), 5, Color(0, 0, 0, 0.45))
	p.paint([Vector2(-14, -7.5), Vector2(14, -7.5), Vector2(14, -6), Vector2(-14, -6)], pal["accent"])
	p.paint([Vector2(-14, 6), Vector2(14, 6), Vector2(14, 7.5), Vector2(-14, 7.5)], pal["accent"])

func tesla_turret(p, pal):
	p.cyl(Vector2(-1, 0), 9.0, 3.0, pal["dark"], 0.4, 20)
	p.rod(Vector2(3, 0), Vector2(15, 0), 3.2, pal["trim"], 0.6)
	for r in [6.0, 4.6, 3.2]:
		p.cyl(Vector2(-1, 0), r, 1.0, COPPER if r != 4.6 else Color(0.45, 0.28, 0.15), 0.7, 16)
	p.dome(Vector2(16, 0), 3.0, Color(0.55, 0.8, 1.0), 0.8, 3, 12)


func siege_hull(p, pal):
	p.tread(Vector2(0, -12.5), Vector2(44, 7), RUBBER)
	p.tread(Vector2(0, 12.5), Vector2(44, 7), RUBBER)
	p.cbox(Vector2(0, 0), Vector2(38, 21), 5.0, 3.5, pal["body"], 0.35)
	p.prism([Vector2(14, -9), Vector2(20, -6), Vector2(20, 6), Vector2(14, 9)], 2.0, pal["dark"], 0.4)
	p.rod(Vector2(-19, -6), Vector2(-23, -6), 2.4, Color(0.2, 0.2, 0.2))
	p.rod(Vector2(-19, 6), Vector2(-23, 6), 2.4, Color(0.2, 0.2, 0.2))
	p.grille(Vector2(-13, 0), Vector2(8, 14), 6, Color(0, 0, 0, 0.45))

func siege_turret(p, pal):
	p.rod(Vector2(6, 0), Vector2(34, 0), 4.5, Color(0.22, 0.22, 0.23), 0.55)
	p.box(Vector2(33, 0), Vector2(4, 7), 1.0, Color(0.18, 0.18, 0.19), 0.4)
	p.cbox(Vector2(-2, 0), Vector2(20, 16), 4.0, 3.0, pal["body"], 0.4)
	p.cyl(Vector2(-5, -3), 2.6, 1.0, pal["dark"], 0.3, 10)
	p.paint([Vector2(5, -8), Vector2(7, -8), Vector2(7, 8), Vector2(5, 8)], pal["accent"])


func drone(p, pal):
	for d in [Vector2(9, 9), Vector2(9, -9), Vector2(-9, 9), Vector2(-9, -9)]:
		p.rod(Vector2(0, 0), d, 2.0, pal["dark"], 0.4)
		p.cyl(d, 3.6, 1.2, pal["dark"], 0.4, 12)
	p.cbox(Vector2(0, 0), Vector2(11, 8), 2.5, 1.5, pal["body"], 0.5)
	p.dome(Vector2(1, 0), 3.0, pal["accent"], 0.6, 3, 12)
	p.lamp(Vector2(6, 0), 1.0, Color(1, 0.25, 0.2))


func gunship(p, pal):
	p.rod(Vector2(-6, 0), Vector2(-31, 0), 4.0, pal["body"], 0.4)
	p.box(Vector2(-30, 0), Vector2(4, 13), 1.0, pal["dark"], 0.3)
	p.box(Vector2(-2, 0), Vector2(8, 32), 1.5, pal["dark"], 0.35)
	p.rod(Vector2(-8, -13), Vector2(6, -13), 3.2, Color(0.25, 0.27, 0.22))
	p.rod(Vector2(-8, 13), Vector2(6, 13), 3.2, Color(0.25, 0.27, 0.22))
	p.prism([Vector2(18, 0), Vector2(12, -7), Vector2(-2, -8), Vector2(-12, -5), Vector2(-14, 0), Vector2(-12, 5), Vector2(-2, 8), Vector2(12, 7)], 3.0, pal["body"], 0.4)
	p.glass([Vector2(16, 0), Vector2(11, -4.5), Vector2(4, -4.5), Vector2(4, 4.5), Vector2(11, 4.5)])
	p.paint([Vector2(-10, -1), Vector2(2, -1), Vector2(2, 1), Vector2(-10, 1)], pal["accent"])
	p.cyl(Vector2(0, 0), 3.0, 1.0, pal["dark"], 0.5, 12)


func gun_turret(p, pal):
	p.rod(Vector2(4, -3), Vector2(26, -3), 2.6, Color(0.15, 0.15, 0.16), 0.6)
	p.rod(Vector2(4, 3), Vector2(26, 3), 2.6, Color(0.15, 0.15, 0.16), 0.6)
	p.cbox(Vector2(0, 0), Vector2(18, 16), 4.0, 3.0, pal["body"], 0.4)
	p.paint([Vector2(-7, -1.2), Vector2(5, -1.2), Vector2(5, 1.2), Vector2(-7, 1.2)], pal["accent"])


func uplink_dish(p, pal):
	p.rod(Vector2(0, 0), Vector2(-14, 0), 5.0, pal["dark"], 0.4)
	for r in [30.0, 24.0, 17.0, 10.0]:
		p.cyl(Vector2(0, 0), r, 3.0, Color(0.80, 0.82, 0.84) if r != 24.0 else Color(0.70, 0.72, 0.75), 0.6, 28)
	p.rod(Vector2(0, -22), Vector2(0, 0), 1.6, STEEL)
	p.rod(Vector2(0, 22), Vector2(0, 0), 1.6, STEEL)
	p.dome(Vector2(0, 0), 4.0, pal["accent"], 0.7, 3, 12)


# ======================================================================== buildings
# Drawn in the painter's 3/4 view (see painter.gd): you see roofs and south walls, and the sun casts
# shadows to the south-east. Coordinates are relative to the centre of the footprint; +y is south.

func _pad(p, size, col = CONCRETE):
	p.box(Vector2.ZERO, size - Vector2(8, 8), 4.0, col, 0.05)
	var h = (size - Vector2(18, 18)) / 2
	p.line(Vector2(-h.x, 0), Vector2(h.x, 0), Color(0, 0, 0, 0.14), 1.0)
	p.line(Vector2(0, -h.y), Vector2(0, h.y), Color(0, 0, 0, 0.14), 1.0)
	p.weather(size - Vector2(26, 26), 1.0, int(size.x + size.y))


func _hazard(p, center, size):
	p.paint([center - size / 2, center + Vector2(size.x / 2, -size.y / 2), center + size / 2, center + Vector2(-size.x / 2, size.y / 2)], WARN)
	var n = int(size.x / 6)
	for i in range(n):
		var x = center.x - size.x / 2 + i * 6 + 1
		p.line(Vector2(x, center.y + size.y / 2), Vector2(x + 3, center.y - size.y / 2), Color(0.1, 0.1, 0.1), 1.6)


func _door(p, x, wall_y, w, h, col):
	# A door / opening on a south wall.
	p._quad(p.Q(Vector2(x - w / 2, wall_y), 0), p.Q(Vector2(x + w / 2, wall_y), 0), p.Q(Vector2(x + w / 2, wall_y), h), p.Q(Vector2(x - w / 2, wall_y), h), col, col.lightened(0.08))


func _shadow_box(p, center, size, h):
	p.cast_shadow(p.rect_pts(center, size), h)


func _wall(pal):
	return pal["body"].lightened(0.06)


# Command Centre: tall glass-fronted tower with wings, radar dish and antenna mast.
func b_hq(p, pal, size):
	_pad(p, size)
	_shadow_box(p, Vector2(-56, 22), Vector2(62, 84), 20)
	_shadow_box(p, Vector2(56, 22), Vector2(62, 84), 20)
	_shadow_box(p, Vector2(0, 4), Vector2(86, 100), 62)
	for x in [-56, 56]:
		p.block(Vector2(x, 22), Vector2(62, 84), 20, _wall(pal), pal["body"], 4.0)
		p.windows(Vector2(x, 22), Vector2(52, 84), 6, 14, 5, 0.4)
		p.grille(Vector2(x, 10 - 15), Vector2(30, 22), 6, Color(0, 0, 0, 0.3))
	p.block(Vector2(0, 4), Vector2(86, 100), 62, _wall(pal), pal["body"], 5.0)
	for row in range(4):
		p.windows(Vector2(0, 4), Vector2(76, 100), 12 + row * 12, 20 + row * 12, 7, 0.45)
	p.wall_band(Vector2(0, 4), Vector2(86, 100), 56, 61, pal["accent"])
	_door(p, 0, 54, 20, 10, Color(0.08, 0.09, 0.10))
	# roof equipment (at roof height 62)
	var up = Vector2(0, -62 * p.OBL)
	p.box(Vector2(-24, -20) + up, Vector2(22, 18), 2, pal["dark"], 0.3)
	p.grille(Vector2(-24, -20) + up, Vector2(16, 12), 5, Color(0, 0, 0, 0.4))
	p.paint(p.circle_pts(Vector2(14, 18) + up, 15, 20), Color(0.30, 0.31, 0.32))
	p.paint(p.rect_pts(Vector2(14, 18) + up, Vector2(12, 3)), WARN)
	p.cylinder(Vector2(22, -24) + up, 4, 10, STEEL)
	p.dome(Vector2(22, -24) + up + Vector2(0, -12 * p.OBL), 13, Color(0.82, 0.84, 0.86), 0.6, 5, 24)
	p.rod(Vector2(-30, 26) + up, Vector2(-30, -22) + up, 1.8, STEEL)
	p.lamp(Vector2(-30, -22) + up, 1.6, Color(1, 0.2, 0.15))


# Power Plant: two concrete cooling towers, a turbine hall and a transformer yard.
func b_power(p, pal, size):
	_pad(p, size)
	p.cast_shadow(p.circle_pts(Vector2(-27, -18), 25, 16), 58)
	p.cast_shadow(p.circle_pts(Vector2(27, -18), 25, 16), 58)
	_shadow_box(p, Vector2(-14, 36), Vector2(72, 26), 20)
	for x in [-27, 27]:
		# Hyperbolic cooling tower: wide base, narrow waist, flared open top.
		var conc = Color(0.80, 0.77, 0.71)
		p.cylinder(Vector2(x, -18), 25, 18, conc, conc, 0.05, 28)
		p.cylinder(Vector2(x, -18 - 18 * p.OBL), 22, 18, conc, conc, 0.05, 28)
		p.cylinder(Vector2(x, -18 - 36 * p.OBL), 20, 14, conc, conc, 0.05, 28)
		p.cylinder(Vector2(x, -18 - 50 * p.OBL), 22, 8, conc, conc.lightened(0.05), 0.05, 28)
		p.hole(Vector2(x, -18), 58, 17)
		p.rings(Vector2(x, -18), 25.5, 13, 17, 1, pal["accent"])
	p.pipe3(Vector2(-27, 8), Vector2(-27, 24), 6, 5, STEEL)
	p.pipe3(Vector2(27, 8), Vector2(27, 24), 6, 5, STEEL)
	p.block(Vector2(-14, 36), Vector2(72, 26), 20, _wall(pal), pal["body"], 3.0)
	p.wall_band(Vector2(-14, 36), Vector2(72, 26), 14, 18, pal["accent"])
	p.windows(Vector2(-14, 36), Vector2(60, 26), 4, 10, 6, 0.5)
	# transformer yard with warning sign
	p.block(Vector2(42, 40), Vector2(22, 18), 12, Color(0.30, 0.32, 0.33), Color(0.36, 0.38, 0.40), 2.0, 1.0, 0.4)
	p.grille(Vector2(42, 40 - 12 * p.OBL), Vector2(16, 12), 5, Color(0, 0, 0, 0.5))
	_door(p, 42, 49, 10, 8, WARN)
	p.line(Vector2(43, 49 - 5.2), Vector2(41, 49 - 3), Color(0.1, 0.1, 0.1), 1.2)
	p.line(Vector2(41, 49 - 3), Vector2(43.5, 49 - 3), Color(0.1, 0.1, 0.1), 1.2)
	p.line(Vector2(43.5, 49 - 3), Vector2(41.5, 49 - 0.8), Color(0.1, 0.1, 0.1), 1.2)


# Uralium Refinery: storage tanks, a tall processing column, a chimney stack and an unloading bay.
func b_refinery(p, pal, size):
	_pad(p, size)
	_hazard(p, Vector2(0, 50), Vector2(84, 10))
	p.cast_shadow(p.circle_pts(Vector2(-62, -8), 23, 14), 34)
	p.cast_shadow(p.circle_pts(Vector2(-14, -8), 23, 14), 34)
	_shadow_box(p, Vector2(54, 0), Vector2(62, 74), 30)
	p.cast_shadow(p.circle_pts(Vector2(30, -34), 8, 10), 78)
	p.cast_shadow(p.circle_pts(Vector2(76, -30), 6, 10), 92)
	# pipe rack behind the tanks
	p.pipe3(Vector2(-76, -34), Vector2(40, -34), 22, 4, STEEL)
	p.pipe3(Vector2(-76, -40), Vector2(40, -40), 22, 3, Color(0.62, 0.30, 0.20))
	for x in [-62, -14]:
		p.cylinder(Vector2(x, -8), 23, 34, Color(0.78, 0.78, 0.76), Color(0.84, 0.84, 0.82), 0.45, 28)
		p.rings(Vector2(x, -8), 23.5, 12, 20, 2, Color(0.62, 0.10, 0.08))
		p.dome(Vector2(x, -8 - 34 * p.OBL), 16, Color(0.86, 0.86, 0.84), 0.5, 4, 24)
		p.pipe3(Vector2(x, 14), Vector2(x, 34), 4, 4, STEEL)
	p.pipe3(Vector2(-62, 34), Vector2(24, 34), 4, 4, STEEL)
	# processing column (tall, thin) and chimney stack
	p.cylinder(Vector2(30, -34), 8, 78, Color(0.72, 0.73, 0.74), Color(0.6, 0.6, 0.6), 0.5, 16)
	p.rings(Vector2(30, -34), 8.4, 10, 74, 6, Color(0.25, 0.25, 0.26))
	p.block(Vector2(54, 0), Vector2(62, 74), 30, _wall(pal), pal["body"], 4.0)
	p.wall_band(Vector2(54, 0), Vector2(62, 74), 23, 28, pal["accent"])
	p.windows(Vector2(54, 0), Vector2(50, 74), 12, 19, 5, 0.3)
	_door(p, 54, 37, 30, 11, Color(0.10, 0.10, 0.11))
	p.cylinder(Vector2(76, -30), 6, 92, Color(0.66, 0.42, 0.32), Color(0.5, 0.32, 0.25), 0.1, 14)
	p.hole(Vector2(76, -30), 92, 4)
	p.rings(Vector2(76, -30), 6.4, 80, 90, 2, Color(0.9, 0.9, 0.88))


# Barracks: two arched huts, a guard tower with a searchlight and a sandbagged yard.
func b_barracks(p, pal, size):
	_pad(p, size, Color(0.60, 0.53, 0.42))
	_shadow_box(p, Vector2(-26, -10), Vector2(44, 76), 20)
	_shadow_box(p, Vector2(24, -10), Vector2(44, 76), 20)
	_shadow_box(p, Vector2(46, 42), Vector2(16, 16), 44)
	for x in [-26, 24]:
		# arched (Nissen) hut: wall + strongly bevelled roof reads as a curved roof
		p.block(Vector2(x, -10), Vector2(44, 76), 12, _wall(pal), pal["body"], 16.0, 0.55, 0.35)
		for i in range(6):
			var y = -42 + i * 13 - 12 * p.OBL
			p.line(Vector2(x - 20, y), Vector2(x + 20, y), Color(0, 0, 0, 0.16), 1.0)
		_door(p, x, 28, 12, 10, Color(0.10, 0.10, 0.10))
		p.wall_band(Vector2(x, -10), Vector2(44, 76), 10, 12, pal["accent"])
	# sandbag wall along the south side
	for i in range(9):
		p.cbox(Vector2(-52 + i * 9, 54), Vector2(9, 6), 2.0, 2.0, Color(0.66, 0.57, 0.40), 0.0)
	for i in range(8):
		p.cbox(Vector2(-47.5 + i * 9, 50), Vector2(9, 6), 2.0, 2.0, Color(0.70, 0.61, 0.44), 0.0)
	# guard tower on legs
	for d in [Vector2(-6, -6), Vector2(6, -6), Vector2(-6, 6), Vector2(6, 6)]:
		p.line(Vector2(46, 42) + d, Vector2(46, 42) + d + Vector2(0, -34 * p.OBL), Color(0.25, 0.22, 0.18), 1.6)
	p.block(Vector2(46, 42 - 34 * p.OBL), Vector2(18, 18), 10, Color(0.36, 0.33, 0.28), pal["body"], 5.0, 0.6)
	p.lamp(Vector2(46, 51 - 38 * p.OBL), 2.0, Color(1, 0.95, 0.7))
	# flag
	p.line(Vector2(-54, 40), Vector2(-54, 40 - 46 * p.OBL), STEEL, 1.4)
	p.paint([Vector2(-54, 40 - 46 * p.OBL), Vector2(-38, 44 - 46 * p.OBL), Vector2(-54, 50 - 46 * p.OBL)], pal["accent"])


# War Factory: huge assembly hall with a saw-tooth roof, a big roll-up vehicle door and a crane.
func b_factory(p, pal, size):
	_pad(p, size)
	_hazard(p, Vector2(0, 80), Vector2(110, 10))
	_shadow_box(p, Vector2(0, -6), Vector2(170, 130), 40)
	p.block(Vector2(0, -6), Vector2(170, 130), 40, _wall(pal), pal["body"], 4.0)
	# saw-tooth roof: glass skylight strips facing north
	var up = Vector2(0, -40 * p.OBL)
	for i in range(5):
		var y = -62 + i * 25
		p.prism([Vector2(-78, y) + up, Vector2(78, y) + up, Vector2(78, y + 20) + up, Vector2(-78, y + 20) + up], 7.0, pal["body"], 0.3, 0.9)
		p.glass([Vector2(-74, y + 1) + up, Vector2(74, y + 1) + up, Vector2(74, y + 6) + up, Vector2(-74, y + 6) + up], 0.6)
	# south wall: big roll-up door with slats, small windows, stripe
	p.wall_band(Vector2(0, -6), Vector2(170, 130), 33, 38, pal["accent"])
	_door(p, 0, 59, 96, 28, Color(0.20, 0.21, 0.22))
	for k in range(6):
		var z = 3 + k * 4.4
		p.draw_line(p.Q(Vector2(-48, 59), z), p.Q(Vector2(48, 59), z), Color(0, 0, 0, 0.45), 1.0 * p.sc)
	_door(p, 0, 59, 96, 3, WARN)
	p.windows(Vector2(-66, -6), Vector2(30, 130), 14, 24, 3, 0.4)
	p.windows(Vector2(66, -6), Vector2(30, 130), 14, 24, 3, 0.4)
	# exhaust stacks and a gantry crane
	p.cast_shadow(p.circle_pts(Vector2(-70, -56), 5, 8), 70)
	p.cylinder(Vector2(-70, -56) + up, 5, 28, Color(0.45, 0.45, 0.46), Color(0.1, 0.1, 0.1), 0.4, 12)
	p.cylinder(Vector2(-56, -56) + up, 5, 22, Color(0.45, 0.45, 0.46), Color(0.1, 0.1, 0.1), 0.4, 12)
	p.rod(Vector2(60, -50) + up + Vector2(0, -10), Vector2(60, 50) + up + Vector2(0, -10), 5, WARN, 0.3)
	p.box(Vector2(60, 10) + up + Vector2(0, -10), Vector2(12, 10), 2, Color(0.25, 0.25, 0.26), 0.4)


# Helipad: landing pad with markings and lights, a small control tower and a fuel tank.
func b_helipad(p, pal, size):
	_pad(p, size)
	p.cyl(Vector2(-6, 6), 46, 3, Color(0.30, 0.31, 0.32), 0.1, 40)
	p.paint(p.circle_pts(Vector2(-6, 6), 38, 36), Color(0.92, 0.92, 0.9))
	p.paint(p.circle_pts(Vector2(-6, 6), 35, 36), Color(0.31, 0.32, 0.33))
	for r in [Vector2(-18, 6), Vector2(6, 6)]:
		p.paint(p.rect_pts(r, Vector2(6, 34)), Color(0.92, 0.92, 0.9))
	p.paint(p.rect_pts(Vector2(-6, 6), Vector2(18, 6)), Color(0.92, 0.92, 0.9))
	_shadow_box(p, Vector2(44, -40), Vector2(22, 22), 34)
	p.block(Vector2(44, -40), Vector2(22, 22), 26, _wall(pal), pal["body"], 2.0)
	p.block(Vector2(44, -40 - 26 * p.OBL), Vector2(28, 26), 8, Color(0.14, 0.20, 0.26), pal["accent"], 3.0, 1.0, 0.5)
	p.rod(Vector2(44, -42 - 34 * p.OBL), Vector2(44, -62 - 34 * p.OBL), 1.4, STEEL)
	p.cast_shadow(p.circle_pts(Vector2(-46, -44), 9, 10), 14)
	p.cylinder(Vector2(-46, -44), 9, 14, Color(0.80, 0.80, 0.78), Color(0.86, 0.86, 0.84), 0.5, 16)
	p.rings(Vector2(-46, -44), 9.3, 5, 9, 1, Color(0.7, 0.12, 0.1))


# Gun Tower base: a reinforced concrete bunker tower (the turret is drawn live on top).
func b_gun_tower(p, pal, size):
	p.cast_shadow(p.circle_pts(Vector2(0, 4), 22, 14), 30)
	p.cylinder(Vector2(0, 4), 24, 8, Color(0.52, 0.49, 0.44), Color(0.56, 0.53, 0.48), 0.05, 24)
	p.cylinder(Vector2(0, 4 - 8 * p.OBL), 19, 22, Color(0.60, 0.57, 0.52), pal["dark"], 0.1, 24)
	p.rings(Vector2(0, 4 - 8 * p.OBL), 19.3, 15, 19, 1, pal["accent"])
	p.rings(Vector2(0, 4 - 8 * p.OBL), 19.3, 6, 10, 1, Color(0.08, 0.08, 0.08))


# Tesla Coil: a tall stacked coil tower topped with a discharge sphere.
func b_tesla_coil(p, pal, size):
	p.cast_shadow(p.circle_pts(Vector2(0, 6), 14, 12), 70)
	p.block(Vector2(0, 6), Vector2(48, 44), 10, pal["dark"].lightened(0.08), pal["dark"], 6.0, 0.8, 0.4)
	_door(p, -12, 28, 10, 6, WARN)
	var z = 10.0
	var r = 16.0
	for k in range(7):
		var c = COPPER if k % 2 == 0 else Color(0.36, 0.22, 0.12)
		p.cylinder(Vector2(0, 6 - z * p.OBL), r, 7, c, c.lightened(0.1), 0.7, 20)
		z += 7
		r -= 1.5
	p.cylinder(Vector2(0, 6 - z * p.OBL), 3, 8, STEEL, STEEL, 0.6, 10)
	p.sphere(Vector2(0, 6), z + 14, 9, Color(0.72, 0.78, 0.84), 0.9)


# Orbital Uplink: control bunker, solar arrays and the pedestal for the big dish (drawn live).
func b_orbital_uplink(p, pal, size):
	_pad(p, size)
	for y in [-42, -26, 30, 46]:
		for x in [-46, -30]:
			p.paint(p.rect_pts(Vector2(x, y), Vector2(14, 14)), Color(0.10, 0.15, 0.32), 0.9)
			p.line(Vector2(x - 7, y), Vector2(x + 7, y), Color(0.5, 0.6, 0.8, 0.5), 0.6)
			p.line(Vector2(x, y - 7), Vector2(x, y + 7), Color(0.5, 0.6, 0.8, 0.5), 0.6)
	_shadow_box(p, Vector2(-38, 2), Vector2(26, 30), 16)
	p.block(Vector2(-38, 2), Vector2(26, 30), 16, _wall(pal), pal["body"], 3.0)
	p.windows(Vector2(-38, 2), Vector2(22, 30), 6, 12, 3, 0.7)
	p.cast_shadow(p.circle_pts(Vector2(16, 6), 30, 14), 40)
	p.cylinder(Vector2(16, 6), 22, 10, Color(0.50, 0.48, 0.44), Color(0.54, 0.52, 0.48), 0.1, 24)
	p.cylinder(Vector2(16, 6 - 10 * p.OBL), 9, 26, pal["dark"], pal["dark"], 0.4, 16)
	p.rings(Vector2(16, 6), 22.3, 6, 9, 1, pal["accent"])


# Shield Generator (King Khan): emitter sphere held in a ring of pylons.
func b_shield_generator(p, pal, size):
	_pad(p, size)
	p.cast_shadow(p.circle_pts(Vector2(0, 4), 30, 14), 50)
	p.cylinder(Vector2(0, 4), 40, 10, pal["dark"].lightened(0.1), pal["dark"], 0.4, 28)
	for i in range(6):
		var a = i * TAU / 6 + 0.5
		var c = Vector2(0, 4) + Vector2(cos(a), sin(a) * 0.8) * 32
		p.cylinder(c - Vector2(0, 10 * p.OBL), 5, 30, pal["body"].lightened(0.1), pal["trim"], 0.5, 10)
	p.sphere(Vector2(0, 4), 44, 20, pal["accent"], 0.9)


# ======================================================================== catalogue

# unit shape/kind -> [hull_func, turret_func_or_empty, cell_size, scale]
func unit_parts(kind, shape, radius):
	var s = 1.0
	match shape:
		"infantry":
			return ["soldier", "", 32, s]
		"infantry_heavy":
			return ["rocketeer" if kind.find("rocket") >= 0 else "trooper", "", 34, s]
		"infantry_cloak":
			return ["warrior", "", 32, s]
		"buggy":
			return ["buggy", "mg_turret", 44, s]
		"harvester":
			return ["harvester", "", 64, s]
		"tank_tesla":
			s = radius / 18.0
			return ["tank_hull", "tesla_turret", int(56 * s), s]
		"tank_siege":
			s = radius / 21.0
			return ["siege_hull", "siege_turret", int(76 * s), s]
		"drone":
			return ["drone", "", 36, s]
		"heli":
			return ["gunship", "", 76, s]
	return ["soldier", "", 32, s]


func building_func(kind):
	return "b_" + kind
