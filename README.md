# Minigames

A Roblox party-game experience built with Rojo. Players drop into a shared lobby,
then get cycled through a random rotation of six minigames each round — from
last-one-standing elimination arenas to a checkpoint race, a memory/precision
challenge, and a role-switching chase game. Everything — the lobby, each arena, the
UI, and the round loop — is built procedurally at runtime, so there's no manual
Studio authoring required to run the place.

## How a round works

The server runs a continuous loop (`GameManager.Run`):

1. **Waiting for players** — if there are fewer than `Config.MinPlayers` in the
   server, the game idles and broadcasts a waiting state to clients.
2. **Intermission** — a minigame is picked at random and announced. A countdown
   (`Config.IntermissionTime`, 15s by default) plays before the round starts.
3. **Round** — the chosen minigame's arena is built, players are teleported in, and
   the round timer (`Config.RoundTime`, 60s by default) starts. The round ends early
   the moment a winning condition is met, or is forced to a decision when the timer
   runs out.
4. **Results** — winners are announced, coins are awarded, and a short results
   countdown (`Config.ResultsTime`, 5s by default) plays.
5. Players are teleported back to the lobby and the loop repeats.

Coins are tracked per-player via `leaderstats` and persisted with `DataStoreService`.
Winners earn `Config.CoinsPerWin` (50), and everyone else who participated earns
`Config.CoinsParticipation` (5).

## Minigames

### Spleef
A floating ice-tile arena. Tiles start vanishing shortly after a player steps on
them, dropping anyone standing on them into the void below. Last player standing
wins; if the timer runs out, everyone still standing wins together.

### Color Rush
A grid of colored pads. A "safe" color is announced, and after a shrinking
countdown every pad that isn't that color falls away. The sequence repeats,
countdown getting faster each round, until only one color's players remain.

### Lava Rise
A scattered platform tower that players climb. After a short delay, lava rises
steadily from the base and eliminates anyone it touches. The highest surviving
player(s) win — if the round timer runs out first, whoever climbed highest wins.

### Parkour Race
A zig-zagging obstacle course, including platforms that tween back and forth over
gaps. Touching a platform sets it as your checkpoint, so falling respawns you there
instead of eliminating you — the challenge is speed and timing, not survival. First
to touch the finish line wins outright; if the timer runs out first, whoever reached
the furthest checkpoint wins (ties share it).

### Simon Says
Four colored pads flash a sequence that gets one step longer every round. After the
playback, everyone has to step on the pads in the same order — a wrong pad or running
out of time eliminates you. Last player standing after enough rounds wins; if the
timer runs out, everyone still in wins together.

### Infection Tag
One random player starts infected and gets a speed boost; touching a survivor
infects them too, so the infected side spreads by chain reaction across an arena of
pillars and cover. Survivors win if anyone is still clean when the timer runs out —
but if the infection reaches every player first, the round ends immediately and the
infected side wins instead.

## Project structure

```
minigames/
├── default.project.json          # Rojo project definition
└── src/
    ├── ReplicatedStorage/
    │   ├── Config.lua             # All tunable values (timers, arena sizes, coin rewards, etc.)
    │   └── Net.lua                # RemoteEvent creation/lookup helpers
    ├── ServerScriptService/
    │   ├── Main.server.lua        # Entry point: player setup + starts the round loop
    │   └── Modules/
    │       ├── GameManager.lua    # Server-authoritative round loop
    │       ├── LobbyBuilder.lua   # Procedurally builds the lobby/spawn pads
    │       ├── PlayerData.lua     # leaderstats + DataStore-backed coin persistence
    │       ├── MinigameUtils.lua  # Shared helpers (teleporting, fall detection, etc.)
    │       └── Minigames/
    │           ├── Spleef.lua
    │           ├── ColorRush.lua
    │           ├── LavaRise.lua
    │           ├── ParkourRace.lua
    │           ├── SimonSays.lua
    │           └── InfectionTag.lua
    └── StarterPlayerScripts/
        ├── Main.client.lua        # Wires server state to the client UI
        └── Modules/
            ├── HUD.lua             # In-round HUD (game name, timer, coins)
            ├── IntermissionScreen.lua
            ├── WinnerScreen.lua
            └── SoundPlayer.lua
```

## Adding a new minigame

Each minigame module implements a common interface consumed by `GameManager`:

```lua
Init(players: { Player }) -> ()      -- build the arena, teleport players in
Start() -> ()                        -- begin the round (start timers, hazards, etc.)
Cleanup() -> ()                      -- tear down the arena and reset state
GetWinners(final: boolean?) -> { Player }  -- return winners, or {} if undecided
```

Drop the new module into `src/ServerScriptService/Modules/Minigames/` and register
it in the `GAMES` table in `GameManager.lua`.

## Running the project

