# Flutter 500 Conversion Plan

## Executive Summary

This document outlines the complete plan to convert the Flutter cribbage game into a game of 500 (Five Hundred). The conversion involves replacing the cribbage-specific game mechanics with trick-taking gameplay, bidding system, partnerships, and trump-based scoring.

**Project Scope:**
- Convert existing Flutter cribbage app (~9,237 lines) to 500
- Target: Single player + 3 AI opponents (fixed partnerships)
- 45-card deck (Joker + 4-Ace) with 5-card kitty
- Standard bidding (6-10 in suits/no-trump, no special bids initially)
- Basic but playable AI
- Complete replacement of cribbage content

**Timeline Estimate:** 40-60 hours of development work

**Current Progress:**
- ✅ **Phase 1: Foundation (8-10 hours)** - COMPLETE
  - Updated Card model with joker and 45-card deck
  - Created 500 game models (Bid, Trick, Position, Team)
  - Implemented Avondale scoring table
  - Built Trump rules and comparison logic
- ✅ **Phase 2: Core Game Logic (12-15 hours)** - COMPLETE
  - Implemented Bidding Engine (American variant)
  - Built Trick-Taking Engine with full validation
  - Created 500 scoring system
  - Developed Bidding AI
  - Developed Play AI
- ✅ **Phase 3: State & Engine (10-12 hours)** - COMPLETE
  - Redesigned GameState for 4-player 500
  - Updated deal_utils for 45-card deck and 10-card hands
  - Rewrote GameEngine with complete 500 game flow (728 lines)
- 🔄 **Phase 4: UI Overhaul (8-10 hours)** - 70% COMPLETE
  - ✅ Updated main.dart and app.dart
  - ✅ Created BiddingDialog widget
  - ✅ Created ScoreDisplay widget
  - ✅ Created simplified ActionBar500
  - ✅ Created minimal GameScreen500
  - ⏳ Old cribbage UI files still exist (causing compile errors)
  - ⏳ Need to delete or update remaining old widgets
- ⏳ **Phase 5: Testing & Polish (5-8 hours)** - PENDING

---

## Table of Contents

