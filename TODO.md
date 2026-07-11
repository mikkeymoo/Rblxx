# TODO: Hardcore Minigame Pack (Rojo)

You are an autonomous coding agent. Build this in full, unattended, no confirmation gates. Report what you did and any assumptions at the end. Do not stop to ask permission mid-run; make the best-practice call, note it, keep going.

## Prime directive

Add a pack of three brutally hardcore, server-authoritative minigames plus the full surrounding game loop (matchmaking, teleport, lobby, intermission, UI, DataStore leaderboards) to an EXISTING Rojo project. Fit the existing project, do not restructure it.

## Read first, before writing anything

1. Read `default.project.json` (or `*.project.json`). Learn the current path mappings, service tree, and folder conventions. Everything you add follows what is already there.
2. Read `wally.toml` if present, and `.gitignore`, `selene.toml`, `stylua.toml`, `aftman.toml` / `rokit.toml` if present. Match existing tool versions and style config. Do not downgrade or fork them.
3. Scan existing modules for the naming and structure conventions already in use (PascalCase modules/types, camelCase functions/vars, SCREAMING_SNAKE_CASE constants). Mirror them. If the repo already has a framework, USE IT instead of anything below that conflicts.
4. Confirm `rojo build` succeeds on the untouched repo before you change anything, so you have a clean baseline.

## Non-negotiable constraints

- Every script is a real `.luau` file on disk (`.server.luau`, `.client.luau`, `init.luau` for folder-as-module). No code that exists only inside Studio. The whole feature must round-trip through `rojo build`.
- Server is the single source of truth. All elimination, scoring, win detection, and state transitions are decided on the server. The client sends inputs and renders; it never reports its own death, position-as-truth, or score.
- Pragmatic anti-cheat: validate every RemoteEvent payload on the server (type, range, rate). Reject impossible inputs. Do not trust client-reported hits, positions, or timings. You do not need rollback netcode or lag compensation; you DO need "client cannot lie about surviving."
- Use `task.wait` / `task.spawn` / `task.delay`, never `wait` / `spawn` / `delay`. No polling loops where an event or signal will do. No string concatenation in hot loops (use `table.concat`). Safe instance navigation (`FindFirstChild`), not blind dot-chains.
- `--!strict` at the top of every new module. Type-annotate public function signatures and shared data shapes. Keep it Selene-clean and StyLua-formatted against the repo's existing config.
- Every connection, thread, and instance a minigame creates must be tracked and torn down when the round ends. Use a Trove/Maid-style cleanup object per round and per minigame. No leaked connections between rounds. This is the number-one correctness requirement for a round-cycling game.

## Dependencies (open-source only)

