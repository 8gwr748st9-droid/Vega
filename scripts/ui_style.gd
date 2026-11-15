extends Reference
# Shared UI styling: dark translucent panels, thin borders, amber accent, Rajdhani typeface.

const PANEL = Color(0.055, 0.065, 0.08, 0.90)
const PANEL_SOLID = Color(0.075, 0.085, 0.10, 1.0)
const BUTTON = Color(0.13, 0.15, 0.18, 1.0)
const BUTTON_HOVER = Color(0.19, 0.22, 0.26, 1.0)
const LINE = Color(1, 1, 1, 0.10)
const ACCENT = Color(0.96, 0.69, 0.25)
const TEXT = Color(0.90, 0.92, 0.94)
const TEXT_DIM = Color(0.60, 0.64, 0.68)
const GOOD = Color(0.42, 0.90, 0.52)
const BAD = Color(0.98, 0.38, 0.30)


static func font(size, weight = "SemiBold"):
	var data = DynamicFontData.new()
	data.font_path = "res://fonts/Rajdhani-%s.ttf" % weight
	data.antialiased = true
	var f = DynamicFont.new()
	f.font_data = data
	f.size = size
	f.use_filter = true
	return f


static func box(bg, border = LINE, border_w = 1, radius = 5, margin = 8):
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.6
	s.content_margin_bottom = margin * 0.6
	s.anti_aliasing = true
	return s


static func make_theme():
	var t = Theme.new()
	t.default_font = font(17)
	t.set_stylebox("normal", "Button", box(BUTTON))
	t.set_stylebox("hover", "Button", box(BUTTON_HOVER, ACCENT))
	t.set_stylebox("pressed", "Button", box(Color(0.26, 0.21, 0.12), ACCENT))
	t.set_stylebox("disabled", "Button", box(Color(0.09, 0.10, 0.12, 0.9), Color(1, 1, 1, 0.04)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_color_hover", "Button", Color(1, 1, 1))
	t.set_color("font_color_pressed", "Button", ACCENT)
	t.set_color("font_color_disabled", "Button", Color(0.42, 0.45, 0.48))
	t.set_stylebox("panel", "Panel", box(PANEL, LINE, 1, 0))
	t.set_stylebox("panel", "PanelContainer", box(PANEL, LINE, 1, 8, 18))
	t.set_color("font_color", "Label", TEXT)
	t.set_stylebox("panel", "TooltipPanel", box(PANEL_SOLID, ACCENT, 1, 4))
	t.set_color("font_color", "TooltipLabel", TEXT)
	return t


static func label(text, size = 17, color = TEXT, weight = "SemiBold"):
	var l = Label.new()
	l.text = text
	l.add_font_override("font", font(size, weight))
	l.add_color_override("font_color", color)
	return l
