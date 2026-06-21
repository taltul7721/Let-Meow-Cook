# Laser sweep animation (PNG sequence)

Transparent laser frames live in **`png/`**:

- `lazer_video00.png` … `lazer_video59.png` (60 frames)
- Export as **PNG with alpha** from your editor

Sweep sound:

- **`lazer_video_sound.mp3`** — plays in sync when the sweep starts

## In-game

- **`LaserSprite`** (`AnimatedSprite2D`) loads all frames at runtime
- Frames are centered on the 1152×648 viewport (current export is 1052×648)
- Tune **`animation_fps`** on `LaserSprite` if the motion feels too fast/slow vs the sound
- Old `.ogv` / `.webm` files are no longer used

## Re-exporting

If you replace the animation, keep the same naming pattern (`lazer_video##.png`) or update  
`FRAME_COUNT` and `FRAMES_DIR` in `scripts/gameplay/laser_sweep_sprite.gd`.
