# VEGA — Game Design Document

*Status: living document. Items marked **(TBD)** need the author's decision.*

## 1. Pitch

A modern, approachable real-time strategy game (in the spirit of late-90s/early-2000s classics such as
Red Alert 2) set on **Vega**, a desert planet ruled by the tyrant **King Khan**. **Uralium**, a red metal used for weapons and fuel, lies in veins across the sand. It is essential to
holding Khan's kingdom; whoever controls it controls Vega. You play the **Prince of Arthem**, who comes to overthrow Khan,
uncovers a secret about his own bloodline, and finally frees the planet's hoarded water so the desert can
bloom again.

- **Platform:** macOS 10.12+ (target: MacBook Air 2014, Intel HD 5000, 4 GB RAM, High Sierra 10.13.6)
- **Engine:** Godot 3.6 (GLES2 renderer, free, open source, runs on High Sierra)
- **Modes:** 10-mission single-player campaign, skirmish vs. computer
- **Look:** high-resolution 2D, bold ink outlines, flat posterised colours: a comic-book style
- **Cutscenes:** in-engine (letterbox, animated portraits, typed dialogue, camera pans)

## 2. The world

| Element | Description |
|---|---|
| **Uralium** | A red metal lying in veins on the sand. Used for weapon production and fuel, and essential to keeping control of Khan's kingdom. Harvested and refined into credits. |
| **Uralium blooms** | Pockets of Uralium packed under high pressure. If anything touches one, it bursts into a deadly red cloud that kills everything close by, then leaves a rich new Uralium field. |
| **Sandeaters** | Huge creatures living under the sand. They mainly eat Uralium and fiercely protect their feeding grounds. Anything they eat (a person, a car, a harvester) is lost, and the sandeater itself then disappears and comes back later. Rock is safe; they cannot be killed. Freedom Fighters ride them by making them believe they are mating, and a ridden sandeater leaves lines of Uralium on the sand that can be harvested. |
| **Rock plateaus** | The only ground solid enough to build on. |
| **Water** | Khan hoards the planet's water. Releasing it is the campaign's final goal. |
| **Wildlife** | Lizards, sand hoppers and birds. Purely cosmetic: they flee units, scatter at explosions, burrow when sandeaters pass. |
| **Weather** | Drifting dust clouds. It never rains. |

## 3. Factions

### Arthems (player faction in the campaign)
Highly adaptable. They hate King Khan and are strong enough to challenge him.
- **Style:** helicopters, drones, stealth, explosives; very strong defences and base.
- **Experimental tech:** an orbital vaporiser that destroys structures or armoured vehicles from space.
  It is unstable and still in its test phase: it always lands somewhat off target, but it fills the
  enemy with fear, and nearby enemy units panic and flee.
- **Units (prototype):** Ranger (infantry), Dune Buggy, Harvester, Strike Drone, Gunship
- **Defence:** Gun Tower

### Klingos (Emissaries of King Khan)
Rootless warriors with very high firepower.
- **Weakness:** slower than everyone else on sand (70% speed); heavy weapons take time to reload.
- **Style:** Tesla-coil technology and explosives; **air power** that rains on the enemy
  (expensive, must charge before use).
- **Secret:** they use stem-cell technology to live for centuries.
- **Units (prototype):** Heavy Trooper, Rocketeer, Harvester, Tesla Tank, Siege Crawler
- **Defence:** Tesla Coil
- **Planned:** Air-strike support power (charge timer + Uralium cost)

### Freedom Fighters (the people of Vega)
They only want to be free of the King. They hate the Klingos.
- **No base.** They appear through story events and raids.
- **Fast on sand, leave no tracks, ignored by sandeaters**, and can **ride sandeaters** to move quickly
  (they trick them into thinking they are mating; the ride leaves harvestable lines of Uralium).
- Simple weapons and improvised explosive devices.
- **Hijackers:** specialists who can steal enemy vehicles (max 2 alive at a time).
- **Missions 9–10:** they have captured almost all of Khan's technology and use it in surprise
  attacks. They never upgrade; they simply have the tech.
- **Theme:** will the Arthems free Vega, or just replace one ruler with another?

### King Khan (missions 9–10 only)
Ruthless. The best technology on Vega: upgraded Klingos technology, a shield generator and super-units.
- **Units (defined, not yet playable):** Praetorian (elite Tesla infantry), Storm Tank (fast Tesla tank that can hit air),
  Colossus (super-unit siege walker), Harvester
- **Buildings:** Shield Generator (protects nearby buildings until knocked offline)

## 4. Story outline — "The Liberation of Vega"

