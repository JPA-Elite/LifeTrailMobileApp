# LifeTrail

Life Trail Mobile — an original 2D landscape life-simulation game built with Flutter + Flame.

Explore a small town, manage stats (health / energy / happiness / intelligence / strength / charm / education / money), attend school, work, talk to NPCs, complete quests, and manage time, weather, and money — including an ATM/bank system. Landscape-only, immersive fullscreen.

## Features

- **2D town + interiors (Flame):** walkable town world with pedestrians, vehicles, interactables, feet-collision, plus enterable building interiors
- **Time system:** day / clock / weekday, time advances with activities and building entries (90 min per entry), night-time building lockout (go home to sleep to 07:00)
- **Stats & activities:** eat, study, exercise, work, talk, socialize, church, rest, class, gym — each costs time + energy and trains stats
- **School sim:** class attendance, attendance rate, weekly reset, subject quizzes (`assets/data/school/quiz.json`)
- **NPCs & dialogue:** data-driven NPCs, relationship tiers (Stranger → Best Friend), branching dialogue nodes
- **Quests:** locked → available → active → completed, gated by flags / relationships / day / stats, with money / relationship / flag rewards
- **Inventory & items:** stackable items, pickup / remove, persisted in save
- **Economy + ATM:** cash (₱) + bank balance, deposit / withdraw / 6-digit PIN change (default `000000`), persisted in flags
- **Location hours:** Summertime-Saga-style opening hours per location (school, bank, plaza, mall, etc.)
- **HUD:** stat bars, clock/day HUD, mini-map, dialogue box, action buttons
- **Save / load:** `shared_preferences`-backed slots (`slot1` for Continue + multi-slot screen), corrupt-save handling
- **State:** `flutter_riverpod` `ChangeNotifierProvider<GameState>` + JSON snapshot load/save

## Tech Stack

- Flutter (SDK `^3.12.2`), Dart
- `flame ^1.22.0` — game rendering
- `flutter_riverpod ^2.6.1` — game state
- `shared_preferences ^2.3.3` — saves
- `intl ^0.20.2` — formatting
- `cupertino_icons`, `flutter_lints`

## Getting Started

Prerequisites: Flutter SDK installed and a connected device / emulator.

```bash
flutter pub get
flutter run
```

Landscape is forced (`landscapeLeft` / `landscapeRight`) with immersive-sticky fullscreen — run on a landscape-capable device.

Useful commands:

```bash
flutter analyze
flutter test
flutter run -d chrome   # web preview (game is tuned for mobile landscape)
```

## Project Structure

```text
lib/
  main.dart              # locks landscape + immersive mode, ProviderScope root
  app/                   # MaterialApp, theme, routes (/, /game, /settings, /save-load)
  game/
    life_game.dart       # Flame game root
    world/               # town_world, life_world, interior_world, map_data,
                         # interactable, pedestrian, vehicle, mini_map_scene
    player/              # player_component, stick_figure
    systems/core_systems.dart  # Activities, LocationHours, Money/Energy/Relationship
    state/               # GameState (Riverpod), GameStateSnapshot
  models/                # player, game_time, npc, quest, item, location_dialogue
  screens/               # main_menu, game, atm, save_load, settings
  services/              # game_data_service (JSON loader), save_service, audio_service
  widgets/               # game_hud, stat_bar, mini_map, dialogue_box, action_buttons
assets/
  images/                # town/building/home sprites + plaza.jpg
  data/
    npcs/npcs.json
    quests/quests.json
    items/items.json
    dialogue/{alex,maria,ben}.json
    locations/
    school/quiz.json
test/
```

## Game Data (no code changes needed)

All content is JSON under `assets/` and loaded once via `GameDataService.loadAll()`:

| Path | Edits |
| ---- | ----- |
| `assets/data/npcs/npcs.json` | NPC ids, names, relationships |
| `assets/data/quests/quests.json` | quest gates, objectives, rewards |
| `assets/data/items/items.json` | items / inventory defs |
| `assets/data/dialogue/*.json` | NPC dialogue nodes |
| `assets/data/locations/` | location defs |
| `assets/data/school/quiz.json` | quiz subjects + questions |

Declared in `pubspec.yaml` under `flutter: assets:`. After adding new files, add them there too.

## Core Rules (from code)

- Building entry: `GameState.minutesPerBuildingEntry = 90`, tracked in `flags['building_entries']`.
- Night: `time.isNight` blocks all building entry except `home`. Message directs player home to sleep.
- Sleep: advances to 07:00 next day, restores energy to 100, +5 health, resets weather to sunny, resets weekly attendance flag on Monday.
- Exhaustion: `energy < 10`. Activities blocked when `energy + energyDelta < 0`.
- Debt hook: `debtDueDay = 7`, `isDebtOverdue = day > 7 && flags['debt_paid'] == 0`.
- ATM: `bank_balance` defaults to 2000, PIN stored in `flags['atm_pin']`, withdraw/deposit cost 5 min each.

## Screens / Routes

- `/` — Main menu: New Game, Continue (slot1 if present), Slots, Settings
- `/game` — Flame town + HUD, pause / save entry point
- `/save-load` — multi-slot save/load via `PrefsSaveService`
- `/settings` — app settings
- ATM — in-game bank UI (withdraw / deposit / change PIN)

New Game seeds: `PlayerModel()` defaults (85 HP / 80 energy / 72 happiness / 10 INT/STR/CHM/EDU / ₱500), `GameTime.morning(1)`, 1× bread.

## Screenshots

_Add landscape screenshots here (`docs/screenshots/` recommended)._

## Contributing

1. `flutter analyze` must pass (`flutter_lints`).
2. Add/extend tests in `test/` for any `GameState` / system change.
3. Keep game balance numbers in `core_systems.dart`, not in widgets.
