# Five Hundred

A Flutter implementation of the classic Five Hundred card game — a 4-player trick-taking game with bidding, trump suits, and team-based scoring.

## About the Game

Five Hundred is a trick-taking card game for 4 players in two partnerships. Players bid on how many tricks (out of 10) their team will win and which suit will be trump. The winning bidder's team must make their bid to score points; otherwise they are set back. First team to reach 500 points wins; first to reach -500 points loses.

**Key rules:**
- 4 players: North/South vs East/West
- 10 tricks per hand, plus a 3-card kitty
- Bidding range: 6–10 tricks in Spades, Clubs, Diamonds, Hearts, or No Trump
- The Joker and both Jacks of trump follow special trump ordering rules
- Scoring uses the standard Avondale table

## Features

- Full single-player gameplay against three AI opponents
- Complete bidding auction with AI strategy
- Kitty exchange phase — pick up 3 cards and discard 3
- Trump rules including Joker, right bower, and left bower
- Claim detection — automatically wins remaining tricks when the outcome is certain
- Avondale scoring table with game-end detection at ±500
- Multiple themes with date-based rotation and manual override
- Persistent game state across sessions via SharedPreferences
- Cut-for-deal ceremony to determine the first dealer

## Screenshots

> Screenshots and feature graphics are in `assets/`.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `>=3.3.0 <4.0.0`)
- Android SDK or Chrome for running the app

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
# Chrome (web)
flutter run -d chrome

# Android emulator
flutter run -d emulator

# Helper script (checks emulator status first)
./run.sh
```

## Building

### Android (Google Play Store)

Release builds require signing credentials set as environment variables:

```bash
export FIVEHUNDRED_KEYSTORE_PASSWORD=<keystore-password>
export FIVEHUNDRED_KEY_PASSWORD=<key-password>
```

The keystore path is expected at `~/.android/keystores/fivehundred-release-key.jks`.

```bash
# Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# APK for direct installation
flutter build apk --release

# Fast incremental bundle build
./run-bundle-fast.sh
```

> **Never commit keystore files (`.jks`) or `key.properties` to version control.**

### Version

Version is defined in `pubspec.yaml` in the format `major.minor.patch+versionCode` (e.g. `1.0.26+26`). The Android `versionCode` and `versionName` are read from `pubspec.yaml` automatically.

## Testing

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/trick_engine_test.dart

# Run static analysis
flutter analyze

# Format code
dart format lib/
```

### Test coverage

```bash
./test-coverage.sh
```

Test files are in `test/` and mirror the `lib/` structure with a `_test.dart` suffix. Key test files:

| File | What it covers |
|------|----------------|
| `card_model_test.dart` | Card and suit models |
| `trick_engine_test.dart` | Trick play and winner logic |
| `bidding_engine_test.dart` | Bid validation and auction |
| `five_hundred_scorer_test.dart` | Avondale scoring |
| `trump_rules_test.dart` | Trump ordering (Joker, bowers) |
| `game_state_test.dart` | State transitions |
| `game_persistence_test.dart` | Save/load persistence |
| `theme_calculator_test.dart` | Date-based theme rotation |

## Architecture

### State management

- `GameEngine` (`lib/src/game/engine/game_engine.dart`) — central `ChangeNotifier` that owns all mutable state
- `GameState` (`lib/src/game/engine/game_state.dart`) — immutable snapshot with `copyWith` transitions
- Provider pattern used throughout for reactive UI updates

### Game flow

```
Setup → Dealing → Bidding → Kitty Exchange → Playing → Scoring → (repeat)
```

### Directory layout

```
lib/
  src/
    game/
      engine/       # GameEngine, GameState
      logic/        # bidding_engine, trick_engine, trump_rules, play_ai, bidding_ai,
                    # five_hundred_scorer, avondale_table, deal_utils, claim_analyzer
      models/       # PlayingCard, Bid, Trick, Position, Team, GamePhase
    ui/
      screens/      # GameScreen
      widgets/      # action_bar, hand_display, trick_area, status_bar, overlays/
      components/   # smaller UI building blocks
      theme/        # theme definitions, date calculator
    services/
      game_persistence.dart     # abstract interface + SharedPreferences impl
      settings_repository.dart  # theme/settings persistence
    app.dart        # FiveHundredApp root widget
  main.dart         # entry point
test/               # mirrors lib/ with _test.dart suffix
assets/             # app icons and feature graphic
```

### AI behavior

- **Bidding AI** (`bidding_ai.dart`) — evaluates hand strength using heuristics (trump length, high cards, void suits)
- **Play AI** (`play_ai.dart`) — basic trick-taking strategy (lead winners, follow suit, sluff losers)
- AI actions fire after a short timer delay to feel natural

## Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `shared_preferences` | Local persistence |
| `path_provider` | File system access |
| `intl` | Date/number formatting |
| `flutter_launcher_icons` *(dev)* | App icon generation |
| `fake_async` *(dev)* | Testing timer-based AI |

## Contributing

1. Follow the existing naming conventions (`lower_snake_case` files, `PascalCase` classes, `lowerCamelCase` members).
2. Keep line length ≤ 100 characters where practical.
3. Run `dart format lib/` and `flutter analyze` before committing.
4. Add a regression test when fixing a bug.

## License

Private project — all rights reserved.
