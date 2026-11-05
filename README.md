# Worldfront

A Godot 4 prototype for a future real-time strategy game.

## Current prototype
- Larger grassland map with textured ground, worn dirt tracks, and a winding stream.
- Red and Blue capitals with separate resource counters.
- Seven civilians per team, rendered as blocky pixel-art humans with different looks.
- Multiple walking styles, leg and arm cycles, and an occasional jog.
- Workers gather wood and stone and bring it back to their own capital.
- Carrying slows workers down; heavy stone loads tire them faster and make them visibly strain.
- Exhausted workers sit down to recover, with small stamina bars when tired.
- No combat or full world map yet.

## Run it
1. Install Godot 4.3 or newer.
2. Download or clone this repository.
3. In Godot's Project Manager, click **Import** and select `project.godot`.
4. Open the project and press **F6** or **F5** to run the game.

The prototype uses built-in drawing and does not need external art assets.

## Living colony simulation (browser)

The browser simulation is in `index.html`. The living-colony branch layers new behaviour onto the existing civilian, construction, settlement, economy and military systems:

- A unique king per nation, royal inspections and occasional citizen escorts.
- Surveying expeditions before settlers plant a national flag and extend territorial ownership.
- Housing capacity, homeless citizens, outdoor rest and morale/unrest pressure.
- Short-lived conversation bubbles and footpaths formed from real civilian movement.
- River-aware placement and movement, varied river widths, farms, houses and forest trees.
- Strategic military training grounds near national borders.
- Optional positional synthesized audio with separate people, military, environment and work volume controls.

Audio is generated with the browser Web Audio API and starts only after the player enables it. The regression suite runs a deterministic multi-year simulation and checks settlement growth alongside the new lifecycle and world systems.