This project uses [Rojo](https://rojo.space/). From the `minigames/` directory:

```bash
rojo serve
```

Then connect from Roblox Studio via the Rojo plugin using `default.project.json`.

---

## Hardcore Minigame Pack

A second, self-contained pack of three brutally hardcore, server-authoritative
minigames sits alongside the base pack above, in the same place. It's opt-in:
touch the red kiosk near the base lobby (or use the in-game "Join Queue"
button) to enter its matchmaking queue. Only queued players are ever pulled
into a Hardcore round — the base pack's own loop is untouched and keeps
running exactly as before for everyone else.

### The three games

#### Collapse Protocol
A hex-tile floor over a kill void. Each tile you stand on starts crumbling on
a timer that shrinks every round; standing still is death. Periodic
server-triggered "quakes" pre-fault a random cluster of tiles a moment before
they drop. Last player standing wins (ties share first if the timer runs
out). Escalation: crumble timer shrinks, quake frequency rises, and tile
regrowth is disabled entirely in the final third of the round.

#### Signal Jammer
Hold the moving capture point alone to score; a second player nearby
contests the hold and decays it instead. Telegraphed pulse waves sweep the
arena on a shrinking rhythm — get caught in an active pulse and you're out.
Ranked by score (alive beats eliminated). Escalation: pulses fire more
often, the telegraph warning window shortens, and simultaneous pulses appear
in the back half of the round.

#### Freefall Gauntlet
A vertical shaft of rotating hazard rings, each with one gap. Fall through
the gaps to reach the landing pad; touching a ring (including missing a gap
outright, which is physically the same collision) eliminates you. Ranked by
landing time, then by how far still-falling players got if the round times
out. Escalation: rings spin faster the longer the round runs, gaps get
tighter the deeper you fall, and wind gusts start shoving falling players
around in the back half.

### Full loop

- **Round manager** (`ServerScriptService/Hardcore/RoundManager.luau`) drives
  a state machine — `WaitingForPlayers -> Intermission -> Loading ->
  InProgress -> Results -> back` — broadcast to clients over
  `HardcoreRemotes/StateChanged`. It picks the next game from the registry
  by filtering on the current queue size and mode against each game's
  metadata, builds that game's arena fresh every round, and tears the whole
  round down (arena, connections, threads) through one `Trove` per round.
- **Matchmaking** (`ServerScriptService/Hardcore/Matchmaking.luau`) is a
  single-place, in-place queue: touch the kiosk or fire `RequestJoinQueue`
  to join, `RequestLeaveQueue` to leave. This topology was chosen because
  the base pack has no `TeleportService`/reserved-server convention to
  match and this repo has no second place to teleport to; the module's
  public surface (`JoinQueue`/`LeaveQueue`/`Dequeue`/`GetQueueCount`) is the
  seam a reserved-server topology could be swapped in behind later.
- **Leaderboard** (`ServerScriptService/Hardcore/Leaderboard.luau`) persists
  wins, points, best placement, and games played per player. Every
  DataStore call is `pcall`-wrapped with retries, writes merge via
  `UpdateAsync` so concurrent servers can't clobber each other, a
  token-bucket budgets writes per minute, and a session cache means award
  calls never yield the round loop. A global top-N is exposed over the
  `GetLeaderboardSnapshot` RemoteFunction (cached for a few seconds
  server-side so spamming the leaderboard UI can't hammer the DataStore).
- **UI** (`StarterPlayerScripts/HardcoreModules/`) — a persistent queue
  widget, intermission/loading countdown, in-round HUD, an elimination/
  spectator overlay, a results screen, and the leaderboard panel. Every
  value comes from the server over `HardcoreRemotes/*`; the client only
  renders and forwards button clicks back as remote calls.

### Config reference

Everything tunable lives in `ReplicatedStorage/Hardcore/Config.luau`:
round/intermission/loading/results durations, points per placement, the
queue kiosk location, leaderboard DataStore/budget settings, and a
per-game table of arena dimensions and escalation curves (`{Start, Finish,
Min?, Max?}`, linearly interpolated by `ReplicatedStorage/Hardcore/
Escalation.luau`). Difficulty tuning is always a number change in this one
file, never a change to game logic.

### Common minigame interface

Every Hardcore minigame is a module returning a class table implementing:

```lua
Metadata: { Name, MinPlayers, MaxPlayers, SupportsTeams, RoundDurationCap }
.new(context: MinigameContext) -> Minigame   -- context: Participants, Arena, Config, Cleanup (Trove), RoundIndex, Mode
:Start()                                      -- build spawn-in, begin hazards
:Stop()                                       -- no-op by convention; RoundManager cleans context.Cleanup right after
:OnPlayerEliminated(player)                   -- authoritative; also called by RoundManager on mid-round disconnect
:GetResults() -> { {Player, Placement, Score} }
.Completed: Signal                            -- fired once a winner/placement order is decided (or never, if the round times out)
```

RoundManager only ever talks to `ServerScriptService/Hardcore/
MinigameRegistry.luau`, filtering games by `Metadata.MinPlayers`/
`MaxPlayers` against the current queue size (mode is currently always
`"FFA"`; `SupportsTeams` is validated by the filter so a future team mode
only needs a real mode source, no registry changes).

### Adding a fourth game

1. Write a map builder under `ServerScriptService/Hardcore/MapBuilders/`
   that builds your arena from `Config` into a `Folder` and returns it
   (see any existing builder — keep geometry parametric, no hardcoded
   `workspace.Something.Deep.Chain` references).
2. Write the minigame module under `ServerScriptService/Hardcore/
   Minigames/` implementing the interface above. Reuse
   `ServerScriptService/Modules/MinigameUtils.lua` (teleport-in-circle,
   spectate, fall-watching) and `ServerScriptService/Hardcore/
   HardcoreUtils.luau` (rate limiting, spectator stands) rather than
   duplicating them.
3. Add its tunables to `ReplicatedStorage/Hardcore/Config.luau`.
4. Register it in `ServerScriptService/Hardcore/MinigameRegistry.luau`'s
   `GAMES` table (metadata + module + map builder). That's the only file
   RoundManager reads from, so nothing else changes.

### Project structure (additions)

```
minigames/
├── selene.toml
├── stylua.toml
└── src/
    ├── ReplicatedStorage/
    │   └── Hardcore/
    │       ├── Config.luau            # every Hardcore-pack tunable
    │       ├── Remotes.luau           # all RemoteEvents/RemoteFunctions, defined once
    │       ├── Types.luau             # the common minigame interface + shared shapes
    │       ├── Escalation.luau        # curve -> value helper shared by every game
    │       ├── HexGrid.luau           # axial hex-grid math (Collapse Protocol)
    │       ├── Trove.luau             # cleanup-tracking utility (self-authored, see below)
    │       └── Signal.luau            # BindableEvent-backed signal utility (self-authored)
    ├── ServerScriptService/
    │   ├── HardcoreMain.server.luau   # entry point, sibling to Main.server.lua
    │   └── Hardcore/
    │       ├── RoundManager.luau      # the state machine
    │       ├── MinigameRegistry.luau  # registers games against the common interface
    │       ├── Matchmaking.luau       # queue / teleport topology, isolated behind one module
    │       ├── Leaderboard.luau       # DataStore-backed persistent stats
    │       ├── HardcoreLobby.luau     # builds the queue kiosk
    │       ├── HardcoreUtils.luau     # rate limiter, spectator stands
    │       ├── MapBuilders/
    │       │   ├── CollapseProtocolMap.luau
    │       │   ├── SignalJammerMap.luau
    │       │   └── FreefallGauntletMap.luau
    │       └── Minigames/
    │           ├── CollapseProtocol.luau
    │           ├── SignalJammer.luau
    │           └── FreefallGauntlet.luau
    └── StarterPlayerScripts/
        ├── HardcoreMain.client.luau
        └── HardcoreModules/
            ├── QueueWidget.luau
            ├── IntermissionUI.luau
            ├── GameHUD.luau
            ├── EliminationOverlay.luau
            ├── ResultsUI.luau
            └── LeaderboardUI.luau
```

### Notes and known limitations

- **No Wally.** This build environment has no `rojo`/`wally`/`selene`/
  `stylua` binaries and no package-registry network access to verify a
  `wally.lock` would resolve, so pulling in third-party `Signal`/`Trove`
  packages couldn't be verified end-to-end. `Trove.luau` and `Signal.luau`
  are small, self-authored, dependency-free equivalents instead (a
  BindableEvent-backed signal and a cleanup tracker with the same shape as
  the well-known community packages). If your toolchain has Wally
  available, swapping either for a real package is a drop-in replacement
  behind the same `Types.luau` contract.
- **Two loops, one place.** The base pack's `GameManager` loop was left
  completely untouched (per the brief: fit the existing project, don't
  restructure it) and pulls in every connected player each round. The
  Hardcore pack only ever touches players who explicitly queue, so it can't
  drag someone out of a base-pack round — but the reverse isn't guarded:
  a player mid-Hardcore-round is still a normal connected player, so if the
  base loop's intermission lands at the same moment it will also try to
  teleport them into a base arena. Fixing that fully means either a shared
  "player is busy" check in `GameManager.lua` (touches the base pack) or
  running the Hardcore pack on a separate reserved server. Left as a
  follow-up rather than modifying the base pack's own file.
- **Team mode is declared, not built.** `SupportsTeams` is part of every
  game's metadata and the registry's filter honors it, but there's no team-
  assignment UI yet — `Mode` is always `"FFA"`. Wiring a real team mode is
  additive: pick a mode source, thread it into `RoundManager.Run`'s
  `pickGame`/context construction, done.