Character names (approved): Prince *Arion*, Commander *Sela* (Arthem advisor),
Emissary *Vorg* (Klingos), *Nadir* (Freedom Fighter leader).

| # | Mission | Story beat | New elements |
|---|---|---|---|
| 1 | **Landfall** | Arthems land on Vega, build a foothold, destroy a Klingos outpost. | Base building, harvesting, sandeaters, Uralium blooms |
| 2 | **Red Sands** | Hold three Uralium fields against Klingos raids. | Using blooms as traps |
| 3 | **Riders of the Deep** | First contact with the Freedom Fighters; escort their scouts. | Freedom Fighters, sandeater riding |
| 4 | **Shadows over Vega** | Destroy a Klingos relay tower undetected. | Helipad, Gunship, stealth |
| 5 | **Broken Trust** | Freedom Fighters doubt Arthem's motives; rescue their hijackers. | Hijackers (max 2), trust theme |
| 6 | **The Tesla Wall** | Break a fortified line of Tesla coils. | Strike Drones, explosives |
| 7 | **The King of Klingos** | Siege the Klingos citadel; the Prince kills the King of Klingos. | Siege tactics, hero unit **(TBD)** |
| 8 | **Blood of the Ancients** | Revelation: the King of Klingos was the Prince's great-great-grandfather (stem-cell longevity). Capture the labs. | Arthems gain Klingos technology |
| 9 | **Wrath of Khan** | King Khan takes the field. Survive his onslaught. At the end, when all hope seems lost, the Freedom Fighters strike with Khan's stolen technology and knock his systems offline. | Khan faction, unstable orbital vaporiser, Freedom Fighter strike |
| 10 | **The Waters of Vega** | Khan's technology is **offline for 15 minutes**. That window is all the Arthems have to take his palace. | 15-minute timer, Freedom Fighter allies |

**Ending:** the Arthems rule and Vega is free. The Prince releases the water Khan held back; the planet
turns green and the deserts disappear (final in-engine cutscene: sand transitions to grass and water).

**Decided:** the Freedom Fighter strike ends mission 9; mission 10 is the 15-minute window.

## 5. Gameplay systems

| System | Design |
|---|---|
| **Economy** | Harvesters collect Uralium → Refinery → credits. Refinery comes with a free Harvester. |
| **Power** | Power Plants supply power; most buildings consume it. Low power = production at 50%, defences offline. |
| **Construction** | RA2-style: build in the sidebar, then click READY and place on rock near your base. |
| **Tech progression** | Unlocked by campaign progress (tech level per mission). Some upgrades cost Uralium, others need power. Skirmish uses full tech. |
| **Terrain** | Sand vs rock. Klingos slow on sand; Freedom Fighters fast on sand. Only rock is buildable. Vehicles leave tracks on sand. |
| **Sandeaters** | Each guards a Uralium feeding ground and slowly eats it. Hunts moving units on sand in its territory (harvesters first). Swallowed units are lost; the sandeater then vanishes for 1.5–2.5 minutes and resurfaces in its territory. |
| **Uralium blooms** | Touch → 1.4 s fuse → deadly blast (ground only) → new Uralium field. |
| **Support powers** | **Arthem orbital vaporiser** (done in the prototype): Orbital Uplink building, 3-minute charge that needs power; the beam drifts 50–170 px off target (test phase); vaporises vehicles and structures, wounds infantry; every enemy unit within ~550 px panics and flees for 8 s. *(Planned)* Klingos air strike, Freedom Fighter sandeater strike. |

## 6. Art direction

- High-resolution 2D, **comic-book look**: thick dark ink outlines, flat posterised colours, halftone dots
  in portraits, comic sound-effect lettering ("BOOM!", "ZZZAP!", "GULP!").
- Faction colours: Arthem blue, Klingos red, Freedom Fighter sand-gold, Khan purple.
- **Current state:** all graphics are code-drawn placeholders; they will be replaced with painted sprites
  as they become available.
- Performance budget (Intel HD 5000): 2D only, GLES2, ≤ ~200 units on screen.

## 7. Roadmap

1. **Prototype (this commit):** skirmish + mission 1, economy, power, combat, sandeaters, blooms, orbital strike, wildlife, dust, cutscenes, AI.
2. Support powers, hijackers, Klingos air strike, fog of war, control groups, sound effects.
3. Missions 2–5 with scripted events.
4. Real art pass (sprites, portraits), music.
5. Missions 6–10, King Khan faction, ending cutscene.
6. Balancing and difficulty tuning (playtesting by the author).
