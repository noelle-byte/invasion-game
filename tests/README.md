Run the scene-based checks from the project directory:

```sh
godot --headless --path . --script tests/gameplay_loop.gd
```

The checks instantiate the actual house and cover phone gating, breach grace,
hunt/chase transitions, hearing without position tracking, calming, search,
roam movement and routes to every marker, sprint speed/stamina, flash cone,
range, walls, night-scaled battery cost, stun/attack blocking and light restore.
They use controlled positions and elapsed awareness time for repeatability.

Manual playtest: answer the phone with E, ignore a real knock at either door,
leave during the 2.5-second grace period, let the enemy see you, sprint with
Shift, break sight around a wall, then aim and press F. Confirm the brief burst,
escape during stun, and eventual room searching/roaming. Check battery pickups,
both doors, the HUD, and the next phone-gated night. Visual appearance and overall
difficulty still need this hands-on pass.

Directional sound-cue checks:

```sh
godot --headless --path . --script tests/sound_cues.gd
```

Knocks pulse pink at 0 / 0.45 / 0.9 seconds (real) or 0 / 0.9 / 1.15
seconds (false). Breaches pulse orange for 0.7 seconds. Footsteps pulse white
within 850 units, every 110 units actually travelled. The eight ring sections
capture direction at emission, without continuous tracking. SoundCues exposes
one event for later audio integration; no audio assets are currently played.

Manual checks: distinguish both knock rhythms, check cues in all rooms and
against dark backgrounds, and walk between opposite doors with empty stamina
to tune the new eight-second response window. Aggression now decays at 9/sec.

Menu, pause, retry, completion and debug regression checks:

```sh
godot --headless --path . --script tests/menu_flow.gd
```

Run the project (F6 on the house bypasses the main menu; F5 uses it). Escape
pauses; F3 toggles diagnostics in debug builds. Settings persist under user://.
Retry Night reloads the house with that night selected, fresh battery/stamina,
all pickups, and a new phone call. Restart Game starts at Night 1. Retry does
not restore a mid-night checkpoint or preserve spent resources.

Check menus with mouse and keyboard, resource bars at your window size,
insufficient-charge feedback, the paused settings screen, and F3 paths/radii
across room camera transitions. Debug tools are unavailable in release builds.

Music box checks:

```sh
godot --headless --path . --script tests/music_box.gd
```

The box drains over 45 seconds on Night 1, accelerating by 15% of the
Night 1 rate per later night and can be wound by holding E
near it. Once empty, its penalty lasts until the next phone-gated night:
Knocker AI +4 (capped at 20), speed +15%, aggression gain +30%, running hearing range +40%, and
knock opportunity and response timers run 25% faster. The Wraith gains up to
15% speed, capped at player walking speed. Its direct tracking has no aggression
or hearing range to increase. Playtest the timing and HUD placement in-game.
