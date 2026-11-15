# Vega

A 2D real-time strategy game for macOS set on the desert planet Vega. You harvest Uralium, the red metal
that fuels Khan's weapons, while sandeaters guard their feeding grounds. The aim is to free the planet from King Khan.

See [docs/DESIGN.md](docs/DESIGN.md) for the story, factions and roadmap.

## What's in the prototype

- Main menu, skirmish (play as Arthems or Klingos) and Campaign Mission 1 "Landfall" with in-engine cutscenes
- Semi-realistic graphics made entirely in code, with no image files:
  - sunlit desert terrain with dunes, cracked rock plateaus and red Uralium ore
  - shaded units with soft shadows, pre-rendered when the game first starts
  - buildings drawn in a tilted 3D view so each looks like what it is
  - fire, smoke, sparks, scorch marks, dust and glowing Tesla bolts
- Base building in a sidebar, like Red Alert 2: power, refinery, barracks, war factory, helipad and defences
- Harvesters, infantry, vehicles, a drone, an attack helicopter, Tesla weapons and missiles
- Units steer around buildings
- Sandeaters that guard Uralium fields, swallow intruders, vanish and return later
- Arthem Orbital Uplink: an unstable test-phase vaporiser that drifts off target and makes enemies flee
- Freedom Fighter raids in skirmish, riding sandeaters that leave harvestable lines of Uralium
- Desert wildlife, dust clouds and vehicle tracks
- A computer opponent with three difficulty levels

**If the game stutters** on an older Mac, set **GRAPHICS** to **FAST** in the main menu. That turns off
the glow and halves the particle effects.

**First launch:** the menu shows "Preparing graphics..." for a few seconds while units and buildings are
rendered. The result is saved, so later launches start straight away.

## Running it on a Mac (High Sierra 10.13.6 or newer)

1. Download **Godot 3.6 (Standard version, macOS)** from <https://godotengine.org/download/3.x/macos/>.
   Don't use Godot 4, because this project is built for Godot 3.
2. Unzip it and move `Godot.app` to Applications. The first time, right-click it and choose **Open**,
   because macOS warns about downloaded apps.
3. Get this project. Either use **Code → Download ZIP** on GitHub, or run:
   ```bash
   git clone https://github.com/8gwr748st9-droid/Vega.git
   ```
4. Open Godot, click **Import**, select the `project.godot` file in the `Vega` folder, then press **F5**
   (or the ▶ button) to play.

## Controls

| Action | Input |
|---|---|
| Select | Left-click, or drag a box |
| Move / attack / harvest | Right-click (two-finger click on a trackpad) |
| Attack-move | Ctrl or Option + right-click |
| Select whole army | Q |
| Stop | X |
| Jump to base | H |
| Pause | P |
| Scroll | WASD, arrow keys, screen edges, two-finger swipe, minimap |
| Zoom | Mouse wheel or pinch |

To build: click a structure in the sidebar, wait until it says **READY**, click it again and place it
on rock near your base.

## Project layout

```
project.godot        Godot project settings (GLES3 renderer, falls back to GLES2)
scenes/              Menu.tscn, Game.tscn
scripts/data.gd      All unit / building / faction stats (balance here)
scripts/missions.gd  Campaign missions and cutscene dialogue
scripts/game.gd      Match logic: economy, power, input, win/lose
scripts/ai.gd        Computer opponent
scripts/art/         Painter and designs that pre-render units and buildings
shaders/             Terrain shader
fonts/               Rajdhani typeface (SIL Open Font License)
scripts/...          Units, buildings, map, sandeaters, orbital strike, wildlife, HUD, cutscenes
tests/               Smoke test, screenshot and gallery tools
docs/DESIGN.md       Game design document
```

## Making a Mac app

In Godot: **Project → Export → Add… → macOS**. Download the export templates when asked, then export
`Vega.app`.
