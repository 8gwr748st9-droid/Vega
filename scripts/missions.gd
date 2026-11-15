extends Reference
# Campaign data. Character names marked (placeholder) are waiting for the author's final choice.
#
# Each cutscene line: {"who": speaker, "faction": colour key, "text": line, "focus": "player_base"|"enemy_base"|"center"|null}

const CAST = {
	"Prince Arion": "arthem",      # (placeholder name) – the hero, Prince of Arthem
	"Commander Sela": "arthem",    # (placeholder) – Arthem field commander / advisor
	"Emissary Vorg": "klingos",    # (placeholder) – Klingos emissary of King Khan
	"Nadir": "freedom",            # (placeholder) – Freedom fighter leader
	"King Khan": "khan",
}

const MISSIONS = [
	{
		"id": 1,
		"title": "Landfall",
		"playable": true,
		"tech": 1,
		"briefing": "Establish an Arthem foothold on the rock plateau, harvest Uralium and destroy the Klingos outpost to the south-east.",
		"objectives": ["Harvest 2500 Uralium", "Destroy the Klingos outpost"],
		"uralium_goal": 2500,
		"intro": [
			{"who": "Commander Sela", "text": "Vega, my prince. See the red veins in the sand? Uralium. Every weapon and every fuel cell in Khan's kingdom is made from it.", "focus": "center"},
			{"who": "Prince Arion", "text": "Whoever holds the Uralium holds Vega. Khan hoards it - and the water - while his people die of thirst. That ends with us.", "focus": "player_base"},
			{"who": "Commander Sela", "text": "The Klingos have an outpost on the far plateau. Their emissaries enforce Khan's law with Tesla fire.", "focus": "enemy_base"},
			{"who": "Emissary Vorg", "text": "Arthem ships on Vega? The King will be... displeased. Burn them.", "focus": "enemy_base"},
			{"who": "Prince Arion", "text": "Build the base. Get the harvesters on the sand. And beware the sandeaters - they feed on Uralium and guard it fiercely.", "focus": "player_base"},
			{"who": "Commander Sela", "text": "One more thing - some Uralium lies packed under pressure. If anything touches those mounds, they explode. Keep the troops clear.", "focus": "player_base"},
		],
		"outro": [
			{"who": "Commander Sela", "text": "The outpost has fallen. The Klingos are retreating into the deep desert.", "focus": "enemy_base"},
			{"who": "Prince Arion", "text": "We were watched the whole time, Sela. Not by the Klingos. By the desert itself.", "focus": "center"},
			{"who": "Nadir", "text": "(from the dunes) Another lord comes to Vega. Let us see what kind he is.", "focus": "center"},
		],
	},
	{"id": 2, "title": "Red Sands", "playable": false, "tech": 1,
		"briefing": "Hold three Uralium fields against Klingos raids. Pressurised Uralium blooms dot the field - use them as traps."},
	{"id": 3, "title": "Riders of the Deep", "playable": false, "tech": 1,
		"briefing": "First contact with the Freedom Fighters. Learn how they ride the sandeaters - by making them believe they are mating - and escort their scouts across open sand."},
	{"id": 4, "title": "Shadows over Vega", "playable": false, "tech": 2,
		"briefing": "Helicopters and stealth arrive. Destroy a Klingos relay tower without being detected."},
	{"id": 5, "title": "Broken Trust", "playable": false, "tech": 2,
		"briefing": "The Freedom Fighters ask: will Arthem simply replace Khan? Rescue their captured hijackers to earn their trust."},
	{"id": 6, "title": "The Tesla Wall", "playable": false, "tech": 2,
		"briefing": "Break the fortified Klingos line of Tesla coils with drones and explosives."},
	{"id": 7, "title": "The King of Klingos", "playable": false, "tech": 3,
		"briefing": "Siege the Klingos citadel. The Prince faces the King of Klingos."},
	{"id": 8, "title": "Blood of the Ancients", "playable": false, "tech": 3,
		"briefing": "The truth: the King of Klingos was the Prince's great-great-grandfather. Seize the stem-cell laboratories and claim Klingos technology."},
	{"id": 9, "title": "Wrath of Khan", "playable": false, "tech": 4,
		"briefing": "King Khan takes the field with the best technology on Vega. Hold out with the unstable orbital vaporiser. When all hope seems lost, the Freedom Fighters strike - wielding Khan's own stolen technology - and knock his systems offline."},
	{"id": 10, "title": "The Waters of Vega", "playable": false, "tech": 4,
		"briefing": "Khan's technology is offline for 15 minutes. This is the Arthems' only chance: take his palace and free the water."},
]


static func get_mission(n):
	for m in MISSIONS:
		if m["id"] == n:
			return m
	return null


static func faction_of(who):
	if CAST.has(who):
		return CAST[who]
	return "arthem"