- Prefer the professional-standard setup: manage packages with **Wally**. Only pull FREE, open-source packages. Good candidates: a Signal library (e.g. sleitnick's `signal`), a cleanup library (`trove` or `maid`), and a Promise lib only if genuinely needed. Do not add anything heavyweight or closed.
- If the repo already vendors equivalents, use those and add nothing.
- If adding Wally to a repo that lacks it, wire it minimally: `wally.toml`, install to a `Packages/` folder, map that folder in the project file, and gitignore the installed packages (commit the manifest + lockfile, not the downloads).
- Record every dependency you add, and why, in the run report.

## Map geometry (best practice)

- Build arena geometry **from code at runtime** (a `MapBuilder` module per game that spawns parts into a container folder), so maps live as diffable Luau, not as binary blobs Git can't merge. Do not commit `.rbxm`/`.rbxmx` map blobs into the repo for these arenas.
- Keep all geometry parametric and driven by the config module (arena size, tile count, spawn ring radius, kill-floor Y). Difficulty tuning changes numbers, not geometry code.
- Reference spawned instances by name/reference from the container the builder returns. Never hardcode `workspace.Something.Deep.Chain`.

## The three minigames (invent these, make them genuinely hardcore)

Design three ORIGINAL games. They must punish mistakes hard, escalate every round, and reward mastery. Suggested originals (build these or better):

1. **Collapse Protocol** — a hex-tile floor over a kill void. Each hex the player stands on begins to crumble on a timer that shrinks every round; standing still is death. Periodic server-triggered "quakes" pre-fault a random cluster of tiles. Last player standing wins. Escalation: crumble timer down, quake frequency up, tile-regrow disabled in final third.

2. **Signal Jammer** — players must reach and hold a moving capture point while server-spawned "pulse" waves sweep the arena on a telegraphed rhythm; caught in a pulse = eliminated. The safe rhythm speeds up and the telegraph window shortens each round. Holding the point scores; contested holds decay. Escalation: pulse speed up, telegraph time down, multiple simultaneous pulses late-game.

3. **Freefall Gauntlet** — a vertical descent through server-driven rotating hazard rings; players fall/parkour downward and must thread gaps. Missing a gap or touching a ring = out. Ring rotation speed and gap size scale with round. Reaching the floor alive scores by placement/time. Escalation: rotation up, gaps tighten, wind gusts (server-applied impulses) added late.

For each game: contact/hitbox detection is server-side, elimination is server-decided, and eliminated players enter spectator state until the round ends.

## Common minigame interface

Every minigame is a self-contained module returning a table that implements one uniform contract so the round manager can drive any of them identically:

- `.new(context) -> Minigame` — context carries the participant list, arena container, config, and a cleanup object
- `:Start()` — build map, spawn players, begin
- `:Stop()` — halt and hand back cleanup
- `:OnPlayerEliminated(player)` — server-side, authoritative
- `:GetResults() -> { {player, placement, score} }` — final standings
- a metadata block: `Name`, `MinPlayers`, `MaxPlayers`, `SupportsTeams`, `RoundDurationCap`

The manager must handle **various lobby models** per game via that metadata: free-for-all any count, small lobby, battle-royale, and team modes. A game declares what it supports; the manager only picks games valid for the current player count and mode.

## Full game loop to build

- **Round manager** (server): state machine — `WaitingForPlayers -> Intermission -> Loading -> InProgress -> Results -> back`. Picks the next valid minigame, filters by player count/mode, tracks eliminations, crowns a winner, awards points, cleans up fully, loops. No leaked state between rounds.
- **Matchmaking / teleport**: pick the best-practice topology yourself and state the choice in the report. Default to a lobby + reserved-server teleport model (`TeleportService`, reserved servers, `TeleportData` for party/round context) if the repo shows no existing convention; fall back to single-place in-place cycling if that fits the existing project better. Whatever you pick, isolate it behind one module so it can be swapped.
- **DataStore leaderboards** (persistent): wins, points, best placement, games played. Wrap every DataStore call in `pcall`, use `UpdateAsync` for read-modify-write, budget/throttle requests, retry on failure, and never block the round loop on a DataStore call. Include a session cache. Expose a global top-N leaderboard surface.
- **UI** (client): lobby screen, intermission countdown, per-game HUD (timer, players-left, your-score), elimination/spectator overlay, results screen with standings, and a leaderboard board. Server drives all values over remotes; client only renders. Plain-text-safe, no reliance on external assets you can't reference.
- **Shared config module**: one place for all tunables — round/intermission durations, per-game escalation curves, point values, arena dimensions, min/max players. Difficulty lives here, not scattered in logic.
- **Shared remotes module**: define every RemoteEvent/RemoteFunction once; server and client both require the same definitions. No ad-hoc remote creation.

## Placement in the tree

Follow the existing project mappings. Absent a convention, use: shared code (config, remotes, types, minigame interface, packages) in `ReplicatedStorage`; server logic (round manager, each minigame, map builders, leaderboards, teleport) in `ServerScriptService`; client logic (UI, HUD, input) in `StarterPlayer.StarterPlayerScripts`. Keep each minigame in its own folder with an `init.luau`.

## Tooling

- Add/respect **Selene** and **StyLua** config only. No GitHub Actions / CI.
- All new code must pass `selene .` and be formatted by `stylua .` against the repo's config (create sane configs only if none exist).
- Add a `.gitignore` entry for installed Wally packages and any built place files if not already ignored.

## Definition of done

1. `rojo build` produces a valid tree with everything wired.
2. `wally install` (if used) resolves cleanly; only free/open-source packages.
3. `selene .` passes; `stylua --check .` passes on new files.
4. Three original hardcore minigames implemented against the common interface, each with runtime-built maps and per-round escalation.
5. Full loop runs: matchmaking/teleport, round state machine, intermission, UI, spectator state, results, persistent DataStore leaderboards.
6. Server-authoritative throughout; every remote payload validated; no client-trusted elimination or scoring.
7. Per-round cleanup verified — no connection/instance/thread leaks across rounds.
8. A `README` (or section) documenting each game, all tunable config values, the interface contract, and how to add a fourth game.

## Run report (end of run)

State: the framework/packages you chose and why, the teleport topology you picked, the exact files added and where, any place you deviated from the existing repo convention and why, and anything left as a follow-up. Terse. No em dashes.
