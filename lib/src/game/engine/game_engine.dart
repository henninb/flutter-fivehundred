import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/card.dart';
import '../models/game_models.dart';
import '../logic/deal_utils.dart';
import '../logic/bidding_engine.dart';
import '../logic/bidding_ai.dart';
import '../logic/trick_engine.dart';
import '../logic/play_ai.dart';
import '../logic/trump_rules.dart';
import '../logic/five_hundred_scorer.dart';
import '../logic/claim_analyzer.dart';
import '../../services/game_persistence.dart';
import 'game_state.dart';

/// Game engine for 500
///
/// Orchestrates the entire game flow:
/// 1. Setup & Deal
/// 2. Bidding (4-way auction)
/// 3. Kitty Exchange (contractor picks up and discards)
/// 4. Trick Play (10 tricks)
/// 5. Scoring
/// 6. Repeat or Game Over
class GameEngine extends ChangeNotifier {
  GameEngine({GamePersistence? persistence})
      : _persistence = persistence,
        _state = const GameState();

  // ignore: unused_field
  final GamePersistence? _persistence;
  GameState _state;

  GameState get state => _state;

  /// Get the current winner of the trick in progress
  /// Returns null if no trick is in progress or trick is empty
  Position? getCurrentTrickWinner() {
    if (_state.currentTrick == null || _state.currentTrick!.isEmpty) {
      return null;
    }

    final trumpRules = TrumpRules(trumpSuit: _state.trumpSuit);
    final trickEngine = TrickEngine(trumpRules: trumpRules);
    return trickEngine.getCurrentWinner(_state.currentTrick!);
  }

