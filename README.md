# 🎮 Yoink Empire

A meme-flavored PvP "steal" game for Roblox, built with [Rojo](https://rojo.space)
so the whole game lives in this git repo as plain Luau.

> Build a base of goofy creatures that print cash, then race to steal the
> rarest creatures off everyone else's base before they steal yours.

See **[GAME_DESIGN.md](./GAME_DESIGN.md)** for the full concept.

## Quick start

### 1. Install the tools

Install [Rokit](https://github.com/rojo-rbx/rokit) (toolchain manager), then
from this folder:

```bash
rokit install
```

This installs the pinned Rojo version from `rokit.toml`.
(Or install Rojo directly: `cargo install rojo`, or via the
[Roblox Studio plugin](https://create.roblox.com/store/asset/13916111004/Rojo).)

### 2. Open Studio

1. Open Roblox Studio with a **Baseplate** template.
2. Install the **Rojo** plugin in Studio (Plugins → Manage Plugins → Rojo) if
   you haven't.

### 3. Sync the code

From this folder, start the Rojo server:

```bash
rojo serve
```

Then in Studio open the **Rojo** plugin panel and click **Connect**. The
`src/` code syncs straight into the place.

### 4. Play

Press **Play** in Studio. You'll spawn on your base. Hit **🎲 ROLL** to buy
creatures, watch your cash climb, then walk to another base and hold the
**Steal** prompt.

> **Test stealing with 2 players:** Test → Clients and Servers → set Players
> to 2 → Start. Each window gets its own base so you can rob yourself.

## Controls & features

| Action | How |
| ------ | --- |
| Roll a creature | **🎲 ROLL** button |
| Steal a rival's creature | Walk up + **hold E** |
| Sell your own creature | Walk up + **press F** |
| Upgrade base lock (defense) | **🔒 Buy Lock** button |
| Rebirth (reset for x income) | **♻️ Rebirth** button |
| Disguise as a crate | **🥷 Disguise** button |
| Buy VIP (x2 income) | **💎 VIP x2** button |

### Monetization setup

In the Creator Dashboard create a **VIP game pass** and any **cash developer
products**, then paste their IDs into `GameConfig.Monetization` (in
`src/shared/GameConfig.luau`). Map each product id to a cash amount in
`ProductCash`. Until IDs are set, the VIP button shows a "coming soon" message
and everything else works normally.

### Saving (DataStore)

Progress (cash, creatures, locks, rebirths) is saved via `DataStoreService`.
For saves to work **in Studio**, enable
*Game Settings → Security → Enable Studio Access to API Services*. Without it
the game still runs, but progress lasts only for the session.

## Project layout

```
src/shared   -> ReplicatedStorage.Shared   (config + remotes)
src/server   -> ServerScriptService.Server (game logic)
src/client   -> StarterPlayerScripts.Client(HUD)
```

Mapping is defined in `default.project.json`.

## Tuning

All gameplay numbers (prices, income, rarities, the creature roster) live in
`src/shared/GameConfig.luau`. Edit and re-sync — no other code changes needed.
