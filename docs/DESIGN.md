# VEGA — Game Design Document

*Status: living document. Items marked **(TBD)** need the author's decision.*

## 1. Pitch

A modern, approachable real-time strategy game (in the spirit of late-90s/early-2000s classics such as
Red Alert 2) set on **Vega**, a desert planet ruled by the tyrant **King Khan**. Red spice lies across the
sand; whoever controls it controls Vega. You play the **Prince of Arthem**, who comes to overthrow Khan,
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
| **Spice** | Red grains lying on the sand. Harvested and refined into credits. |
| **Spice blooms** | Pockets of spice packed under high pressure. If anything touches one, it bursts into a deadly red cloud that kills everything close by, then leaves a rich new spice field. |
| **Sandworms** | Giant worms that hunt vibration on open sand. Rock is safe. They cannot be killed. Freedom Fighters can ride them. |
| **Rock plateaus** | The only ground solid enough to build on. |
| **Water** | Khan hoards the planet's water. Releasing it is the campaign's final goal. |
| **Wildlife** | Lizards, sand hoppers and birds. Purely cosmetic: they flee units, scatter at explosions, burrow from worms. |
| **Weather** | Drifting dust clouds. It never rains. |

## 3. Factions

### Arthems (player faction in the campaign)
Highly adaptable. They hate King Khan and are strong enough to challenge him.
- **Style:** helicopters, drones, stealth, explosives; very strong defences and base.
- **Experimental tech:** an orbital weapon that vaporises structures or armoured vehicles from space,
  but it is highly unstable (misfires, long charge, can hit near the aim point). **(TBD: misfire rules)**
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
- **Planned:** Air-strike support power (charge timer + spice cost)

### Freedom Fighters (the people of Vega)
They only want to be free of the King. They hate the Klingos.
- **No base.** They appear through story events and raids.
- **Fast on sand, leave no tracks, never attract sandworms**, and can **ride sandworms** to move quickly.
- Simple weapons and improvised explosive devices.
- **Hijackers:** specialists who can steal enemy vehicles (max 2 alive at a time).
- **Missions 9–10:** they have captured almost all of Khan's technology and use it in surprise
  attacks. They never upgrade; they simply have the tech.
- **Theme:** will the Arthems free Vega, or just replace one ruler with another?

### King Khan (missions 9–10 only)
Ruthless. The best technology on Vega. **(TBD: unit roster; proposal: upgraded versions of all Klingos tech
plus unique super-units and a shield generator.)**

## 4. Story outline — "The Liberation of Vega"

Character names are **placeholders (TBD)**: Prince *Arion*, Commander *Sela* (Arthem advisor),
Emissary *Vorg* (Klingos), *Nadir* (Freedom Fighter leader).

| # | Mission | Story beat | New elements |
|---|---|---|---|
| 1 | **Landfall** | Arthems land on Vega, build a foothold, destroy a Klingos outpost. | Base building, harvesting, sandworms, spice blooms |
| 2 | **Red Sands** | Hold three spice fields against Klingos raids. | Using blooms as traps |
| 3 | **Riders of the Deep** | First contact with the Freedom Fighters; escort their scouts. | Freedom Fighters, worm riding |
| 4 | **Shadows over Vega** | Destroy a Klingos relay tower undetected. | Helipad, Gunship, stealth |
| 5 | **Broken Trust** | Freedom Fighters doubt Arthem's motives; rescue their hijackers. | Hijackers (max 2), trust theme |
| 6 | **The Tesla Wall** | Break a fortified line of Tesla coils. | Strike Drones, explosives |
| 7 | **The King of Klingos** | Siege the Klingos citadel; the Prince kills the King of Klingos. | Siege tactics, hero unit **(TBD)** |
| 8 | **Blood of the Ancients** | Revelation: the King of Klingos was the Prince's great-great-grandfather (stem-cell longevity). Capture the labs. | Arthems gain Klingos technology |
| 9 | **Wrath of Khan** | King Khan takes the field. Survive his onslaught. | Khan faction, unstable orbital vaporiser |
| 10 | **The Waters of Vega** | All hope seems lost, then the Freedom Fighters strike and Khan's tech goes **offline for 15 minutes**. Take his palace. | 15-minute timer, Freedom Fighter allies |

**Ending:** the Arthems rule and Vega is free. The Prince releases the water Khan held back; the planet
turns green and the deserts disappear (final in-engine cutscene: sand transitions to grass and water).

**Open question:** in which mission does the Freedom Fighter strike happen: the end of 9 or the start of 10?
The current plan puts it at the start of 10.

## 5. Gameplay systems

| System | Design |
|---|---|
| **Economy** | Harvesters collect spice → Refinery → credits. Refinery comes with a free Harvester. |
| **Power** | Power Plants supply power; most buildings consume it. Low power = production at 50%, defences offline. |
| **Construction** | RA2-style: build in the sidebar, then click READY and place on rock near your base. |
| **Tech progression** | Unlocked by campaign progress (tech level per mission). Some upgrades cost spice, others need power. Skirmish uses full tech. |
| **Terrain** | Sand vs rock. Klingos slow on sand; Freedom Fighters fast on sand. Only rock is buildable. Vehicles leave tracks on sand. |
| **Sandworms** | Hunt moving units on sand (harvesters most of all); swallow everything on sand near where they surface. |
| **Spice blooms** | Touch → 1.4 s fuse → deadly blast (ground only) → new spice field. |
| **Support powers** | *(planned)* Klingos air strike, Arthem orbital vaporiser (unstable), Freedom Fighter worm strike. |

## 6. Art direction

- High-resolution 2D, **comic-book look**: thick dark ink outlines, flat posterised colours, halftone dots
  in portraits, comic sound-effect lettering ("BOOM!", "ZZZAP!", "GULP!").
- Faction colours: Arthem blue, Klingos red, Freedom Fighter sand-gold, Khan purple.
- **Current state:** all graphics are code-drawn placeholders; they will be replaced with painted sprites
  as they become available.
- Performance budget (Intel HD 5000): 2D only, GLES2, ≤ ~200 units on screen.

## 7. Roadmap

1. **Prototype (this commit):** skirmish + mission 1, economy, power, combat, worms, blooms, wildlife, dust, cutscenes, AI.
2. Support powers, hijackers, Klingos air strike, fog of war, control groups, sound effects.
3. Missions 2–5 with scripted events.
4. Real art pass (sprites, portraits), music.
5. Missions 6–10, King Khan faction, ending cutscene.
6. Balancing and difficulty tuning (playtesting by the author).
