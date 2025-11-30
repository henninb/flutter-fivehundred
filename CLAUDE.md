# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter implementation of the classic Five Hundred card game. This is a 4-player trick-taking game with bidding, trump suits, and team-based scoring. The codebase uses Flutter/Dart with Provider for state management and SharedPreferences for persistence.

## Development Commands

### Setup & Dependencies
```bash
flutter pub get                    # Install dependencies
```

### Running the App
```bash
flutter run -d chrome              # Run on Chrome
flutter run -d emulator            # Run on Android emulator
./run.sh                           # Helper script that checks emulator status and runs app
```

### Building
```bash
flutter build appbundle --release  # Build Android App Bundle (AAB) for Play Store
./run-bundle-fast.sh              # Fast incremental bundle build
flutter build apk --release        # Build APK for direct installation
```

### Testing & Analysis
```bash
flutter test                       # Run all tests
flutter test test/card_model_test.dart  # Run specific test file
flutter analyze                    # Run static analysis
dart format lib/                   # Format code
```

### Android Release Building

Release builds require environment variables for signing:
- `FIVEHUNDRED_KEYSTORE_PASSWORD` - Keystore password
- `FIVEHUNDRED_KEY_PASSWORD` - Key password

The keystore path is hardcoded to `~/.android/keystores/fivehundred-release-key.jks` in `android/app/build.gradle.kts`.

## Architecture

### Application Bootstrap
- **Entry point**: `lib/main.dart` - Initializes SharedPreferences, creates GameEngine with persistence, wraps app in ChangeNotifierProvider
- **App widget**: `lib/src/app.dart` (FiveHundredApp) - Loads settings/theme from persistent storage, provides theme management callbacks, renders GameScreen

### State Management
- **GameEngine** (`lib/src/game/engine/game_engine.dart`) - Central state manager extending ChangeNotifier
- **GameState** (`lib/src/game/engine/game_state.dart`) - Immutable state object with copyWith pattern
- Provider pattern used throughout for reactive UI updates

### Game Flow Architecture
The game progresses through distinct phases managed by GameEngine:
1. **Setup** - Cut for deal to determine dealer
2. **Dealing** - Distribute 10 cards to each player + 3-card kitty
3. **Bidding** - 4-way auction (6-10 tricks in spades/clubs/diamonds/hearts/no-trump)
4. **Kitty Exchange** - Winning bidder picks up kitty and discards 3 cards
5. **Playing** - 10 tricks with trump rules
6. **Scoring** - Calculate points using Avondale table, check for game end (500/-500)

### Core Game Logic (`lib/src/game/logic/`)
- **bidding_engine.dart** - Bid validation and auction mechanics
- **bidding_ai.dart** - AI bidding strategy
- **trick_engine.dart** - Trick play validation and winner determination
- **play_ai.dart** - AI card play strategy
- **trump_rules.dart** - Trump suit card ordering (including Joker and Jacks)
- **five_hundred_scorer.dart** - Scoring based on Avondale table
- **avondale_table.dart** - Standard 500 scoring reference
- **deal_utils.dart** - Deck creation and shuffling
- **claim_analyzer.dart** - Analyzes if remaining tricks are automatic wins

### Models (`lib/src/game/models/`)
- **card.dart** - PlayingCard model (Suit, Rank, special cards like Joker)
- **game_models.dart** - Core game types:
  - `Position` (north/south/east/west) - Player positions
  - `Team` (northSouth/eastWest) - Team assignments
  - `BidSuit` - Extends Suit to include no-trump
  - `Bid` - Bid with tricks, suit, and bidder
  - `Trick` - Collection of played cards
  - `GamePhase` enum - Current game phase

### Services (`lib/src/services/`)
- **game_persistence.dart** - Abstract persistence interface + SharedPreferences implementation
- **settings_repository.dart** - Loads/saves game settings (theme selection, etc.)

