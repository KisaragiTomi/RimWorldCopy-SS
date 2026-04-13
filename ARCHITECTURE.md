# RimWorld Copy Project Architecture

## Overview

- Engine: Godot 4.6 (GDScript)
- Goal: System-level recreation of RimWorld core gameplay
- Status: Verified through 60+ game years, 21.57M ticks, zero crashes, 1000+ Pawn scale
- Project path: D:\\MyProject\\RimWorldCopy
- Original RimWorld path: D:\\SteamLibrary\\steamapps\\common\\RimWorld

## Directory Structure

RimWorldUI/scripts/autoload/ contains global singletons: GameState, UIManager, TickManager, DefDatabase.
RimWorldUI/scripts/core/ contains Map, Cell, Pathfinder, Region, SaveLoad.
RimWorldUI/scripts/entities/ contains Thing, Pawn, Building, Plant, Item.
RimWorldUI/scripts/ai/ contains ThinkTree, ThinkNode, Job, JobDriver, Toil.
RimWorldUI/scripts/systems/ contains WorkManager, NeedManager, HealthManager, CombatManager, IncidentManager.
RimWorldUI/defs/ contains JSON data definitions for terrain, things, work_types, research.

## Core Design Principles

1. Def-driven: All game content defined via JSON Defs, code only implements mechanics.
2. Tick-driven: All dynamic systems hooked to TickManager, unified scheduling with pause/speed support.
3. ECS-leaning: Data and logic separated; Pawn holds Components (Skills, Needs, Health), Systems process them.
4. Reference-first: Check decompiled source before implementing each system.

## AI Work System (4-Layer Architecture)

Layer 1: AI Decision (ThinkTree) with 19 JobGiver nodes.
Layer 2: Work Assignment via JobGiver_Work to WorkTypeDef to WorkGiverDef.
Layer 3: Job Execution via Pawn_JobTracker to Job to JobDriver to Toil.
Layer 4: Player Settings via Pawn_WorkSettings with priorities 1-4.

## Key Systems

GameState in autoload/game_state.gd manages game state machine.
TickManager in autoload/tick_manager.gd drives time and ticks.
PawnManager in systems/pawn_manager.gd manages pawns and AI drivers.
ThinkTree in ai/think_tree.gd has 19 JobGiver decision nodes.
IncidentManager in systems/incident_manager.gd handles random events.
RaidManager in systems/raid_manager.gd handles raids.
SaveLoad in core/save_load.gd handles save/load in .rws JSON format.
ZoneManager handles Stockpile and GrowingZone areas.

## Critical Bug Fixes History

Bug 1 - AI idle 100 percent: Haul Job with no Stockpile instantly completed then 60 tick cooldown locked Wander out. Fixed by adding Stockpile pre-check in job_giver_haul.gd and fallthrough in pawn_manager.gd think tree.

Bug 2 - Temperature drift to -264C: incident_manager.gd line 208 used pure additive random walk with no mean reversion. Fix: add seasonal_baseline and spring force using lerp.

Bug 3 - Raid positive feedback loop: raid_manager.gd line 40 colony_strength counted enemy pawns. Fixed by filtering faction==enemy and adding clampi(2, 30) cap.

Bug 4 - Cache corruption crash: .godot/imported cache corruption caused non-deterministic crashes. Fixed by cleaning .godot/imported and reimporting via editor.

Bug 5 - Zone load loss: save_load.gd load_map() did not restore ZoneManager.zones dictionary. Fixed by adding _restore_zones() method.

## Performance Characteristics

FPS scales linearly with Pawn count: 60 FPS at 6 Pawns, 50 at 305, 30 at 502, 15 at 1000.
Memory grows at 3.6-4.3 MB per game year with no leaks.
At 1000 Pawns: Working Set 526MB, Private Memory 608MB.
Thread count constant at 35, handle count at 496.

## Save Format

Format: JSON with .rws extension, version 2.
Contains: map, game_state, pawns, things, zones, research, trade data.
Autosave: 3 rotating slots.

## Development Tools

Autotest skill at .cursor/skills/rimworld-autotest/SKILL.md for automated testing.
game_cmd.py sends TCP commands to running game.
monitor_game.py provides automated monitoring and data collection.
gctl.py is the Godot control script.

## Godot Build

Using godot-source-lumen 4.6 custom compiled.
Disable Terrain3D module with scons module_terrain_3d_enabled=no.
Launch with --path parameter, defaults to main menu, use eval switch_to_game() to enter game.
