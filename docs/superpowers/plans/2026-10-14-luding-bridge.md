# Luding Bridge Implementation Plan

> Inline execution is authorized by the user's instruction to develop, run, test and repair autonomously. Use checkpoints after each task.

**Goal:** Deliver a playable Windows Godot 4.6 third-person story with combat, skeletal humans, cooperative bridge repair, chain traversal, retry and ending.

**Architecture:** Keep the Kenney project and inherit its CharacterBody3D controller and camera follow behavior. Isolate soldier visuals, world construction, combat, mission state and HUD. Physics rays determine hits and bridge access; explicit mission gates own one-shot interactions and checkpoint restoration.

**Tech Stack:** Godot 4.6 standard, GDScript, Quaternius CC0 glTF/animation rotation retargeting, Windows x64.

## Global Constraints

- 3D第三人称; Windows; Godot 4.6; GDScript.
- INTRO → COMBAT → PICKUP → COOPERATE → CROSSING → ENDING.
- Five rigged humanoids, real bridge collision, solid cover, visible NPC movement.
- Cinematic dialogue locks weapons; carrying and climbing lock incompatible actions.
- Original repositories remain unchanged; report tested vs untested behavior honestly.

### Task 1: Baseline runtime

Files: original `scripts/player.gd`, `scripts/view.gd` retained; external `work/check_original.gd` verifies baseline.

- [x] Clone pinned upstream commits, audit MIT and CC0 notices.
- [x] Download portable engine and resources from official distribution endpoints.
- [x] Run original movement/camera checks and save an image.

Validation command: Godot `--path work/Starter-Kit-3D-Platformer --script <absolute work/check_original.gd>`. Expected: `ORIGINAL PASS`.

### Task 2: Skeletal actor and adapted controller

Create `game/soldier_visual.gd`, `game/player.gd`, `game/camera.gd`. Visual owns imported skeleton and AnimationPlayer; controller owns health, motion and locks; camera consumes `target: Node3D`.

- [x] Write `tests/test_contract.gd` first and observe missing-feature failure.
- [x] Retarget rotation tracks by exact bone names, preserving target rest lengths.
- [x] Use Idle_Loop, Walk_Loop, Sprint_Loop, Jump_Loop, Hit_Chest and Death01; add two-bone hand targets for long gun, board and chain.
- [x] Validate skeleton, animation motion, WASD, sprint, jump and camera rotation in the engine.

Test contract:
```gdscript
check(player.visual.skeleton.get_bone_count() > 60, "real skeleton")
check(player.position.distance_to(before) > 0.3, "WASD moves the player")
```

### Task 3: Bridge and canyon

Create `game/bridge_world.gd`, `game/river.gdshader`. Produce `repair_body: StaticBody3D`, `board: MeshInstance3D`, gap and path coordinates. Terrain, chain links, timber, mountains, foam, smoke and shadows use coherent muted colors.

- [x] Verify physical hole before repair and solid ray hit after enabling the repair body.
- [x] Build 26m playable bridge with two distinct gaps, both banks and river beneath.
- [x] Render and inspect the actor scale and environment.

Test contract:
```gdscript
check(not world.repair_enabled, "gap starts open")
check(ray_down(Vector3(0, 2, -9.5)).is_empty(), "missing board has no collision")
```

### Task 4: State and cooperative interaction

Create `game/mission.gd`, `game/npc.gd`. Produce guarded `interact()`, `retry_checkpoint()`, `restart()` and mission `phase`. NPC moves along authored paths with skeletal walking; timed pickups/placing synchronize hands and board.

- [x] Reject early repair, ending, duplicate place and simultaneous combat inputs.
- [x] Attach board to carry node, reduce speed, await Amu and animate its final transform.
- [x] Enable bridge collision only at placement completion.
- [x] Move chain traversal visibly with W/S, sway and A/D balance; restore checkpoint after falling.

Test contract:
```gdscript
mission.interact()
check(mission.phase == mission.Phase.COMBAT, "combat gate")
check(world.repair_enabled, "placement changes walkable space")
```

### Task 5: Combat

Create `game/combat.gd`. Adapt Kenney FPS cooldown, ray hit, damage, recoil and audio to camera target + muzzle obstruction rays. NPCs receive health/death and perception/line-of-sight. Add finite clip, reserve/reload and aim feedback.

- [x] Verify real cover blocks a ray and exposed player takes damage.
- [x] Verify deaths stop attacks and health clamps at zero.
- [x] Verify reload cannot exceed clip or reserve; retry restores combat and bridge stage.

### Task 6: Story and HUD

Create `game/hud.gd`, `game/main.tscn`. Opening river-to-bridge camera, original supplied dialogue, objectives, contextual prompts, weapon/health UI, pause, retry, ending camera and five settlement statistics.

- [x] Inspect Chinese UI at 1280×720.
- [x] Verify intro completion enters combat, dialogue prevents shooting, ending shows only after traversal and nearby teammates.
- [x] Provide replay and checkpoint buttons plus a quit action.

### Task 7: Full replay and delivery

Expand `tests/test_contract.gd` with input-driven scenario and screenshots. Use real scene, physics and input actions; direct damage/setup only in isolated edge-case tests.

- [x] Run headless assertions, then rendered gameplay replay through every phase.
- [x] Observe visual pickup, cooperation, climb and ending in captured images.
- [x] Export Windows x64 executable using verified official templates; run exported build.
- [x] Write `DEMO_REPORT.md`, source/license manifest and Chinese play instructions.
- [x] Tag working milestones and deliver project, executable and test evidence.

Self-review: all eight requirement sections map to the tasks above; no paid resource dependencies; authored poses and lack of human manual playtest must be disclosed.

Execution complete: baseline, contract, combat, checkpoint, pose and rendered full replay verified. Two playable Git versions are retained; seven separate snapshots were not created.
