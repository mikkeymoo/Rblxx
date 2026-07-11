# Minigames

A Roblox party-game experience built with Rojo. Players drop into a shared lobby,
then get cycled through a random rotation of elimination-style minigames each round.
Everything — the lobby, each arena, the UI, and the round loop — is built procedurally
at runtime, so there's no manual Studio authoring required to run the place.

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
    │           └── LavaRise.lua
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
