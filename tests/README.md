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