  // Timers for AI delays
  Timer? _aiTimer;

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    super.dispose();
  }

  // ============================================================================
  // GAME LIFECYCLE
  // ============================================================================

  /// Initialize game (load saved state if available)
  Future<void> initialize() async {
    // For now, just start fresh
    // TODO: Implement state persistence
    notifyListeners();
  }

  /// Start a new game
  void startNewGame() {
    _updateState(
      const GameState(
        gameStarted: true,
        currentPhase: GamePhase.setup,
        gameStatus: 'Tap Cut for Deal to determine dealer',
      ),
    );
    // Immediately show the cut for deal deck
    cutForDeal();
  }

  /// Perform cut for deal - show spread deck for player to tap
  void cutForDeal() {
    final deck = createDeck();

    // Initialize the spread deck and reset selection state
    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.cutForDeal,
        cutDeck: deck,
        cutCards: {},
        playerHasSelectedCutCard: false,
        gameStatus: 'Tap the deck to cut for dealer',
      ),
    );
  }

  /// Player selects a card from the spread deck
  void selectCutCard(int index) {
    if (_state.playerHasSelectedCutCard) {
      return; // Already selected
    }

    if (index < 0 || index >= _state.cutDeck.length) {
      return; // Invalid index
    }

    final deck = _state.cutDeck;
    final random = Random();

    // Player (South) selects their card
    final playerCard = deck[index];
    final cutCards = <Position, PlayingCard>{
      Position.south: playerCard,
    };
    final usedIndices = <int>{index};

    // AI players automatically select random cards (different from player's card)
    for (final position in [Position.north, Position.east, Position.west]) {
      int aiIndex;
      do {
        aiIndex = random.nextInt(deck.length);
      } while (usedIndices.contains(aiIndex));

      usedIndices.add(aiIndex);
      cutCards[position] = deck[aiIndex];
    }

    // Determine winner
    Position? highestPosition;
    int highestRank = -1;
    int highestSuit = 999; // Lower is better (hearts=0 is best)

    // First check if anyone drew the Joker - Joker always wins
    for (final entry in cutCards.entries) {
      if (entry.value.isJoker) {
        highestPosition = entry.key;
        break;
      }
    }

    // If no Joker, find highest card
    if (highestPosition == null) {
      for (final entry in cutCards.entries) {
        final card = entry.value;
        final position = entry.key;

        final rank = card.rank.index;
        final suit = card.suit.index;

        // Compare: higher rank wins, or if same rank, lower suit index wins (hearts=0 best)
        if (rank > highestRank || (rank == highestRank && suit < highestSuit)) {
          highestRank = rank;
          highestSuit = suit;
          highestPosition = position;
        }
      }
    }

    // Update state with results
    if (highestPosition != null) {
      final winnerName = _state.getName(highestPosition);
      final winningCard = cutCards[highestPosition]!;
      _updateState(
        _state.copyWith(
          cutCards: cutCards,
          playerHasSelectedCutCard: true,
          dealer: highestPosition,
          gameStatus:
              '$winnerName wins with ${winningCard.label} and will deal. Tap Deal to start.',
        ),
      );
    }
  }

  /// Deal cards
  void dealCards() {
    final deck = createDeck();
    final dealResult = dealHand(deck: deck, dealer: _state.dealer);

    // DEBUG: Log the deal
    _debugLog(
      '\n========== DEAL CARDS (Hand #${_state.handNumber + 1}) ==========',
    );
    _debugLog('Dealer: ${_state.dealer.name}');
    _debugLog('Deck size: ${deck.length}');

    // Check for Joker in each hand
    for (final position in Position.values) {
      final hand = dealResult.hands[position]!;
      final hasJoker = hand.any((card) => card.isJoker);
      _debugLog(
        '${position.name}: ${hand.length} cards${hasJoker ? ' ⭐ HAS JOKER' : ''}',
      );
      if (hasJoker) {
        _debugLog('  Cards: ${hand.map((c) => c.label).join(', ')}');
      }
    }

    final kittyHasJoker = dealResult.kitty.any((card) => card.isJoker);
    _debugLog(
      'Kitty: ${dealResult.kitty.length} cards${kittyHasJoker ? ' ⭐ HAS JOKER' : ''}',
    );
    if (kittyHasJoker) {
      _debugLog('  Cards: ${dealResult.kitty.map((c) => c.label).join(', ')}');
    }

    // Count total cards
    final totalCards =
        dealResult.hands.values.fold(0, (sum, hand) => sum + hand.length) +
            dealResult.kitty.length;
    _debugLog('Total cards dealt: $totalCards (should be 45)');

    // Count Jokers
    var jokerCount = 0;
    for (final hand in dealResult.hands.values) {
      jokerCount += hand.where((card) => card.isJoker).length;
    }
    jokerCount += dealResult.kitty.where((card) => card.isJoker).length;
    _debugLog('Total Jokers in deal: $jokerCount (should be 1)');
    _debugLog('========================================\n');

    // Sort player's hand by suit for easier viewing
    final sortedPlayerHand = sortHandBySuit(dealResult.hands[Position.south]!);

    _debugLog('⏱️ [TIMING] About to update state with dealt cards...');

    // Update state with dealt cards but skip dealing phase - go directly to bidding
    _updateState(
      _state.copyWith(
        playerHand: sortedPlayerHand,
        partnerHand: dealResult.hands[Position.north],
        opponentEastHand: dealResult.hands[Position.east],
        opponentWestHand: dealResult.hands[Position.west],
        kitty: dealResult.kitty,
        handNumber: _state.handNumber + 1,
        cutCards: {}, // Clear cut cards after dealing
      ),
    );

    _debugLog('⏱️ [TIMING] State updated, calling _startBidding()...');

    // Start bidding immediately (will set phase to bidding)
    _startBidding();

    _debugLog('⏱️ [TIMING] _startBidding() completed');
  }

  // ============================================================================
  // TEST HANDS (Debug/Testing Support)
  // ============================================================================

  /// Apply a test hand to the South player
  ///
  /// This is a debug/testing feature that replaces the player's current hand
  /// with a specific set of cards. The remaining cards are redistributed to
  /// other players and the kitty.
  ///
  /// Can only be called during the bidding phase before the player has bid.
  void applyTestHand(List<PlayingCard> testHand) {
    if (_state.currentPhase != GamePhase.bidding) {
      _debugLog('⚠️ Cannot apply test hand - not in bidding phase');
      return;
    }

    if (testHand.length != 10) {
      _debugLog(
        '⚠️ Cannot apply test hand - must have exactly 10 cards (got ${testHand.length})',
      );
      return;
    }

    _debugLog('\n========== APPLYING TEST HAND ==========');
    _debugLog('Test hand: ${testHand.map((c) => c.label).join(', ')}');

    // Get all cards from all hands AND kitty (45 total: 4 hands * 10 + 5 kitty)
    final allCards = <PlayingCard>[
      ..._state.playerHand,
      ..._state.partnerHand,
      ..._state.opponentEastHand,
      ..._state.opponentWestHand,
      ..._state.kitty,
    ];

    _debugLog('Total cards before redistribution: ${allCards.length}');

    // VALIDATION: Verify test hand cards exist in the current deal
    final deck = createDeck();
    for (final testCard in testHand) {
      final existsInDeck = deck.any(
        (deckCard) => deckCard.rank == testCard.rank && deckCard.suit == testCard.suit,
      );
      if (!existsInDeck) {
        _debugLog('⚠️ ERROR: Test hand contains invalid card: ${testCard.label}');
        _debugLog('⚠️ Test hand rejected - all cards must be from standard deck');
        return;
      }
    }

    // VALIDATION: Check for duplicate cards in test hand
    final testHandSet = <String>{};
    for (final card in testHand) {
      final key = '${card.rank.name}_${card.suit.name}';
      if (testHandSet.contains(key)) {
        _debugLog('⚠️ ERROR: Test hand contains duplicate card: ${card.label}');
        _debugLog('⚠️ Test hand rejected - no duplicates allowed');
        return;
      }
      testHandSet.add(key);
    }

    // Remove test hand cards from available pool
    final availableCards = <PlayingCard>[];
    for (final card in allCards) {
      // Check if this card is in the test hand
      final isInTestHand = testHand.any(
        (testCard) => testCard.rank == card.rank && testCard.suit == card.suit,
      );
      if (!isInTestHand) {
        availableCards.add(card);
      }
    }

    _debugLog('Available cards after removing test hand: ${availableCards.length} (should be 35)');

    // Shuffle available cards
    availableCards.shuffle(Random());

    // Distribute to other players (10 cards each) and kitty (5 cards)
    final newPartnerHand = availableCards.sublist(0, 10);
    final newEastHand = availableCards.sublist(10, 20);
    final newWestHand = availableCards.sublist(20, 30);
    final newKitty = availableCards.sublist(30, 35);

    // Sort hands
    final sortedTestHand = sortHandBySuit(testHand);

    _debugLog('✅ Test hand applied successfully');
    _debugLog('New kitty: ${newKitty.map((c) => c.label).join(', ')}');
    _debugLog('========================================\n');

    // Update state with new hands
    _updateState(
      _state.copyWith(
        playerHand: sortedTestHand,
        partnerHand: newPartnerHand,
        opponentEastHand: newEastHand,
        opponentWestHand: newWestHand,
        kitty: newKitty,
        gameStatus: 'Test hand applied - make your bid',
      ),
    );
  }

  // ============================================================================
  // BIDDING PHASE
  // ============================================================================

  void _startBidding() {
    _debugLog('⏱️ [TIMING] _startBidding() called');

    final biddingEngine = BiddingEngine(dealer: _state.dealer);
    final biddingOrder = biddingEngine.getBiddingOrder();

    _debugLog('⏱️ [TIMING] First bidder: ${biddingOrder.first.name}');

    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.bidding,
        isBiddingPhase: true,
        bidHistory: [],
        currentBidder: biddingOrder.first,
        gameStatus: 'Bidding: ${_state.getName(biddingOrder.first)}',
        clearCurrentHighBid: true,
        clearWinningBid: true,
        clearContractor: true,
      ),
    );

    _debugLog('⏱️ [TIMING] State updated to bidding phase');

    // If first bidder is AI, trigger AI bidding
    if (biddingOrder.first != Position.south) {
      _debugLog('⏱️ [TIMING] First bidder is AI, scheduling AI bid');
      _scheduleAIBid();
    } else {
      _debugLog('⏱️ [TIMING] First bidder is PLAYER, showing bidding dialog');
      _updateState(_state.copyWith(showBiddingDialog: true));
      _debugLog('⏱️ [TIMING] showBiddingDialog set to true');
    }
  }

  /// Player submits a bid
  void submitPlayerBid(Bid? bid, {bool isInkle = false}) {
    if (_state.currentBidder != Position.south) return;

    final biddingEngine = BiddingEngine(dealer: _state.dealer);

    // Validate bid
    final validation = biddingEngine.validateBid(
      bidder: Position.south,
      proposedBid: bid,
      currentBids: _state.bidHistory,
      isInkle: isInkle,
    );

    if (!validation.isValid) {
      // Log bid validation failure
      _debugLog('\n[BID VALIDATION FAILED]');
      _debugLog('Player: ${_state.getName(Position.south)}');
      _debugLog('Attempted bid: ${bid != null ? '${bid.tricks}${bid.suit.name}' : 'PASS'}');
      _debugLog('Is Inkle: $isInkle');
      _debugLog('Current high bid: ${_state.currentHighBid != null ? '${_state.currentHighBid!.tricks}${_state.currentHighBid!.suit.name}' : 'none'}');
      _debugLog('Reason: ${validation.errorMessage ?? 'Invalid bid'}');
      _debugLog('Bid history: ${_state.bidHistory.map((e) => e.toString()).join(', ')}');

      _updateState(
        _state.copyWith(
          gameStatus: validation.errorMessage ?? 'Invalid bid',
        ),
      );
      return;
    }

    // Add bid to history
    final action = bid == null
        ? BidAction.pass
        : (isInkle ? BidAction.inkle : BidAction.bid);
    final entry = BidEntry(bidder: Position.south, action: action, bid: bid);

    _addBidEntry(entry);
    _updateState(_state.copyWith(showBiddingDialog: false));

    // Check if auction complete
    _checkAuctionComplete();
  }

  /// AI makes a bid
  void _scheduleAIBid() {
    if (_state.currentBidder == null) return;
    if (_state.currentBidder == Position.south) return;

    _updateState(
      _state.copyWith(
        aiThinkingPosition: _state.currentBidder,
      ),
    );

    _aiTimer?.cancel();
    _aiTimer = Timer(const Duration(milliseconds: 400), () {
      _executeAIBid();
    });
  }

  void _executeAIBid() {
    final position = _state.currentBidder;
    if (position == null || position == Position.south) return;

    final hand = _state.getHand(position);
    final biddingEngine = BiddingEngine(dealer: _state.dealer);

    // Get AI decision
    final decision = BiddingAI.chooseBid(
      hand: hand,
      currentBids: _state.bidHistory,
      position: position,
      canInkle: biddingEngine.canInkle(position, _state.bidHistory),
    );

    // Add bid to history
    final entry = BidEntry(
      bidder: position,
      action: decision.action,
      bid: decision.bid,
    );

    _addBidEntry(entry);

    // Check if auction complete
    _checkAuctionComplete();
  }

  void _addBidEntry(BidEntry entry) {
    final newHistory = [..._state.bidHistory, entry];

    // Update high bid if this is a real bid (not pass, not inkle)
    Bid? newHighBid = _state.currentHighBid;
    if (entry.bid != null && entry.action == BidAction.bid) {
      if (newHighBid == null || entry.bid!.beats(newHighBid)) {
        newHighBid = entry.bid;
      }
    }

    _updateState(
      _state.copyWith(
        bidHistory: newHistory,
        currentHighBid: newHighBid,
        pendingBidEntry: entry,
        gameStatus: entry.toString(),
        clearAiThinkingPosition: true,
      ),
    );
  }

  void _checkAuctionComplete() {
    final biddingEngine = BiddingEngine(dealer: _state.dealer);

    if (!biddingEngine.isComplete(_state.bidHistory)) {
      // More bids needed - advance to next bidder
      final nextBidder = biddingEngine.getNextBidder(_state.bidHistory);
      _updateState(
        _state.copyWith(
          currentBidder: nextBidder,
          gameStatus: nextBidder != null
              ? 'Bidding: ${_state.getName(nextBidder)}'
              : 'Auction complete',
        ),
      );

      if (nextBidder != null && nextBidder != Position.south) {
        _scheduleAIBid();
      } else if (nextBidder == Position.south) {
        _updateState(_state.copyWith(showBiddingDialog: true));
      }
      return;
    }

    // Auction complete - determine result
    final result = biddingEngine.determineWinner(_state.bidHistory);

    switch (result.status) {
      case AuctionStatus.won:
        _updateState(
          _state.copyWith(
            isBiddingPhase: false,
            winningBid: result.winningBid,
            contractor: result.winner,
            gameStatus: result.message,
            clearCurrentBidder: true,
          ),
        );
        // Start kitty exchange
        Future.delayed(const Duration(milliseconds: 1000), _startKittyExchange);
        break;

      case AuctionStatus.redeal:
        // Stay in bidding phase and redeal without leaving the bid screen
        _updateState(
          _state.copyWith(
            gameStatus: result.message,
          ),
        );
        // Redeal after delay, then restart bidding
        Future.delayed(const Duration(milliseconds: 1500), () {
          dealCards();
          // After dealing, restart bidding automatically
          Future.delayed(const Duration(milliseconds: 500), _startBidding);
        });
        break;

      case AuctionStatus.incomplete:
        // Shouldn't happen, but just in case
        break;
    }
  }

  // ============================================================================
  // KITTY EXCHANGE
  // ============================================================================

  void _startKittyExchange() {
    final contractor = _state.contractor;
    if (contractor == null) return;

    _debugLog('\n========== KITTY EXCHANGE ==========');
    _debugLog('Contractor: ${_state.getName(contractor)} (${contractor.name})');
    _debugLog('Kitty cards: ${_state.kitty.map((c) => c.label).join(', ')}');

    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.kittyExchange,
        gameStatus: '${_state.getName(contractor)} exchanges kitty',
      ),
    );

    if (contractor == Position.south) {
      // Player picks up kitty
      _debugLog('Player hand before kitty: ${_state.playerHand.length} cards');
      final kittyHasJoker = _state.kitty.any((c) => c.isJoker);
      final handHasJoker = _state.playerHand.any((c) => c.isJoker);
      _debugLog(
        'Hand has Joker: $handHasJoker, Kitty has Joker: $kittyHasJoker',
      );

      final newHand = [..._state.playerHand, ..._state.kitty];
      _debugLog('Player hand after kitty: ${newHand.length} cards');

      // Sort hand with trump consideration (we know trump from winning bid)
      final trumpSuit = _getBidSuitAsTrumpSuit();
      final sortedHand = sortHandBySuit(newHand, trumpSuit: trumpSuit);

      _updateState(
        _state.copyWith(
          playerHand: sortedHand,
          kitty: [],
          gameStatus: 'Select 5 cards to discard',
        ),
      );
    } else {
      // AI picks up kitty and discards
      Future.delayed(
        const Duration(milliseconds: 1000),
        _executeAIKittyExchange,
      );
    }
  }

  void _executeAIKittyExchange() {
    final contractor = _state.contractor;
    if (contractor == null || contractor == Position.south) return;

    var hand = _state.getHand(contractor);
    hand = [...hand, ..._state.kitty];

    // AI strategy: Keep highest cards (simple for now)
    // TODO: Improve AI to keep trump and high cards in trump suit
    final trumpRules = TrumpRules(trumpSuit: _getBidSuitAsTrumpSuit());
    hand.sort((a, b) => trumpRules.compare(b, a)); // Sort high to low

    final kept = hand.take(10).toList();

    // Update hand
    switch (contractor) {
      case Position.north:
        _updateState(_state.copyWith(partnerHand: kept));
        break;
      case Position.east:
        _updateState(_state.copyWith(opponentEastHand: kept));
        break;
      case Position.west:
        _updateState(_state.copyWith(opponentWestHand: kept));
        break;
      case Position.south:
        break; // Already handled
    }

    _startPlay();
  }

  /// Player confirms kitty exchange (discards selected 5 cards)
  void confirmKittyExchange() {
    if (_state.contractor != Position.south) return;

    // Must have exactly 5 cards selected
    if (_state.selectedCardIndices.length != 5) {
      _updateState(
        _state.copyWith(
          gameStatus: 'Must select exactly 5 cards to discard',
        ),
      );
      return;
    }

    // DEBUG: Log discarded cards
    _debugLog('Player discarding ${_state.selectedCardIndices.length} cards:');
    final discardedCards = <PlayingCard>[];
    for (final index in _state.selectedCardIndices) {
      final card = _state.playerHand[index];
      discardedCards.add(card);
      _debugLog('  - ${card.label}${card.isJoker ? ' ⭐' : ''}');
    }

    // Remove selected cards from hand
    final newHand = <PlayingCard>[];
    for (int i = 0; i < _state.playerHand.length; i++) {
      if (!_state.selectedCardIndices.contains(i)) {
        newHand.add(_state.playerHand[i]);
      }
    }

    // Should have exactly 10 cards remaining
    if (newHand.length != 10) {
      _updateState(
        _state.copyWith(
          gameStatus: 'Error: Wrong number of cards after discard',
        ),
      );
      return;
    }

    _debugLog('Player hand after discard: ${newHand.length} cards');
    final hasJoker = newHand.any((c) => c.isJoker);
    _debugLog('Hand has Joker: $hasJoker');
    _debugLog('========================================\n');

    // Update state and start play
    _updateState(
      _state.copyWith(
        playerHand: newHand,
        clearSelectedCardIndices: true,
        gameStatus: 'Discarded 5 cards',
      ),
    );

    _startPlay();
  }

  /// Player toggles card selection for kitty exchange
  void toggleCardSelection(int index) {
    if (_state.currentPhase != GamePhase.kittyExchange) return;
    if (_state.contractor != Position.south) return;

    final selectedIndices = Set<int>.from(_state.selectedCardIndices);

    // Toggle: if already selected, deselect; otherwise select
    if (selectedIndices.contains(index)) {
      selectedIndices.remove(index);
    } else {
      // Only allow selecting up to 5 cards
      if (selectedIndices.length < 5) {
        selectedIndices.add(index);
      }
    }

    final remaining = 5 - selectedIndices.length;
    final statusMessage = remaining == 0
        ? 'Click Discard to continue'
        : 'Select $remaining more card(s) to discard';

    _updateState(
      _state.copyWith(
        selectedCardIndices: selectedIndices,
        gameStatus: statusMessage,
      ),
    );
  }

  Suit? _getBidSuitAsTrumpSuit() {
    if (_state.winningBid == null) return null;
    switch (_state.winningBid!.suit) {
      case BidSuit.spades:
        return Suit.spades;
      case BidSuit.clubs:
        return Suit.clubs;
      case BidSuit.diamonds:
        return Suit.diamonds;
      case BidSuit.hearts:
        return Suit.hearts;
      case BidSuit.noTrump:
        return null;
    }
  }

  // ============================================================================
  // PLAY PHASE
  // ============================================================================

  void _startPlay() {
    final trumpSuit = _getBidSuitAsTrumpSuit();
    final leader = _state.contractor!; // Contractor leads

    // DEBUG: Verify all hands before play starts
    _debugLog('\n========== START PLAY PHASE ==========');
    _debugLog('Contractor: ${_state.getName(leader)} (${leader.name})');
    _debugLog('Trump: ${trumpSuit?.name ?? 'No Trump'}');
    _debugLog('\nHand verification:');
    var totalCards = 0;
    var jokerCount = 0;
    for (final position in Position.values) {
      final hand = _state.getHand(position);
      final hasJoker = hand.any((c) => c.isJoker);
      jokerCount += hand.where((c) => c.isJoker).length;
      totalCards += hand.length;
      _debugLog(
        '${_state.getName(position)}: ${hand.length} cards${hasJoker ? ' ⭐ HAS JOKER' : ''}',
      );
    }
    _debugLog('Total cards: $totalCards (should be 40)');
    _debugLog('Total Jokers: $jokerCount (should be 1)');
    if (totalCards != 40) {
      _debugLog('⚠️ WARNING: Card count mismatch!');
    }
    if (jokerCount != 1) {
      _debugLog('⚠️ WARNING: Joker count mismatch!');
    }
    _debugLog('========================================\n');

    // Re-sort player's hand with trump consideration
    // (In case player wasn't contractor and hand still sorted by natural suits)
    final sortedPlayerHand =
        sortHandBySuit(_state.playerHand, trumpSuit: trumpSuit);

    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.play,
        isPlayPhase: true,
        trumpSuit: trumpSuit,
        playerHand: sortedPlayerHand,
        currentTrick: Trick(plays: [], leader: leader, trumpSuit: trumpSuit),
        completedTricks: [],
        tricksWonNS: 0,
        tricksWonEW: 0,
        currentPlayer: leader,
        gameStatus: '${_state.getName(leader)} leads',
        clearSelectedCardIndices: true,
      ),
    );

    // Update claim status at start of play
    _updateClaimStatus();

    // If AI leads, schedule AI play
    if (leader != Position.south) {
      _scheduleAIPlay();
    }
  }

  /// Player plays a card
  void playCard(int cardIndex) {
    if (_state.currentPlayer != Position.south) return;
    if (_state.currentTrick == null) return;

    final card = _state.playerHand[cardIndex];
    final trumpRules = TrumpRules(trumpSuit: _state.trumpSuit);
    final trickEngine = TrickEngine(trumpRules: trumpRules);

    // Check if player is leading with joker in no-trump - needs suit nomination
    if (card.isJoker &&
        _state.currentTrick!.isEmpty &&
        _state.trumpSuit == null) {
      // Store card index and show suit nomination dialog
      _updateState(
        _state.copyWith(
          showSuitNominationDialog: true,
          pendingCardIndex: cardIndex,
          gameStatus: 'Nominate a suit for the Joker',
        ),
      );
      return;
    }

    // DEBUG: Log card play
    final suitInfo = card.isJoker ? '⭐ JOKER' : '(${card.suit.name})';
    _debugLog(
      '[PLAY] ${_state.getName(Position.south)} plays ${card.label} $suitInfo (hand size before: ${_state.playerHand.length})',
    );

    // Play the card
    final result = trickEngine.playCard(
      currentTrick: _state.currentTrick!,
      card: card,
      player: Position.south,
      playerHand: _state.playerHand,
      nominatedSuit: _state.nominatedSuit,
    );

    if (result.status == TrickStatus.error) {
      _updateState(_state.copyWith(gameStatus: result.message));
      return;
    }

    // Remove card from hand
    final newHand = List<PlayingCard>.from(_state.playerHand);
    newHand.removeAt(cardIndex);

    _debugLog(
      '[PLAY] ${_state.getName(Position.south)} hand size after: ${newHand.length}',
    );

    _updateState(
      _state.copyWith(
        playerHand: newHand,
        currentTrick: result.trick,
        gameStatus: result.message,
        clearSelectedCardIndices: true,
      ),
    );

    if (result.status == TrickStatus.complete) {
      _handleTrickComplete(result.trick, result.winner!);
    } else {
      // Advance to next player
      _advanceToNextPlayer();
    }
  }

  /// Confirm card play after suit nomination
  void confirmCardPlayWithNominatedSuit(Suit nominatedSuit) {
    final cardIndex = _state.pendingCardIndex;
    if (cardIndex == null) return;

    // Close dialog and set nominated suit
    _updateState(
      _state.copyWith(
        showSuitNominationDialog: false,
        nominatedSuit: nominatedSuit,
        clearPendingCardIndex: true,
      ),
    );

    // Now play the card with the nominated suit
    final card = _state.playerHand[cardIndex];
    final trumpRules = TrumpRules(trumpSuit: _state.trumpSuit);
    final trickEngine = TrickEngine(trumpRules: trumpRules);

    // DEBUG: Log card play
    _debugLog(
      '[PLAY] ${_state.getName(Position.south)} plays ${card.label} ⭐ JOKER (nominated suit: ${nominatedSuit.name}) (hand size before: ${_state.playerHand.length})',
    );

    // Play the card with nominated suit
    final result = trickEngine.playCard(
      currentTrick: _state.currentTrick!,
      card: card,
      player: Position.south,
      playerHand: _state.playerHand,
      nominatedSuit: nominatedSuit,
    );

    if (result.status == TrickStatus.error) {
      _updateState(_state.copyWith(gameStatus: result.message));
      return;
    }

    // Remove card from hand
    final newHand = List<PlayingCard>.from(_state.playerHand);
    newHand.removeAt(cardIndex);

    _debugLog(
      '[PLAY] ${_state.getName(Position.south)} hand size after: ${newHand.length}',
    );

    _updateState(
      _state.copyWith(
        playerHand: newHand,
        currentTrick: result.trick,
        gameStatus: result.message,
        clearSelectedCardIndices: true,
      ),
    );

    if (result.status == TrickStatus.complete) {
      _handleTrickComplete(result.trick, result.winner!);
    } else {
      // Advance to next player
      _advanceToNextPlayer();
    }
  }

  void _advanceToNextPlayer() {
    final nextPlayer = _state.currentPlayer!.next;
    _updateState(
      _state.copyWith(
        currentPlayer: nextPlayer,
        gameStatus: '${_state.getName(nextPlayer)}\'s turn',
      ),
    );

    if (nextPlayer != Position.south) {
      _scheduleAIPlay();
    }
  }

  /// Update the claim status - check if player can claim all remaining tricks
  void _updateClaimStatus() {
    // Only during play phase
    if (!_state.isPlayPhase || _state.playerHand.isEmpty) {
      if (_state.canPlayerClaimRemainingTricks) {
        _updateState(_state.copyWith(canPlayerClaimRemainingTricks: false));
      }
      return;
    }

    final trumpRules = TrumpRules(trumpSuit: _state.trumpSuit);
    final analyzer = ClaimAnalyzer(
      playerHand: _state.playerHand,
      otherHands: {
        Position.north: _state.partnerHand,
        Position.east: _state.opponentEastHand,
        Position.west: _state.opponentWestHand,
      },
      trumpRules: trumpRules,
      completedTricks: _state.completedTricks,
      currentTrick: _state.currentTrick,
      currentPlayer: _state.currentPlayer,
    );

    final canClaim = analyzer.canClaimRemainingTricks();

    if (canClaim != _state.canPlayerClaimRemainingTricks) {
      _updateState(_state.copyWith(canPlayerClaimRemainingTricks: canClaim));
      if (canClaim) {
        _debugLog('✨ Player can now claim all remaining tricks!');
      }
    }
  }

  /// Claim remaining tricks - auto-play through them with animations
  Future<void> claimRemainingTricks() async {
    if (!_state.canPlayerClaimRemainingTricks) {
      _updateState(
        _state.copyWith(
          gameStatus: 'Cannot claim - not guaranteed to win all tricks',
        ),
      );
      return;
    }

    // Validate game state before starting claim
    final totalCardsRemaining =
        _state.playerHand.length +
        _state.partnerHand.length +
        _state.opponentEastHand.length +
        _state.opponentWestHand.length;

    final tricksRemaining = 10 - _state.completedTricks.length;
    final currentTrickCards = _state.currentTrick?.plays.length ?? 0;
    final cardsNeeded = (tricksRemaining * 4) - currentTrickCards;

    if (totalCardsRemaining != cardsNeeded) {
      _debugLog('⚠️ ERROR: Invalid game state before claim');
      _debugLog('  Total cards remaining: $totalCardsRemaining');
      _debugLog('  Cards needed: $cardsNeeded');
      _debugLog('  Tricks remaining: $tricksRemaining');
      _debugLog('  Current trick cards: $currentTrickCards');
      _updateState(
        _state.copyWith(
          gameStatus: 'Cannot claim - invalid game state detected',
          canPlayerClaimRemainingTricks: false,
        ),
      );
      return;
    }

    // Immediately hide the claim button to prevent multiple clicks
    _updateState(_state.copyWith(canPlayerClaimRemainingTricks: false));

    _debugLog('\n========== CLAIMING REMAINING TRICKS ==========');
    _debugLog('Player claims they will win all remaining tricks');
    _debugLog('Cards in hand: ${_state.playerHand.length}');
    _debugLog('Starting from trick ${_state.completedTricks.length + 1}');
    _debugLog('Validated: $totalCardsRemaining cards for $cardsNeeded slots');

    // Safety: track iterations to prevent infinite loops
    int outerLoopIterations = 0;
    const maxOuterIterations = 50; // Should never need more than ~15

    // Auto-play through remaining tricks until we have 10
    while (_state.completedTricks.length < 10) {
      outerLoopIterations++;
      if (outerLoopIterations > maxOuterIterations) {
        _debugLog('⚠️ ERROR: Claim exceeded max iterations. Aborting.');
        _updateState(
          _state.copyWith(
            gameStatus: 'Error during claim - please continue manually',
          ),
        );
        return;
      }

      // Safety check: ensure we still have cards to play
      final totalCardsRemaining =
          _state.playerHand.length +
          _state.partnerHand.length +
          _state.opponentEastHand.length +
          _state.opponentWestHand.length;

      if (totalCardsRemaining == 0 && _state.completedTricks.length < 10) {
        _debugLog(
            '⚠️ ERROR: No cards remaining but only ${_state.completedTricks.length} tricks completed',);
        _updateState(
          _state.copyWith(
            gameStatus: 'Error during claim - cards exhausted early',
          ),
        );
        return;
      }

      // If current trick is not complete, finish it
      if (_state.currentTrick != null && !_state.currentTrick!.isComplete) {
        final success = await _autoPlayCurrentTrick();
        if (!success) {
          _debugLog('⚠️ ERROR: Failed to complete trick during claim');
          _debugLog('⚠️ Re-enabling manual play for recovery');
          // Re-evaluate claim status to potentially re-enable button or allow manual play
          _updateClaimStatus();
          return;
        }
      } else if (_state.completedTricks.length < 10) {
        // Start a new trick
        // Determine who leads (winner of last trick or current leader)
        Position leader;
        if (_state.completedTricks.isEmpty) {
          leader = _state.currentPlayer ?? _state.contractor!;
        } else {
          // Get winner of last trick
          final trumpRules = TrumpRules(trumpSuit: _state.trumpSuit);
          final trickEngine = TrickEngine(trumpRules: trumpRules);
          final winner = trickEngine.getCurrentWinner(_state.completedTricks.last);

          // Safety check: winner should never be null for a completed trick
          if (winner == null) {
            _debugLog('⚠️ ERROR: Cannot determine winner of last trick during claim');
            _debugLog('⚠️ Re-enabling manual play for recovery');
            _updateState(
              _state.copyWith(
                gameStatus: 'Error: Cannot determine trick winner - continue manually',
              ),
            );
            _updateClaimStatus();
            return;
          }

          leader = winner;
        }

        _debugLog(
            'Starting trick ${_state.completedTricks.length + 1}, ${_state.getName(leader)} leads',);

        _updateState(
          _state.copyWith(
            currentTrick: Trick(
              plays: [],
              leader: leader,
              trumpSuit: _state.trumpSuit,
            ),
            currentPlayer: leader,
          ),
        );

        final success = await _autoPlayCurrentTrick();
        if (!success) {
          _debugLog('⚠️ ERROR: Failed to complete trick during claim');
          _debugLog('⚠️ Re-enabling manual play for recovery');
          // Re-evaluate claim status to potentially re-enable button or allow manual play
          _updateClaimStatus();
          return;
        }
      }
    }

    _debugLog('✅ Claim complete - all 10 tricks played');
    _debugLog('===============================================\n');
  }

  /// Auto-play the current trick (called during claim)
  /// Returns true if successful, false if error occurred
  Future<bool> _autoPlayCurrentTrick() async {
    // DEBUG: Log hand sizes at start of trick
    _debugLog(
        '  Hand sizes: South=${_state.playerHand.length}, North=${_state.partnerHand.length}, '
        'East=${_state.opponentEastHand.length}, West=${_state.opponentWestHand.length}');

    // Safety: track iterations to prevent infinite loops within a trick
    int innerLoopIterations = 0;
    const maxInnerIterations = 10; // Should only need 4 (one per player)

    while (_state.currentTrick != null && !_state.currentTrick!.isComplete) {
      innerLoopIterations++;
      if (innerLoopIterations > maxInnerIterations) {
        _debugLog('⚠️ ERROR: Trick auto-play exceeded max iterations');
        _updateState(
          _state.copyWith(
            gameStatus: 'Error during trick auto-play',
          ),
        );
        return false;
      }

      // Safety: check current player is valid
      if (_state.currentPlayer == null) {
        _debugLog('⚠️ ERROR: Current player is null during auto-play');
        _updateState(
          _state.copyWith(
            gameStatus: 'Error: Invalid game state during claim',
          ),
        );
        return false;
      }

      final position = _state.currentPlayer!;
      final hand = _state.getHand(position);

      // Safety: check hand is not empty
      if (hand.isEmpty) {
        _debugLog(
            '⚠️ ERROR: ${_state.getName(position)} has no cards but trick not complete',);
        _updateState(
          _state.copyWith(
            gameStatus: 'Error: Player has no cards during claim',
          ),
        );
        return false;
      }

      final trumpRules = TrumpRules(trumpSuit: _state.trumpSuit);
      final trickEngine = TrickEngine(trumpRules: trumpRules);

      // Choose card to play
      final card = PlayAI.chooseCard(
        hand: hand,
        currentTrick: _state.currentTrick!,
        trumpRules: trumpRules,
        position: position,
        partner: position.partner,
        trickEngine: trickEngine,
      );

      _debugLog(
          '  ${_state.getName(position)} plays ${card.label} (${hand.length} cards in hand)',);

      // Play the card
      final result = trickEngine.playCard(
        currentTrick: _state.currentTrick!,
        card: card,
        player: position,
        playerHand: hand,
      );

      // Safety: check for play errors
      if (result.status == TrickStatus.error) {
        _debugLog('⚠️ ERROR: ${result.message}');
        _updateState(
          _state.copyWith(
            gameStatus: 'Error playing card: ${result.message}',
          ),
        );
        return false;
      }

      // Remove card from hand
      final newHand = List<PlayingCard>.from(hand);
      final wasRemoved = newHand.remove(card);

      // Safety: verify card was actually in the hand
      if (!wasRemoved) {
        _debugLog(
            '⚠️ ERROR: Card ${card.label} not found in ${_state.getName(position)} hand',);
        _updateState(
          _state.copyWith(
            gameStatus: 'Error: Card not found in hand',
          ),
        );
        return false;
      }

      // Update the appropriate hand
      switch (position) {
        case Position.north:
          _updateState(_state.copyWith(partnerHand: newHand));
          break;
        case Position.east:
          _updateState(_state.copyWith(opponentEastHand: newHand));
          break;
        case Position.west:
          _updateState(_state.copyWith(opponentWestHand: newHand));
          break;
        case Position.south:
          _updateState(_state.copyWith(playerHand: newHand));
          break;
      }

      _updateState(
        _state.copyWith(
          currentTrick: result.trick,
          gameStatus:
              'Auto-playing: ${_state.getName(position)} plays ${card.label}',
        ),
      );

      // Brief delay for animation
      await Future.delayed(const Duration(milliseconds: 400));

      if (result.status == TrickStatus.complete) {
        // Trick complete - update state
        if (result.winner == null) {
          _debugLog('⚠️ ERROR: Trick complete but winner is null');
          _updateState(
            _state.copyWith(
              gameStatus: 'Error: Cannot determine trick winner',
            ),
          );
          return false;
        }

        final winner = result.winner!;
        final newCompleted = [..._state.completedTricks, result.trick];

        _debugLog('  Trick ${newCompleted.length} won by ${_state.getName(winner)}');
        _debugLog(
            '  Hand sizes after trick: South=${_state.playerHand.length}, North=${_state.partnerHand.length}, '
            'East=${_state.opponentEastHand.length}, West=${_state.opponentWestHand.length}');

        // Safety: verify we don't exceed 10 tricks
        if (newCompleted.length > 10) {
          _debugLog('⚠️ ERROR: Exceeded 10 tricks!');
          _updateState(
            _state.copyWith(
              gameStatus: 'Error: Too many tricks completed',
            ),
          );
          return false;
        }

        final winnerTeam = winner.team;
        var newTricksNS = _state.tricksWonNS;
        var newTricksEW = _state.tricksWonEW;

        if (winnerTeam == Team.northSouth) {
          newTricksNS++;
        } else {
          newTricksEW++;
        }

        _updateState(
          _state.copyWith(
            completedTricks: newCompleted,
            tricksWonNS: newTricksNS,
            tricksWonEW: newTricksEW,
            gameStatus: '${_state.getName(winner)} wins trick',
          ),
        );

        // Delay before next trick
        await Future.delayed(const Duration(milliseconds: 600));

        // Check if all tricks complete
        if (newCompleted.length == 10) {
          _debugLog('All 10 tricks complete - scoring hand');
          _verifyAllCardsUnique(newCompleted);
          await Future.delayed(const Duration(milliseconds: 1000));
          _scoreHand();
          return true;
        }

        // Safety: Check if winner has cards before starting next trick
        final winnerHand = _state.getHand(winner);
        if (winnerHand.isEmpty) {
          _debugLog(
              '⚠️ ERROR: Trick winner ${_state.getName(winner)} has no cards to lead next trick',);
          _updateState(
            _state.copyWith(
              gameStatus:
                  'Error: Trick winner has no cards - game state corrupted',
            ),
          );
          return false;
        }

        // Start next trick with winner leading
        _updateState(
          _state.copyWith(
            currentTrick: Trick(
              plays: [],
              leader: winner,
              trumpSuit: _state.trumpSuit,
            ),
            currentPlayer: winner,
            clearNominatedSuit: true,
          ),
        );

        // Exit this trick's loop - outer loop will call us again for next trick
        return true;
      } else {
        // Advance to next player
        _updateState(
          _state.copyWith(
            currentPlayer: _state.currentPlayer!.next,
          ),
        );
      }
    }

    // Loop exited normally (trick complete)
    return true;
  }

  void _scheduleAIPlay() {
    _updateState(_state.copyWith(aiThinkingPosition: _state.currentPlayer));

    _aiTimer?.cancel();
    _aiTimer = Timer(const Duration(milliseconds: 600), _executeAIPlay);
  }

  void _executeAIPlay() {
    final position = _state.currentPlayer;
    if (position == null || position == Position.south) return;
    if (_state.currentTrick == null) return;

    final hand = _state.getHand(position);
    final trumpRules = TrumpRules(trumpSuit: _state.trumpSuit);
    final trickEngine = TrickEngine(trumpRules: trumpRules);

    // DEBUG: Log hand size before
    _debugLog(
      '[PLAY] ${_state.getName(position)} hand size before: ${hand.length}',
    );

    // AI chooses card
    final card = PlayAI.chooseCard(
      hand: hand,
      currentTrick: _state.currentTrick!,
      trumpRules: trumpRules,
      position: position,
      partner: position.partner,
      trickEngine: trickEngine,
    );

    // DEBUG: Log card play
    final suitInfo = card.isJoker ? '⭐ JOKER' : '(${card.suit.name})';
    _debugLog(
      '[PLAY] ${_state.getName(position)} plays ${card.label} $suitInfo',
    );

    // Play the card
    final result = trickEngine.playCard(
      currentTrick: _state.currentTrick!,
      card: card,
      player: position,
      playerHand: hand,
    );

    // Remove card from hand
    final newHand = List<PlayingCard>.from(hand);
    newHand.remove(card);

    _debugLog(
      '[PLAY] ${_state.getName(position)} hand size after: ${newHand.length}',
    );

    switch (position) {
      case Position.north:
        _updateState(_state.copyWith(partnerHand: newHand));
        break;
      case Position.east:
        _updateState(_state.copyWith(opponentEastHand: newHand));
        break;
      case Position.west:
        _updateState(_state.copyWith(opponentWestHand: newHand));
        break;
      case Position.south:
        break;
    }

    _updateState(
      _state.copyWith(
        currentTrick: result.trick,
        gameStatus: result.message,
        clearAiThinkingPosition: true,
      ),
    );

    if (result.status == TrickStatus.complete) {
      _handleTrickComplete(result.trick, result.winner!);
    } else {
      _advanceToNextPlayer();
    }
  }

  void _handleTrickComplete(Trick trick, Position winner) {
    // DEBUG: Log trick completion
    _debugLog(
      '\n---------- TRICK ${_state.completedTricks.length + 1} COMPLETE ----------',
    );
    _debugLog('Winner: ${_state.getName(winner)} (${winner.name})');
    final ledSuit = trick.ledSuit;
    if (ledSuit != null) {
      _debugLog('Led suit: ${ledSuit.name}');
    } else if (_state.nominatedSuit != null) {
      _debugLog(
        'Nominated suit: ${_state.nominatedSuit!.name} (joker led in no-trump)',
      );
    } else {
      _debugLog('Led suit: joker in no-trump (no suit nominated)');
    }
    _debugLog('Cards played:');
    for (final play in trick.plays) {
      final suitInfo =
          play.card.isJoker ? '⭐ JOKER' : '(${play.card.suit.name})';
      _debugLog(
        '  ${_state.getName(play.player)}: ${play.card.label} $suitInfo',
      );
    }

    // Add trick to completed tricks
    final newCompleted = [..._state.completedTricks, trick];

    // Update tricks won
    final winnerTeam = winner.team;
    var newTricksNS = _state.tricksWonNS;
    var newTricksEW = _state.tricksWonEW;

    if (winnerTeam == Team.northSouth) {
      newTricksNS++;
    } else {
      newTricksEW++;
    }

    _debugLog('Team ${winnerTeam.name} wins trick');
    _debugLog('Score: N-S: $newTricksNS, E-W: $newTricksEW');
    _debugLog('${_state.getName(winner)} will lead next trick');
    _debugLog('----------------------------------------\n');

    _updateState(
      _state.copyWith(
        completedTricks: newCompleted,
        tricksWonNS: newTricksNS,
        tricksWonEW: newTricksEW,
        gameStatus: '${_state.getName(winner)} wins trick',
      ),
    );

    // Update claim status after trick completion
    _updateClaimStatus();

    // Check if all tricks played
    if (newCompleted.length == 10) {
      // DEBUG: Verify all cards are unique
      _verifyAllCardsUnique(newCompleted);

      // Last trick - give extra time to see the cards before scoring
      Future.delayed(const Duration(milliseconds: 3000), _scoreHand);
    } else {
      // Start next trick with winner leading
      Future.delayed(const Duration(milliseconds: 2500), () {
        _startNextTrick(winner);
      });
    }
  }

  /// Verify that all 40 cards played are unique (no duplicates)
  void _verifyAllCardsUnique(List<Trick> completedTricks) {
    _debugLog('\n========== VERIFYING ALL CARDS PLAYED ==========');

    // Collect all cards played
    final allCardsPlayed = <PlayingCard>[];
    for (final trick in completedTricks) {
      for (final play in trick.plays) {
        allCardsPlayed.add(play.card);
      }
    }

    _debugLog('Total cards played: ${allCardsPlayed.length} (should be 40)');

    // Check for duplicates
    final cardCounts = <String, int>{};
    final duplicates = <String, int>{};

    for (final card in allCardsPlayed) {
      final label = card.label;
      cardCounts[label] = (cardCounts[label] ?? 0) + 1;

      if (cardCounts[label]! > 1) {
        duplicates[label] = cardCounts[label]!;
      }
    }

    if (duplicates.isEmpty) {
      _debugLog('✅ All 40 cards are unique - no duplicates found!');
    } else {
      _debugLog('⚠️⚠️⚠️ DUPLICATE CARDS FOUND! ⚠️⚠️⚠️');
      for (final entry in duplicates.entries) {
        _debugLog('  ${entry.key} appeared ${entry.value} times');
      }

      // Show which tricks had the duplicates
      _debugLog('\nDetailed breakdown by trick:');
      for (int i = 0; i < completedTricks.length; i++) {
        final trick = completedTricks[i];
        _debugLog('Trick ${i + 1}:');
        for (final play in trick.plays) {
          final isDuplicate = duplicates.containsKey(play.card.label);
          _debugLog(
            '  ${_state.getName(play.player)}: ${play.card.label}${isDuplicate ? ' ⚠️ DUPLICATE' : ''}',
          );
        }
      }
    }

    _debugLog('================================================\n');
  }

  void _startNextTrick(Position leader) {
    _updateState(
      _state.copyWith(
        currentTrick: Trick(
          plays: [],
          leader: leader,
          trumpSuit: _state.trumpSuit,
        ),
        currentPlayer: leader,
        gameStatus: '${_state.getName(leader)} leads',
        clearSelectedCardIndices: true,
        clearNominatedSuit: true, // Clear nominated suit for new trick
      ),
    );

    // Update claim status at start of new trick
    _updateClaimStatus();

    if (leader != Position.south) {
      _scheduleAIPlay();
    }
  }

  // ============================================================================
  // SCORING
  // ============================================================================

  void _scoreHand() {
    if (_state.winningBid == null || _state.contractor == null) return;

    final contractorTeam = _state.contractor!.team;
    final contractorTricks = _state.getTricksWon(contractorTeam);
    final opponentTricks = _state.getTricksWon(
      contractorTeam == Team.northSouth ? Team.eastWest : Team.northSouth,
    );

    final handScore = FiveHundredScorer.scoreHand(
      contract: _state.winningBid!,
      contractorTricks: contractorTricks,
      opponentTricks: opponentTricks,
    );

    // Apply scores
    var newScoreNS = _state.teamNorthSouthScore;
    var newScoreEW = _state.teamEastWestScore;

    if (contractorTeam == Team.northSouth) {
      newScoreNS += handScore.contractorPoints;
      newScoreEW += handScore.opponentPoints;
    } else {
      newScoreEW += handScore.contractorPoints;
      newScoreNS += handScore.opponentPoints;
    }

    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.scoring,
        isPlayPhase: false,
        teamNorthSouthScore: newScoreNS,
        teamEastWestScore: newScoreEW,
        gameStatus: FiveHundredScorer.getHandResultDescription(
          contract: _state.winningBid!,
          score: handScore,
          contractorTeam: contractorTeam,
        ),
      ),
    );

    // Show score animation
    if (handScore.contractorPoints != 0) {
      _updateState(
        _state.copyWith(
          scoreAnimation: ScoreAnimation(
            points: handScore.contractorPoints,
            team: contractorTeam,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        ),
      );

      Timer(const Duration(seconds: 2), () {
        _updateState(
          _state.copyWith(clearScoreAnimation: true),
        );
      });
    }

    // Check game over
    final gameOverStatus = FiveHundredScorer.checkGameOver(
      teamNSScore: newScoreNS,
      teamEWScore: newScoreEW,
    );

    if (gameOverStatus != null) {
      // Delay before showing game over to let user see final trick and score
      Future.delayed(const Duration(milliseconds: 3000), () {
        _handleGameOver(gameOverStatus, newScoreNS, newScoreEW);
      });
    }
    // Otherwise, stay in scoring phase - user must click "Next Hand" to continue
  }

  /// Start the next hand (public for UI button)
  void startNextHand() {
    final nextDealer = getNextDealer(_state.dealer);

    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.setup,
        dealer: nextDealer,
        playerHand: [],
        partnerHand: [],
        opponentEastHand: [],
        opponentWestHand: [],
        kitty: [],
        bidHistory: [],
        completedTricks: [],
        tricksWonNS: 0,
        tricksWonEW: 0,
        gameStatus: 'Tap Deal for next hand',
        clearCurrentBidder: true,
        clearCurrentHighBid: true,
        clearWinningBid: true,
        clearContractor: true,
        clearTrumpSuit: true,
        clearCurrentTrick: true,
        clearCurrentPlayer: true,
        clearPendingBidEntry: true,
      ),
    );
  }

  void _handleGameOver(
    GameOverStatus status,
    int finalScoreNS,
    int finalScoreEW,
  ) {
    final winningTeam = (status == GameOverStatus.teamNSWins ||
            status == GameOverStatus.teamEWLoses)
        ? Team.northSouth
        : Team.eastWest;

    final playerWon = winningTeam == Team.northSouth;

    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.gameOver,
        showGameOverDialog: true,
        gameOverData: GameOverData(
          winningTeam: winningTeam,
          finalScoreNS: finalScoreNS,
          finalScoreEW: finalScoreEW,
          status: status,
          gamesWon: playerWon ? _state.gamesWon + 1 : _state.gamesWon,
          gamesLost: playerWon ? _state.gamesLost : _state.gamesLost + 1,
        ),
        gamesWon: playerWon ? _state.gamesWon + 1 : _state.gamesWon,
        gamesLost: playerWon ? _state.gamesLost : _state.gamesLost + 1,
        gameStatus: FiveHundredScorer.getGameOverMessage(
          status,
          finalScoreNS,
          finalScoreEW,
        ),
      ),
    );
  }

  /// Dismiss game over dialog and reset for new game
  void dismissGameOverDialog() {
    _updateState(
      _state.copyWith(
        showGameOverDialog: false,
        clearGameOverData: true,
      ),
    );

    // Reset to setup
    _updateState(
      GameState(
        gameStarted: true,
        currentPhase: GamePhase.setup,
        dealer: Position.west,
        gamesWon: _state.gamesWon,
        gamesLost: _state.gamesLost,
        gameStatus: 'Tap Deal to start',
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  void _updateState(GameState newState) {
    // Log phase transitions
    if (_state.currentPhase != newState.currentPhase) {
      _debugLog(
        '\n[PHASE TRANSITION] ${_state.currentPhase.name} -> ${newState.currentPhase.name}',
      );
      if (newState.gameStatus.isNotEmpty) {
        _debugLog('Status: ${newState.gameStatus}');
      }
    }

    _state = newState;
    notifyListeners();
  }
}
