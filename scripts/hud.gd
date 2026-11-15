extends CanvasLayer
# In-game interface: sidebar (minimap, resources, build cards with icons), messages, objectives.

const UIStyle = preload("res://scripts/ui_style.gd")
const MinimapScript = preload("res://scripts/minimap.gd")

const SIDEBAR_W = 248
const CARD = Vector2(110, 86)

var game
var root
var credits_label
var power_label
var power_bar
var message_label
var message_time = 0.0
var objectives_label
var info_label
var struct_cards = {}
var unit_cards = {}
var orbital_button
var refresh = 0.0
var paused_label
var game_over_panel
var shown_credits = 0.0


func _ready():
	layer = 10
	pause_mode = Node.PAUSE_MODE_PROCESS
	root = Control.new()
	root.anchor_right = 1
	root.anchor_bottom = 1
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIStyle.make_theme()
	add_child(root)

	var side = Panel.new()
	side.anchor_left = 1
	side.anchor_right = 1
	side.anchor_bottom = 1
	side.margin_left = -SIDEBAR_W
	root.add_child(side)

	var vb = VBoxContainer.new()
	vb.anchor_right = 1
	vb.anchor_bottom = 1
	vb.margin_left = 10
	vb.margin_right = -10
	vb.margin_top = 8
	vb.margin_bottom = -8
	vb.add_constant_override("separation", 5)
	side.add_child(vb)

	var f = game.team_faction[game.player_team]
	var title = UIStyle.label(Data.FACTIONS[f]["name"].to_upper(), 20, Data.faction_color(f).lightened(0.35), "Bold")
	title.align = Label.ALIGN_CENTER
	vb.add_child(title)

	var mm = MinimapScript.new()
	mm.game = game
	mm.rect_min_size = Vector2(SIDEBAR_W - 20, SIDEBAR_W - 20)
	vb.add_child(mm)

	var res = HBoxContainer.new()
	vb.add_child(res)
	res.add_child(UIStyle.label("URALIUM", 14, UIStyle.TEXT_DIM))
	credits_label = UIStyle.label("0", 24, UIStyle.ACCENT, "Bold")
	credits_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	credits_label.align = Label.ALIGN_RIGHT
	res.add_child(credits_label)

	var pw = HBoxContainer.new()
	vb.add_child(pw)
	pw.add_child(UIStyle.label("POWER", 14, UIStyle.TEXT_DIM))
	power_label = UIStyle.label("", 16)
	power_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	power_label.align = Label.ALIGN_RIGHT
	pw.add_child(power_label)
	power_bar = ProgressBar.new()
	power_bar.percent_visible = false
	power_bar.rect_min_size = Vector2(0, 5)
	power_bar.add_stylebox_override("bg", UIStyle.box(Color(1, 1, 1, 0.08), Color(0, 0, 0, 0), 0, 2, 0))
	vb.add_child(power_bar)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.scroll_horizontal_enabled = false
	vb.add_child(scroll)
	var lists = VBoxContainer.new()
	lists.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lists.add_constant_override("separation", 5)
	scroll.add_child(lists)

	lists.add_child(UIStyle.label("STRUCTURES", 14, UIStyle.TEXT_DIM))
	var sg = GridContainer.new()
	sg.columns = 2
	sg.add_constant_override("hseparation", 5)
	sg.add_constant_override("vseparation", 5)
	lists.add_child(sg)
	for k in Data.buildings_for(f, game.tech):
		if k == "hq":
			continue
		var card = _make_card(k + "/" + (f if Data.BUILDINGS[k]["faction"] == "any" else Data.BUILDINGS[k]["faction"]))
		card["button"].connect("pressed", self, "_on_struct_pressed", [k])
		sg.add_child(card["button"])
		struct_cards[k] = card

	lists.add_child(UIStyle.label("UNITS", 14, UIStyle.TEXT_DIM))
	var ug = GridContainer.new()
	ug.columns = 2
	ug.add_constant_override("hseparation", 5)
	ug.add_constant_override("vseparation", 5)
	lists.add_child(ug)
	for k in Data.units_for(f, game.tech):
		var card2 = _make_card(k + "/hull")
		card2["button"].connect("pressed", self, "_on_unit_pressed", [k])
		ug.add_child(card2["button"])
		unit_cards[k] = card2

	orbital_button = Button.new()
	orbital_button.rect_min_size = Vector2(0, 46)
	orbital_button.visible = false
	orbital_button.connect("pressed", self, "_on_orbital_pressed")
	lists.add_child(orbital_button)

	message_label = UIStyle.label("", 24, Color(1, 0.93, 0.72), "Bold")
	message_label.margin_left = 18
	message_label.margin_top = 12
	message_label.add_color_override("font_color_shadow", Color(0, 0, 0, 0.8))
	message_label.add_constant_override("shadow_offset_x", 1)
	message_label.add_constant_override("shadow_offset_y", 2)
	root.add_child(message_label)

	objectives_label = UIStyle.label("", 17)
	objectives_label.margin_left = 18
	objectives_label.margin_top = 48
	objectives_label.add_color_override("font_color_shadow", Color(0, 0, 0, 0.8))
	root.add_child(objectives_label)

	info_label = UIStyle.label("", 16, UIStyle.TEXT)
	info_label.anchor_top = 1
	info_label.anchor_bottom = 1
	info_label.margin_left = 18
	info_label.margin_top = -56
	info_label.add_color_override("font_color_shadow", Color(0, 0, 0, 0.85))
	root.add_child(info_label)

	paused_label = UIStyle.label("PAUSED", 64, Color(1, 1, 1, 0.9), "Bold")
	paused_label.anchor_right = 1
	paused_label.anchor_top = 0.4
	paused_label.margin_right = -SIDEBAR_W
	paused_label.align = Label.ALIGN_CENTER
	paused_label.visible = false
	root.add_child(paused_label)

	_refresh()


