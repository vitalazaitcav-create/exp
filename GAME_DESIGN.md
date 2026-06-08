# 🎮 Yoink Empire — Game Design

A meme-flavored PvP "steal" game for Roblox. Build a base of goofy creatures
that print cash, then race to steal the rarest creatures off everyone else's
base before they steal yours.

## Core loop (what the player does 90% of the time)

1. **Roll** a random creature from the gacha (`$50` per roll).
2. Creatures sit on your base and **generate cash every second**.
3. Spend cash on more rolls → chase rarer creatures.
4. **Sneak onto rival bases** and hold the *Steal* prompt to yoink their best
   creatures.
5. **Defend / re-steal** — there is a cooldown, so timing and risk matter.

## Rarities & economy

| Rarity    | Cash/sec | Gacha weight |
| --------- | -------- | ------------ |
| Common    | 1        | 100          |
| Uncommon  | 3        | 45           |
| Rare      | 8        | 18           |
| Epic      | 20       | 7            |
| Legendary | 55       | 2.5          |
| Mythic    | 140      | 0.7          |
| Secret    | 400      | 0.1          |

All of this lives in `src/shared/GameConfig.luau` — tune freely.

## What makes it *ours* (not a clone)

- **Original meme roster** — Derp Duck, Buff Shrimp, Cosmic Capybara, The
  Glorptron 9000… no third-party trademarks.
- **Steal = skill + risk** — hold-to-steal timer + per-player cooldown means
  you can be interrupted or counter-stolen, creating clip-worthy moments.
- **Steals leaderboard** — bragging rights drive the competitive/viral angle.
- **Clean, data-driven config** so we can add seasonal creatures fast.

## Architecture

Server-authoritative. The client only sends "I want to roll" and renders the
HUD; all economy and steal logic runs on the server.

```
src/
├── shared/
│   ├── GameConfig.luau   # creatures, rarities, tuning numbers
│   └── Remotes.luau      # RemoteEvent accessor (server creates, client waits)
├── server/
│   ├── init.server.luau  # bootstraps all services in order
│   ├── DataService.luau  # leaderstats: Cash + Steals
│   ├── PlotService.luau  # builds bases, assigns plots, owns creature stands
│   ├── IncomeService.luau# pays cash per tick from placed creatures
│   ├── ShopService.luau  # gacha rolls
│   └── StealService.luau # validates + transfers steals
└── client/
    └── init.client.luau  # cash HUD, ROLL button, toast notifications
```

## Roadmap ideas (next steps)

- 💾 **Persistence** — wire `DataStoreService` into `DataService`.
- 🔒 **Base defense** — buyable locks that increase steal time.
- 🎯 **Bounty system** — top thieves get marked, others earn bonus for robbing them.
- 🐾 **3D models** — swap the placeholder neon cubes for real meshes.
- 💸 **Monetization** — Game Passes (auto-collect, extra slots) + Dev Products (cash, luck boosts).
- 🥷 **Disguises** — sneak onto bases disguised as harmless props (signature viral mechanic).
