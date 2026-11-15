extends Reference
# Shared comic-book UI styling: chunky dark borders and warm desert colours.

const INK = Color("#1d130c")
const PANEL = Color("#3b2a1c")
const PANEL_LIGHT = Color("#5a412b")
const ACCENT = Color("#f0b54a")
const TEXT = Color("#fbeed5")


static func box(bg, border = INK, border_w = 3, radius = 6):
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = border_w
	s.border_width_right = border_w
	s.border_width_top = border_w
	s.border_width_bottom = border_w + 1
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s


static func make_theme():
	var t = Theme.new()
	t.set_stylebox("normal", "Button", box(PANEL_LIGHT))
	t.set_stylebox("hover", "Button", box(Color("#7a5735"), ACCENT))
	t.set_stylebox("pressed", "Button", box(Color("#a8743c"), ACCENT))
	t.set_stylebox("disabled", "Button", box(Color("#2e241b"), Color("#2a1d13")))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_color_hover", "Button", Color(1, 1, 1))
	t.set_color("font_color_pressed", "Button", Color(1, 1, 1))
	t.set_color("font_color_disabled", "Button", Color(0.55, 0.5, 0.45))
	t.set_stylebox("panel", "Panel", box(PANEL, INK, 4, 8))
	t.set_stylebox("panel", "PanelContainer", box(PANEL, INK, 4, 8))
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color_shadow", "Label", Color(0, 0, 0, 0.6))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)
	return t
