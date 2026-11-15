# Vega

A 2D real-time strategy game for macOS set on the desert planet Vega. You harvest red spice and build a
base, while sandworms hunt on the open sand. The aim is to free the planet from King Khan.

See [docs/DESIGN.md](docs/DESIGN.md) for the story, factions and roadmap.

## What's in the prototype

- Main menu, skirmish (play as Arthems or Klingos) and Campaign Mission 1 "Landfall" with in-engine cutscenes
- Procedural desert map with rock plateaus, spice fields and explosive spice blooms
- Base building in a sidebar, like Red Alert 2: power, refinery, barracks, war factory, helipad and defences
- Harvesters, infantry, vehicles, a drone, a gunship, Tesla weapons and missiles
- Sandworms, desert wildlife, dust clouds and vehicle tracks
- A computer opponent with three difficulty levels
- Freedom Fighter worm-rider raids in skirmish
- Placeholder comic-style graphics drawn in code, with no image files yet

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
project.godot        Godot project settings (GLES2 renderer for older Macs)
scenes/              Menu.tscn, Game.tscn
scripts/data.gd      All unit / building / faction stats (balance here)
scripts/missions.gd  Campaign missions and cutscene dialogue
scripts/game.gd      Match logic: economy, power, input, win/lose
scripts/ai.gd        Computer opponent
scripts/...          Units, buildings, map, worms, wildlife, HUD, cutscenes
tests/smoke_test.gd  Headless test that simulates a few minutes of play
docs/DESIGN.md       Game design document
```

## Making a Mac app

In Godot: **Project → Export → Add… → macOS**. Download the export templates when asked, then export
`Vega.app`.