func _make_card(art_id):
	# A build button: picture on top, name and price/status below, progress strip at the bottom.
	var b = Button.new()
	b.rect_min_size = CARD
	b.rect_clip_content = true
	var icon = TextureRect.new()
	icon.expand = true
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.rect_position = Vector2(6, 2)
	icon.rect_size = Vector2(CARD.x - 12, 48)
	b.add_child(icon)
	var name_l = UIStyle.label("", 14)
	name_l.rect_position = Vector2(4, 48)
	name_l.rect_size = Vector2(CARD.x - 8, 16)
	name_l.align = Label.ALIGN_CENTER
	name_l.clip_text = true
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(name_l)
	var status = UIStyle.label("", 14, UIStyle.ACCENT)
	status.rect_position = Vector2(4, 64)
	status.rect_size = Vector2(CARD.x - 8, 16)
	status.align = Label.ALIGN_CENTER
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(status)
	var bar = ColorRect.new()
	bar.color = UIStyle.ACCENT
	bar.rect_position = Vector2(0, CARD.y - 3)
	bar.rect_size = Vector2(0, 3)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(bar)
	return {"button": b, "icon": icon, "name": name_l, "status": status, "bar": bar, "art": art_id}


func _on_struct_pressed(kind):
	var sb = game.struct_build[game.player_team]
	if sb["kind"] == kind:
		if sb["ready"]:
			game.begin_placement(kind)
		else:
			game.cancel_structure(game.player_team)
	elif sb["kind"] == "":
		game.start_structure(game.player_team, kind)
	_refresh()


func _on_orbital_pressed():
	if game.orbital_ready(game.player_team):
		game.targeting = "orbital"
		game.placing = ""
		show_message("Pick a target. Test-phase beam: it WILL drift off target.")


func _on_unit_pressed(kind):
	game.queue_unit(game.player_team, kind)
	_refresh()


func show_message(text):
	if message_label:
		message_label.text = text
		message_label.modulate.a = 1.0
		message_time = 5.0


func set_objectives(text):
	objectives_label.text = text


func _process(delta):
	message_time -= delta
	if message_label and message_time < 1.0:
		message_label.modulate.a = clamp(message_time, 0.0, 1.0)
	# Credits tick up and down smoothly instead of jumping.
	var target = game.credits[game.player_team]
	shown_credits = lerp(shown_credits, target, min(1.0, delta * 8.0))
	if abs(shown_credits - target) < 1.0:
		shown_credits = target
	credits_label.text = str(int(round(shown_credits)))
	refresh -= delta
	if refresh <= 0:
		refresh = 0.2
		_refresh()


func _unhandled_key_input(event):
	if event.pressed and not event.echo and event.scancode == KEY_P and not game.game_over:
		if game.cutscene and game.cutscene.active:
			return
		get_tree().paused = not get_tree().paused
		paused_label.visible = get_tree().paused


func _set_card(card, title, status, status_col, disabled, frac, tip):
	if card["icon"].texture == null and Art.has(card["art"]):
		card["icon"].texture = Art.icon_texture(card["art"])
	card["name"].text = title
	card["status"].text = status
	card["status"].add_color_override("font_color", status_col)
	card["button"].disabled = disabled
	card["button"].hint_tooltip = tip
	card["icon"].modulate = Color(1, 1, 1, 0.3) if disabled else Color(1, 1, 1, 1)
	card["name"].modulate = Color(1, 1, 1, 0.45) if disabled else Color(1, 1, 1, 1)
	card["bar"].rect_size = Vector2(CARD.x * clamp(frac, 0, 1), 3)