### UI Structure (`lib/src/ui/`)
- **screens/** - Full-screen views (primarily GameScreen)
- **widgets/** - Reusable game components (action_bar, hand_display, trick_area, status_bar, persistent_game_board, overlays/)
- **components/** - Smaller UI building blocks
- **theme/** - Theme definitions and date-based theme calculator

### Theme System
- Supports multiple themes with date-based rotation
- User can override with manual theme selection
- Themes stored in `lib/src/models/theme_models.dart`
- Theme definitions in `lib/src/ui/theme/theme_definitions.dart`
- Date calculator in `lib/src/ui/theme/theme_calculator.dart`

## Coding Conventions

### File Organization
- **Game logic**: `lib/src/game/` (models, logic, engine)
- **UI code**: `lib/src/ui/` (screens, widgets, components, theme)
- **Services**: `lib/src/services/` (persistence, repositories)
- **Tests**: `test/` (mirror lib/ structure with `_test.dart` suffix)

### Naming
- Files: `lower_snake_case.dart`
- Classes: `PascalCase`
- Functions/variables: `lowerCamelCase`
- Constants: `lowerCamelCase` (Dart convention)
- Line length: ≤100 characters when practical

### Code Style
- Use `dart format` before committing
- Require trailing commas (enforced in `analysis_options.yaml`)
- Prefer immutable data with `copyWith` for state transitions
- Keep widgets small and composable
- Use `const` constructors wherever possible

### AI Behavior
- AI players use timers (`_aiTimer` in GameEngine) to introduce realistic delays
- Bidding AI in `bidding_ai.dart` uses hand evaluation heuristics
- Play AI in `play_ai.dart` uses basic trick-taking strategy

## Testing

### Test Files
All tests in `test/` directory with `_test.dart` suffix:
- `card_model_test.dart` - Card model tests
- `game_state_test.dart` - State management tests
- `bidding_engine_test.dart` - Bidding logic tests
- `trick_engine_test.dart` - Trick play tests
- `five_hundred_scorer_test.dart` - Scoring tests
- `game_persistence_test.dart` - Persistence tests
- `theme_calculator_test.dart` - Theme calculation tests
- `string_sanitizer_test.dart` - Utility tests

### Test Patterns
- Use `flutter_test` package
- Prioritize deterministic tests for game logic
- Use `fake_async` for testing timer-based AI behavior
- Test state transitions with `copyWith` pattern
- Add regression tests when fixing bugs

## Assets & Resources

- **Icons**: Custom app icon at `assets/fivehundred_icon.png`
- **Launcher icons**: Generated via `flutter_launcher_icons` package
- **Icon generation**: `lib/icon_generator.dart` - Script for creating icons

## Important Notes

### Security
- Never commit keystore files (`.jks`)
- Never commit `key.properties` if it exists
- Signing passwords must be in environment variables

### Platform Support
- Primary target: Android (Google Play Store)
- Web and desktop support available via Flutter
- Platform folders can be regenerated with `flutter create . --platforms=android,ios,...`

### Version Management
- Version defined in `pubspec.yaml` (format: `1.0.16+16` where +16 is versionCode)
- Android versionCode/versionName read from pubspec via Flutter plugin

### Dependencies
- **provider** - State management
- **shared_preferences** - Local persistence
- **path_provider** - File system access
- **intl** - Internationalization utilities
- **flutter_launcher_icons** - Icon generation (dev)
- **fake_async** - Testing timer-based code (dev)

## Common Patterns

### State Updates in GameEngine
```dart
void _updateState(GameState newState) {
  _state = newState;
  notifyListeners();
}
```
Always use `_updateState` to ensure UI reactivity.

### Immutable State Transitions
```dart
_updateState(_state.copyWith(
  currentPhase: GamePhase.bidding,
  gameStatus: 'Place your bid',
));
```

### Position Iteration
```dart
// Clockwise around table
Position current = Position.north;
for (int i = 0; i < 4; i++) {
  // ... do something with current
  current = current.next;
}
```

### Team Checks
```dart
if (position.team == contractor.team) {
  // Same team as contractor
}

if (position == contractor || position == contractor.partner) {
  // Contractor or partner
}
```

## Related Documentation

- `AGENTS.md` - Detailed guidelines for AI agents (overlaps with this file)
- `QUICK_SETUP_GUIDE.md` - Android release signing and Play Store publishing guide
- `README.md` - Basic project introduction
- `PRIVACY_POLICY.md` - Privacy policy for app store