1. [Requirements Summary](#requirements-summary)
2. [Architecture Analysis](#architecture-analysis)
3. [Conversion Strategy](#conversion-strategy)
4. [Phase-by-Phase Plan](#phase-by-phase-plan)
5. [File-by-File Changes](#file-by-file-changes)
6. [New Components](#new-components)
7. [Testing Strategy](#testing-strategy)
8. [Risk Mitigation](#risk-mitigation)
9. [Success Criteria](#success-criteria)

---

## Requirements Summary

### Game Configuration
- **Players:** 1 human + 3 AI opponents
- **Partnerships:** Fixed (Player + AI South partner vs AI West + AI East opponents)
- **Seating:** Player (North), Partner (South), Opponents (West, East)
- **Deck:** 45 cards (Joker + ranks 4-Ace in all suits)
- **Kitty:** 5 cards dealt face down
- **Deal Pattern:** 3-3-4-4-3-3 with kitty dealt in middle

### Bidding System
- **Auction:** Full 4-way bidding (player + 3 AI)
- **Bid Range:** 6-10 tricks
- **Suits:** Spades < Clubs < Diamonds < Hearts < No Trump
- **American Variant:** Single round of bidding, each player bids once
- **Inkle:** First two players can bid 6 (inkle), but can't win auction
- **Redeal:** If no one bids 7+, reshuffle and redeal

### Trump System
- **Trump Order (High to Low):**
  - Joker (best bower)
  - Jack of trump suit (right bower)
  - Jack of same color (left bower)
  - Ace, King, Queen, 10, 9, 8, 7, 6, 5, 4
- **Non-Trump Suits:**
  - Ace, King, Queen, (Jack), 10, 9, 8, 7, 6, 5, 4
  - Note: Jack only present if not trump or left bower
- **No Trump:** Only joker is trump

### Joker Rules
- **In Trump Suits:** Always highest card
- **In No Trump:** Can only play when void in led suit
- **Leading Joker:** Player nominates a suit, others must follow

### Gameplay
- **Trick Taking:** 10 tricks per hand
- **Must Follow Suit:** Including left bower (counted as trump suit)
- **Trick Winner:** Highest trump or highest card of led suit
- **Turn Order:** Winner of trick leads next

### Scoring
- **Making Contract:** Score equals bid value (e.g., 7♠ made = 140 points)
- **Failing Contract:** Lose bid value from score (can go negative)
- **Overtricks:** No bonus for overtricks
- **Opponents:** Always score 10 points per trick taken
- **Win Condition:** First team to 500+ points wins
- **Lose Condition:** Team at -500 or below loses

### Bid Values (Avondale Table)
```
Tricks | Spades | Clubs | Diamonds | Hearts | No Trump
-------|--------|-------|----------|--------|----------
  6    |   40   |  60   |    80    |  100   |   120
  7    |  140   | 160   |   180    |  200   |   220
  8    |  240   | 260   |   280    |  300   |   320
  9    |  340   | 360   |   380    |  400   |   420
 10    |  440   | 460   |   480    |  500   |   520
```

### AI Complexity
- **Bidding AI:** Basic hand evaluation (trump count, high cards, distribution)
- **Card Play AI:** Simple rule-based (play high in partner's trick, low otherwise)
- **Partnership Coordination:** Minimal (track partner vs opponent tricks)

### UI Preferences
- **Theme:** Basic UI initially (polish later)
- **Scoring Display:** Trick-by-trick running score
- **No Initial Polish:** Skip animations, fancy themes for v1

---

## Architecture Analysis

### Current Cribbage Architecture

**State Management:**
- Pattern: Provider + ChangeNotifier
- Controller: `GameEngine` (1849 lines)
- State: Immutable `GameState` (311 lines)
- Pure Logic: Separated in `/game/logic`

**Game Flow (Cribbage):**
1. Setup → Cut for dealer → Dealing
2. Crib Selection (discard 2 cards each)
3. Pegging Phase (play cards sequentially, score points)
4. Hand Counting (score remaining hands)
5. Game Over (121 points)

**Key Components:**
- `GameState`: 40+ properties for all game state
- `GameEngine`: Coordinates entire game flow
- `CribbageScorer`: Pure scoring functions
- `OpponentAI`: Crib selection + card play decisions
- `PeggingRoundManager`: Manages pegging state machine

### Target 500 Architecture

**Game Flow (500):**
1. Setup → Deal cards
2. Bidding Phase (4-way auction)
3. Kitty Exchange (winner picks up, discards 5)
4. Trick-Taking Phase (10 tricks)
5. Scoring (contract made/failed, opponent points)
6. Next Hand (rotate dealer) or Game Over (500+ points)

**Required State Changes:**
- Remove: Pegging state, hand counting state, cribbage board positions
- Add: Bidding state, trump suit, current trick, tricks won per team
- Modify: Deck (52→45 cards, add joker), hand size (6→10 cards)

**Component Mapping:**
- `GameState` → Redesign for 500
- `GameEngine` → Rewrite for trick-taking flow
- `CribbageScorer` → Replace with `TrickTakingEngine` + `FiveHundredScorer`
- `OpponentAI` → Replace with `BiddingAI` + `PlayAI`
- `PeggingRoundManager` → Replace with `TrickManager`

---

## Conversion Strategy

### Overall Approach: **Incremental Replacement**

We'll replace components incrementally while maintaining a working app at each step:

1. **Phase 1: Foundation** - Update models and data structures
2. **Phase 2: Core Logic** - Implement 500 game logic
3. **Phase 3: State & Engine** - Rewrite GameState and GameEngine
4. **Phase 4: UI** - Update screens and widgets
5. **Phase 5: Testing** - Comprehensive testing and polish

### Reuse vs. Replace Decision Matrix

| Component | Decision | Rationale |
|-----------|----------|-----------|
| Card model | **Modify** | Add joker rank, update values |
| GameState | **Rewrite** | Fundamentally different state structure |
| GameEngine | **Rewrite** | Different game flow entirely |
| CribbageScorer | **Replace** | Trick-taking vs. cribbage scoring |
| OpponentAI | **Replace** | Bidding + trick play vs. crib selection |
| PeggingRoundManager | **Replace** | Trick management vs. pegging |
| GamePersistence | **Modify** | Same persistence mechanism, different data |
| SettingsRepository | **Modify** | Update settings model |
| Theme system | **Keep** | Reuse as-is (maybe add 500 themes later) |
| ScoreAnimation | **Keep** | Reuse for score feedback |
| ActionBar | **Modify** | Different actions (Bid, Play, etc.) |
| Test infrastructure | **Keep & Adapt** | Reuse test patterns, rewrite test cases |
| Main.dart + Provider setup | **Keep** | Same state management pattern |

### Migration Path

```
Current Cribbage App
        ↓
[Phase 1] Update Card model, create 500 models
        ↓
[Phase 2] Implement trick-taking logic, scoring, AI
        ↓
[Phase 3] Replace GameState & GameEngine
        ↓
[Phase 4] Update UI screens and widgets
        ↓
[Phase 5] Test, debug, polish
        ↓
500 Game App
```

---

## Phase-by-Phase Plan

### Phase 1: Foundation (8-10 hours)

**Goal:** Update data models and create new 500-specific structures

#### Task 1.1: Update Card Model (2 hours)
**File:** `lib/src/game/models/card.dart`

**Changes:**
1. Add `Rank.joker` to enum
2. Add `Rank.four` to enum
3. Update `value` getter for 500 (face cards = 10, ace = 11, joker = 0)
4. Add `compareInTrump()` method for trump ordering
5. Add `isLeftBower()` helper method
6. Update `createDeck()` to create 45-card deck with joker

**Tests to Update:**
- `test/card_model_test.dart` - Update all tests for 45-card deck

#### Task 1.2: Create 500 Models (3 hours)
**New File:** `lib/src/game/models/game_models.dart`

**Create:**
```dart
enum Suit { spades, clubs, diamonds, hearts, noTrump }

enum Position { north, south, east, west }  // Player positions

enum Team { northSouth, eastWest }

class Bid {
  final int tricks;      // 6-10
  final Suit suit;
  final Position bidder;

  int get value;  // From Avondale table
  bool beats(Bid other);
}

class Trick {
  final List<CardPlay> plays;
  final Suit? ledSuit;
  final Position leader;

  Position get winner;
  bool get isComplete;
}

class CardPlay {
  final PlayingCard card;
  final Position player;
}

enum BidAction { pass, bid, inkle }

class BidEntry {
  final Position bidder;
  final BidAction action;
  final Bid? bid;
}
```

**Tests to Create:**
- `test/game_models_test.dart` - Test bid comparison, trick winner logic

#### Task 1.3: Create Avondale Scoring Table (1 hour)
**New File:** `lib/src/game/logic/avondale_table.dart`

**Create:**
```dart
class AvondaleTable {
  static const Map<int, Map<Suit, int>> bidValues = {
    6: {Suit.spades: 40, Suit.clubs: 60, ...},
    7: {Suit.spades: 140, ...},
    // ... all bid values
  };

  static int getBidValue(int tricks, Suit suit) { ... }
}
```

**Tests:**
- `test/avondale_table_test.dart` - Verify all bid values

#### Task 1.4: Create Trump Comparator (2 hours)
**New File:** `lib/src/game/logic/trump_rules.dart`

**Create:**
```dart
class TrumpRules {
  final Suit? trumpSuit;

  // Compare two cards in context of trump
  int compare(PlayingCard a, PlayingCard b);

  // Get effective suit (left bower counts as trump)
  Suit getEffectiveSuit(PlayingCard card);

  // Check if card is trump
  bool isTrump(PlayingCard card);

  // Check if card is bower
  bool isRightBower(PlayingCard card);
  bool isLeftBower(PlayingCard card);
}
```

**Tests:**
- `test/trump_rules_test.dart` - Test all trump scenarios, bower logic

---

### Phase 2: Core Game Logic (12-15 hours)

**Goal:** Implement 500-specific game logic

#### Task 2.1: Implement Bidding Logic (3 hours)
**New File:** `lib/src/game/logic/bidding_engine.dart`

**Create:**
```dart
class BiddingEngine {
  final List<Position> playerOrder;  // Dealer is last

  // American variant: one round only, first two can inkle
  BiddingResult conductAuction(
    List<BidEntry> currentBids,
    Position currentBidder,
    Bid? playerBid,
  );

  Position? getWinner(List<BidEntry> bids);
  bool needsRedeal(List<BidEntry> bids);
  Bid? getHighestBid(List<BidEntry> bids);
}

class BiddingResult {
  final Bid? winningBid;
  final Position? winner;
  final bool needsRedeal;
  final String message;
}
```

**Tests:**
- `test/bidding_engine_test.dart` - Test auction rules, inkle, redeal

#### Task 2.2: Implement Trick-Taking Engine (4 hours)
**New File:** `lib/src/game/logic/trick_engine.dart`

**Create:**
```dart
class TrickEngine {
  final TrumpRules trumpRules;

  // Play a card to current trick
  TrickResult playCard(
    Trick currentTrick,
    PlayingCard card,
    Position player,
    List<PlayingCard> playerHand,
  );

  // Validate if card can be legally played
  bool isLegalPlay(
    PlayingCard card,
    Trick currentTrick,
    List<PlayingCard> hand,
  );

  // Determine trick winner
  Position getTrickWinner(Trick trick);

  // Get legal cards for player
  List<PlayingCard> getLegalCards(
    List<PlayingCard> hand,
    Trick currentTrick,
  );
}

class TrickResult {
  final Trick updatedTrick;
  final Position? winner;  // null if trick incomplete
  final bool trickComplete;
  final String message;
}
```

**Tests:**
- `test/trick_engine_test.dart` - Test follow suit, trump, joker rules

#### Task 2.3: Implement 500 Scoring (2 hours)
**New File:** `lib/src/game/logic/five_hundred_scorer.dart`

**Create:**
```dart
class FiveHundredScorer {
  // Score a completed hand
  static HandScore scoreHand({
    required Bid contract,
    required int tricksTakenByContractor,
    required int tricksTakenByOpponents,
    required Team contractorTeam,
  });

  // Check game over
  static GameOverStatus? checkGameOver({
    required int teamNSScore,
    required int teamEWScore,
  });
}

class HandScore {
  final int contractorPoints;  // + or - bid value
  final int opponentPoints;    // 10 per trick
  final bool contractMade;
  final int tricksOver;        // overtricks (not scored)
}

enum GameOverStatus {
  teamNSWins,
  teamEWWins,
  teamNSLoses,  // -500 or below
  teamEWLoses,
}
```

**Tests:**
- `test/five_hundred_scorer_test.dart` - All scoring scenarios

#### Task 2.4: Implement Bidding AI (3-4 hours)
**New File:** `lib/src/game/logic/bidding_ai.dart`

**Create:**
```dart
class BiddingAI {
  // Evaluate hand and decide bid
  static BidDecision chooseBid({
    required List<PlayingCard> hand,
    required List<BidEntry> currentBids,
    required Position position,
    required bool canInkle,
  });

  // Hand evaluation (basic)
  static HandEvaluation evaluateHand(List<PlayingCard> hand);

  // Best suit for this hand
  static Suit getBestSuit(HandEvaluation eval);
}

class BidDecision {
  final BidAction action;  // pass, bid, inkle
  final Bid? bid;
  final String reasoning;  // For debugging
}

class HandEvaluation {
  final Map<Suit, double> suitStrength;  // 0-10 per suit
  final int highCardCount;
  final int trumpCount;  // If suited
  final double overallStrength;  // 0-10
}
```

**Bidding Heuristics (Basic):**
- Count trumps in each suit (Joker, bowers, high cards)
- 7+ cards in suit = good trump suit
- 3+ top trumps (A, K, Q) = +1 level
- Joker = +1 level
- Minimum 5 tricks estimated to bid 6
- Minimum 6 tricks estimated to bid 7
- Very simple, doesn't consider partner or position

**Tests:**
- `test/bidding_ai_test.dart` - Test hand evaluation, bid selection

#### Task 2.5: Implement Play AI (3-4 hours)
**New File:** `lib/src/game/logic/play_ai.dart`

**Create:**
```dart
class PlayAI {
  // Choose card to play in trick
  static PlayingCard chooseCard({
    required List<PlayingCard> hand,
    required Trick currentTrick,
    required TrumpRules trumpRules,
    required Position position,
    required Position partner,
    required Map<Position, int> tricksWon,
  });

  // Simple rule-based strategy
  static PlayStrategy determineStrategy(
    Trick trick,
    Position position,
    Position partner,
  );
}

enum PlayStrategy {
  leadHigh,      // Leading: play highest card
  leadTrump,     // Leading: play trump
  followLow,     // Following: play lowest legal card
  followHigh,    // Following: play highest to win
  trumpIn,       // Void in led suit: play trump
  discard,       // Void and can't/won't trump: discard
}
```

**Play Heuristics (Basic):**
- **Leading:** Play highest card in longest suit
- **Following (partner winning):** Play lowest legal card
- **Following (opponent winning):** Try to win with lowest winning card
- **Void:** Play trump if able, otherwise discard lowest
- **No complex signals or card counting in v1**

**Tests:**
- `test/play_ai_test.dart` - Test play decisions in various scenarios

---

### Phase 3: State & Engine (10-12 hours)

**Goal:** Rewrite GameState and GameEngine for 500

#### Task 3.1: Design New GameState (3 hours)
**File:** `lib/src/game/engine/game_state.dart` (complete rewrite)

**New Structure:**
```dart
@immutable
class GameState {
  // Game setup
  final bool gameStarted;
  final GamePhase currentPhase;
  final Position dealer;
  final int handNumber;

  // Scores
  final int teamNorthSouthScore;
  final int teamEastWestScore;
  final int gamesWon;
  final int gamesLost;

  // Player info
  final String playerName;     // North
  final String partnerName;    // South
  final String opponentWestName;
  final String opponentEastName;

  // Hands (10 cards each)
  final List<PlayingCard> playerHand;      // North
  final List<PlayingCard> partnerHand;     // South
  final List<PlayingCard> opponentWestHand;
  final List<PlayingCard> opponentEastHand;
  final List<PlayingCard> kitty;

  // Bidding phase
  final bool isBiddingPhase;
  final List<BidEntry> bidHistory;
  final Position currentBidder;
  final Bid? currentHighBid;
  final Bid? winningBid;
  final Position? contractor;

  // Play phase
  final bool isPlayPhase;
  final Suit? trumpSuit;
  final Trick? currentTrick;
  final List<Trick> completedTricks;
  final Position currentPlayer;
  final Map<Position, int> tricksWon;
  final int? selectedCardIndex;

  // UI state
  final String gameStatus;
  final bool showGameOverDialog;
  final GameOverData? gameOverData;
  final ScoreAnimation? scoreAnimation;

  GameState copyWith({...});
}

enum GamePhase {
  setup,
  dealing,
  bidding,
  kittyExchange,
  play,
  scoring,
  gameOver,
}

class GameOverData {
  final Team winningTeam;
  final int finalScoreNS;
  final int finalScoreEW;
  final GameOverStatus status;
  final int gamesWon;
  final int gamesLost;
}
```

**Tests:**
- `test/game_state_test.dart` - Test copyWith, equality, serialization

#### Task 3.2: Implement Dealing Logic (2 hours)
**File:** `lib/src/game/logic/deal_utils.dart` (rewrite)

**Replace with:**
```dart
class DealUtils {
  // Deal 10 cards to each player + 5 to kitty
  // Pattern: 3-3-4-4-3-3, kitty in middle
  static DealResult dealHand({
    required List<PlayingCard> deck,
    required Position dealer,
  });
}

class DealResult {
  final Map<Position, List<PlayingCard>> hands;
  final List<PlayingCard> kitty;
}
```

**Tests:**
- `test/deal_utils_test.dart` - Verify 45 cards dealt correctly

#### Task 3.3: Rewrite GameEngine (5-7 hours)
**File:** `lib/src/game/engine/game_engine.dart` (complete rewrite)

**New GameEngine:**
```dart
class GameEngine extends ChangeNotifier {
  GameState _state;
  final GamePersistence _persistence;

  // Injected logic components
  final BiddingEngine _biddingEngine;
  final TrickEngine _trickEngine;
  final FiveHundredScorer _scorer;
  final BiddingAI _biddingAI;
  final PlayAI _playAI;

  GameState get state => _state;

  // Game lifecycle
  void initialize();
  void startNewGame();

  // Dealing phase
  void dealCards();

  // Bidding phase
  void submitBid(Bid? bid);  // null = pass
  void submitInkle(Suit suit);
  Future<void> _runAIBidding();

  // Kitty exchange
  void toggleKittyCardSelection(int index);
  void confirmKittyExchange();

  // Play phase
  void playCard(int cardIndex);
  bool isCardPlayable(int cardIndex);
  Future<void> _runAITurn();
  void _advanceToNextTrick();

  // Scoring phase
  void _scoreHand();
  void proceedToNextHand();
  void dismissGameOverDialog();

  // Helpers
  void _updateState(GameState newState);
  Future<void> _saveState();
}
```

**Key Methods Detail:**

**`dealCards()`:**
1. Create 45-card deck
2. Shuffle
3. Deal using DealUtils
4. Set phase to bidding
5. Start AI bidding

**`submitBid(Bid? bid)`:**
1. Validate bid beats current high bid
2. Add to bid history
3. Advance to next bidder
4. If all passed or 3 passes after bid, determine winner or redeal
5. Trigger AI bidding for next player

**`_runAIBidding()`:**
1. Get AI decision from BiddingAI
2. Add to bid history
3. Update state
4. Delay (500ms for realism)
5. Check if auction complete
6. If complete and winner exists, go to kitty exchange
7. If no winner, redeal

**`confirmKittyExchange()`:**
1. Contractor picks up kitty
2. Contractor discards 5 cards
3. For AI contractor, use simple logic (discard lowest non-trump)
4. Set trump suit from winning bid
5. Start play phase

**`playCard(int cardIndex)`:**
1. Validate card is legal
2. Play card to trick
3. Update state
4. If trick complete, determine winner, advance
5. Else if AI turn next, trigger AI turn

**`_runAITurn()`:**
1. Get current AI position's hand
2. Use PlayAI to choose card
3. Delay (500ms)
4. Play card

**`_advanceToNextTrick()`:**
1. Add completed trick to history
2. Update tricks won count
3. If 10 tricks complete, go to scoring
4. Else start new trick, winner leads

**`_scoreHand()`:**
1. Count tricks per team
2. Use FiveHundredScorer
3. Update scores
4. Check game over
5. Show result dialog

**Tests:**
- `test/game_engine_test.dart` - Test all game flow scenarios

---

### Phase 4: UI Overhaul (8-10 hours)

**Goal:** Update all UI screens and widgets for 500

#### Task 4.1: Update Main App (1 hour)
**Files:**
- `lib/src/app.dart` - Rename to `FiveHundredApp`
- `lib/main.dart` - Update app name, references

**Changes:**
- Rename `CribbageApp` → `FiveHundredApp`
- Update theme title to "500"
- Update persistence keys

#### Task 4.2: Redesign Game Screen (4-5 hours)
**File:** `lib/src/ui/screens/game_screen.dart` (major rewrite)

**New Layout:**
```
┌─────────────────────────────────────┐
│  Header: Scores (Teams NS vs EW)   │
│  Current Trump | Tricks Won         │
├─────────────────────────────────────┤
│                                     │
│  Opponent West Hand (facedown)     │
│                                     │
│         ┌─────────────┐             │
│         │   Trick     │             │
│         │  (4 cards)  │             │
│         └─────────────┘             │
│                                     │
│  Player Hand (10 cards, faceup)    │
│  [selectable/playable]             │
│                                     │
├─────────────────────────────────────┤
│  Action Bar: Bid | Pass | Play     │
│  Status Message                     │
└─────────────────────────────────────┘
```

**Widgets Needed:**
- `PlayerHandWidget` - Shows 10 cards horizontally (scrollable if needed)
- `OpponentHandWidget` - Shows N facedown cards
- `TrickDisplay` - Shows current trick (4 cards in NESW positions)
- `ScoreHeader` - Team scores, trump indicator, tricks won
- `BiddingDialog` - Bid selection UI
- `GameOverDialog` - Winner, final scores

**Key Changes:**
- Remove cribbage board visualization
- Add 4-player hand layout
- Add trick display in center
- Update action bar for bidding/playing

#### Task 4.3: Create Bidding UI (2 hours)
**New File:** `lib/src/ui/widgets/bidding_dialog.dart`

**Create:**
```dart
class BiddingDialog extends StatelessWidget {
  // Shows grid of bid options
  // Rows: 6-10 tricks
  // Cols: ♠ ♣ ♦ ♥ NT
  // Grayed out if lower than current high bid
  // Pass button
  // Inkle button (if allowed)
}
```

#### Task 4.4: Update Action Bar (1 hour)
**File:** `lib/src/ui/widgets/action_bar.dart` (modify)

**New Actions:**
- Deal (setup/scoring phase)
- Bid (bidding phase)
- Pass (bidding phase)
- Play (play phase, when card selected)
- Continue (scoring phase)

**Remove:**
- Confirm Crib
- Go
- Show Hand

#### Task 4.5: Replace Cribbage Board (1 hour)
**File:** `lib/src/ui/widgets/cribbage_board.dart` → **DELETE**
**New File:** `lib/src/ui/widgets/score_display.dart`

**Create:**
```dart
class ScoreDisplay extends StatelessWidget {
  // Simple score table
  // Team N-S: XXX
  // Team E-W: XXX
  // Tricks won this hand: N-S: X, E-W: X
}
```

#### Task 4.6: Update Settings Screen (1 hour)
**File:** `lib/src/ui/screens/settings_screen.dart`

**Changes:**
- Remove "Counting Mode" setting (not applicable)
- Keep theme selection
- Add "AI Difficulty" placeholder (for future)
- Add "Show Trick History" toggle

---

### Phase 5: Testing & Polish (5-8 hours)

**Goal:** Ensure game is fully playable and bug-free

#### Task 5.1: Update Unit Tests (3-4 hours)

**Files to Update:**
- `test/card_model_test.dart` - ✓ Updated in Phase 1
- `test/game_models_test.dart` - ✓ Created in Phase 1
- `test/avondale_table_test.dart` - ✓ Created in Phase 1
- `test/trump_rules_test.dart` - ✓ Created in Phase 1
- `test/bidding_engine_test.dart` - ✓ Created in Phase 2
- `test/trick_engine_test.dart` - ✓ Created in Phase 2
- `test/five_hundred_scorer_test.dart` - ✓ Created in Phase 2
- `test/bidding_ai_test.dart` - ✓ Created in Phase 2
- `test/play_ai_test.dart` - ✓ Created in Phase 2
- `test/game_state_test.dart` - ✓ Created in Phase 3
- `test/deal_utils_test.dart` - Update for 45-card deck
- `test/game_engine_test.dart` - Complete rewrite for 500

**Files to Delete:**
- `test/cribbage_scorer_test.dart`
- `test/opponent_ai_test.dart` (replaced by bidding_ai/play_ai tests)
- `test/pegging_round_manager_test.dart`
- `test/pegging_scorer_test.dart`

**New Test Coverage:**
- Complete game flow (deal → bid → play → score)
- AI bidding decisions
- AI play decisions
- Trump suit handling
- Joker special cases
- Scoring (made/failed contracts)

#### Task 5.2: Integration Testing (2 hours)

**Manual Test Scenarios:**
1. **Complete Game Flow:**
   - Start game
   - Deal cards
   - Bidding (player wins, AI wins)
   - Kitty exchange
   - Play 10 tricks
   - Score correctly
   - Next hand

2. **Bidding Scenarios:**
   - All pass (redeal)
   - Inkle bids
   - Player outbids AI
   - AI outbids player

3. **Trick-Taking Scenarios:**
   - Follow suit
   - Trump in when void
   - Joker leading/following
   - Left bower as trump
   - All combinations of trump suits

4. **Scoring Scenarios:**
   - Make contract (7, 8, 9, 10 tricks)
   - Fail contract
   - Opponents score 10/trick
   - Win game (500+)
   - Lose game (-500)

5. **Edge Cases:**
   - Negative scores
   - Tie situations
   - Multiple redeals
   - Joker in no-trump

#### Task 5.3: Bug Fixes & Polish (1-2 hours)

**Expected Issues:**
- AI delay timing
- UI responsiveness
- Card selection clarity
- Bid dialog UX
- Score display readability

**Polish Tasks:**
- Clear status messages
- Smooth transitions
- Helpful error messages
- Consistent styling

---

## File-by-File Changes

### Files to DELETE (Cribbage-Specific)

```
lib/src/game/logic/cribbage_scorer.dart
lib/src/game/logic/opponent_ai.dart
lib/src/game/logic/pegging_round_manager.dart
lib/src/ui/widgets/cribbage_board.dart
lib/src/ui/widgets/hand_counting_dialog.dart
lib/src/ui/widgets/manual_counting_dialog.dart
lib/src/ui/widgets/debug_score_dialog.dart (optional: could adapt)

test/cribbage_scorer_test.dart
test/opponent_ai_test.dart
test/pegging_round_manager_test.dart
test/pegging_scorer_test.dart
test/hand_counting_dialog_test.dart
```

### Files to CREATE (500-Specific)

```
lib/src/game/models/game_models.dart
lib/src/game/logic/avondale_table.dart
lib/src/game/logic/trump_rules.dart
lib/src/game/logic/bidding_engine.dart
lib/src/game/logic/trick_engine.dart
lib/src/game/logic/five_hundred_scorer.dart
lib/src/game/logic/bidding_ai.dart
lib/src/game/logic/play_ai.dart
lib/src/ui/widgets/bidding_dialog.dart
lib/src/ui/widgets/trick_display.dart
lib/src/ui/widgets/score_display.dart
lib/src/ui/widgets/player_hand_widget.dart
lib/src/ui/widgets/opponent_hand_widget.dart

test/game_models_test.dart
test/avondale_table_test.dart
test/trump_rules_test.dart
test/bidding_engine_test.dart
test/trick_engine_test.dart
test/five_hundred_scorer_test.dart
test/bidding_ai_test.dart
test/play_ai_test.dart
test/bidding_dialog_test.dart
```

### Files to MODIFY

| File | Changes |
|------|---------|
| `lib/main.dart` | Update app name references |
| `lib/src/app.dart` | Rename CribbageApp → FiveHundredApp |
| `lib/src/game/models/card.dart` | Add joker, add rank 4, update values, add trump comparison |
| `lib/src/game/engine/game_state.dart` | Complete rewrite for 500 state |
| `lib/src/game/engine/game_engine.dart` | Complete rewrite for 500 flow |
| `lib/src/game/logic/deal_utils.dart` | Update for 45-card deck, 10 cards each, 5-card kitty |
| `lib/src/services/game_persistence.dart` | Update serialization for new GameState |
| `lib/src/models/game_settings.dart` | Update settings model (remove counting mode, etc.) |
| `lib/src/ui/screens/game_screen.dart` | Major redesign for 4-player layout |
| `lib/src/ui/widgets/action_bar.dart` | Update actions (Bid, Pass, Play) |
| `lib/src/ui/widgets/welcome_screen.dart` | Update game description |
| `lib/src/ui/widgets/score_animation.dart` | Minor updates (should mostly work as-is) |
| `test/card_model_test.dart` | Update for 45-card deck, joker |
| `test/game_state_test.dart` | Complete rewrite |
| `test/game_engine_test.dart` | Complete rewrite |
| `test/deal_utils_test.dart` | Update for 500 dealing |
| `test/game_persistence_test.dart` | Update for new state structure |

### Files to KEEP (Reuse As-Is or Minimal Changes)

```
lib/src/services/settings_repository.dart (minor updates)
lib/src/ui/theme/* (all theme files - reuse)
lib/src/ui/widgets/score_animation.dart (reuse)
lib/src/ui/widgets/card_constants.dart (reuse)
lib/src/ui/widgets/theme_selector_bar.dart (reuse)
lib/src/utils/string_sanitizer.dart (reuse)

test/settings_repository_test.dart (minor updates)
test/theme_models_test.dart (reuse)
test/string_sanitizer_test.dart (reuse)
```

---

## New Components Detail

### 1. Bidding System

**BiddingEngine:**
- Manages auction state machine
- Enforces American variant rules (one round, inkle)
- Determines redeal conditions
- Returns winner and winning bid

**BiddingDialog:**
- 5×5 grid of bid buttons (6-10 tricks × S/C/D/H/NT)
- Grays out invalid bids (lower than current high)
- Pass button always available
- Inkle button for positions 0-1 (dealer left, dealer's partner)

**BiddingAI:**
- Simple hand evaluation (trump count, high cards)
- Conservative bidding (won't overbid)
- Doesn't consider position or partner yet
- Estimates tricks based on trump strength

### 2. Trick-Taking System

**TrickEngine:**
- Validates legal plays (must follow suit)
- Handles trump suit overrides
- Manages joker special rules
- Determines trick winner using TrumpRules

**TrickDisplay Widget:**
- Shows 4 cards in NESW compass layout
- Highlights current player
- Animates card play (optional in v1)
- Shows who won trick

**PlayAI:**
- Rule-based card selection
- Basic strategy: high when winning, low when losing
- Minimal partner coordination
- No card counting or advanced signals

### 3. Trump & Scoring

**TrumpRules:**
- Encapsulates all trump comparison logic
- Handles right bower, left bower, joker
- Determines effective suit of cards
- Used by both TrickEngine and PlayAI

**FiveHundredScorer:**
- Uses Avondale table for bid values
- Calculates contractor points (± bid value)
- Calculates opponent points (10/trick)
- Detects game over (500+ or -500)

### 4. State Management

**New GameState:**
- Supports 4 players (hands, names, positions)
- Tracks bidding history and current bid
- Tracks current trick and completed tricks
- Tracks tricks won per team
- Phase-based state (bidding, kitty, play, scoring)

**GameEngine:**
- Orchestrates entire game flow
- Manages AI turns with delays
- Coordinates between logic components
- Persists state between sessions

---

## Testing Strategy

### Unit Test Coverage

**Target: 80%+ coverage on game logic**

**Critical Test Areas:**
1. **Trump Rules:** All bower and joker scenarios
2. **Bidding Engine:** Auction rules, inkle, redeal
3. **Trick Engine:** Legal play validation, follow suit
4. **Scoring:** All Avondale values, made/failed contracts
5. **AI Bidding:** Hand evaluation accuracy
6. **AI Play:** Legal card selection, basic strategy

### Integration Tests

**Test Complete Game Flows:**
1. Full game (deal → bid → play → score → repeat)
2. Redeal scenario (all pass in bidding)
3. Player wins bid
4. AI wins bid
5. Contract made vs. failed
6. Game over (win/loss)

### Manual Testing Checklist

- [ ] Deal produces 45 cards correctly
- [ ] Bidding UI shows all valid options
- [ ] AI bidding is reasonable (not too high/low)
- [ ] Kitty exchange works for player
- [ ] Trump suit is applied correctly
- [ ] Can only play legal cards
- [ ] Joker rules enforced in no-trump
- [ ] Trick winner determined correctly
- [ ] Scores calculated correctly
- [ ] Game over at 500+ or -500
- [ ] Next hand rotates dealer
- [ ] State persists between app restarts

---

## Risk Mitigation

### High-Risk Areas

**Risk 1: AI Quality**
- **Concern:** Basic AI may be too weak or too strong
- **Mitigation:**
  - Start very simple (almost random)
  - Playtest and tune heuristics iteratively
  - Add difficulty levels later if needed

**Risk 2: Trick-Taking Logic Bugs**
- **Concern:** Trump, bower, joker rules are complex
- **Mitigation:**
  - Comprehensive unit tests for TrumpRules
  - Test all edge cases (left bower, joker in NT, etc.)
  - Manual testing with known scenarios

**Risk 3: State Complexity**
- **Concern:** 4 players, bidding, tricks = large state space
- **Mitigation:**
  - Immutable state with clear phase transitions
  - Extensive GameEngine tests
  - State persistence for debugging

**Risk 4: UI Complexity**
- **Concern:** Fitting 4 hands + trick on screen
- **Mitigation:**
  - Iterative UI design
  - Test on multiple screen sizes
  - Simplify layout (facedown opponent hands help)

**Risk 5: Game Flow Timing**
- **Concern:** AI turns need delays, but not too slow
- **Mitigation:**
  - Configurable delays
  - User testing for "feel"
  - Option to speed up AI later

### Medium-Risk Areas

**Risk 6: Persistence Migration**
- **Concern:** Existing cribbage save data incompatible
- **Mitigation:**
  - Complete replacement strategy
  - Clear all prefs on first run
  - Version check in persistence

**Risk 7: Testing Coverage**
- **Concern:** Not enough time for thorough testing
- **Mitigation:**
  - Write tests incrementally during development
  - Prioritize logic tests over UI tests
  - Automated test suite catches regressions

---

## Success Criteria

### Functional Requirements

- [ ] Complete playable game of 500
- [ ] 1 human + 3 AI players
- [ ] Full bidding system (6-10 in all suits/NT)
- [ ] Correct trump and bower handling
- [ ] Accurate scoring using Avondale table
- [ ] Game over at 500+ or -500
- [ ] State persistence (resume game)
- [ ] Basic but competent AI

### Technical Requirements

- [ ] No cribbage references in code
- [ ] Clean architecture (models → logic → engine → UI)
- [ ] 80%+ unit test coverage on logic
- [ ] All tests passing
- [ ] No compiler warnings
- [ ] App runs on Android, iOS, Web

### User Experience

- [ ] Clear, understandable UI
- [ ] Smooth game flow
- [ ] Helpful status messages
- [ ] Bid selection is intuitive
- [ ] Card selection is clear
- [ ] Scores are prominently displayed
- [ ] Game is fun to play

### Code Quality

- [ ] Consistent naming (no cribbage terminology)
- [ ] Documented complex logic (trump rules, scoring)
- [ ] No code duplication
- [ ] Clear separation of concerns
- [ ] Follows Flutter/Dart best practices

---

## Timeline Estimate

**Total: 40-60 hours**

| Phase | Tasks | Time Estimate |
|-------|-------|---------------|
| Phase 1: Foundation | Card model, 500 models, trump rules | 8-10 hours |
| Phase 2: Core Logic | Bidding, tricks, scoring, AI | 12-15 hours |
| Phase 3: State & Engine | GameState, GameEngine rewrite | 10-12 hours |
| Phase 4: UI Overhaul | Screens, widgets, dialogs | 8-10 hours |
| Phase 5: Testing & Polish | Tests, debugging, polish | 5-8 hours |

**Breakdown by Week (assuming 8-10 hours/week):**
- Week 1: Phase 1 (Foundation)
- Week 2-3: Phase 2 (Core Logic)
- Week 4: Phase 3 (State & Engine)
- Week 5: Phase 4 (UI Overhaul)
- Week 6: Phase 5 (Testing & Polish)

**Fast Track (assuming 15-20 hours/week):**
- Week 1: Phases 1-2
- Week 2: Phase 3
- Week 3: Phases 4-5

---

## Next Steps

### Immediate Actions

1. **Review & Approve Plan**
   - Confirm overall approach
   - Approve architecture decisions
   - Clarify any questions

2. **Set Up Development Environment**
   - Ensure Flutter SDK is up to date
   - Verify dependencies in `pubspec.yaml`
   - Run existing tests to confirm baseline

3. **Create Feature Branch**
   ```bash
   git checkout -b feature/convert-to-500
   ```

4. **Begin Phase 1**
   - Start with Task 1.1: Update Card Model
   - Write tests first (TDD approach)
   - Commit frequently

### Development Workflow

**Per Task:**
1. Write/update tests
2. Implement code
3. Run tests (`flutter test`)
4. Manual testing if UI-related
5. Commit with clear message
6. Move to next task

**Per Phase:**
1. Complete all tasks in phase
2. Run full test suite
3. Manual integration testing
4. Commit phase completion
5. Review before moving to next phase

---

## Appendices

### A. Avondale Scoring Table (Complete)

| Tricks | Spades | Clubs | Diamonds | Hearts | No Trump |
|--------|--------|-------|----------|--------|----------|
| 6      | 40     | 60    | 80       | 100    | 120      |
| 7      | 140    | 160   | 180      | 200    | 220      |
| 8      | 240    | 260   | 280      | 300    | 320      |
| 9      | 340    | 360   | 380      | 400    | 420      |
| 10     | 440    | 460   | 480      | 500    | 520      |

### B. Trump Order Reference

**In Trump Suit (e.g., Hearts):**
1. Joker (best bower)
2. J♥ (right bower)
3. J♦ (left bower - same color)
4. A♥
5. K♥
6. Q♥
7. 10♥
8. 9♥, 8♥, 7♥, 6♥, 5♥, 4♥

**In Same-Color Non-Trump (e.g., Diamonds when Hearts trump):**
1. A♦
2. K♦
3. Q♦
4. 10♦
5. 9♦, 8♦, 7♦, 6♦, 5♦, 4♦
(Note: J♦ is in trump suit)

**In Other Suits (e.g., Spades/Clubs when Hearts trump):**
1. A
2. K
3. Q
4. J
5. 10
6. 9, 8, 7, 6, 5, 4

### C. Follow Suit Rules

**Must follow suit if able:**
- If hearts led and you have any heart (including left bower if hearts trump), must play heart
- If unable to follow, can play any card
- Trump always wins over non-trump
- Highest trump wins
- If no trump played, highest card of led suit wins

**Joker in No-Trump:**
- Can only play if void in led suit
- When leading joker, must name suit (others must follow named suit)
- Joker always wins trick

### D. Key Differences from Cribbage

| Aspect | Cribbage | 500 |
|--------|----------|-----|
| **Players** | 2 players | 4 players (2 teams) |
| **Objective** | First to 121 points | First team to 500 points |
| **Deck** | 52 cards | 45 cards (with joker) |
| **Hand Size** | 6 cards (4 after crib) | 10 cards |
| **Game Type** | Counting points in hand | Trick-taking |
| **Bidding** | None | Central mechanic |
| **Trump** | None | Changes each hand |
| **Scoring** | Complex (15s, pairs, runs) | Contract-based |
| **Negative Scores** | No | Yes (can go negative) |
| **Win Condition** | > 121 points | > 500 or opponent < -500 |

---

**Document Version:** 1.0
**Last Updated:** 2025-01-26
**Author:** Claude Code (AI Assistant)
**Based On:** Flutter Cribbage codebase analysis + 500 game rules