func _refresh():
	var t = game.player_team
	var ok = game.has_power(t)
	power_label.text = "%d / %d" % [game.power_used[t], game.power_made[t]]
	power_label.add_color_override("font_color", UIStyle.GOOD if ok else UIStyle.BAD)
	power_bar.max_value = max(1, game.power_made[t])
	power_bar.value = min(game.power_used[t], game.power_made[t])
	power_bar.add_stylebox_override("fg", UIStyle.box(UIStyle.GOOD if ok else UIStyle.BAD, Color(0, 0, 0, 0), 0, 2, 0))

	var sb = game.struct_build[t]
	for k in struct_cards.keys():
		var d = Data.get_def(k)
		var status = "$%d" % d["cost"]
		var col = UIStyle.ACCENT
		var frac = 0.0
		if sb["kind"] == k:
			frac = sb["progress"] / d["build_time"]
			if sb["ready"]:
				status = "READY - PLACE"
				col = UIStyle.GOOD
				frac = 1.0
			else:
				status = "%d%%" % int(100 * frac)
		var locked = not game.requirements_met(t, k)
		var names = []
		for r in d.get("requires", []):
			names.append(Data.get_def(r)["name"])
		var tip = "%s\nPower: %+d" % [d["name"], d.get("power", 0)]
		if locked:
			tip += "\nNeeds: %s" % PoolStringArray(names).join(", ")
		_set_card(struct_cards[k], d["name"], status, col, locked or (sb["kind"] != "" and sb["kind"] != k), frac, tip)
	for k in unit_cards.keys():
		var d2 = Data.get_def(k)
		var q = game.queued_count(t, k)
		var producers = game.producers_for(t, k)
		var frac2 = 0.0
		for b in producers:
			if b.queue.size() > 0 and b.queue[0] == k:
				frac2 = max(frac2, b.progress / d2["build_time"])
		var status2 = "$%d" % d2["cost"]
		if q > 0:
			status2 += "   x%d" % q
		_set_card(unit_cards[k], d2["name"], status2, UIStyle.ACCENT, producers.empty(), frac2,
			"%s\nBuilt at: %s" % [d2["name"], Data.get_def(d2["built_at"])["name"]])

	var has_uplink = game.has_building(t, "orbital_uplink")
	orbital_button.visible = has_uplink
	if has_uplink:
		var pct = int(100 * game.orbital_charge[t] / game.orbital_time())
		if game.targeting == "orbital":
			orbital_button.text = "ORBITAL STRIKE  -  choose target"
		elif pct >= 100:
			orbital_button.text = "ORBITAL STRIKE  -  READY"
		else:
			orbital_button.text = "ORBITAL STRIKE  -  %d%%" % pct
		orbital_button.disabled = pct < 100

	var sel = []
	for s in game.selected:
		if is_instance_valid(s) and not s.dead:
			sel.append(s)
	if sel.size() == 1:
		var e = sel[0]
		info_label.text = "%s     %d / %d" % [e.def["name"].to_upper(), int(e.hp), int(e.max_hp)]
		if e.def.get("harvester", false):
			info_label.text += "     CARGO %d" % int(e.cargo)
	elif sel.size() > 1:
		info_label.text = "%d UNITS SELECTED" % sel.size()
	elif game.elapsed < 45:
		info_label.text = "Drag: select    Right-click: move / attack    Ctrl or Option + right-click: attack-move\nQ: select army    X: stop    H: home    P: pause    WASD, edges or trackpad: scroll"
	else:
		info_label.text = ""


func show_game_over(won):
	get_tree().paused = false
	game_over_panel = PanelContainer.new()
	game_over_panel.anchor_left = 0.5
	game_over_panel.anchor_top = 0.5
	game_over_panel.margin_left = -230 - SIDEBAR_W / 2
	game_over_panel.margin_top = -110
	game_over_panel.margin_right = 230 - SIDEBAR_W / 2
	root.add_child(game_over_panel)
	var vb = VBoxContainer.new()
	vb.add_constant_override("separation", 12)
	game_over_panel.add_child(vb)
	var l = UIStyle.label("VICTORY" if won else "DEFEAT", 56, UIStyle.ACCENT if won else UIStyle.BAD, "Bold")
	l.align = Label.ALIGN_CENTER
	vb.add_child(l)
	var sub = UIStyle.label("Vega remembers your name." if won else "The sands swallow another army.", 20, UIStyle.TEXT_DIM)
	sub.align = Label.ALIGN_CENTER
	vb.add_child(sub)
	var b = Button.new()
	b.text = "BACK TO MENU"
	b.rect_min_size = Vector2(220, 46)
	b.connect("pressed", self, "_to_menu")
	vb.add_child(b)


func _to_menu():
	get_tree().paused = false
	get_tree().change_scene("res://scenes/Menu.tscn")
